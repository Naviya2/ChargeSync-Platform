using System.Text;
using System.Text.Json.Serialization;
using Api.Common;
using Application;
using Infrastructure;
using Infrastructure.Authentication;
using AgentClient;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Dynamically bind to cloud-assigned PORT (e.g. Render, Railway) if set
var port = Environment.GetEnvironmentVariable("PORT");
if (!string.IsNullOrEmpty(port))
{
    builder.WebHost.UseUrls($"http://0.0.0.0:{port}");
}

builder.Services
    .AddControllers()
    .AddJsonOptions(options =>
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));

builder.Services.AddApplication();
var workflowPolicy = builder.Configuration.GetSection("SupportWorkflow").Get<Application.Support.SupportWorkflowPolicy>() ?? new();
if (workflowPolicy.RefundApprovalThresholdLkr < 0) throw new InvalidOperationException("Refund approval threshold cannot be negative.");
builder.Services.AddSingleton(workflowPolicy);
builder.Services.AddHostedService<Api.SupportWorkflowWorker>();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddAgentClient(builder.Configuration);

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<Application.Common.Interfaces.ICurrentUser, Api.Authentication.CurrentUser>();

var jwtSettings = builder.Configuration.GetSection(JwtSettings.SectionName).Get<JwtSettings>()
    ?? throw new InvalidOperationException("Missing 'Jwt' configuration section.");

if (string.IsNullOrWhiteSpace(jwtSettings.Key))
{
    throw new InvalidOperationException(
        "Jwt:Key is not configured. Set it with: dotnet user-secrets set \"Jwt:Key\" \"<32+ char secret>\" --project src/Api");
}

var groqApiKey = builder.Configuration["Groq:ApiKey"];
if (string.IsNullOrWhiteSpace(groqApiKey))
{
    // Groq key is optional at startup; AI planning endpoints will fail gracefully at request time.
    // To configure: dotnet user-secrets set "Groq:ApiKey" "<your-key>" --project src/Api
    Console.WriteLine("WARNING: Groq:ApiKey is not configured. AI planning features will be unavailable.");
}

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        // Keep JWT claim names as issued ("sub", "role", ...) instead of remapping to legacy URIs.
        options.MapInboundClaims = false;

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtSettings.Issuer,
            ValidateAudience = true,
            ValidAudience = jwtSettings.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.Key)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(30)
        };
    });

builder.Services.AddAuthorizationBuilder()
    .SetFallbackPolicy(new AuthorizationPolicyBuilder().RequireAuthenticatedUser().Build())
    .AddPolicy(AuthorizationPolicies.Admin, p => p.RequireRole("Admin"))
    .AddPolicy(AuthorizationPolicies.StationOwner, p => p.RequireRole("StationOwner", "Admin"))
    .AddPolicy(AuthorizationPolicies.SupportManager, p => p.RequireRole("SupportManager", "Admin"))
    .AddPolicy(AuthorizationPolicies.Driver, p => p.RequireRole("Driver"));

builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

// Allow Flutter web (Chrome) and any local dev origin to reach the API.
builder.Services.AddCors(options =>
{
    options.AddPolicy("FlutterDev", policy =>
    {
        policy
            .AllowAnyOrigin()   // tighten to specific origins in production
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "ChargeSync API", Version = "v1" });

    var scheme = new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Paste the JWT returned by /api/auth/login (no 'Bearer ' prefix).",
        Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
    };

    options.AddSecurityDefinition("Bearer", scheme);
    options.AddSecurityRequirement(new OpenApiSecurityRequirement { [scheme] = Array.Empty<string>() });
});

var app = builder.Build();

await app.Services.InitialiseDatabaseAsync();

app.UseExceptionHandler();

app.UseCors("FlutterDev");  // must be before Auth middleware

// Always enable Swagger for easier testing/debugging in all environments
app.UseSwagger();
app.UseSwaggerUI();

app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedFor | Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedProto
});

if (!app.Environment.IsProduction())
{
    app.UseHttpsRedirection();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/health", () => Results.Ok(new { status = "Healthy", timestamp = DateTime.UtcNow }))
    .AllowAnonymous();

app.MapControllers();

app.Run();

/// <summary>Exposed so the integration-test host can reference the entry point.</summary>
public partial class Program;
