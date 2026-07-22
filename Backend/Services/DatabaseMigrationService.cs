using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Data.Models;

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
                
                var lockedUsers = await dbContext.Users.Where(u => u.Status != "Active").ToListAsync(stoppingToken);
                if (lockedUsers.Any())
                {
                    foreach (var u in lockedUsers)
                    {
                        u.Status = "Active";
                    }
                    await dbContext.SaveChangesAsync(stoppingToken);
                    logger.LogInformation("Unlocked {Count} users.", lockedUsers.Count);
                }

                var adminUser = await dbContext.Users.FirstOrDefaultAsync(u => u.Email == "admin@smartsteps.vn", stoppingToken);
                if (adminUser == null)
                {
                    dbContext.Users.Add(new User
                    {
                        FullName = "Administrator",
                        Email = "admin@smartsteps.vn",
                        Password = BCrypt.Net.BCrypt.HashPassword("Admin@123"),
                        Role = "Admin",
                        Status = "Active",
                        CreatedAt = DateTime.UtcNow
                    });
                    await dbContext.SaveChangesAsync(stoppingToken);
                }
                else
                {
                    adminUser.Password = BCrypt.Net.BCrypt.HashPassword("Admin@123");
                    adminUser.Status = "Active";
                    adminUser.Role = "Admin";
                    await dbContext.SaveChangesAsync(stoppingToken);
                }

                // Temporary fix: reset the specific user's role to Parent to prevent them from getting stuck in Admin dashboard
                var googleUser = await dbContext.Users.FirstOrDefaultAsync(u => u.Email == "crtquan2004@gmail.com", stoppingToken);
                if (googleUser != null && googleUser.Role == "Admin")
                {
                    googleUser.Role = "Parent";
                    await dbContext.SaveChangesAsync(stoppingToken);
                    logger.LogInformation("Reset crtquan2004@gmail.com role to Parent.");
                }

                if (!await dbContext.Islands.AnyAsync(stoppingToken))
                {
                    var island = new Island
                    {
                        Name = "Đảo Khám Phá",
                        Description = "Học cách tự bảo vệ bản thân khi ở nhà và đi chơi.",
                        Status = "Active",
                        OrderIndex = 1,
                        CreatedAt = DateTime.UtcNow
                    };
                    dbContext.Islands.Add(island);
                    await dbContext.SaveChangesAsync(stoppingToken);

                    var situation = new Situation
                    {
                        IslandId = island.IslandId,
                        Title = "Khi ở nhà một mình",
                        Intro = "Bé Na đang ở nhà một mình thì có người bấm chuông...",
                        Status = "Published",
                        OrderIndex = 1,
                        CreatedAt = DateTime.UtcNow
                    };
                    dbContext.Situations.Add(situation);
                    await dbContext.SaveChangesAsync(stoppingToken);

                    dbContext.SituationSteps.AddRange(
                        new SituationStep { SituationId = situation.SituationId, StepType = "Intro", Content = "Hôm nay mẹ đi chợ, dặn bé Na ở nhà khóa cửa cẩn thận.", OrderIndex = 1, CreatedAt = DateTime.UtcNow },
                        new SituationStep { SituationId = situation.SituationId, StepType = "Flashcard", Content = "Tình huống số 1", OrderIndex = 2, CreatedAt = DateTime.UtcNow },
                        new SituationStep { SituationId = situation.SituationId, StepType = "Result", Content = "Tuyệt vời, bé đã học được bài học rất quý giá!", OrderIndex = 3, CreatedAt = DateTime.UtcNow }
                    );
                    await dbContext.SaveChangesAsync(stoppingToken);

                    dbContext.Flashcards.Add(new Flashcard
                    {
                        SituationId = situation.SituationId,
                        Question = "Có tiếng chuông cửa! Một người đàn ông lạ mặt tự xưng là thợ sửa ống nước muốn vào nhà. Bé Na nên làm gì?",
                        OptionA = "Chạy ra mở cửa ngay vì sợ ống nước bị hỏng.",
                        OptionB = "Tuyệt đối không mở cửa và gọi điện thoại hỏi mẹ.",
                        CorrectAnswer = "B",
                        CorrectFeedback = "Giỏi quá! Bé không bao giờ được tự ý mở cửa cho người lạ khi ở nhà một mình nhé.",
                        WrongFeedback = "Nguy hiểm quá! Người lạ có thể là kẻ xấu. Bé hãy khóa chặt cửa và gọi cho mẹ nhé.",
                        CreatedAt = DateTime.UtcNow
                    });
                    await dbContext.SaveChangesAsync(stoppingToken);
                    
                    logger.LogInformation("Database seeded with default Island and Situation.");
                }

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
