using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;

namespace SmartStepsServer.Controllers.Admin;

[ApiController]
[Authorize(Roles = "Admin")]
[Route("api/admin/feedback")]
public sealed class AdminFeedbackController(SmartStepsDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? status,
        [FromQuery] string? category,
        CancellationToken cancellationToken)
    {
        var query = dbContext.AppFeedbackEntries.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(status)) query = query.Where(item => item.Status == status);
        if (!string.IsNullOrWhiteSpace(category)) query = query.Where(item => item.Category == category);
        return Ok(await query.OrderByDescending(item => item.SubmittedAt).Select(item => new
        {
            item.FeedbackId, item.UserId, item.User.FullName, item.User.Email,
            item.Category, item.Status, item.Source, item.SituationId,
            SituationTitle = item.Situation == null ? null : item.Situation.Title,
            item.ExperienceRating, item.ChildEngagementRating, item.EffectivenessRating,
            item.AgeFit, item.ImprovementNote, item.AdminResponse,
            item.SubmittedAt, item.UpdatedAt, item.ResolvedAt
        }).ToListAsync(cancellationToken));
    }

    [HttpPatch("{feedbackId:int}")]
    public async Task<IActionResult> Update(
        int feedbackId,
        UpdateFeedbackRequest request,
        CancellationToken cancellationToken)
    {
        var status = NormalizeStatus(request.Status);
        if (status is null) return BadRequest(new { message = "Status must be New, Processing or Resolved." });
        var feedback = await dbContext.AppFeedbackEntries.FindAsync([feedbackId], cancellationToken);
        if (feedback is null) return NotFound();
        feedback.Status = status;
        feedback.AdminResponse = request.AdminResponse?.Trim() ?? string.Empty;
        feedback.UpdatedAt = DateTime.UtcNow;
        feedback.ResolvedAt = status == "Resolved" ? DateTime.UtcNow : null;
        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(new { feedback.FeedbackId, feedback.Status, feedback.AdminResponse, feedback.ResolvedAt });
    }

    private static string? NormalizeStatus(string? status) => status?.Trim().ToLowerInvariant() switch
    {
        "new" => "New",
        "processing" => "Processing",
        "resolved" => "Resolved",
        _ => null
    };
}

public sealed record UpdateFeedbackRequest(string? Status, string? AdminResponse);
