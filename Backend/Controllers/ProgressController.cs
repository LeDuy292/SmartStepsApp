using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Data.Models;

namespace SmartStepsServer.Controllers;

[ApiController]
[Route("api/progress")]
public sealed class ProgressController : ControllerBase
{
    private const string LocalSessionPlaceholderPassword = "LOCAL_SESSION_PLACEHOLDER";

    private readonly SmartStepsDbContext _dbContext;

    public ProgressController(SmartStepsDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet]
    [ProducesResponseType(typeof(LearningProgressResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<LearningProgressResponse>> GetProgress(
        [FromQuery] string userEmail,
        CancellationToken cancellationToken)
    {
        var normalizedEmail = NormalizeEmail(userEmail);
        if (normalizedEmail is null)
        {
            return BadRequest(new { message = "userEmail is required." });
        }

        var user = await _dbContext.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(item => item.Email == normalizedEmail, cancellationToken);

        if (user is null)
        {
            return Ok(new LearningProgressResponse
            {
                UserEmail = normalizedEmail,
                CompletedSituationIds = [],
                Items = [],
            });
        }

        var progressItems = await _dbContext.UserProgresses
            .AsNoTracking()
            .Where(item => item.UserId == user.UserId)
            .OrderBy(item => item.IslandId)
            .ThenBy(item => item.SituationId)
            .Select(item => new LearningProgressItemResponse
            {
                IslandId = item.IslandId,
                SituationId = item.SituationId,
                CurrentStep = item.CurrentStep,
                Status = item.Status,
                LastAccessedAt = item.LastAccessedAt,
                UpdatedAt = item.UpdatedAt,
            })
            .ToListAsync(cancellationToken);

        return Ok(new LearningProgressResponse
        {
            UserId = user.UserId,
            UserEmail = user.Email,
            CompletedSituationIds = progressItems
                .Where(item => item.Status == "Completed")
                .Select(item => item.SituationId)
                .Distinct()
                .OrderBy(item => item)
                .ToList(),
            Items = progressItems,
        });
    }

    [HttpPost("complete")]
    [ProducesResponseType(typeof(CompleteSituationProgressResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CompleteSituationProgressResponse>> CompleteSituation(
        [FromBody] CompleteSituationProgressRequest request,
        CancellationToken cancellationToken)
    {
        var normalizedEmail = NormalizeEmail(request.UserEmail);
        if (normalizedEmail is null)
        {
            return BadRequest(new { message = "userEmail is required." });
        }

        if (request.SituationId <= 0)
        {
            return BadRequest(new { message = "situationId must be greater than 0." });
        }

        var situation = await _dbContext.Situations
            .AsNoTracking()
            .Where(item =>
                item.SituationId == request.SituationId &&
                item.Status == "Published" &&
                item.Island.Status == "Active")
            .Select(item => new
            {
                item.SituationId,
                item.IslandId,
                item.OrderIndex,
            })
            .SingleOrDefaultAsync(cancellationToken);

        if (situation is null)
        {
            return NotFound(new { message = "Situation was not found." });
        }

        var finalStepId = await _dbContext.SituationSteps
            .AsNoTracking()
            .Where(item => item.SituationId == request.SituationId)
            .OrderByDescending(item => item.OrderIndex)
            .Select(item => item.StepId)
            .FirstOrDefaultAsync(cancellationToken);

        if (finalStepId <= 0)
        {
            return BadRequest(new { message = "Situation does not have any steps." });
        }

        var user = await FindOrCreateUserAsync(
            normalizedEmail,
            request.FullName,
            cancellationToken);

        var utcNow = DateTime.UtcNow;
        var progress = await _dbContext.UserProgresses
            .SingleOrDefaultAsync(
                item => item.UserId == user.UserId && item.SituationId == request.SituationId,
                cancellationToken);

        if (progress is null)
        {
            progress = new UserProgress
            {
                UserId = user.UserId,
                IslandId = situation.IslandId,
                SituationId = situation.SituationId,
                CurrentStep = finalStepId,
                Status = "Completed",
                LastAccessedAt = utcNow,
                CreatedAt = utcNow,
                UpdatedAt = utcNow,
            };

            _dbContext.UserProgresses.Add(progress);
        }
        else
        {
            progress.IslandId = situation.IslandId;
            progress.CurrentStep = finalStepId;
            progress.Status = "Completed";
            progress.LastAccessedAt = utcNow;
            progress.UpdatedAt = utcNow;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new CompleteSituationProgressResponse
        {
            ProgressId = progress.ProgressId,
            UserId = user.UserId,
            UserEmail = user.Email,
            IslandId = situation.IslandId,
            SituationId = situation.SituationId,
            Status = progress.Status,
            CurrentStep = progress.CurrentStep,
            CompletedAt = progress.UpdatedAt ?? progress.CreatedAt,
        });
    }

    private async Task<User> FindOrCreateUserAsync(
        string email,
        string? fullName,
        CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users.SingleOrDefaultAsync(
            item => item.Email == email,
            cancellationToken);

        if (user is not null)
        {
            return user;
        }

        user = new User
        {
            Email = email,
            FullName = BuildFullName(fullName, email),
            Password = LocalSessionPlaceholderPassword,
            Role = "Parent",
            CreatedAt = DateTime.UtcNow,
        };

        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return user;
    }

    private static string? NormalizeEmail(string? value)
    {
        var normalized = value?.Trim().ToLowerInvariant();
        return string.IsNullOrWhiteSpace(normalized) ? null : normalized;
    }

    private static string BuildFullName(string? fullName, string email)
    {
        var normalizedName = fullName?.Trim();
        if (!string.IsNullOrWhiteSpace(normalizedName))
        {
            return normalizedName;
        }

        var emailPrefix = email.Split('@')[0].Replace('.', ' ').Replace('_', ' ').Trim();
        return string.IsNullOrWhiteSpace(emailPrefix) ? "SmartSteps Parent" : emailPrefix;
    }
}

public sealed class CompleteSituationProgressRequest
{
    public int SituationId { get; set; }

    public string UserEmail { get; set; } = string.Empty;

    public string? FullName { get; set; }
}

public sealed class CompleteSituationProgressResponse
{
    public int ProgressId { get; set; }

    public int UserId { get; set; }

    public string UserEmail { get; set; } = string.Empty;

    public int IslandId { get; set; }

    public int SituationId { get; set; }

    public int CurrentStep { get; set; }

    public string Status { get; set; } = string.Empty;

    public DateTime CompletedAt { get; set; }
}

public sealed class LearningProgressResponse
{
    public int? UserId { get; set; }

    public string UserEmail { get; set; } = string.Empty;

    public IReadOnlyList<int> CompletedSituationIds { get; set; } = [];

    public IReadOnlyList<LearningProgressItemResponse> Items { get; set; } = [];
}

public sealed class LearningProgressItemResponse
{
    public int IslandId { get; set; }

    public int SituationId { get; set; }

    public int CurrentStep { get; set; }

    public string Status { get; set; } = string.Empty;

    public DateTime? LastAccessedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }
}
