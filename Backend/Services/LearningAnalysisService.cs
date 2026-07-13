using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Data.Models;

namespace SmartStepsServer.Services;

public sealed class LearningAnalysisService(SmartStepsDbContext dbContext) : ILearningAnalysisService
{
    public async Task<LearningAnalysisResult> GenerateAsync(
        int childId,
        DateTime periodFrom,
        DateTime periodTo,
        CancellationToken cancellationToken)
    {
        var childExists = await dbContext.Users
            .AsNoTracking()
            .AnyAsync(user => user.UserId == childId, cancellationToken);
        if (!childExists)
        {
            throw new LearningAnalysisNotFoundException("Child account was not found.");
        }

        var allProgress = await dbContext.UserProgresses
            .AsNoTracking()
            .Where(progress => progress.UserId == childId)
            .Include(progress => progress.Situation)
                .ThenInclude(situation => situation.Island)
            .ToListAsync(cancellationToken);

        var allAnswers = await dbContext.UserAnswers
            .AsNoTracking()
            .Where(answer => answer.UserId == childId)
            .Include(answer => answer.Flashcard)
                .ThenInclude(flashcard => flashcard.Situation)
                    .ThenInclude(situation => situation.SituationSkills)
                        .ThenInclude(situationSkill => situationSkill.Skill)
            .ToListAsync(cancellationToken);

        var periodProgress = allProgress
            .Where(progress => IsInPeriod(
                progress.UpdatedAt ?? progress.LastAccessedAt ?? progress.CreatedAt,
                periodFrom,
                periodTo))
            .ToList();
        var periodAnswers = allAnswers
            .Where(answer => IsInPeriod(answer.AnsweredAt ?? answer.CreatedAt, periodFrom, periodTo))
            .ToList();

        var completedSituationIds = periodProgress
            .Where(progress => progress.Status == "Completed")
            .Select(progress => progress.SituationId)
            .Distinct()
            .ToHashSet();

        if (completedSituationIds.Count == 0)
        {
            return new LearningAnalysisResult
            {
                HasEnoughData = false,
                Message = "Chưa có đủ dữ liệu để đánh giá. Hãy cho bé hoàn thành ít nhất một bài học.",
                ChildId = childId,
                PeriodFrom = periodFrom,
                PeriodTo = periodTo,
            };
        }

        var catalog = await dbContext.Situations
            .AsNoTracking()
            .Where(situation => situation.Status == "Published" && situation.Island.Status == "Active")
            .Include(situation => situation.Island)
            .Include(situation => situation.SituationSkills)
                .ThenInclude(situationSkill => situationSkill.Skill)
            .Include(situation => situation.ParentReviewQuestions)
            .OrderBy(situation => situation.Island.OrderIndex)
            .ThenBy(situation => situation.OrderIndex)
            .ToListAsync(cancellationToken);

        var skillResults = BuildSkillAssessments(allAnswers);
        await SaveSkillAssessmentsAsync(childId, skillResults, cancellationToken);

        var recommendations = BuildRecommendations(
            allProgress,
            allAnswers,
            skillResults,
            catalog,
            DateTime.UtcNow);
        await SaveRecommendationsAsync(childId, recommendations, cancellationToken);

        var totalLessons = periodProgress.Select(progress => progress.SituationId).Distinct().Count();
        var totalAnswers = periodAnswers.Count;
        var correctAnswers = periodAnswers.Count(answer => answer.IsCorrect);
        var correctRate = CalculateRate(correctAnswers, totalAnswers);
        var completionRate = CalculateRate(completedSituationIds.Count, totalLessons);
        var activeDays = periodProgress
            .Select(progress => (progress.LastAccessedAt ?? progress.CreatedAt).Date)
            .Concat(periodAnswers.Select(answer => (answer.AnsweredAt ?? answer.CreatedAt).Date))
            .Distinct()
            .Count();

        var strongSkills = skillResults
            .Where(skill => skill.MasteryLevel is "Achieved" or "Mastered")
            .Select(skill => skill.SkillName)
            .ToList();
        var weakSkills = skillResults
            .Where(skill => skill.MasteryLevel is "NotAchieved" or "NeedsReview")
            .Select(skill => skill.SkillName)
            .ToList();
        var parentAdvice = BuildParentAdvice(catalog, recommendations);
        var summary = BuildSummary(completedSituationIds.Count, totalAnswers, correctRate, strongSkills, weakSkills);
        var generatedAt = DateTime.UtcNow;

        var report = new LearningReport
        {
            ChildId = childId,
            PeriodFrom = periodFrom,
            PeriodTo = periodTo,
            TotalLessons = totalLessons,
            CompletedLessons = completedSituationIds.Count,
            CorrectRate = correctRate,
            Summary = summary,
            Strengths = strongSkills.Count == 0 ? "Chưa có đủ dữ liệu để xác định điểm mạnh ổn định." : string.Join(", ", strongSkills),
            AreasForImprovement = weakSkills.Count == 0 ? "Chưa ghi nhận kỹ năng cần ưu tiên cải thiện." : string.Join(", ", weakSkills),
            ParentAdvice = string.Join("\n", parentAdvice),
            GeneratedAt = generatedAt,
        };
        dbContext.LearningReports.Add(report);
        await dbContext.SaveChangesAsync(cancellationToken);

        var safeRequestData = JsonSerializer.Serialize(new
        {
            completedLessons = completedSituationIds.Count,
            totalAnswers,
            correctAnswers,
            correctRate,
            strongSkills,
            weakSkills,
            reviewSituationIds = recommendations
                .Where(item => item.RecommendationType != "NextLesson")
                .Select(item => item.SituationId),
            candidateSituationIds = recommendations.Select(item => item.SituationId),
            periodFrom,
            periodTo,
        });
        var safeResponseData = JsonSerializer.Serialize(new
        {
            summary,
            strengths = report.Strengths,
            areasForImprovement = report.AreasForImprovement,
            parentAdvice,
        });
        dbContext.AIAnalysisLogs.Add(new AIAnalysisLog
        {
            ChildId = childId,
            ReportId = report.ReportId,
            RequestData = safeRequestData,
            ResponseData = safeResponseData,
            ModelName = "RuleBasedFallback",
            Status = "Fallback",
            ErrorMessage = "AI provider is not configured; approved rule-based narrative was used.",
            CreatedAt = generatedAt,
        });
        await dbContext.SaveChangesAsync(cancellationToken);

        return new LearningAnalysisResult
        {
            HasEnoughData = true,
            Message = "Báo cáo học tập đã được tạo.",
            ReportId = report.ReportId,
            ChildId = childId,
            PeriodFrom = periodFrom,
            PeriodTo = periodTo,
            TotalLessons = totalLessons,
            CompletedLessons = completedSituationIds.Count,
            CompletionRate = completionRate,
            TotalAnswers = totalAnswers,
            CorrectAnswers = correctAnswers,
            CorrectRate = correctRate,
            ActiveDays = activeDays,
            Summary = summary,
            Skills = skillResults,
            Recommendations = recommendations,
            ParentAdvice = parentAdvice,
        };
    }

    private static List<SkillAssessmentResult> BuildSkillAssessments(IReadOnlyCollection<UserAnswer> answers)
    {
        return answers
            .SelectMany(answer => answer.Flashcard.Situation.SituationSkills.Select(situationSkill => new
            {
                Answer = answer,
                situationSkill.SkillId,
                situationSkill.Skill.Name,
                answer.Flashcard.SituationId,
            }))
            .GroupBy(item => new { item.SkillId, item.Name })
            .Select(group =>
            {
                var totalAttempts = group.Count();
                var correctAttempts = group.Count(item => item.Answer.IsCorrect);
                var correctRate = CalculateRate(correctAttempts, totalAttempts);
                var mastered = correctRate == 1m &&
                    group.All(item => item.Answer.AttemptCount == 1) &&
                    group.Select(item => item.SituationId).Distinct().Count() >= 2;

                return new SkillAssessmentResult
                {
                    SkillId = group.Key.SkillId,
                    SkillName = group.Key.Name,
                    TotalAttempts = totalAttempts,
                    CorrectAttempts = correctAttempts,
                    CorrectRate = correctRate,
                    MasteryLevel = mastered
                        ? "Mastered"
                        : correctRate >= 0.8m
                            ? "Achieved"
                            : correctRate >= 0.6m
                                ? "NeedsReview"
                                : "NotAchieved",
                };
            })
            .OrderBy(result => result.SkillId)
            .ToList();
    }

    private async Task SaveSkillAssessmentsAsync(
        int childId,
        IReadOnlyCollection<SkillAssessmentResult> results,
        CancellationToken cancellationToken)
    {
        var existing = await dbContext.SkillAssessments
            .Where(assessment => assessment.ChildId == childId)
            .ToDictionaryAsync(assessment => assessment.SkillId, cancellationToken);
        var assessedAt = DateTime.UtcNow;

        foreach (var result in results)
        {
            if (!existing.TryGetValue(result.SkillId, out var assessment))
            {
                assessment = new SkillAssessment { ChildId = childId, SkillId = result.SkillId };
                dbContext.SkillAssessments.Add(assessment);
            }

            assessment.TotalAttempts = result.TotalAttempts;
            assessment.CorrectAttempts = result.CorrectAttempts;
            assessment.CorrectRate = result.CorrectRate;
            assessment.MasteryLevel = result.MasteryLevel;
            assessment.LastAssessedAt = assessedAt;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static List<LessonRecommendationResult> BuildRecommendations(
        IReadOnlyCollection<UserProgress> progressItems,
        IReadOnlyCollection<UserAnswer> answers,
        IReadOnlyCollection<SkillAssessmentResult> skills,
        IReadOnlyList<Situation> catalog,
        DateTime utcNow)
    {
        var candidates = new Dictionary<int, LessonRecommendationResult>();

        void Add(Situation situation, string type, string reason, int priority)
        {
            if (!candidates.TryGetValue(situation.SituationId, out var existing) || priority > existing.Priority)
            {
                candidates[situation.SituationId] = new LessonRecommendationResult
                {
                    SituationId = situation.SituationId,
                    SituationTitle = situation.Title,
                    RecommendationType = type,
                    Reason = reason,
                    Priority = priority,
                    RecommendedAt = utcNow,
                };
            }
        }

        foreach (var progress in progressItems.Where(item => item.Status != "Completed"))
        {
            var situation = catalog.FirstOrDefault(item => item.SituationId == progress.SituationId);
            if (situation is not null)
            {
                Add(situation, "Review", "Bài học chưa hoàn thành và cần được tiếp tục từ bước gần nhất.", 100);
            }
        }

        foreach (var group in answers.GroupBy(answer => answer.Flashcard.SituationId))
        {
            var situation = catalog.FirstOrDefault(item => item.SituationId == group.Key);
            if (situation is null)
            {
                continue;
            }

            if (group.Any(answer => !answer.IsCorrect))
            {
                Add(situation, "Review", "Bé đã có câu trả lời chưa đúng trong bài học này.", 95);
            }
            else if (group.Any(answer => answer.AttemptCount > 1))
            {
                Add(situation, "Review", "Bé cần nhiều hơn một lần thử để trả lời đúng.", 80);
            }
        }

        foreach (var skill in skills.Where(item => item.MasteryLevel is "NotAchieved" or "NeedsReview"))
        {
            var situation = catalog.FirstOrDefault(item =>
                item.SituationSkills.Any(situationSkill => situationSkill.SkillId == skill.SkillId));
            if (situation is not null)
            {
                Add(situation, "WeakSkill", $"Kỹ năng {skill.SkillName} đang ở mức cần củng cố.", 85);
            }
        }

        foreach (var progress in progressItems.Where(item => item.Status == "Completed"))
        {
            var lastAccessedAt = progress.LastAccessedAt ?? progress.UpdatedAt ?? progress.CreatedAt;
            var days = (utcNow - lastAccessedAt).TotalDays;
            if (days < 7)
            {
                continue;
            }

            var situation = catalog.FirstOrDefault(item => item.SituationId == progress.SituationId);
            if (situation is not null)
            {
                var priority = days >= 30 ? 75 : days >= 14 ? 65 : 55;
                Add(situation, "PeriodicReview", $"Bài học đã {Math.Floor(days)} ngày chưa được ôn lại.", priority);
            }
        }

        var completedIds = progressItems
            .Where(item => item.Status == "Completed")
            .Select(item => item.SituationId)
            .ToHashSet();
        var nextLesson = catalog.FirstOrDefault(item => !completedIds.Contains(item.SituationId));
        if (nextLesson is not null)
        {
            Add(nextLesson, "NextLesson", "Đây là bài học đã xuất bản tiếp theo trong lộ trình.", 50);
        }

        if (candidates.Count == 0 && catalog.Count > 0)
        {
            Add(catalog[0], "PeriodicReview", "Bé đã hoàn thành các bài hiện có; hãy ôn lại bài đầu tiên.", 40);
        }

        return candidates.Values
            .OrderByDescending(item => item.Priority)
            .ThenBy(item => item.SituationId)
            .Take(10)
            .ToList();
    }

    private async Task SaveRecommendationsAsync(
        int childId,
        IReadOnlyCollection<LessonRecommendationResult> results,
        CancellationToken cancellationToken)
    {
        var pending = await dbContext.LessonRecommendations
            .Where(item => item.ChildId == childId && item.Status == "Pending")
            .ToListAsync(cancellationToken);
        var resultSituationIds = results.Select(item => item.SituationId).ToHashSet();
        var obsolete = pending.Where(item =>
            !resultSituationIds.Contains(item.SituationId) &&
            !item.Reason.StartsWith("Phụ huynh", StringComparison.OrdinalIgnoreCase));
        dbContext.LessonRecommendations.RemoveRange(obsolete);

        foreach (var result in results)
        {
            var entity = pending.FirstOrDefault(item => item.SituationId == result.SituationId);
            if (entity is not null && entity.Reason.StartsWith("Phụ huynh", StringComparison.OrdinalIgnoreCase))
            {
                result.RecommendationId = entity.RecommendationId;
                continue;
            }

            if (entity is null)
            {
                entity = new LessonRecommendation
                {
                    ChildId = childId,
                    SituationId = result.SituationId,
                    Status = "Pending",
                };
                dbContext.LessonRecommendations.Add(entity);
            }

            entity.RecommendationType = result.RecommendationType;
            entity.Reason = result.Reason;
            entity.Priority = result.Priority;
            entity.CreatedAt = result.RecommendedAt;
            entity.CompletedAt = null;
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        foreach (var result in results)
        {
            var entity = pending.FirstOrDefault(item => item.SituationId == result.SituationId) ??
                dbContext.LessonRecommendations.Local.FirstOrDefault(item =>
                    item.ChildId == childId && item.SituationId == result.SituationId);
            if (entity is not null)
            {
                result.RecommendationId = entity.RecommendationId;
            }
        }
    }

    private static IReadOnlyList<string> BuildParentAdvice(
        IReadOnlyCollection<Situation> catalog,
        IReadOnlyCollection<LessonRecommendationResult> recommendations)
    {
        var situationIds = recommendations
            .OrderByDescending(item => item.Priority)
            .Select(item => item.SituationId)
            .ToHashSet();

        var advice = catalog
            .Where(situation => situationIds.Contains(situation.SituationId))
            .SelectMany(situation => situation.ParentReviewQuestions)
            .Select(review => string.IsNullOrWhiteSpace(review.SuggestedActivity)
                ? review.QuestionText
                : review.SuggestedActivity!)
            .Where(text => !string.IsNullOrWhiteSpace(text))
            .Distinct()
            .Take(3)
            .ToList();

        if (advice.Count == 0)
        {
            advice.Add("Phụ huynh hãy cùng bé ôn lại bài được đề xuất và hỏi bé cách tìm người lớn đáng tin cậy khi gặp nguy hiểm.");
        }

        return advice;
    }

    private static string BuildSummary(
        int completedLessons,
        int totalAnswers,
        decimal correctRate,
        IReadOnlyCollection<string> strongSkills,
        IReadOnlyCollection<string> weakSkills)
    {
        var accuracyText = totalAnswers == 0
            ? "chưa có câu trả lời được ghi nhận"
            : $"đạt tỷ lệ trả lời đúng {correctRate:P0}";
        var strengthText = strongSkills.Count == 0
            ? "Chưa có đủ dữ liệu để xác định điểm mạnh ổn định."
            : $"Bé đang làm tốt các kỹ năng: {string.Join(", ", strongSkills)}.";
        var improvementText = weakSkills.Count == 0
            ? "Chưa ghi nhận kỹ năng cần ưu tiên cải thiện."
            : $"Nên ưu tiên củng cố: {string.Join(", ", weakSkills)}.";

        return $"Trong kỳ báo cáo, bé đã hoàn thành {completedLessons} bài học và {accuracyText}. {strengthText} {improvementText}";
    }

    private static decimal CalculateRate(int numerator, int denominator)
    {
        return denominator == 0 ? 0 : decimal.Round((decimal)numerator / denominator, 4);
    }

    private static bool IsInPeriod(DateTime value, DateTime from, DateTime to)
    {
        return value >= from && value <= to;
    }
}

public sealed class LearningAnalysisNotFoundException(string message) : Exception(message);
