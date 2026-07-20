using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;

namespace SmartStepsServer.Controllers;

[ApiController]
[Route("api/media")]
public sealed class MediaController : ControllerBase
{
    private const string CloudinaryBaseUrl = "https://res.cloudinary.com/dtm5a4bwr/video/upload";

    private readonly SmartStepsDbContext _dbContext;
    private readonly ILogger<MediaController> _logger;

    public MediaController(
        SmartStepsDbContext dbContext,
        ILogger<MediaController> logger)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    [HttpPost("signed-url")]
    [ProducesResponseType(typeof(CreateSignedMediaUrlResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CreateSignedMediaUrlResponse>> CreateSignedUrl(
        CreateSignedMediaUrlRequest request,
        CancellationToken cancellationToken)
    {
        var media = await _dbContext.SituationSteps
            .AsNoTracking()
            .Where(step => step.StepId == request.StepId)
            .Select(step => new
            {
                step.StepId,
                step.MediaUrl,
                SituationStatus = step.Situation.Status
            })
            .SingleOrDefaultAsync(cancellationToken);

        if (media is null
            || !string.Equals(media.SituationStatus, "Published", StringComparison.OrdinalIgnoreCase)
            || string.IsNullOrWhiteSpace(media.MediaUrl))
        {
            return NotFound(new { message = "Media was not found." });
        }

        var publicUrl = ResolveMediaUrl(media.MediaUrl);

        return Ok(new CreateSignedMediaUrlResponse
        {
            StepId = media.StepId,
            Bucket = "dtm5a4bwr",
            Path = media.MediaUrl,
            SignedUrl = publicUrl,
            ExpiresInSeconds = 31536000,
            ExpiresAtUtc = DateTime.UtcNow.AddDays(365)
        });
    }

    [HttpPost("signed-voice-url")]
    [ProducesResponseType(typeof(CreateSignedVoiceUrlResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CreateSignedVoiceUrlResponse>> CreateSignedVoiceUrl(
        CreateSignedVoiceUrlRequest request,
        CancellationToken cancellationToken)
    {
        var rawPath = request.MediaUrl.Trim();

        var isPublishedFlashcardVoice = await _dbContext.Flashcards
            .AsNoTracking()
            .AnyAsync(flashcard =>
                flashcard.Situation.Status == "Published" &&
                flashcard.Situation.Island.Status == "Active" &&
                (flashcard.QuestionVoiceUrl == rawPath ||
                    flashcard.OptionAVoiceUrl == rawPath ||
                    flashcard.OptionBVoiceUrl == rawPath),
                cancellationToken);

        if (!isPublishedFlashcardVoice)
        {
            return NotFound(new { message = "Voice media was not found." });
        }

        var publicUrl = ResolveMediaUrl(rawPath);

        return Ok(new CreateSignedVoiceUrlResponse
        {
            Bucket = "dtm5a4bwr",
            Path = rawPath,
            SignedUrl = publicUrl,
            ExpiresInSeconds = 31536000,
            ExpiresAtUtc = DateTime.UtcNow.AddDays(365)
        });
    }

    private static string ResolveMediaUrl(string mediaUrl)
    {
        var trimmed = mediaUrl.Trim();

        if (trimmed.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            trimmed.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            return trimmed;
        }

        var objectPath = trimmed.Replace('\\', '/').TrimStart('/');
        return $"{CloudinaryBaseUrl}/{objectPath}";
    }
}

public sealed class CreateSignedMediaUrlRequest
{
    [Range(1, int.MaxValue)]
    public int StepId { get; set; }
}

public sealed class CreateSignedMediaUrlResponse
{
    public int StepId { get; set; }
    public string Bucket { get; set; } = string.Empty;
    public string Path { get; set; } = string.Empty;
    public string SignedUrl { get; set; } = string.Empty;
    public int ExpiresInSeconds { get; set; }
    public DateTime ExpiresAtUtc { get; set; }
}

public sealed class CreateSignedVoiceUrlRequest
{
    [Required]
    public string MediaUrl { get; set; } = string.Empty;
}

public sealed class CreateSignedVoiceUrlResponse
{
    public string Bucket { get; set; } = string.Empty;
    public string Path { get; set; } = string.Empty;
    public string SignedUrl { get; set; } = string.Empty;
    public int ExpiresInSeconds { get; set; }
    public DateTime ExpiresAtUtc { get; set; }
}
