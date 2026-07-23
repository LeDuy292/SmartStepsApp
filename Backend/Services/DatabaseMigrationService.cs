using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Data.Models;

namespace SmartStepsServer.Services;

public sealed class DatabaseMigrationService(
    IConfiguration configuration,
    IServiceScopeFactory scopeFactory,
    IHostEnvironment environment,
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

                if (environment.IsDevelopment() || configuration.GetValue<bool>("Seed:SampleFeedback"))
                {
                    await SeedSampleFeedbackAsync(dbContext, logger, stoppingToken);
                }
                
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

    private static async Task SeedSampleFeedbackAsync(
        SmartStepsDbContext dbContext,
        ILogger logger,
        CancellationToken cancellationToken)
    {
        var sampleUsers = new[]
        {
            new DemoFeedbackUser("Nguyễn Văn Hùng", "nguyen.vanhung@smartsteps.vn"),
            new DemoFeedbackUser("Nguyễn Văn Bình", "nguyen.vanbinh@smartsteps.vn"),
            new DemoFeedbackUser("Trần Minh Châu", "tran.minhchau@smartsteps.vn"),
            new DemoFeedbackUser("Lê Gia Hân", "le.giahan@smartsteps.vn"),
            new DemoFeedbackUser("Phạm An Nhiên", "pham.annhien@smartsteps.vn")
        };

        var sampleEmails = sampleUsers.Select(user => user.Email).ToArray();
        var existingUsers = await dbContext.Users
            .Where(user => sampleEmails.Contains(user.Email))
            .ToDictionaryAsync(user => user.Email, cancellationToken);

        foreach (var sampleUser in sampleUsers)
        {
            if (!existingUsers.ContainsKey(sampleUser.Email))
            {
                dbContext.Users.Add(new User
                {
                    FullName = sampleUser.FullName,
                    Email = sampleUser.Email,
                    Password = BCrypt.Net.BCrypt.HashPassword("Demo@123"),
                    Role = "Parent",
                    Status = "Active",
                    CreatedAt = DateTime.UtcNow
                });
            }
        }

        if (dbContext.ChangeTracker.HasChanges())
        {
            await dbContext.SaveChangesAsync(cancellationToken);
            existingUsers = await dbContext.Users
                .Where(user => sampleEmails.Contains(user.Email))
                .ToDictionaryAsync(user => user.Email, cancellationToken);
        }

        var now = DateTime.UtcNow;
        var samples = new[]
        {
            new DemoFeedbackSeed("demo-feedback-001", "nguyen.vanhung@smartsteps.vn", "home_exit_prompt", 5, 5, 5, "Phù hợp", "Rất hài lòng với khóa học, tương tác vui nên bé nhà không vàng nước mắt khi học nữa.", now.AddHours(-2)),
            new DemoFeedbackSeed("demo-feedback-002", "nguyen.vanbinh@smartsteps.vn", "lesson_complete", 5, 4, 5, "Phù hợp", "Bé thích phần flashcard và phần thưởng sao. Mong có thêm nhiều bài về an toàn giao thông.", now.AddHours(-4)),
            new DemoFeedbackSeed("demo-feedback-003", "tran.minhchau@smartsteps.vn", "home_exit_prompt", 4, 5, 4, "Hơi dễ", "Giao diện dễ thương, con tự bấm được. Một vài câu hỏi có thể thêm giọng đọc rõ hơn.", now.AddDays(-1).AddHours(-1)),
            new DemoFeedbackSeed("demo-feedback-004", "le.giahan@smartsteps.vn", "quick_review", 5, 5, 4, "Phù hợp", "Nội dung gần gũi, phụ huynh dễ ôn lại cùng bé sau mỗi bài học.", now.AddDays(-1).AddHours(-5)),
            new DemoFeedbackSeed("demo-feedback-005", "pham.annhien@smartsteps.vn", "lesson_complete", 3, 4, 3, "Cần hướng dẫn", "Bé hơi lúng túng ở phần chọn đáp án, nên có thêm gợi ý bằng hình ảnh trước khi trả lời.", now.AddDays(-2)),
            new DemoFeedbackSeed("demo-feedback-006", "nguyen.vanhung@smartsteps.vn", "quick_review", 4, 4, 4, "Phù hợp", "Phần ôn tập nhanh hữu ích, giúp mình biết con đã nhớ được tình huống nào.", now.AddDays(-3)),
            new DemoFeedbackSeed("demo-feedback-007", "tran.minhchau@smartsteps.vn", "home_exit_prompt", 5, 5, 5, "Phù hợp", "Con rất thích nhân vật và màu sắc. Bài học ngắn vừa đủ để giữ tập trung.", now.AddDays(-4)),
            new DemoFeedbackSeed("demo-feedback-008", "nguyen.vanbinh@smartsteps.vn", "lesson_complete", 4, 3, 4, "Phù hợp", "Ứng dụng ổn, mong phần âm thanh tải nhanh hơn khi mạng yếu.", now.AddDays(-5)),
            new DemoFeedbackSeed("demo-feedback-009", "le.giahan@smartsteps.vn", "quick_review", 2, 3, 3, "Hơi khó", "Một số nội dung cần phụ huynh giải thích thêm, nhưng tổng thể vẫn hữu ích.", now.AddDays(-6)),
            new DemoFeedbackSeed("demo-feedback-010", "pham.annhien@smartsteps.vn", "home_exit_prompt", 5, 4, 5, "Phù hợp", "Bé nhớ được quy tắc không mở cửa cho người lạ sau khi học, rất đáng giá.", now.AddDays(-7)),
            new DemoFeedbackSeed("demo-feedback-011", "nguyen.vanhung@smartsteps.vn", "lesson_complete", 3, 2, 3, "Cần cải thiện", "Một số câu hỏi hơi khó, nên có thêm gợi ý hoặc ví dụ minh họa.", now.AddDays(-8)),
            new DemoFeedbackSeed("demo-feedback-012", "tran.minhchau@smartsteps.vn", "quick_review", 1, 2, 2, "Cần cải thiện", "Bé chưa quen thao tác trên màn hình nhỏ, cần nút bấm lớn hơn ở vài bước.", now.AddDays(-9))
        };

        var sampleClientIds = samples.Select(item => item.ClientId).ToArray();
        var existingClientIds = await dbContext.AppFeedbackEntries
            .Where(item => sampleClientIds.Contains(item.ClientId))
            .Select(item => item.ClientId)
            .ToListAsync(cancellationToken);
        var existingClientIdSet = existingClientIds.ToHashSet(StringComparer.OrdinalIgnoreCase);

        var addedCount = 0;
        foreach (var sample in samples)
        {
            if (existingClientIdSet.Contains(sample.ClientId) ||
                !existingUsers.TryGetValue(sample.Email, out var user))
            {
                continue;
            }

            dbContext.AppFeedbackEntries.Add(new AppFeedback
            {
                UserId = user.UserId,
                ClientId = sample.ClientId,
                Source = sample.Source,
                ExperienceRating = sample.ExperienceRating,
                ChildEngagementRating = sample.ChildEngagementRating,
                EffectivenessRating = sample.EffectivenessRating,
                AgeFit = sample.AgeFit,
                ImprovementNote = sample.ImprovementNote,
                SubmittedAt = sample.SubmittedAt,
                CreatedAt = now
            });
            addedCount++;
        }

        if (addedCount > 0)
        {
            await dbContext.SaveChangesAsync(cancellationToken);
            logger.LogInformation("Seeded {Count} sample feedback entries.", addedCount);
        }
    }

    private sealed record DemoFeedbackUser(string FullName, string Email);

    private sealed record DemoFeedbackSeed(
        string ClientId,
        string Email,
        string Source,
        int ExperienceRating,
        int ChildEngagementRating,
        int EffectivenessRating,
        string AgeFit,
        string ImprovementNote,
        DateTime SubmittedAt);

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
