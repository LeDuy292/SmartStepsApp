using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SmartStepsServer.Data.Models;
using SmartStepsServer.Data.Seed;

namespace SmartStepsServer.Data;

public class SmartStepsDbContext : DbContext
{
    public SmartStepsDbContext(DbContextOptions<SmartStepsDbContext> options) : base(options)
    {
    }

    // DbSets
    public DbSet<User> Users { get; set; } = null!;
    public DbSet<Island> Islands { get; set; } = null!;
    public DbSet<Situation> Situations { get; set; } = null!;
    public DbSet<SituationStep> SituationSteps { get; set; } = null!;
    public DbSet<Flashcard> Flashcards { get; set; } = null!;
    public DbSet<Skill> Skills { get; set; } = null!;
    public DbSet<SituationSkill> SituationSkills { get; set; } = null!;
    public DbSet<UserProgress> UserProgresses { get; set; } = null!;
    public DbSet<UserAnswer> UserAnswers { get; set; } = null!;
    public DbSet<ParentReviewQuestion> ParentReviewQuestions { get; set; } = null!;
    public DbSet<PremiumSubscription> PremiumSubscriptions { get; set; } = null!;
    public DbSet<PremiumPayment> PremiumPayments { get; set; } = null!;
    public DbSet<PremiumCodeRedemption> PremiumCodeRedemptions { get; set; } = null!;
    public DbSet<LearningReport> LearningReports { get; set; } = null!;
    public DbSet<LessonRecommendation> LessonRecommendations { get; set; } = null!;
    public DbSet<SkillAssessment> SkillAssessments { get; set; } = null!;
    public DbSet<AIAnalysisLog> AIAnalysisLogs { get; set; } = null!;
    public DbSet<AppFeedback> AppFeedbackEntries { get; set; } = null!;
    public DbSet<ChildLinkCode> ChildLinkCodes { get; set; } = null!;
    public DbSet<LessonAssignment> LessonAssignments { get; set; } = null!;
    public DbSet<ParentActivityConfirmation> ParentActivityConfirmations { get; set; } = null!;
    public DbSet<ChildTask> ChildTasks { get; set; } = null!;
    public DbSet<TaskProgress> TaskProgresses { get; set; } = null!;
    public DbSet<RewardItem> RewardItems { get; set; } = null!;
    public DbSet<RewardRedemption> RewardRedemptions { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure User
        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("Users", table =>
            {
                table.HasCheckConstraint("CK_Users_Role", "\"Role\" IN ('Child', 'Parent', 'Admin', 'ContentCreator')");
            });

            entity.HasKey(e => e.UserId);
            entity.Property(e => e.FullName).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Email).HasColumnType("varchar(255)").HasMaxLength(255).IsRequired();
            entity.HasIndex(e => e.Email).IsUnique();
            entity.Property(e => e.Password).HasColumnType("varchar(255)").HasMaxLength(255).IsRequired();
            entity.Property(e => e.Role).HasColumnType("varchar(30)").HasMaxLength(30).IsRequired();
            entity.Property(e => e.ProfileJson).HasColumnType("text");
            ConfigureAuditColumns(entity);

            entity.HasOne(e => e.Parent)
                .WithMany(e => e.Children)
                .HasForeignKey(e => e.ParentId)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasMany(e => e.PremiumSubscriptions)
                .WithOne(e => e.User)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasMany(e => e.PremiumPayments)
                .WithOne(e => e.User)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasMany(e => e.PremiumCodeRedemptions)
                .WithOne(e => e.User)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.NoAction);
        });

        modelBuilder.Entity<AppFeedback>(entity =>
        {
            entity.ToTable("AppFeedback", table =>
            {
                table.HasCheckConstraint("CK_AppFeedback_ExperienceRating", "\"ExperienceRating\" BETWEEN 1 AND 5");
                table.HasCheckConstraint("CK_AppFeedback_ChildEngagementRating", "\"ChildEngagementRating\" BETWEEN 1 AND 5");
                table.HasCheckConstraint("CK_AppFeedback_EffectivenessRating", "\"EffectivenessRating\" BETWEEN 1 AND 5");
                table.HasCheckConstraint("CK_AppFeedback_Category", "\"Category\" IN ('Bug', 'Suggestion', 'InappropriateContent')");
                table.HasCheckConstraint("CK_AppFeedback_Status", "\"Status\" IN ('New', 'Processing', 'Resolved')");
            });
            entity.HasKey(e => e.FeedbackId);
            entity.HasIndex(e => new { e.UserId, e.ClientId }).IsUnique();
            entity.Property(e => e.ClientId).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Source).HasMaxLength(50).IsRequired();
            entity.Property(e => e.AgeFit).HasMaxLength(50).IsRequired();
            entity.Property(e => e.ImprovementNote).HasMaxLength(2000).IsRequired();
            entity.Property(e => e.Category).HasMaxLength(30).IsRequired();
            entity.Property(e => e.Status).HasMaxLength(20).IsRequired();
            entity.Property(e => e.AdminResponse).HasMaxLength(2000).IsRequired();
            entity.HasOne(e => e.User)
                .WithMany(e => e.AppFeedbackEntries)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(e => e.Situation)
                .WithMany()
                .HasForeignKey(e => e.SituationId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<ChildLinkCode>(entity =>
        {
            entity.HasIndex(e => e.Code).IsUnique();
            entity.Property(e => e.Code).HasMaxLength(12).IsRequired();
            entity.HasOne(e => e.Child).WithMany().HasForeignKey(e => e.ChildId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(e => e.UsedByParent).WithMany().HasForeignKey(e => e.UsedByParentId).OnDelete(DeleteBehavior.NoAction);
        });

        modelBuilder.Entity<LessonAssignment>(entity =>
        {
            entity.ToTable("LessonAssignment", table =>
                table.HasCheckConstraint("CK_LessonAssignment_Status", "\"Status\" IN ('Assigned', 'InProgress', 'Completed', 'Cancelled')"));
            entity.Property(e => e.Status).HasMaxLength(20).IsRequired();
            entity.Property(e => e.Note).HasMaxLength(500).IsRequired();
            entity.HasIndex(e => new { e.ChildId, e.Status });
            entity.HasOne(e => e.Parent).WithMany().HasForeignKey(e => e.ParentId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(e => e.Child).WithMany().HasForeignKey(e => e.ChildId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(e => e.Situation).WithMany().HasForeignKey(e => e.SituationId).OnDelete(DeleteBehavior.NoAction);
        });

        modelBuilder.Entity<ParentActivityConfirmation>(entity =>
        {
            entity.Property(e => e.Note).HasMaxLength(1000).IsRequired();
            entity.HasIndex(e => new { e.ParentId, e.ChildId, e.SituationId });
            entity.HasOne(e => e.Parent).WithMany().HasForeignKey(e => e.ParentId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(e => e.Child).WithMany().HasForeignKey(e => e.ChildId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(e => e.Situation).WithMany().HasForeignKey(e => e.SituationId).OnDelete(DeleteBehavior.NoAction);
        });

        // Configure Island
        modelBuilder.Entity<Island>(entity =>
        {
            entity.ToTable("Island", table =>
            {
                table.HasCheckConstraint("CK_Island_Status", "\"Status\" IN ('Active', 'Hidden')");
            });

            entity.HasKey(e => e.IslandId);
            entity.Property(e => e.Name).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.ImageUrl).HasColumnType("varchar(500)").HasMaxLength(500);
            entity.Property(e => e.Status).HasColumnType("varchar(30)").HasMaxLength(30).IsRequired();
            ConfigureAuditColumns(entity);

            entity.HasMany(e => e.Situations)
                .WithOne(e => e.Island)
                .HasForeignKey(e => e.IslandId)
                .OnDelete(DeleteBehavior.NoAction);
        });

        // Configure Situation
        modelBuilder.Entity<Situation>(entity =>
        {
            entity.ToTable("Situation", table =>
            {
                table.HasCheckConstraint(
                    "CK_Situation_Status",
                    "\"Status\" IN ('Draft', 'Pending', 'Approved', 'Rejected', 'Published', 'Hidden')");
            });

            entity.HasKey(e => e.SituationId);
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Status).HasColumnType("varchar(30)").HasMaxLength(30).IsRequired();
            ConfigureAuditColumns(entity);

            entity.HasMany(e => e.SituationSteps)
                .WithOne(e => e.Situation)
                .HasForeignKey(e => e.SituationId)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasMany(e => e.Flashcards)
                .WithOne(e => e.Situation)
                .HasForeignKey(e => e.SituationId)
                .OnDelete(DeleteBehavior.NoAction);
        });

        // Configure SituationStep
        modelBuilder.Entity<SituationStep>(entity =>
        {
            entity.ToTable("SituationStep", table =>
            {
                table.HasCheckConstraint("CK_SituationStep_StepType", "\"StepType\" IN ('Intro', 'Story', 'Flashcard', 'Result')");
            });

            entity.HasKey(e => e.StepId);
            entity.Property(e => e.StepType).HasColumnType("varchar(30)").HasMaxLength(30).IsRequired();
            entity.Property(e => e.MediaUrl).HasColumnType("varchar(500)").HasMaxLength(500);
            ConfigureAuditColumns(entity);
        });

        // Configure Flashcard
        modelBuilder.Entity<Flashcard>(entity =>
        {
            entity.ToTable("Flashcard", table =>
            {
                table.HasCheckConstraint("CK_Flashcard_CorrectAnswer", "\"CorrectAnswer\" IN ('A', 'B')");
            });

            entity.HasKey(e => e.FlashcardId);
            entity.Property(e => e.Question).IsRequired();
            entity.Property(e => e.OptionA).HasMaxLength(500).IsRequired();
            entity.Property(e => e.OptionB).HasMaxLength(500).IsRequired();
            entity.Property(e => e.QuestionVoiceUrl).HasColumnType("varchar(500)").HasMaxLength(500);
            entity.Property(e => e.OptionAVoiceUrl).HasColumnType("varchar(500)").HasMaxLength(500);
            entity.Property(e => e.OptionBVoiceUrl).HasColumnType("varchar(500)").HasMaxLength(500);
            entity.Property(e => e.CorrectAnswer).HasColumnType("char(1)").HasMaxLength(1).IsFixedLength().IsRequired();
            ConfigureAuditColumns(entity);

            entity.HasMany(e => e.UserAnswers)
                .WithOne(e => e.Flashcard)
                .HasForeignKey(e => e.FlashcardId)
                .OnDelete(DeleteBehavior.NoAction);
        });

        // Configure Skill
        modelBuilder.Entity<Skill>(entity =>
        {
            entity.ToTable("Skill");
            entity.HasKey(e => e.SkillId);
            entity.Property(e => e.Name).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(500);
            ConfigureAuditColumns(entity);
        });

        // Configure SituationSkill (Many-to-Many)
        modelBuilder.Entity<SituationSkill>(entity =>
        {
            entity.ToTable("SituationSkill");
            entity.HasKey(e => new { e.SituationId, e.SkillId });

            entity.HasOne(e => e.Situation)
                .WithMany(e => e.SituationSkills)
                .HasForeignKey(e => e.SituationId)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasOne(e => e.Skill)
                .WithMany(e => e.SituationSkills)
                .HasForeignKey(e => e.SkillId)
                .OnDelete(DeleteBehavior.NoAction);
        });

        // Configure UserProgress
        modelBuilder.Entity<UserProgress>(entity =>
        {
            entity.ToTable("UserProgress", table =>
            {
                table.HasCheckConstraint("CK_UserProgress_Status", "\"Status\" IN ('InProgress', 'Completed')");
            });

            entity.HasKey(e => e.ProgressId);
            entity.Property(e => e.Status).HasColumnType("varchar(30)").HasMaxLength(30).IsRequired();
            ConfigureAuditColumns(entity);

            entity.HasOne(e => e.User)
                .WithMany(e => e.UserProgresses)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasOne(e => e.Island)
                .WithMany(e => e.UserProgresses)
                .HasForeignKey(e => e.IslandId)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasOne(e => e.Situation)
                .WithMany(e => e.UserProgresses)
                .HasForeignKey(e => e.SituationId)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasOne(e => e.SituationStep)
                .WithMany(e => e.UserProgresses)
                .HasForeignKey(e => e.CurrentStep)
                .OnDelete(DeleteBehavior.NoAction);
        });

        // Configure UserAnswer
        modelBuilder.Entity<UserAnswer>(entity =>
        {
            entity.ToTable("UserAnswer", table =>
            {
                table.HasCheckConstraint("CK_UserAnswer_SelectedAnswer", "\"SelectedAnswer\" IN ('A', 'B')");
                table.HasCheckConstraint("CK_UserAnswer_AttemptCount", "\"AttemptCount\" >= 1");
            });

            entity.HasKey(e => e.AnswerId);
            entity.Property(e => e.SelectedAnswer).HasColumnType("char(1)").HasMaxLength(1).IsFixedLength().IsRequired();
            ConfigureAuditColumns(entity);

            entity.HasOne(e => e.User)
                .WithMany(e => e.UserAnswers)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasOne(e => e.Flashcard)
                .WithMany(e => e.UserAnswers)
                .HasForeignKey(e => e.FlashcardId)
                .OnDelete(DeleteBehavior.NoAction);
        });

        // Configure ParentReviewQuestion
        modelBuilder.Entity<ParentReviewQuestion>(entity =>
        {
            entity.ToTable("ParentReviewQuestion");
            entity.HasKey(e => e.QuestionId);
            entity.Property(e => e.QuestionText).IsRequired();
            ConfigureAuditColumns(entity);

            entity.HasOne(e => e.Skill)
                .WithMany(e => e.ParentReviewQuestions)
                .HasForeignKey(e => e.SkillId)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasOne(e => e.Situation)
                .WithMany(e => e.ParentReviewQuestions)
                .HasForeignKey(e => e.SituationId)
                .OnDelete(DeleteBehavior.NoAction);
        });

        // Configure PremiumPayment
        modelBuilder.Entity<PremiumPayment>(entity =>
        {
            entity.ToTable("PremiumPayment", table =>
            {
                table.HasCheckConstraint(
                    "CK_PremiumPayment_Status",
                    "\"Status\" IN ('Pending', 'Paid', 'Cancelled', 'Expired', 'Failed', 'Refunded')");
                table.HasCheckConstraint("CK_PremiumPayment_Amount", "\"Amount\" >= 0");
            });

            entity.HasKey(e => e.PaymentId);
            entity.HasIndex(e => e.OrderCode).IsUnique();
            entity.HasIndex(e => e.PaymentLinkId).IsUnique().HasFilter("\"PaymentLinkId\" IS NOT NULL");
            entity.Property(e => e.PlanCode).HasColumnType("varchar(50)").HasMaxLength(50).IsRequired();
            entity.Property(e => e.Currency).HasColumnType("varchar(10)").HasMaxLength(10).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Status).HasColumnType("varchar(30)").HasMaxLength(30).IsRequired();
            entity.Property(e => e.PaymentLinkId).HasColumnType("varchar(100)").HasMaxLength(100);
            entity.Property(e => e.CheckoutUrl).HasColumnType("varchar(500)").HasMaxLength(500);
            entity.Property(e => e.ReturnUrl).HasColumnType("varchar(500)").HasMaxLength(500);
            entity.Property(e => e.CancelUrl).HasColumnType("varchar(500)").HasMaxLength(500);
            ConfigureAuditColumns(entity);

            entity.HasOne(e => e.User)
                .WithMany(e => e.PremiumPayments)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.NoAction);
        });

        // Configure PremiumSubscription
        modelBuilder.Entity<PremiumSubscription>(entity =>
        {
            entity.ToTable("PremiumSubscription", table =>
            {
                table.HasCheckConstraint(
                    "CK_PremiumSubscription_Status",
                    "\"Status\" IN ('Active', 'Expired', 'Cancelled')");
                table.HasCheckConstraint(
                    "CK_PremiumSubscription_Source",
                    "\"Source\" IN ('Payment', 'Code')");
            });

            entity.HasKey(e => e.SubscriptionId);
            entity.HasIndex(e => new { e.UserId, e.Status });
            entity.Property(e => e.PlanCode).HasColumnType("varchar(50)").HasMaxLength(50).IsRequired();
            entity.Property(e => e.Status).HasColumnType("varchar(30)").HasMaxLength(30).IsRequired();
            entity.Property(e => e.Source).HasColumnType("varchar(30)").HasMaxLength(30).IsRequired();
            ConfigureAuditColumns(entity);

            entity.HasOne(e => e.User)
                .WithMany(e => e.PremiumSubscriptions)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasOne(e => e.Payment)
                .WithMany(e => e.PremiumSubscriptions)
                .HasForeignKey(e => e.PaymentId)
                .OnDelete(DeleteBehavior.NoAction);
        });

        // Configure PremiumCodeRedemption
        modelBuilder.Entity<PremiumCodeRedemption>(entity =>
        {
            entity.ToTable("PremiumCodeRedemption");
            entity.HasKey(e => e.RedemptionId);
            entity.HasIndex(e => new { e.UserId, e.Code }).IsUnique();
            entity.Property(e => e.Code).HasColumnType("varchar(50)").HasMaxLength(50).IsRequired();
            ConfigureAuditColumns(entity);

            entity.HasOne(e => e.User)
                .WithMany(e => e.PremiumCodeRedemptions)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasOne(e => e.Subscription)
                .WithMany(e => e.CodeRedemptions)
                .HasForeignKey(e => e.SubscriptionId)
                .OnDelete(DeleteBehavior.NoAction);
        });

        modelBuilder.Entity<LearningReport>(entity =>
        {
            entity.ToTable("LearningReport", table =>
            {
                table.HasCheckConstraint("CK_LearningReport_Period", "\"PeriodTo\" >= \"PeriodFrom\"");
                table.HasCheckConstraint("CK_LearningReport_CorrectRate", "\"CorrectRate\" >= 0 AND \"CorrectRate\" <= 1");
            });
            entity.HasKey(e => e.ReportId);
            entity.HasIndex(e => new { e.ChildId, e.PeriodFrom, e.PeriodTo });
            entity.Property(e => e.CorrectRate).HasPrecision(5, 4);
            entity.Property(e => e.Summary).IsRequired();
            entity.Property(e => e.Strengths).IsRequired();
            entity.Property(e => e.AreasForImprovement).IsRequired();
            entity.Property(e => e.ParentAdvice).IsRequired();
            entity.HasOne(e => e.Child)
                .WithMany(e => e.LearningReports)
                .HasForeignKey(e => e.ChildId)
                .OnDelete(DeleteBehavior.NoAction);
        });

        modelBuilder.Entity<LessonRecommendation>(entity =>
        {
            entity.ToTable("LessonRecommendation", table =>
            {
                table.HasCheckConstraint(
                    "CK_LessonRecommendation_Type",
                    "\"RecommendationType\" IN ('NextLesson', 'Review', 'WeakSkill', 'PeriodicReview')");
                table.HasCheckConstraint(
                    "CK_LessonRecommendation_Status",
                    "\"Status\" IN ('Pending', 'Completed', 'Dismissed')");
                table.HasCheckConstraint("CK_LessonRecommendation_Priority", "\"Priority\" >= 0 AND \"Priority\" <= 100");
            });
            entity.HasKey(e => e.RecommendationId);
            entity.HasIndex(e => new { e.ChildId, e.Status, e.Priority });
            entity.Property(e => e.RecommendationType).HasColumnType("varchar(30)").HasMaxLength(30).IsRequired();
            entity.Property(e => e.Status).HasColumnType("varchar(30)").HasMaxLength(30).IsRequired();
            entity.Property(e => e.Reason).IsRequired();
            entity.HasOne(e => e.Child)
                .WithMany(e => e.LessonRecommendations)
                .HasForeignKey(e => e.ChildId)
                .OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(e => e.Situation)
                .WithMany(e => e.LessonRecommendations)
                .HasForeignKey(e => e.SituationId)
                .OnDelete(DeleteBehavior.NoAction);
        });

        modelBuilder.Entity<SkillAssessment>(entity =>
        {
            entity.ToTable("SkillAssessment", table =>
            {
                table.HasCheckConstraint(
                    "CK_SkillAssessment_MasteryLevel",
                    "\"MasteryLevel\" IN ('NotAchieved', 'NeedsReview', 'Achieved', 'Mastered')");
                table.HasCheckConstraint("CK_SkillAssessment_CorrectRate", "\"CorrectRate\" >= 0 AND \"CorrectRate\" <= 1");
            });
            entity.HasKey(e => e.AssessmentId);
            entity.HasIndex(e => new { e.ChildId, e.SkillId }).IsUnique();
            entity.Property(e => e.CorrectRate).HasPrecision(5, 4);
            entity.Property(e => e.MasteryLevel).HasColumnType("varchar(30)").HasMaxLength(30).IsRequired();
            entity.HasOne(e => e.Child)
                .WithMany(e => e.SkillAssessments)
                .HasForeignKey(e => e.ChildId)
                .OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(e => e.Skill)
                .WithMany(e => e.SkillAssessments)
                .HasForeignKey(e => e.SkillId)
                .OnDelete(DeleteBehavior.NoAction);
        });

        modelBuilder.Entity<AIAnalysisLog>(entity =>
        {
            entity.ToTable("AIAnalysisLog", table =>
            {
                table.HasCheckConstraint("CK_AIAnalysisLog_Status", "\"Status\" IN ('Succeeded', 'Fallback', 'Failed', 'Skipped')");
            });
            entity.HasKey(e => e.AnalysisId);
            entity.HasIndex(e => new { e.ChildId, e.CreatedAt });
            entity.Property(e => e.RequestData).HasColumnType("jsonb").IsRequired();
            entity.Property(e => e.ResponseData).HasColumnType("jsonb");
            entity.Property(e => e.ModelName).HasColumnType("varchar(100)").HasMaxLength(100).IsRequired();
            entity.Property(e => e.Status).HasColumnType("varchar(30)").HasMaxLength(30).IsRequired();
            entity.HasOne(e => e.Child)
                .WithMany(e => e.AIAnalysisLogs)
                .HasForeignKey(e => e.ChildId)
                .OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(e => e.Report)
                .WithMany(e => e.AIAnalysisLogs)
                .HasForeignKey(e => e.ReportId)
                .OnDelete(DeleteBehavior.NoAction);
        });

        ConfigureNoActionDeletes(modelBuilder);
        ConfigureSeedData(modelBuilder);
    }

    private static void ConfigureAuditColumns<TEntity>(EntityTypeBuilder<TEntity> entity)
        where TEntity : class
    {
        entity.Property<DateTime>(nameof(User.CreatedAt))
            .HasDefaultValueSql("CURRENT_TIMESTAMP");

        entity.Property<DateTime?>(nameof(User.UpdatedAt));
    }

    private static void ConfigureNoActionDeletes(ModelBuilder modelBuilder)
    {
        foreach (var foreignKey in modelBuilder.Model
            .GetEntityTypes()
            .SelectMany(entityType => entityType.GetForeignKeys()))
        {
            foreignKey.DeleteBehavior = DeleteBehavior.NoAction;
        }
    }

    private static void ConfigureSeedData(ModelBuilder modelBuilder)
    {
        var createdAt = new DateTime(2026, 5, 24, 0, 0, 0, DateTimeKind.Utc);
        var islands = new List<object>();
        var skills = new List<object>();
        var situations = new List<object>();
        var steps = new List<object>();
        var flashcards = new List<object>();
        var situationSkills = new List<object>();
        var parentReviewQuestions = new List<object>();

        var islandId = 1;
        var situationId = 1;
        var stepId = 1;
        var flashcardId = 1;
        var skillId = 1;
        var parentReviewQuestionId = 1;

        foreach (var islandSeed in SmartStepsSeedData.Islands)
        {
            islands.Add(new
            {
                IslandId = islandId,
                islandSeed.Name,
                islandSeed.Description,
                ImageUrl = (string?)null,
                islandSeed.OrderIndex,
                Status = "Active",
                CreatedAt = createdAt,
                UpdatedAt = (DateTime?)null
            });

            foreach (var situationSeed in islandSeed.Situations)
            {
                skills.Add(new
                {
                    SkillId = skillId,
                    Name = situationSeed.SkillName,
                    Description = situationSeed.SkillDescription,
                    CreatedAt = createdAt,
                    UpdatedAt = (DateTime?)null
                });

                situations.Add(new
                {
                    SituationId = situationId,
                    IslandId = islandId,
                    situationSeed.Title,
                    situationSeed.Intro,
                    situationSeed.OrderIndex,
                    Status = "Published",
                    CreatedAt = createdAt,
                    UpdatedAt = (DateTime?)null
                });

                situationSkills.Add(new
                {
                    SituationId = situationId,
                    SkillId = skillId
                });

                flashcards.Add(new
                {
                    FlashcardId = flashcardId,
                    SituationId = situationId,
                    situationSeed.Flashcard.Question,
                    situationSeed.Flashcard.OptionA,
                    situationSeed.Flashcard.OptionB,
                    situationSeed.Flashcard.QuestionVoiceUrl,
                    situationSeed.Flashcard.OptionAVoiceUrl,
                    situationSeed.Flashcard.OptionBVoiceUrl,
                    situationSeed.Flashcard.CorrectAnswer,
                    situationSeed.Flashcard.CorrectFeedback,
                    situationSeed.Flashcard.WrongFeedback,
                    CreatedAt = createdAt,
                    UpdatedAt = (DateTime?)null
                });

                parentReviewQuestions.Add(new
                {
                    QuestionId = parentReviewQuestionId,
                    SkillId = skillId,
                    SituationId = situationId,
                    QuestionText = situationSeed.ParentPractice,
                    SuggestedActivity = situationSeed.RiskAlert,
                    CreatedAt = createdAt,
                    UpdatedAt = (DateTime?)null
                });

                foreach (var stepSeed in situationSeed.Steps)
                {
                    steps.Add(new
                    {
                        StepId = stepId,
                        SituationId = situationId,
                        stepSeed.Content,
                        stepSeed.MediaUrl,
                        stepSeed.StepType,
                        stepSeed.OrderIndex,
                        CreatedAt = createdAt,
                        UpdatedAt = (DateTime?)null
                    });

                    stepId++;
                }

                situationId++;
                flashcardId++;
                skillId++;
                parentReviewQuestionId++;
            }

            islandId++;
        }

        modelBuilder.Entity<Island>().HasData(islands);
        modelBuilder.Entity<Skill>().HasData(skills);
        modelBuilder.Entity<Situation>().HasData(situations);
        modelBuilder.Entity<SituationStep>().HasData(steps);
        modelBuilder.Entity<Flashcard>().HasData(flashcards);
        modelBuilder.Entity<SituationSkill>().HasData(situationSkills);
        modelBuilder.Entity<ParentReviewQuestion>().HasData(parentReviewQuestions);

        modelBuilder.Entity<ChildTask>().HasData(
            new ChildTask
            {
                TaskId = 1,
                ParentId = 1,
                Title = "Tự gấp chăn sau khi ngủ dậy",
                Description = "Thu dọn đồ đạc ngăn nắp 10 phút",
                RewardPoints = 20,
                Frequency = "Daily",
                Status = "Active",
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new ChildTask
            {
                TaskId = 2,
                ParentId = 1,
                Title = "Sắp xếp góc học tập",
                Description = "Xếp sách vở gọn gàng 15 phút",
                RewardPoints = 30,
                Frequency = "Daily",
                Status = "Active",
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new ChildTask
            {
                TaskId = 3,
                ParentId = 1,
                Title = "Giúp bố mẹ tưới cây",
                Description = "Tưới cây cảnh ngoài sân 10 phút",
                RewardPoints = 25,
                Frequency = "Daily",
                Status = "Active",
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            }
        );

        modelBuilder.Entity<RewardItem>().HasData(
            new RewardItem
            {
                RewardId = 1,
                ParentId = 1,
                Title = "Hộp bút siêu anh hùng",
                Description = "Hộp bút 3D cao cấp nhiều ngăn",
                CostPoints = 500,
                RewardType = "Real",
                IsActive = true,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new RewardItem
            {
                RewardId = 2,
                ParentId = 1,
                Title = "30 phút xem hoạt hình",
                Description = "Thêm 30 phút giải trí cuối tuần",
                CostPoints = 300,
                RewardType = "Real",
                IsActive = true,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new RewardItem
            {
                RewardId = 3,
                ParentId = 1,
                Title = "👑 Mũ Phù Thủy Ảo",
                Description = "Trang phục siêu cấp cho Avatar của bé",
                CostPoints = 50,
                RewardType = "Virtual",
                IsActive = true,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            }
        );
    }
}
