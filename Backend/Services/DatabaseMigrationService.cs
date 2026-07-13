using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;

namespace SmartStepsServer.Services;

public sealed class DatabaseMigrationService(
    IConfiguration configuration,
    IServiceScopeFactory scopeFactory,
    ILogger<DatabaseMigrationService> logger) : BackgroundService
{
    private static readonly TimeSpan RetryDelay = TimeSpan.FromSeconds(15);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Let Kestrel start first so liveness checks work while the database starts.
        await Task.Yield();

        while (!stoppingToken.IsCancellationRequested)
        {
            var connectionString = configuration.GetConnectionString("DefaultConnection");

            if (string.IsNullOrWhiteSpace(connectionString))
            {
                logger.LogError(
                    "Database migration is waiting for the required environment variable " +
                    "ConnectionStrings__DefaultConnection.");
                await DelayBeforeRetry(stoppingToken);
                continue;
            }

            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<SmartStepsDbContext>();

                await dbContext.Database.MigrateAsync(stoppingToken);
                logger.LogInformation("Database migrations completed successfully.");
                return;
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                return;
            }
            catch (ObjectDisposedException)
            {
                // The host can dispose DI services before the background token is
                // observed when startup fails, for example when the port is occupied.
                return;
            }
            catch (Exception exception)
            {
                logger.LogError(
                    exception,
                    "Database migration failed. Retrying in {RetrySeconds} seconds.",
                    RetryDelay.TotalSeconds);
                await DelayBeforeRetry(stoppingToken);
            }
        }
    }

    private static async Task DelayBeforeRetry(CancellationToken stoppingToken)
    {
        try
        {
            await Task.Delay(RetryDelay, stoppingToken);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Normal shutdown.
        }
    }
}
