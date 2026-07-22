using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Data.Models;

namespace SmartStepsServer.Controllers;

[ApiController]
[Authorize]
[Route("api/feedback")]
public sealed class FeedbackController(SmartStepsDbContext dbContext) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Create(FeedbackRequest request, CancellationToken cancellationToken)
    {
        if (!int.TryParse(User.FindFirstValue("UserId") ?? User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
            return Forbid();
        if (request.ExperienceRating is < 1 or > 5 || request.ChildEngagementRating is < 1 or > 5 ||
            request.EffectivenessRating is < 1 or > 5 || string.IsNullOrWhiteSpace(request.ClientId))
            return BadRequest(new { message = "Ratings must be between 1 and 5 and clientId is required." });
        var category = NormalizeCategory(request.Category);
        if (category is null)
            return BadRequest(new { message = "Category must be Bug, Suggestion or InappropriateContent." });
        if (request.SituationId is not null && !await dbContext.Situations.AnyAsync(
                item => item.SituationId == request.SituationId, cancellationToken))
            return BadRequest(new { message = "The reported lesson does not exist." });

        var exists = await dbContext.AppFeedbackEntries.AnyAsync(
            item => item.UserId == userId && item.ClientId == request.ClientId, cancellationToken);
        if (exists) return NoContent();
        dbContext.AppFeedbackEntries.Add(new AppFeedback
        {
            UserId = userId,
            ClientId = request.ClientId.Trim(),
            Source = request.Source?.Trim() ?? string.Empty,
            ExperienceRating = request.ExperienceRating,
            ChildEngagementRating = request.ChildEngagementRating,
            EffectivenessRating = request.EffectivenessRating,
            AgeFit = request.AgeFit?.Trim() ?? string.Empty,
            ImprovementNote = request.ImprovementNote?.Trim() ?? string.Empty,
            Category = category,
            Status = "New",
            SituationId = request.SituationId,
            SubmittedAt = request.SubmittedAt?.ToUniversalTime() ?? DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
        });
        await dbContext.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    private static string? NormalizeCategory(string? category) => category?.Trim().ToLowerInvariant() switch
    {
        null or "" or "suggestion" => "Suggestion",
        "bug" => "Bug",
        "inappropriatecontent" or "inappropriate_content" => "InappropriateContent",
        _ => null
    };
}

public sealed record FeedbackRequest(string ClientId, string? Source, DateTime? SubmittedAt,
    int ExperienceRating, int ChildEngagementRating, int EffectivenessRating,
    string? AgeFit, string? ImprovementNote, string? Category = null, int? SituationId = null);
