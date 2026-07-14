namespace SmartStepsServer.Services;

public interface ILearningAnalysisService
{
    Task<LearningAnalysisResult> GenerateAsync(
        int childId,
        DateTime periodFrom,
        DateTime periodTo,
        CancellationToken cancellationToken);
}

public sealed class LearningAnalysisResult
{
    public bool HasEnoughData { get; init; }

    public string Message { get; init; } = string.Empty;

    public int? ReportId { get; init; }

    public int ChildId { get; init; }

    public DateTime PeriodFrom { get; init; }

    public DateTime PeriodTo { get; init; }

    public int TotalLessons { get; init; }

    public int CompletedLessons { get; init; }

    public decimal CompletionRate { get; init; }

    public int TotalAnswers { get; init; }

    public int CorrectAnswers { get; init; }

    public decimal CorrectRate { get; init; }

    public int ActiveDays { get; init; }

    public string Summary { get; init; } = string.Empty;

    public IReadOnlyList<SkillAssessmentResult> Skills { get; init; } = [];

    public IReadOnlyList<LessonRecommendationResult> Recommendations { get; init; } = [];

    public IReadOnlyList<string> ParentAdvice { get; init; } = [];

    public string NarrativeSource { get; init; } = "RuleBasedFallback";
}

public sealed class SkillAssessmentResult
{
    public int SkillId { get; init; }

    public string SkillName { get; init; } = string.Empty;

    public int TotalAttempts { get; init; }

    public int CorrectAttempts { get; init; }

    public decimal CorrectRate { get; init; }

    public string MasteryLevel { get; init; } = string.Empty;
}

public sealed class LessonRecommendationResult
{
    public int RecommendationId { get; set; }

    public int SituationId { get; init; }

    public string SituationTitle { get; init; } = string.Empty;

    public string RecommendationType { get; init; } = string.Empty;

    public string Reason { get; init; } = string.Empty;

    public int Priority { get; set; }

    public DateTime RecommendedAt { get; init; }
}
