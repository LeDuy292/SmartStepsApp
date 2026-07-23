using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Options;
using SmartStepsServer.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

LoadDotEnv(Path.Combine(AppContext.BaseDirectory, ".env"));
LoadDotEnv(Path.Combine(Directory.GetCurrentDirectory(), ".env"));
LoadDotEnv(Path.Combine(Directory.GetCurrentDirectory(), "..", ".env"));
UseLocalDatabaseHostOutsideContainer();

var builder = WebApplication.CreateBuilder(args);

// Console logging works consistently in local development, containers and
// Railway. The Windows Event Log provider can fail for non-admin users.
builder.Logging.ClearProviders();
builder.Logging.AddConsole();

const string AllowReactApp = "_allowReactApp";
var port = builder.Configuration["PORT"];

if (string.IsNullOrWhiteSpace(port))
{
    port = "8080";
}

if (!int.TryParse(port, out var parsedPort) || parsedPort is < 1 or > 65535)
{
    throw new InvalidOperationException("PORT must be a number between 1 and 65535.");
}

builder.WebHost.UseUrls($"http://+:{parsedPort}");

var configuredOrigins = builder.Configuration["Cors:AllowedOrigins"];

var allowedOrigins = (configuredOrigins ?? string.Empty)
    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
    .Distinct(StringComparer.OrdinalIgnoreCase)
    .ToArray();

// Add services to the container.
builder.Services.AddDbContext<SmartStepsDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        npgsqlOptions => npgsqlOptions.EnableRetryOnFailure()));

builder.Services.Configure<SupabaseOptions>(
    builder.Configuration.GetSection("Supabase"));
builder.Services.Configure<PayOsOptions>(
    builder.Configuration.GetSection(PayOsOptions.SectionName));
builder.Services.Configure<DeepSeekOptions>(
    builder.Configuration.GetSection(DeepSeekOptions.SectionName));

builder.Services.AddHttpClient<IPayOsService, PayOsService>();
builder.Services.AddHttpClient<IAiNarrativeService, DeepSeekNarrativeService>((serviceProvider, client) =>
{
    var options = serviceProvider
        .GetRequiredService<Microsoft.Extensions.Options.IOptions<DeepSeekOptions>>()
        .Value;
    client.BaseAddress = new Uri(options.BaseUrl.TrimEnd('/') + "/");
});
builder.Services.AddHostedService<DatabaseMigrationService>();
builder.Services.AddScoped<ILearningAnalysisService, LearningAnalysisService>();

builder.Services.AddControllers();

builder.Services.AddCors(options =>
{
    options.AddPolicy(name: AllowReactApp, policy =>
    {
        policy.SetIsOriginAllowed(origin =>
            allowedOrigins.Contains(origin, StringComparer.OrdinalIgnoreCase) ||
            (builder.Environment.IsDevelopment() && IsLoopbackOrigin(origin)));

        policy.AllowAnyHeader()
              .AllowAnyMethod();
    });
});

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!)),
            RoleClaimType = System.Security.Claims.ClaimTypes.Role,
            NameClaimType = System.Security.Claims.ClaimTypes.Name
        };
    });

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddScoped<SmartStepsServer.Services.IEmailService, SmartStepsServer.Services.EmailService>();

var app = builder.Build();

if (app.Environment.IsDevelopment() || builder.Configuration.GetValue<bool>("Swagger:Enabled"))
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

if (builder.Configuration.GetValue<bool>("HttpsRedirection:Enabled"))
{
    app.UseHttpsRedirection();
}

// CORS phải đặt trước Authorization
app.UseCors(AllowReactApp);

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/health", () => Results.Text("OK"));
app.MapControllers();

using (var scope = app.Services.CreateScope())
{
    try
    {
        var db = scope.ServiceProvider.GetRequiredService<SmartStepsDbContext>();
        db.Database.EnsureCreated();
    }
    catch (Exception ex)
    {
        Console.WriteLine($"DB Init warning: {ex.Message}");
    }
}

app.Run();

static bool IsLoopbackOrigin(string origin)
{
    return Uri.TryCreate(origin, UriKind.Absolute, out var uri) &&
        (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps) &&
        uri.IsLoopback;
}

static void LoadDotEnv(string path)
{
    if (!File.Exists(path))
    {
        return;
    }

    foreach (var rawLine in File.ReadAllLines(path))
    {
        var line = rawLine.Trim();
        if (string.IsNullOrWhiteSpace(line) || line.StartsWith('#'))
        {
            continue;
        }

        if (line.StartsWith("$env:", StringComparison.OrdinalIgnoreCase))
        {
            line = line[5..];
        }

        var separatorIndex = line.IndexOf('=');
        if (separatorIndex <= 0)
        {
            continue;
        }

        var key = line[..separatorIndex].Trim();
        var value = line[(separatorIndex + 1)..].Trim();

        if (string.IsNullOrWhiteSpace(key))
        {
            continue;
        }

        if ((value.StartsWith('"') && value.EndsWith('"')) ||
            (value.StartsWith('\'') && value.EndsWith('\'')))
        {
            value = value[1..^1];
        }

        if (string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable(key)))
        {
            Environment.SetEnvironmentVariable(key, value);
        }
    }
}

static void UseLocalDatabaseHostOutsideContainer()
{
    var isRunningInContainer = string.Equals(
        Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER"),
        "true",
        StringComparison.OrdinalIgnoreCase);

    if (isRunningInContainer)
    {
        return;
    }

    const string connectionStringKey = "ConnectionStrings__DefaultConnection";
    var connectionString = Environment.GetEnvironmentVariable(connectionStringKey);

    if (string.IsNullOrWhiteSpace(connectionString))
    {
        return;
    }

    var usesDockerDatabaseHost =
        connectionString.Contains("Host=smartsteps-db", StringComparison.OrdinalIgnoreCase) ||
        connectionString.Contains("Server=smartsteps-db", StringComparison.OrdinalIgnoreCase);

    connectionString = connectionString
        .Replace("Host=smartsteps-db", "Host=localhost", StringComparison.OrdinalIgnoreCase)
        .Replace("Server=smartsteps-db", "Server=localhost", StringComparison.OrdinalIgnoreCase);

    var hostPortValue = Environment.GetEnvironmentVariable("POSTGRES_HOST_PORT");
    if (usesDockerDatabaseHost &&
        int.TryParse(hostPortValue, out var hostPort) &&
        hostPort is >= 1 and <= 65535)
    {
        connectionString = connectionString.Replace(
            "Port=5432",
            $"Port={hostPort}",
            StringComparison.OrdinalIgnoreCase);
    }

    Environment.SetEnvironmentVariable(connectionStringKey, connectionString);
}
