using System.Security.Claims;
using System.Security.Cryptography;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Data.Models;

namespace SmartStepsServer.Controllers;

[ApiController]
[Authorize]
[Route("api/family")]
public sealed class ParentChildrenController(SmartStepsDbContext dbContext) : ControllerBase
{
    [HttpGet("account")]
    [Authorize(Roles = "Parent")]
    public async Task<IActionResult> GetAccount(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var parentId)) return Forbid();
        var account = await dbContext.Users.AsNoTracking()
            .Where(item => item.UserId == parentId)
            .Select(item => new { item.UserId, item.FullName, item.Email, item.Status })
            .SingleOrDefaultAsync(cancellationToken);
        return account is null ? NotFound() : Ok(account);
    }

    [HttpPut("account")]
    [Authorize(Roles = "Parent")]
    public async Task<IActionResult> UpdateAccount(UpdateAccountRequest request, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var parentId)) return Forbid();
        var fullName = request.FullName?.Trim() ?? string.Empty;
        var email = request.Email?.Trim().ToLowerInvariant() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(fullName) || string.IsNullOrWhiteSpace(email))
            return BadRequest(new { message = "Họ tên và email là bắt buộc." });
        if (await dbContext.Users.AnyAsync(item => item.Email == email && item.UserId != parentId, cancellationToken))
            return Conflict(new { message = "Email đã được sử dụng." });
        var parent = await dbContext.Users.SingleOrDefaultAsync(item => item.UserId == parentId, cancellationToken);
        if (parent is null) return NotFound();
        parent.FullName = fullName[..Math.Min(fullName.Length, 100)];
        parent.Email = email;
        parent.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(new { parent.UserId, parent.FullName, parent.Email, parent.Status });
    }

    [HttpPost("account/change-password")]
    [Authorize(Roles = "Parent")]
    public async Task<IActionResult> ChangePassword(ChangePasswordRequest request, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var parentId)) return Forbid();
        if (request.NewPassword?.Length < 8)
            return BadRequest(new { message = "Mật khẩu mới phải có ít nhất 8 ký tự." });
        var parent = await dbContext.Users.SingleOrDefaultAsync(item => item.UserId == parentId, cancellationToken);
        if (parent is null) return NotFound();
        if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword ?? string.Empty, parent.Password))
            return BadRequest(new { message = "Mật khẩu hiện tại không đúng." });
        parent.Password = BCrypt.Net.BCrypt.HashPassword(request.NewPassword!);
        parent.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    [HttpPost("children")]
    [Authorize(Roles = "Parent")]
    public async Task<IActionResult> CreateChild(CreateChildRequest request, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var parentId)) return Forbid();
        var fullName = request.FullName?.Trim();
        if (string.IsNullOrWhiteSpace(fullName))
            return BadRequest(new { message = "Họ tên của bé là bắt buộc." });

        var email = string.IsNullOrWhiteSpace(request.Email)
            ? $"child_{Guid.NewGuid().ToString("N")[..8]}@smartsteps.local"
            : request.Email.Trim().ToLowerInvariant();

        if (await dbContext.Users.AnyAsync(item => item.Email == email, cancellationToken))
            return Conflict(new { message = "Email đã được sử dụng." });

        var password = string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 8
            ? "12345678"
            : request.Password;

        var child = new User
        {
            FullName = fullName,
            Email = email,
            Password = BCrypt.Net.BCrypt.HashPassword(password),
            Role = "Child",
            Status = "Active",
            ParentId = parentId,
            CreatedAt = DateTime.UtcNow
        };
        dbContext.Users.Add(child);
        await dbContext.SaveChangesAsync(cancellationToken);
        return CreatedAtAction(nameof(GetChildOverview), new { childId = child.UserId },
            new { child.UserId, child.FullName, child.Email });
    }

    [HttpGet("children")]
    [Authorize(Roles = "Parent")]
    public async Task<IActionResult> GetChildren(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var parentId)) return Forbid();
        var children = await dbContext.Users.AsNoTracking()
            .Where(item => item.ParentId == parentId && item.Role == "Child")
            .OrderBy(item => item.FullName)
            .Select(item => new { item.UserId, item.FullName, item.Email, item.Status, item.ProfileJson })
            .ToListAsync(cancellationToken);
        return Ok(children);
    }

    [HttpPut("children/{childId:int}")]
    [Authorize(Roles = "Parent")]
    public async Task<IActionResult> UpdateChild(int childId, UpdateChildRequest request, CancellationToken cancellationToken)
    {
        if (!await CanManageChild(childId, cancellationToken)) return Forbid();
        var fullName = request.FullName?.Trim() ?? string.Empty;
        var email = request.Email?.Trim().ToLowerInvariant() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(fullName) || string.IsNullOrWhiteSpace(email))
            return BadRequest(new { message = "Họ tên và email là bắt buộc." });
        if (await dbContext.Users.AnyAsync(item => item.Email == email && item.UserId != childId, cancellationToken))
            return Conflict(new { message = "Email đã được sử dụng." });
        var child = await dbContext.Users.SingleAsync(item => item.UserId == childId, cancellationToken);
        child.FullName = fullName[..Math.Min(fullName.Length, 100)];
        child.Email = email;
        child.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(new { child.UserId, child.FullName, child.Email, child.Status });
    }

    [HttpPost("children/{childId:int}/reset-password")]
    [Authorize(Roles = "Parent")]
    public async Task<IActionResult> ResetChildPassword(int childId, ResetChildPasswordRequest request, CancellationToken cancellationToken)
    {
        if (!await CanManageChild(childId, cancellationToken)) return Forbid();
        if (request.NewPassword?.Length < 8)
            return BadRequest(new { message = "Mật khẩu mới phải có ít nhất 8 ký tự." });
        var child = await dbContext.Users.SingleAsync(item => item.UserId == childId, cancellationToken);
        child.Password = BCrypt.Net.BCrypt.HashPassword(request.NewPassword!);
        child.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    [HttpPatch("children/{childId:int}/status")]
    [Authorize(Roles = "Parent")]
    public async Task<IActionResult> SetChildStatus(int childId, SetChildStatusRequest request, CancellationToken cancellationToken)
    {
        if (!await CanManageChild(childId, cancellationToken)) return Forbid();
        var status = request.Status?.Trim() switch { "Active" => "Active", "Locked" => "Locked", _ => null };
        if (status is null) return BadRequest(new { message = "Trạng thái phải là Active hoặc Locked." });
        var child = await dbContext.Users.SingleAsync(item => item.UserId == childId, cancellationToken);
        child.Status = status;
        child.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(new { child.UserId, child.Status });
    }

    [HttpDelete("children/{childId:int}/link")]
    [Authorize(Roles = "Parent")]
    public async Task<IActionResult> UnlinkChild(int childId, CancellationToken cancellationToken)
    {
        if (!await CanManageChild(childId, cancellationToken)) return Forbid();
        var child = await dbContext.Users.SingleAsync(item => item.UserId == childId, cancellationToken);
        child.ParentId = null;
        child.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    [HttpGet("notifications")]
    [Authorize(Roles = "Parent")]
    public async Task<IActionResult> GetNotifications(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var parentId)) return Forbid();
        var childIds = dbContext.Users.Where(item => item.ParentId == parentId).Select(item => item.UserId);
        var completed = await dbContext.UserProgresses.AsNoTracking()
            .Where(item => childIds.Contains(item.UserId) && item.Status == "Completed")
            .OrderByDescending(item => item.UpdatedAt ?? item.LastAccessedAt ?? item.CreatedAt).Take(20)
            .Select(item => new { Id = $"progress-{item.ProgressId}", Type = "LessonCompleted", Title = "Trẻ đã hoàn thành bài học", Message = item.User.FullName + " đã hoàn thành " + item.Situation.Title, CreatedAt = item.UpdatedAt ?? item.LastAccessedAt ?? item.CreatedAt })
            .ToListAsync(cancellationToken);
        var overdue = await dbContext.LessonAssignments.AsNoTracking()
            .Where(item => item.ParentId == parentId && item.Status != "Completed" && item.Status != "Cancelled" && item.DueAt < DateTime.UtcNow)
            .OrderByDescending(item => item.DueAt).Take(20)
            .Select(item => new { Id = $"assignment-{item.AssignmentId}", Type = "AssignmentOverdue", Title = "Bài học đã quá hạn", Message = item.Child.FullName + " chưa hoàn thành " + item.Situation.Title, CreatedAt = item.DueAt!.Value })
            .ToListAsync(cancellationToken);
        var responses = await dbContext.AppFeedbackEntries.AsNoTracking()
            .Where(item => item.UserId == parentId && item.AdminResponse != "")
            .OrderByDescending(item => item.UpdatedAt).Take(20)
            .Select(item => new { Id = $"feedback-{item.FeedbackId}", Type = "FeedbackResponse", Title = "Phản hồi từ quản trị viên", Message = item.AdminResponse, CreatedAt = item.UpdatedAt ?? item.CreatedAt })
            .ToListAsync(cancellationToken);
        return Ok(completed.Cast<object>().Concat(overdue).Concat(responses).OrderByDescending(item => ((dynamic)item).CreatedAt).Take(30));
    }

    [HttpGet("children/{childId:int}/overview")]
    [Authorize(Roles = "Parent")]
    public async Task<IActionResult> GetChildOverview(int childId, CancellationToken cancellationToken)
    {
        if (!await CanManageChild(childId, cancellationToken)) return Forbid();
        var progress = await dbContext.UserProgresses.AsNoTracking()
            .Where(item => item.UserId == childId)
            .ToListAsync(cancellationToken);
        var answerStats = await dbContext.UserAnswers.AsNoTracking()
            .Where(item => item.UserId == childId)
            .GroupBy(_ => 1)
            .Select(group => new { Total = group.Count(), Correct = group.Count(item => item.IsCorrect) })
            .SingleOrDefaultAsync(cancellationToken);
        var weakSkills = await dbContext.SkillAssessments.AsNoTracking()
            .Where(item => item.ChildId == childId)
            .OrderBy(item => item.CorrectRate)
            .Take(5)
            .Select(item => new { item.SkillId, item.Skill.Name, item.CorrectRate, item.MasteryLevel })
            .ToListAsync(cancellationToken);
        var totalMinutes = progress.Sum(item => Math.Max(0,
            ((item.UpdatedAt ?? item.LastAccessedAt ?? item.CreatedAt) - item.CreatedAt).TotalMinutes));

        return Ok(new
        {
            ChildId = childId,
            StartedLessons = progress.Count,
            CompletedLessons = progress.Count(item => item.Status == "Completed"),
            TotalAnswers = answerStats?.Total ?? 0,
            CorrectAnswers = answerStats?.Correct ?? 0,
            Accuracy = answerStats is null || answerStats.Total == 0 ? 0 : Math.Round(answerStats.Correct * 100m / answerStats.Total, 1),
            EstimatedLearningMinutes = (int)Math.Round(totalMinutes),
            WeakSkills = weakSkills
        });
    }

    [HttpGet("children/{childId:int}/progress")]
    [Authorize(Roles = "Parent")]
    public async Task<IActionResult> GetChildProgress(int childId, CancellationToken cancellationToken)
    {
        if (!await CanManageChild(childId, cancellationToken)) return Forbid();
        return Ok(await dbContext.UserProgresses.AsNoTracking()
            .Where(item => item.UserId == childId)
            .OrderByDescending(item => item.LastAccessedAt)
            .Select(item => new
            {
                item.ProgressId, item.SituationId, item.Situation.Title, item.Status,
                item.CurrentStep, item.LastAccessedAt, item.CreatedAt, item.UpdatedAt
            }).ToListAsync(cancellationToken));
    }

    [HttpGet("children/{childId:int}/report")]
    [Authorize(Roles = "Parent")]
    public async Task<IActionResult> GetChildReport(int childId, CancellationToken cancellationToken)
    {
        if (!await CanManageChild(childId, cancellationToken)) return Forbid();

        var today = DateTime.UtcNow.Date;
        var weekStart = today.AddDays(-6);
        var previousWeekStart = weekStart.AddDays(-7);
        var progress = await dbContext.UserProgresses.AsNoTracking()
            .Where(item => item.UserId == childId)
            .Select(item => new
            {
                item.SituationId, item.Situation.Title, item.Status, item.CurrentStep,
                item.CreatedAt, item.LastAccessedAt, item.UpdatedAt
            })
            .ToListAsync(cancellationToken);
        var answers = await dbContext.UserAnswers.AsNoTracking()
            .Where(item => item.UserId == childId)
            .Select(item => new
            {
                item.IsCorrect, item.Flashcard.SituationId,
                At = item.AnsweredAt ?? item.CreatedAt
            })
            .ToListAsync(cancellationToken);

        static DateTime ActivityAt(dynamic item) =>
            item.UpdatedAt ?? item.LastAccessedAt ?? item.CreatedAt;
        var thisWeekProgress = progress.Where(item => ActivityAt(item) >= weekStart).ToList();
        var previousWeekProgress = progress.Where(item =>
            ActivityAt(item) >= previousWeekStart && ActivityAt(item) < weekStart).ToList();
        var thisWeekAnswers = answers.Where(item => item.At >= weekStart).ToList();
        var previousWeekAnswers = answers.Where(item =>
            item.At >= previousWeekStart && item.At < weekStart).ToList();

        var daily = Enumerable.Range(0, 7).Select(offset =>
        {
            var day = weekStart.AddDays(offset);
            var dayAnswers = answers.Where(item => item.At.Date == day).ToList();
            var dayProgress = progress.Where(item => ActivityAt(item).Date == day).ToList();
            return new
            {
                Date = day,
                Lessons = dayProgress.Count,
                Completed = dayProgress.Count(item => item.Status == "Completed"),
                Answers = dayAnswers.Count,
                Correct = dayAnswers.Count(item => item.IsCorrect),
                Accuracy = dayAnswers.Count == 0 ? 0 : Math.Round(dayAnswers.Count(item => item.IsCorrect) * 100m / dayAnswers.Count, 1)
            };
        });

        var skills = await dbContext.SkillAssessments.AsNoTracking()
            .Where(item => item.ChildId == childId)
            .OrderByDescending(item => item.CorrectRate)
            .Select(item => new
            {
                item.SkillId, item.Skill.Name, item.TotalAttempts, item.CorrectAttempts,
                Accuracy = Math.Round(item.CorrectRate * 100m, 1), item.MasteryLevel
            })
            .ToListAsync(cancellationToken);

        var answerBySituation = answers.GroupBy(item => item.SituationId)
            .ToDictionary(group => group.Key, group => new
            {
                Total = group.Count(), Correct = group.Count(item => item.IsCorrect)
            });
        var history = progress.OrderByDescending(ActivityAt).Select(item =>
        {
            answerBySituation.TryGetValue(item.SituationId, out var stats);
            return new
            {
                item.SituationId, item.Title, item.Status, item.CurrentStep,
                LastActivityAt = ActivityAt(item),
                TotalAnswers = stats?.Total ?? 0,
                CorrectAnswers = stats?.Correct ?? 0,
                Accuracy = stats is null || stats.Total == 0 ? 0 : Math.Round(stats.Correct * 100m / stats.Total, 1)
            };
        });

        var latestAiAssessment = await dbContext.LearningReports.AsNoTracking()
            .Where(item => item.ChildId == childId)
            .OrderByDescending(item => item.GeneratedAt)
            .Select(item => new
            {
                item.Summary, item.Strengths, item.AreasForImprovement,
                item.ParentAdvice, item.GeneratedAt
            })
            .FirstOrDefaultAsync(cancellationToken);

        return Ok(new
        {
            Week = new
            {
                ActiveDays = thisWeekProgress.Select(ActivityAt).Select(value => value.Date).Distinct().Count(),
                CompletedLessons = thisWeekProgress.Count(item => item.Status == "Completed"),
                TotalAnswers = thisWeekAnswers.Count,
                Accuracy = thisWeekAnswers.Count == 0 ? 0 : Math.Round(thisWeekAnswers.Count(item => item.IsCorrect) * 100m / thisWeekAnswers.Count, 1),
                PreviousCompletedLessons = previousWeekProgress.Count(item => item.Status == "Completed"),
                PreviousAccuracy = previousWeekAnswers.Count == 0 ? 0 : Math.Round(previousWeekAnswers.Count(item => item.IsCorrect) * 100m / previousWeekAnswers.Count, 1)
            },
            Daily = daily,
            Skills = skills,
            History = history,
            AiAssessment = latestAiAssessment
        });
    }

    [HttpGet("children/{childId:int}/assignments")]
    public async Task<IActionResult> GetAssignments(int childId, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId) ||
            (userId != childId && !User.IsInRole("Admin") && !await CanManageChild(childId, cancellationToken))) return Forbid();
        return Ok(await dbContext.LessonAssignments.AsNoTracking().Where(item => item.ChildId == childId)
            .OrderByDescending(item => item.AssignedAt)
            .Select(item => new { item.AssignmentId, item.SituationId, item.Situation.Title, item.Status, item.Note, item.AssignedAt, item.DueAt, item.CompletedAt })
            .ToListAsync(cancellationToken));
    }

    [HttpPost("children/{childId:int}/activities")]
    [Authorize(Roles = "Parent")]
    public async Task<IActionResult> ConfirmActivity(int childId, ActivityConfirmationRequest request, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var parentId) || !await CanManageChild(childId, cancellationToken)) return Forbid();
        if (!await dbContext.Situations.AnyAsync(item => item.SituationId == request.SituationId, cancellationToken)) return NotFound();
        var confirmation = new ParentActivityConfirmation
        {
            ParentId = parentId, ChildId = childId, SituationId = request.SituationId,
            Note = request.Note?.Trim() ?? string.Empty, ConfirmedAt = DateTime.UtcNow
        };
        dbContext.ParentActivityConfirmations.Add(confirmation);
        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(new { confirmation.ConfirmationId, confirmation.ConfirmedAt });
    }

    [HttpGet("children/{childId:int}/activities/pending")]
    [Authorize(Roles = "Parent")]
    public async Task<IActionResult> GetPendingActivities(
        int childId,
        CancellationToken cancellationToken)
    {
        if (!await CanManageChild(childId, cancellationToken)) return Forbid();

        var completedSituationIds = dbContext.UserProgresses
            .Where(item => item.UserId == childId && item.Status == "Completed")
            .Select(item => item.SituationId);
        var confirmedSituationIds = dbContext.ParentActivityConfirmations
            .Where(item => item.ChildId == childId)
            .Select(item => item.SituationId);

        var activities = await dbContext.ParentReviewQuestions.AsNoTracking()
            .Where(item =>
                completedSituationIds.Contains(item.SituationId) &&
                !confirmedSituationIds.Contains(item.SituationId))
            .OrderBy(item => item.Situation.OrderIndex)
            .Select(item => new
            {
                item.SituationId,
                SituationTitle = item.Situation.Title,
                item.QuestionText,
                SkillName = item.Skill.Name
            })
            .ToListAsync(cancellationToken);

        return Ok(activities);
    }

    private bool TryGetUserId(out int userId) => int.TryParse(
        User.FindFirstValue("UserId") ?? User.FindFirstValue(ClaimTypes.NameIdentifier), out userId);

    private async Task<bool> CanManageChild(int childId, CancellationToken cancellationToken)
    {
        if (User.IsInRole("Admin")) return true;
        if (!TryGetUserId(out var parentId) || !User.IsInRole("Parent")) return false;
        return await dbContext.Users.AnyAsync(item => item.UserId == childId && item.ParentId == parentId, cancellationToken);
    }
}

public sealed record LinkChildRequest(string? Code);
public sealed record CreateChildRequest(string FullName, string? Email, string? Password);
public sealed record ActivityConfirmationRequest(int SituationId, string? Note);
public sealed record UpdateAccountRequest(string? FullName, string? Email);
public sealed record ChangePasswordRequest(string? CurrentPassword, string? NewPassword);
public sealed record UpdateChildRequest(string? FullName, string? Email);
public sealed record ResetChildPasswordRequest(string? NewPassword);
public sealed record SetChildStatusRequest(string? Status);
