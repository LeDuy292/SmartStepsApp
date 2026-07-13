using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Data.Models;
using SmartStepsServer.Services;

namespace SmartStepsServer.Controllers;

[ApiController]
[Route("api/learning-analysis/{childId:int}")]
public sealed class LearningAnalysisController(
    ILearningAnalysisService learningAnalysisService,
    SmartStepsDbContext dbContext) : ControllerBase
{
    [HttpPost("reports")]
    [ProducesResponseType(typeof(LearningAnalysisResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<LearningAnalysisResult>> GenerateReport(
        int childId,
        [FromBody] GenerateLearningReportRequest? request,
        CancellationToken cancellationToken)
    {
        if (childId <= 0)
        {
            return BadRequest(new { message = "childId must be greater than 0." });
        }

        var periodTo = EnsureUtc(request?.PeriodTo ?? DateTime.UtcNow);
        var periodFrom = EnsureUtc(request?.PeriodFrom ?? periodTo.AddDays(-30));
        if (periodFrom >= periodTo)
        {
            return BadRequest(new { message = "periodFrom must be earlier than periodTo." });
        }

        try
        {
            return Ok(await learningAnalysisService.GenerateAsync(
                childId,
                periodFrom,
                periodTo,
                cancellationToken));
        }
        catch (LearningAnalysisNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }

    [HttpGet("reports/latest")]
    [ProducesResponseType(typeof(LearningReportResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<LearningReportResponse>> GetLatestReport(
        int childId,
        CancellationToken cancellationToken)
    {
        var report = await dbContext.LearningReports
            .AsNoTracking()
            .Where(item => item.ChildId == childId)
            .OrderByDescending(item => item.GeneratedAt)
            .Select(item => new LearningReportResponse
            {
                ReportId = item.ReportId,
                ChildId = item.ChildId,
                PeriodFrom = item.PeriodFrom,
                PeriodTo = item.PeriodTo,
                TotalLessons = item.TotalLessons,
                CompletedLessons = item.CompletedLessons,
                CorrectRate = item.CorrectRate,
                Summary = item.Summary,
                Strengths = item.Strengths,
                AreasForImprovement = item.AreasForImprovement,
                ParentAdvice = item.ParentAdvice,
                GeneratedAt = item.GeneratedAt,
            })
            .FirstOrDefaultAsync(cancellationToken);

        return report is null
            ? NotFound(new { message = "No learning report has been generated for this child." })
            : Ok(report);
    }

    [HttpGet("recommendations")]
    [ProducesResponseType(typeof(IReadOnlyList<StoredLessonRecommendationResponse>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<StoredLessonRecommendationResponse>>> GetRecommendations(
        int childId,
        [FromQuery] string status = "Pending",
        CancellationToken cancellationToken = default)
    {
        var normalizedStatus = status.Trim();
        if (normalizedStatus is not ("Pending" or "Completed" or "Dismissed"))
        {
            return BadRequest(new { message = "status must be Pending, Completed or Dismissed." });
        }

        var recommendations = await dbContext.LessonRecommendations
            .AsNoTracking()
            .Where(item => item.ChildId == childId && item.Status == normalizedStatus)
            .OrderByDescending(item => item.Priority)
            .ThenBy(item => item.Situation.Island.OrderIndex)
            .ThenBy(item => item.Situation.OrderIndex)
            .Select(item => new StoredLessonRecommendationResponse
            {
                RecommendationId = item.RecommendationId,
                SituationId = item.SituationId,
                SituationTitle = item.Situation.Title,
                SkillNames = item.Situation.SituationSkills
                    .OrderBy(situationSkill => situationSkill.Skill.Name)
                    .Select(situationSkill => situationSkill.Skill.Name)
                    .ToList(),
                RecommendationType = item.RecommendationType,
                Reason = item.Reason,
                Priority = item.Priority,
                Status = item.Status,
                CreatedAt = item.CreatedAt,
                CompletedAt = item.CompletedAt,
            })
            .ToListAsync(cancellationToken);

        return Ok(recommendations);
    }

    [HttpPost("recommendations/{situationId:int}/review")]
    [ProducesResponseType(typeof(StoredLessonRecommendationResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoredLessonRecommendationResponse>> RequestReview(
        int childId,
        int situationId,
        [FromBody] ParentReviewRequest? request,
        CancellationToken cancellationToken)
    {
        var childExists = await dbContext.Users.AnyAsync(user => user.UserId == childId, cancellationToken);
        var situation = await dbContext.Situations
            .Where(item => item.SituationId == situationId && item.Status == "Published")
            .SingleOrDefaultAsync(cancellationToken);
        if (!childExists || situation is null)
        {
            return NotFound(new { message = "Child or published situation was not found." });
        }

        var recommendation = await dbContext.LessonRecommendations.SingleOrDefaultAsync(
            item => item.ChildId == childId && item.SituationId == situationId && item.Status == "Pending",
            cancellationToken);
        var reason = string.IsNullOrWhiteSpace(request?.Reason)
            ? "Phụ huynh đã chủ động yêu cầu bé ôn lại bài học này."
            : request!.Reason.Trim();

        if (recommendation is null)
        {
            recommendation = new LessonRecommendation
            {
                ChildId = childId,
                SituationId = situationId,
                RecommendationType = "Review",
                Reason = reason,
                Priority = 100,
                Status = "Pending",
                CreatedAt = DateTime.UtcNow,
            };
            dbContext.LessonRecommendations.Add(recommendation);
        }
        else
        {
            recommendation.RecommendationType = "Review";
            recommendation.Reason = reason;
            recommendation.Priority = 100;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(new StoredLessonRecommendationResponse
        {
            RecommendationId = recommendation.RecommendationId,
            SituationId = situation.SituationId,
            SituationTitle = situation.Title,
            RecommendationType = recommendation.RecommendationType,
            Reason = recommendation.Reason,
            Priority = recommendation.Priority,
            Status = recommendation.Status,
            CreatedAt = recommendation.CreatedAt,
        });
    }

    [HttpPatch("recommendations/{recommendationId:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateRecommendation(
        int childId,
        int recommendationId,
        [FromBody] UpdateRecommendationRequest request,
        CancellationToken cancellationToken)
    {
        var normalizedStatus = request.Status?.Trim();
        if (normalizedStatus is not ("Completed" or "Dismissed"))
        {
            return BadRequest(new { message = "status must be Completed or Dismissed." });
        }

        var recommendation = await dbContext.LessonRecommendations.SingleOrDefaultAsync(
            item => item.RecommendationId == recommendationId && item.ChildId == childId,
            cancellationToken);
        if (recommendation is null)
        {
            return NotFound(new { message = "Recommendation was not found." });
        }

        recommendation.Status = normalizedStatus;
        recommendation.CompletedAt = normalizedStatus == "Completed" ? DateTime.UtcNow : null;
        await dbContext.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    private static DateTime EnsureUtc(DateTime value)
    {
        return value.Kind switch
        {
            DateTimeKind.Utc => value,
            DateTimeKind.Local => value.ToUniversalTime(),
            _ => DateTime.SpecifyKind(value, DateTimeKind.Utc),
        };
    }
}

public sealed class GenerateLearningReportRequest
{
    public DateTime? PeriodFrom { get; set; }

    public DateTime? PeriodTo { get; set; }
}

public sealed class LearningReportResponse
{
    public int ReportId { get; set; }
    public int ChildId { get; set; }
    public DateTime PeriodFrom { get; set; }
    public DateTime PeriodTo { get; set; }
    public int TotalLessons { get; set; }
    public int CompletedLessons { get; set; }
    public decimal CorrectRate { get; set; }
    public string Summary { get; set; } = string.Empty;
    public string Strengths { get; set; } = string.Empty;
    public string AreasForImprovement { get; set; } = string.Empty;
    public string ParentAdvice { get; set; } = string.Empty;
    public DateTime GeneratedAt { get; set; }
}

public sealed class StoredLessonRecommendationResponse
{
    public int RecommendationId { get; set; }
    public int SituationId { get; set; }
    public string SituationTitle { get; set; } = string.Empty;
    public IReadOnlyList<string> SkillNames { get; set; } = [];
    public string RecommendationType { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public int Priority { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}

public sealed class ParentReviewRequest
{
    public string? Reason { get; set; }
}

public sealed class UpdateRecommendationRequest
{
    public string Status { get; set; } = string.Empty;
}
