using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Data.Models;

namespace SmartStepsServer.Controllers;

[ApiController]
[Authorize]
[Route("api/progress")]
public sealed class ProgressController : ControllerBase
{
    private const string LocalSessionPlaceholderPassword = "LOCAL_SESSION_PLACEHOLDER";

    private readonly SmartStepsDbContext _dbContext;

    public ProgressController(SmartStepsDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpPost("start")]
    [ProducesResponseType(typeof(StartSituationProgressResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StartSituationProgressResponse>> StartSituation(
        [FromBody] StartSituationProgressRequest request,
        CancellationToken cancellationToken)
    {
        var normalizedEmail = NormalizeEmail(request.UserEmail);
        if (normalizedEmail is null || request.SituationId <= 0)
        {
            return BadRequest(new { message = "A valid userEmail and situationId are required." });
        }
        if (!IsCurrentUserEmail(normalizedEmail))
        {
            return Forbid();
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
                FirstStepId = item.SituationSteps
                    .OrderBy(step => step.OrderIndex)
                    .Select(step => step.StepId)
                    .FirstOrDefault(),
            })
            .SingleOrDefaultAsync(cancellationToken);

        if (situation is null)
        {
            return NotFound(new { message = "Situation was not found." });
        }

        if (situation.FirstStepId <= 0)
        {
            return BadRequest(new { message = "Situation does not have any steps." });
        }

        var user = await FindOrCreateUserAsync(normalizedEmail, request.FullName, cancellationToken);
        var utcNow = DateTime.UtcNow;
        var progress = await _dbContext.UserProgresses.SingleOrDefaultAsync(
            item => item.UserId == user.UserId && item.SituationId == situation.SituationId,
            cancellationToken);

        if (progress is null)
        {
            progress = new UserProgress
            {
                UserId = user.UserId,
                IslandId = situation.IslandId,
                SituationId = situation.SituationId,
                CurrentStep = situation.FirstStepId,
                Status = "InProgress",
                LastAccessedAt = utcNow,
                CreatedAt = utcNow,
            };
            _dbContext.UserProgresses.Add(progress);
        }
        else if (progress.Status != "Completed")
        {
            progress.LastAccessedAt = utcNow;
            progress.UpdatedAt = utcNow;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new StartSituationProgressResponse
        {
            ProgressId = progress.ProgressId,
            UserId = user.UserId,
            SituationId = progress.SituationId,
            CurrentStep = progress.CurrentStep,
            Status = progress.Status,
            LastAccessedAt = progress.LastAccessedAt ?? utcNow,
        });
    }

    [HttpPost("answer")]
    [ProducesResponseType(typeof(RecordAnswerResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<RecordAnswerResponse>> RecordAnswer(
        [FromBody] RecordAnswerRequest request,
        CancellationToken cancellationToken)
    {
        var normalizedEmail = NormalizeEmail(request.UserEmail);
        var selectedAnswer = request.SelectedAnswer?.Trim().ToUpperInvariant();
        if (normalizedEmail is null || request.FlashcardId <= 0 || selectedAnswer is not ("A" or "B"))
        {
            return BadRequest(new { message = "A valid userEmail, flashcardId and selectedAnswer (A or B) are required." });
        }
        if (!IsCurrentUserEmail(normalizedEmail))
        {
            return Forbid();
        }

        var flashcard = await _dbContext.Flashcards
            .AsNoTracking()
            .Where(item =>
                item.FlashcardId == request.FlashcardId &&
                item.Situation.Status == "Published" &&
                item.Situation.Island.Status == "Active")
            .Select(item => new
            {
                item.FlashcardId,
                item.SituationId,
                item.CorrectAnswer,
                item.CorrectFeedback,
                item.WrongFeedback,
            })
            .SingleOrDefaultAsync(cancellationToken);

        if (flashcard is null)
        {
            return NotFound(new { message = "Flashcard was not found." });
        }

        var user = await FindOrCreateUserAsync(normalizedEmail, request.FullName, cancellationToken);
        var attemptCount = await _dbContext.UserAnswers
            .Where(item => item.UserId == user.UserId && item.FlashcardId == flashcard.FlashcardId)
            .Select(item => (int?)item.AttemptCount)
            .MaxAsync(cancellationToken) ?? 0;
        attemptCount++;

        var isCorrect = string.Equals(selectedAnswer, flashcard.CorrectAnswer, StringComparison.OrdinalIgnoreCase);
        var answeredAt = DateTime.UtcNow;
        var answer = new UserAnswer
        {
            UserId = user.UserId,
            FlashcardId = flashcard.FlashcardId,
            SelectedAnswer = selectedAnswer,
            IsCorrect = isCorrect,
            AttemptCount = attemptCount,
            AnsweredAt = answeredAt,
            CreatedAt = answeredAt,
        };
        _dbContext.UserAnswers.Add(answer);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new RecordAnswerResponse
        {
            AnswerId = answer.AnswerId,
            UserId = user.UserId,
            SituationId = flashcard.SituationId,
            FlashcardId = flashcard.FlashcardId,
            SelectedAnswer = selectedAnswer,
            IsCorrect = isCorrect,
            AttemptCount = attemptCount,
            Feedback = isCorrect ? flashcard.CorrectFeedback : flashcard.WrongFeedback,
            AnsweredAt = answeredAt,
        });
    }

    [HttpPut("step")]
    [ProducesResponseType(typeof(StartSituationProgressResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StartSituationProgressResponse>> UpdateCurrentStep(
        [FromBody] UpdateCurrentStepRequest request,
        CancellationToken cancellationToken)
    {
        var normalizedEmail = NormalizeEmail(request.UserEmail);
        if (normalizedEmail is null || request.SituationId <= 0 || request.StepId <= 0)
        {
            return BadRequest(new { message = "A valid userEmail, situationId and stepId are required." });
        }
        if (!IsCurrentUserEmail(normalizedEmail))
        {
            return Forbid();
        }

        var userId = await _dbContext.Users
            .Where(user => user.Email == normalizedEmail)
            .Select(user => (int?)user.UserId)
            .SingleOrDefaultAsync(cancellationToken);
        var stepExists = await _dbContext.SituationSteps.AnyAsync(
            step =>
                step.StepId == request.StepId &&
                step.SituationId == request.SituationId &&
                step.Situation.Status == "Published",
            cancellationToken);
        if (userId is null || !stepExists)
        {
            return NotFound(new { message = "Learning progress or situation step was not found." });
        }

        var progress = await _dbContext.UserProgresses.SingleOrDefaultAsync(
            item => item.UserId == userId && item.SituationId == request.SituationId,
            cancellationToken);
        if (progress is null)
        {
            return NotFound(new { message = "Start the situation before updating its current step." });
        }

        if (progress.Status != "Completed")
        {
            progress.CurrentStep = request.StepId;
            progress.Status = "InProgress";
            progress.LastAccessedAt = DateTime.UtcNow;
            progress.UpdatedAt = progress.LastAccessedAt;
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        return Ok(new StartSituationProgressResponse
        {
            ProgressId = progress.ProgressId,
            UserId = progress.UserId,
            SituationId = progress.SituationId,
            CurrentStep = progress.CurrentStep,
            Status = progress.Status,
            LastAccessedAt = progress.LastAccessedAt ?? progress.CreatedAt,
        });
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
        if (!IsCurrentUserEmail(normalizedEmail))
        {
            return Forbid();
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
        if (!IsCurrentUserEmail(normalizedEmail))
        {
            return Forbid();
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

    private bool IsCurrentUserEmail(string email)
    {
        var claimEmail = User.FindFirstValue(JwtRegisteredClaimNames.Email) ??
            User.FindFirstValue(ClaimTypes.Email);
        return string.Equals(claimEmail?.Trim(), email, StringComparison.OrdinalIgnoreCase);
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

public sealed class StartSituationProgressRequest
{
    public int SituationId { get; set; }

    public string UserEmail { get; set; } = string.Empty;

    public string? FullName { get; set; }
}

public sealed class StartSituationProgressResponse
{
    public int ProgressId { get; set; }

    public int UserId { get; set; }

    public int SituationId { get; set; }

    public int CurrentStep { get; set; }

    public string Status { get; set; } = string.Empty;

    public DateTime LastAccessedAt { get; set; }
}

public sealed class RecordAnswerRequest
{
    public int FlashcardId { get; set; }

    public string UserEmail { get; set; } = string.Empty;

    public string SelectedAnswer { get; set; } = string.Empty;

    public string? FullName { get; set; }
}

public sealed class UpdateCurrentStepRequest
{
    public int SituationId { get; set; }

    public int StepId { get; set; }

    public string UserEmail { get; set; } = string.Empty;
}

public sealed class RecordAnswerResponse
{
    public int AnswerId { get; set; }

    public int UserId { get; set; }

    public int SituationId { get; set; }

    public int FlashcardId { get; set; }

    public string SelectedAnswer { get; set; } = string.Empty;

    public bool IsCorrect { get; set; }

    public int AttemptCount { get; set; }

    public string? Feedback { get; set; }

    public DateTime AnsweredAt { get; set; }
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
