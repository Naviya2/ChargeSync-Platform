using System.Diagnostics;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Npgsql;

try
{
    if (args.Length != 3) throw new InvalidOperationException("Expected settings, runtime and output paths.");
    using var settings = JsonDocument.Parse(await File.ReadAllTextAsync(args[0]));
    using var runtime = JsonDocument.Parse(await File.ReadAllTextAsync(args[1]));
    if (!settings.RootElement.GetProperty("disposableDatabase").GetBoolean())
        throw new InvalidOperationException("Only the disposable E2E database is allowed.");
    var connectionString = new NpgsqlConnectionStringBuilder(settings.RootElement.GetProperty("postgresConnection").GetString());
    var fingerprint = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(connectionString.ConnectionString)));
    if (fingerprint != runtime.RootElement.GetProperty("databaseFingerprint").GetString())
        throw new InvalidOperationException("Database and runtime do not match.");
    var clock = Stopwatch.StartNew();
    await using var connection = new NpgsqlConnection(connectionString.ConnectionString);
    await connection.OpenAsync();
    var connectionOpenMs = clock.Elapsed.TotalMilliseconds;
    await using (var marker = new NpgsqlCommand("SELECT count(*) FROM public.\"__ChargeSyncE2E\" WHERE \"ProjectRef\"=@ref AND \"Purpose\"='ChargeSync disposable E2E database'", connection))
    {
        marker.Parameters.AddWithValue("ref", settings.RootElement.GetProperty("supabaseProjectRef").GetString()!);
        if (Convert.ToInt64(await marker.ExecuteScalarAsync()) != 1) throw new InvalidOperationException("E2E marker mismatch.");
    }
    var driver = runtime.RootElement.GetProperty("driver").GetProperty("id").GetGuid();
    var queries = new[] {
        (Name: "stations", Sql: "SELECT \"Id\", \"Name\" FROM \"Stations\" LIMIT 50", Table: "Stations"),
        (Name: "driver-reservations", Sql: "SELECT * FROM \"Reservations\" WHERE \"DriverId\"=@driver ORDER BY \"StartTime\" DESC LIMIT 50", Table: "Reservations"),
        (Name: "driver-invoices", Sql: "SELECT * FROM \"PaymentInvoices\" WHERE \"DriverId\"=@driver LIMIT 50", Table: "PaymentInvoices")
    };
    var results = new List<object>();
    foreach (var query in queries)
    {
        await using var count = new NpgsqlCommand($"SELECT count(*) FROM \"{query.Table}\"", connection);
        var tableRows = Convert.ToInt64(await count.ExecuteScalarAsync());
        var serverTimes = new List<double>();
        var clientTimes = new List<double>();
        var returnedRows = new List<int>();
        JsonElement plan = default;
        // Minimal baseline: one first run and two subsequent warmed measurements.
        double firstServerMs = 0, firstClientMs = 0;
        for (var i = 0; i < 3; i++)
        {
            await using var command = new NpgsqlCommand("EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) " + query.Sql, connection);
            command.Parameters.AddWithValue("driver", driver);
            clock.Restart();
            var raw = (string)(await command.ExecuteScalarAsync())!;
            var clientMs = clock.Elapsed.TotalMilliseconds;
            using var parsed = JsonDocument.Parse(raw);
            var root = parsed.RootElement[0];
            var serverMs = root.GetProperty("Execution Time").GetDouble();
            if (i == 0) { firstServerMs = serverMs; firstClientMs = clientMs; }
            else { serverTimes.Add(serverMs); clientTimes.Add(clientMs); returnedRows.Add(root.GetProperty("Plan").GetProperty("Actual Rows").GetInt32()); }
            plan = root.Clone();
        }
        results.Add(new { name = query.Name, sql = query.Sql, tableRows, firstServerMs, firstClientMs,
            samples = serverTimes.Count, serverExecutionMs = Stats(serverTimes), clientRoundTripMs = Stats(clientTimes),
            returnedRows, explainPlan = plan });
    }
    await File.WriteAllTextAsync(args[2], JsonSerializer.Serialize(new { measuredAt = DateTimeOffset.UtcNow,
        connectionOpenMs, environment = "Local .NET probe to isolated cloud Supabase; persistent connection", queries = results },
        new JsonSerializerOptions { WriteIndented = true }));
    Console.WriteLine("Database timings saved: three read-only SELECT queries, three measurements each.");
    return 0;
}
catch (Exception ex)
{
    Console.Error.WriteLine($"Database measurement failed: {ex.GetType().Name}. No credentials were printed.");
    return 1;
}

static object Stats(List<double> values)
{
    var ordered = values.Order().ToArray();
    return new { average = values.Average(), minimum = ordered[0], maximum = ordered[^1],
        p95 = ordered[(int)Math.Ceiling(ordered.Length * .95) - 1], observations = values };
}
