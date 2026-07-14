using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;

namespace SmartStepsServer.Controllers;

[ApiController]
[Authorize(Roles = "Admin")]
[Route("api/admin")]
public sealed class AdminController(SmartStepsDbContext dbContext) : ControllerBase
{
    [HttpGet("dashboard")]
    public async Task<IActionResult> Dashboard(CancellationToken cancellationToken)
    {
        var users = await dbContext.Users.CountAsync(cancellationToken);
        var completedLessons = await dbContext.UserProgresses.CountAsync(item => item.Status == "Completed", cancellationToken);
        var activePremium = await dbContext.PremiumSubscriptions.CountAsync(
            item => item.Status == "Active" && (item.ExpiresAt == null || item.ExpiresAt > DateTime.UtcNow), cancellationToken);
        var feedback = await dbContext.AppFeedbackEntries.AsNoTracking()
            .OrderByDescending(item => item.SubmittedAt).Take(20)
            .Select(item => new { item.FeedbackId, item.User.Email, item.Source, item.ExperienceRating,
                item.ChildEngagementRating, item.EffectivenessRating, item.AgeFit, item.ImprovementNote, item.SubmittedAt })
            .ToListAsync(cancellationToken);
        return Ok(new { users, completedLessons, activePremium, feedbackCount = await dbContext.AppFeedbackEntries.CountAsync(cancellationToken), feedback });
    }
}
