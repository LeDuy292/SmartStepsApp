using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Options;
using SmartStepsServer.Services;

LoadDotEnv(Path.Combine(AppContext.BaseDirectory, ".env"));
LoadDotEnv(Path.Combine(Directory.GetCurrentDirectory(), ".env"));
LoadDotEnv(Path.Combine(Directory.GetCurrentDirectory(), "..", ".env"));
UseLocalDatabaseHostOutsideContainer();

var builder = WebApplication.CreateBuilder(args);

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
if (string.IsNullOrWhiteSpace(configuredOrigins) && builder.Environment.IsDevelopment())
{
    configuredOrigins = "http://localhost:3000";
}

var allowedOrigins = (configuredOrigins ?? string.Empty)
    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
    .Distinct(StringComparer.OrdinalIgnoreCase)
    .ToArray();

// Add services to the container.
builder.Services.AddDbContext<SmartStepsDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        npgsqlOptions => npgsqlOptions.EnableRetryOnFailure()));

builder.Services.Configure<CloudinaryMediaOptions>(
    builder.Configuration.GetSection(CloudinaryMediaOptions.SectionName));
builder.Services.Configure<PayOsOptions>(
    builder.Configuration.GetSection(PayOsOptions.SectionName));

builder.Services.AddHttpClient<ICloudinaryMediaService, CloudinaryMediaService>();
builder.Services.AddHttpClient<IPayOsService, PayOsService>();
builder.Services.AddHostedService<DatabaseMigrationService>();

builder.Services.AddControllers();

builder.Services.AddCors(options =>
{
    options.AddPolicy(name: AllowReactApp, policy =>
    {
        if (allowedOrigins.Length > 0)
        {
            policy.WithOrigins(allowedOrigins);
        }

        policy.AllowAnyHeader()
              .AllowAnyMethod();
    });
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

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

app.UseAuthorization();

app.MapGet("/health", () => Results.Text("OK"));
app.MapControllers();

app.Run();

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
