using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;

namespace SmartStepsServer.Controllers.Admin;

[Authorize(Roles = "Admin")]
[Route("api/admin/reports")]
[ApiController]
public class AdminReportsController : ControllerBase
{
    private readonly SmartStepsDbContext _context;

    public AdminReportsController(SmartStepsDbContext context)
    {
        _context = context;
    }

    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboardMetrics()
    {
        var totalUsers = await _context.Users.CountAsync(u => u.Role == "Child");
        var totalSituations = await _context.Situations.CountAsync();
        var publishedSituations = await _context.Situations.CountAsync(s => s.Status == "Published");
        
        var totalAnswers = await _context.UserAnswers.CountAsync();
        var correctAnswers = await _context.UserAnswers.CountAsync(a => a.IsCorrect);
        var correctRate = totalAnswers > 0 ? (double)correctAnswers / totalAnswers * 100 : 0;

        var completedLearnings = await _context.UserProgresses.CountAsync(p => p.Status == "Completed");

        return Ok(new
        {
            TotalUsers = totalUsers,
            TotalSituations = totalSituations,
            PublishedSituations = publishedSituations,
            TotalAnswers = totalAnswers,
            CorrectRate = correctRate,
            CompletedLearnings = completedLearnings
        });
    }

    [HttpGet("answers")]
    public async Task<IActionResult> GetRecentAnswers([FromQuery] int limit = 20)
    {
        var answers = await _context.UserAnswers
            .Include(a => a.User)
            .Include(a => a.Flashcard)
            .OrderByDescending(a => a.AnsweredAt)
            .Take(limit)
            .Select(a => new {
                a.AnswerId,
                UserName = a.User.FullName,
                Question = a.Flashcard.Question,
                a.SelectedAnswer,
                a.IsCorrect,
                a.AnsweredAt
            })
            .ToListAsync();

        return Ok(answers);
    }
}
