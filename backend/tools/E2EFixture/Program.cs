using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Domain.Entities;
using Domain.Enums;
using Domain.Users;
using Infrastructure.Authentication;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Npgsql;

// Explicit settings only: never inherit the normal application's database.
try
{
    if (args.Length < 3 || args[0] is not ("prepare" or "validate" or "check-config" or "verify") ||
        !(args.Length == 3 && args[0] != "verify" || args.Length == 4 &&
          (args[0] == "verify" || args[0] == "prepare" && args[3] == "--keep-jwt")))
        throw new SetupException("Usage: E2EFixture prepare|validate|check-config|verify settings.local.json runtime.local.json [outcome.json]");

    var jsonOptions = new JsonSerializerOptions { PropertyNameCaseInsensitive = true, WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
    if (!File.Exists(args[1]))
        throw new SetupException("Create e2e/settings.local.json from settings.example.json and fill in the NEW test project details.");
    var settings = JsonSerializer.Deserialize<Settings>(await File.ReadAllTextAsync(args[1]), jsonOptions)
        ?? throw new SetupException("Settings must contain a JSON object.");
    if (!settings.DisposableDatabase)
        throw new SetupException("Set disposableDatabase=true only for your separate E2E Supabase project.");
    if (!Regex.IsMatch(settings.SupabaseProjectRef, "^[a-z0-9]{20}$"))
        throw new SetupException("supabaseProjectRef must be the 20-character reference of the NEW Supabase project.");

    NpgsqlConnectionStringBuilder target;
    try { target = new(settings.PostgresConnection); }
    catch (ArgumentException) { throw new SetupException("postgresConnection must be a valid Npgsql connection string (Host=...;Port=...;...)."); }
    var direct = target.Host == $"db.{settings.SupabaseProjectRef}.supabase.co";
    var pooler = (target.Host ?? "").EndsWith(".pooler.supabase.com", StringComparison.OrdinalIgnoreCase)
        && target.Username == $"postgres.{settings.SupabaseProjectRef}";
    if ((!direct && !pooler) || target.Port != 5432 || target.Database != "postgres" || string.IsNullOrWhiteSpace(target.Password))
        throw new SetupException("Use the new project's direct connection or session pooler on port 5432, database postgres. The host/username must match supabaseProjectRef.");
    if (target.SslMode is not (SslMode.Require or SslMode.VerifyCA or SslMode.VerifyFull))
        throw new SetupException("The test database connection must require SSL.");
    if (settings.PostgresConnection.Contains("REPLACE", StringComparison.OrdinalIgnoreCase))
        throw new SetupException("Replace all placeholder database values in settings.local.json.");

    var fingerprint = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(target.ConnectionString)));
    if (args[0] == "check-config")
    {
        Console.WriteLine("Configuration format checked. No database connection or writes were made.");
        return 0;
    }

    await using var connection = new NpgsqlConnection(target.ConnectionString);
    await connection.OpenAsync();
    // A shared database with existing public tables cannot be adopted as a test database.
    await using (var check = new NpgsqlCommand("SELECT to_regclass('public.\"__ChargeSyncE2E\"') IS NOT NULL", connection))
    {
        var hasMarker = (bool)(await check.ExecuteScalarAsync())!;
        if (!hasMarker)
        {
            if (args[0] is "validate" or "verify")
                throw new SetupException("The database has not been prepared as an E2E database.");
            await using var tables = new NpgsqlCommand("SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE'", connection);
            if (Convert.ToInt64(await tables.ExecuteScalarAsync()) != 0)
                throw new SetupException("Refusing to modify a database with existing public tables. Use a NEW, empty Supabase project.");
            await using var marker = new NpgsqlCommand("CREATE TABLE public.\"__ChargeSyncE2E\" (\"ProjectRef\" text PRIMARY KEY, \"Purpose\" text NOT NULL)", connection);
            await marker.ExecuteNonQueryAsync();
            await using var insert = new NpgsqlCommand("INSERT INTO public.\"__ChargeSyncE2E\" VALUES (@ref, 'ChargeSync disposable E2E database')", connection);
            insert.Parameters.AddWithValue("ref", settings.SupabaseProjectRef);
            await insert.ExecuteNonQueryAsync();
        }
    }
    await using (var marker = new NpgsqlCommand("SELECT count(*) FROM public.\"__ChargeSyncE2E\" WHERE \"ProjectRef\"=@ref AND \"Purpose\"='ChargeSync disposable E2E database'", connection))
    {
        marker.Parameters.AddWithValue("ref", settings.SupabaseProjectRef);
        if (Convert.ToInt64(await marker.ExecuteScalarAsync()) != 1)
            throw new SetupException("E2E database marker does not match the configured project.");
    }
    await connection.CloseAsync();

    var options = new DbContextOptionsBuilder<AppDbContext>().UseNpgsql(target.ConnectionString).Options;
    await using var db = new AppDbContext(options);
    if (args[0] is "validate" or "verify")
    {
        if (!File.Exists(args[2])) throw new SetupException("Run Prepare.ps1 first to create the test accounts.");
        var runtime = JsonSerializer.Deserialize<Runtime>(await File.ReadAllTextAsync(args[2]), jsonOptions)
            ?? throw new SetupException("Invalid runtime settings.");
        if (runtime.DatabaseFingerprint != fingerprint ||
            !await db.Users.AnyAsync(u => u.Id == runtime.Driver.Id && u.Role == UserRole.Driver) ||
            !await db.Users.AnyAsync(u => u.Id == runtime.Owner.Id && u.Role == UserRole.StationOwner) ||
            !await db.Users.AnyAsync(u => u.Id == runtime.Admin.Id && u.Role == UserRole.Admin) ||
            !await db.Chargers.AnyAsync(c => c.Id == runtime.ChargerId && c.StationId == runtime.StationId) ||
            !await db.Vehicles.AnyAsync(v => v.Id == runtime.VehicleId && v.OwnerId == runtime.Driver.Id))
            throw new SetupException("Runtime accounts do not match this database. Run Prepare.ps1 again.");
        if (args[0] == "verify")
        {
            var outcome = JsonSerializer.Deserialize<Outcome>(await File.ReadAllTextAsync(args[3]), jsonOptions)
                ?? throw new SetupException("Missing completed workflow identifiers.");
            var invoice = await db.PaymentInvoices.AsNoTracking().SingleAsync(i => i.Id == outcome.InvoiceId);
            var session = await db.ChargingSessions.AsNoTracking().SingleAsync(s => s.Id == outcome.SessionId);
            var reservation = await db.Reservations.AsNoTracking().SingleAsync(r => r.Id == outcome.ReservationId);
            var ticket = await db.SupportTickets.AsNoTracking().SingleAsync(t => t.Id == outcome.TicketId);
            var workflow = await db.AgentWorkflowRuns.AsNoTracking().SingleAsync(w => w.TicketId == ticket.Id);
            var persistedDriver = await db.Users.AsNoTracking().SingleAsync(u => u.Id == runtime.Driver.Id);
            if (invoice.DriverId != persistedDriver.Id || invoice.SessionId != session.Id ||
                session.ReservationId != reservation.Id || reservation.DriverId != persistedDriver.Id ||
                reservation.ChargerId != runtime.ChargerId || session.Status != ChargingSessionStatus.Completed ||
                reservation.Status != ReservationStatus.Completed || invoice.Status != InvoiceStatus.Paid ||
                invoice.PaymentMethod != PaymentMethod.Wallet || invoice.RefundedAmount != 20m ||
                outcome.RefundAmount != 20m || ticket.DriverId != persistedDriver.Id || ticket.InvoiceId != invoice.Id ||
                ticket.RefundStatus != "Approved" || ticket.RequestedRefundAmount != 20m ||
                workflow.Status != Domain.Support.AgentWorkflowStatus.Completed || workflow.Decision != "Approved" ||
                workflow.ReviewedBy != runtime.Admin.Id || workflow.Action != "Refund" || workflow.Amount != 20m ||
                persistedDriver.WalletBalance != runtime.InitialWalletBalance - invoice.NetAmountDue + 20m ||
                invoice.GrossAmount != decimal.Round(session.FinalEnergyDeliveredKwh!.Value * invoice.TariffPerKwh, 2, MidpointRounding.AwayFromZero) ||
                await db.PaymentInvoices.CountAsync(i => i.SessionId == session.Id) != 1)
                throw new SetupException("PostgreSQL verification failed: session, invoice, approval or wallet does not match the expected workflow.");
            Console.WriteLine("Verified persisted E2E session, invoice arithmetic, refund approval and single wallet credit.");
        }
        else Console.WriteLine("Verified isolated database and test accounts.");
        return 0;
    }

    var jwtKey = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
    if (args.Length == 4 && args[3] == "--keep-jwt")
    {
        if (!File.Exists(args[2])) throw new SetupException("No existing test JWT key to keep. Prepare normally first.");
        var previous = JsonSerializer.Deserialize<Runtime>(await File.ReadAllTextAsync(args[2]), jsonOptions);
        if (previous?.DatabaseFingerprint == fingerprint && Regex.IsMatch(previous.JwtKey, "^[A-F0-9]{64}$"))
            jwtKey = previous.JwtKey;
        else throw new SetupException("Cannot keep the JWT key across a changed database connection. Prepare normally and restart the E2E backend.");
    }
    await db.Database.MigrateAsync();
    // Each invocation creates fresh accounts so earlier bookings and refunds cannot affect the next run.
    var runId = Guid.NewGuid().ToString("N")[..12];
    var password = "E2e!" + Convert.ToHexString(RandomNumberGenerator.GetBytes(16));
    var hasher = new BcryptPasswordHasher();
    var hash = hasher.Hash(password);
    var driver = User.Create("E2E Driver", $"driver-{runId}@example.test", hash, UserRole.Driver);
    var owner = User.Create("E2E Station Owner", $"owner-{runId}@example.test", hash, UserRole.StationOwner);
    var admin = User.Create("E2E Administrator", $"admin-{runId}@example.test", hash, UserRole.Admin);
    driver.CreditBalance(10000m);
    // All fixture data is atomic. Migrations and the E2E marker are retained if fixture creation fails.
    await using var transaction = await db.Database.BeginTransactionAsync();
    db.Users.AddRange(driver, owner, admin);
    await db.SaveChangesAsync();
    var station = Station.Create($"E2E Station {runId}", "E2E test address", 6.9271, 79.8612, owner.Id);
    station.Approve();
    db.Stations.Add(station);
    await db.SaveChangesAsync();
    var charger = Charger.Create(station.Id, $"E2E-{runId}", "E2E Bay", ConnectorType.CCS2, 20m, 1000m);
    var vehicle = Vehicle.Create(driver.Id, "E2E", "Test vehicle", ConnectorType.CCS2, 50m, 50m);
    db.Chargers.Add(charger);
    db.Vehicles.Add(vehicle);
    for (var day = 0; day < 7; day++)
        db.OperatingHours.Add(OperatingHour.Create(station.Id, day, true, TimeSpan.Zero, new TimeSpan(23, 59, 59)));
    await db.SaveChangesAsync();
    await transaction.CommitAsync();

    var output = new Runtime(runId, fingerprint,
        new Account(driver.Id, driver.Email, password), new Account(owner.Id, owner.Email, password),
        new Account(admin.Id, admin.Email, password), station.Id, charger.Id, vehicle.Id,
        jwtKey, 10000m);
    var outputPath = Path.GetFullPath(args[2]);
    Directory.CreateDirectory(Path.GetDirectoryName(outputPath)!);
    await File.WriteAllTextAsync(outputPath, JsonSerializer.Serialize(output, jsonOptions));
    Console.WriteLine("Prepared E2E database: migrations, 3 accounts, funded driver wallet, station, charger and vehicle.");
    Console.WriteLine("Credentials were saved to the ignored runtime.local.json file. No E2E workflow has been run yet.");
    return 0;
}
catch (SetupException ex)
{
    Console.Error.WriteLine(ex.Message);
    return 1;
}
catch (Exception ex)
{
    // Do not log connection strings, passwords or database parameter values.
    var detail = ex is PostgresException pg ? $" (PostgreSQL SQLSTATE {pg.SqlState})" : "";
    Console.Error.WriteLine($"E2E setup failed: {ex.GetType().Name}{detail}. Check the test connection, project availability and migrations. Credentials were not printed.");
    return 1;
}

sealed class SetupException(string message) : Exception(message);
sealed record Settings(bool DisposableDatabase, string SupabaseProjectRef, string PostgresConnection,
    string AgentServiceUrl, string AgentServiceApiKey);
sealed record Account(Guid Id, string Email, string Password);
sealed record Runtime(string RunId, string DatabaseFingerprint, Account Driver, Account Owner, Account Admin,
    Guid StationId, Guid ChargerId, Guid VehicleId, string JwtKey, decimal InitialWalletBalance);
sealed record Outcome(Guid TicketId, Guid InvoiceId, Guid SessionId, Guid ReservationId, decimal RefundAmount);
