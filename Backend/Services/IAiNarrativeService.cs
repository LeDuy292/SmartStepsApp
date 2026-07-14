namespace SmartStepsServer.Services;

public interface IAiNarrativeService
{
    Task<AiNarrativeResult> GenerateAsync(
        AiNarrativeRequest request,
        CancellationToken cancellationToken);
}

public sealed class AiNarrativeRequest
{
    public int CompletedLessons { get; init; }

    public int TotalAnswers { get; init; }

    public int CorrectAnswers { get; init; }

    public decimal CorrectRate { get; init; }

    public IReadOnlyList<string> StrongSkills { get; init; } = [];

    public IReadOnlyList<string> WeakSkills { get; init; } = [];

    public IReadOnlyList<AiLessonCandidate> Candidates { get; init; } = [];

    public IReadOnlyList<string> ApprovedParentActivities { get; init; } = [];

    public DateTime PeriodFrom { get; init; }

    public DateTime PeriodTo { get; init; }
}

public sealed class AiLessonCandidate
{
    public int SituationId { get; init; }

    public string Title { get; init; } = string.Empty;

    public string RecommendationType { get; init; } = string.Empty;

    public string RuleReason { get; init; } = string.Empty;

    public int RulePriority { get; init; }
}

public sealed class AiNarrativeResult
{
    public bool IsSuccess { get; init; }

    public string ModelName { get; init; } = "RuleBasedFallback";

    public string? Summary { get; init; }

    public string? Strengths { get; init; }

    public string? AreasForImprovement { get; init; }

    public IReadOnlyList<string> ParentAdvice { get; init; } = [];

    public IReadOnlyList<int> RankedSituationIds { get; init; } = [];

    public string? RawResponse { get; init; }

    public string? ErrorMessage { get; init; }
}
