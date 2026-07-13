using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SmartStepsServer.Data;
using SmartStepsServer.Options;
using SmartStepsServer.Services;

namespace SmartStepsServer.Controllers;

[ApiController]
[Route("api/media")]
public sealed class MediaController : ControllerBase
{
    private readonly SmartStepsDbContext _dbContext;
    private readonly ICloudinaryMediaService _cloudinaryMediaService;
    private readonly CloudinaryMediaOptions _options;
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<MediaController> _logger;

    public MediaController(
        SmartStepsDbContext dbContext,
        ICloudinaryMediaService cloudinaryMediaService,
        IOptions<CloudinaryMediaOptions> options,
        IWebHostEnvironment environment,
        ILogger<MediaController> logger)
    {
        _dbContext = dbContext;
        _cloudinaryMediaService = cloudinaryMediaService;
        _options = options.Value;
        _environment = environment;
        _logger = logger;
    }

    [HttpGet("cloudinary-config")]
    [ProducesResponseType(typeof(CloudinaryConfigDiagnosticsResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public ActionResult<CloudinaryConfigDiagnosticsResponse> GetCloudinaryConfig()
    {
        if (!_environment.IsDevelopment())
        {
            return NotFound();
        }

        var validationErrors = ValidateOptions(_options);
        return Ok(new CloudinaryConfigDiagnosticsResponse
        {
            EnvironmentName = _environment.EnvironmentName,
            Effective = new EffectiveCloudinaryConfig
            {
                CloudName = _options.CloudName,
                ApiKeyConfigured = !string.IsNullOrWhiteSpace(_options.ApiKey),
                SignedUrlExpiresInSeconds = _options.SignedUrlExpiresInSeconds,
                ResourceType = _options.ResourceType,
                DeliveryType = _options.DeliveryType
            },
            EnvironmentVariables = new CloudinaryEnvironmentVariables
            {
                CloudName = ReadNonSecretEnvironmentVariable("Cloudinary__CloudName"),
                ApiKey = ReadNonSecretEnvironmentVariable("Cloudinary__ApiKey"),
                ApiSecret = ReadSecretEnvironmentVariable("Cloudinary__ApiSecret"),
                SignedUrlExpiresInSeconds = ReadNonSecretEnvironmentVariable("Cloudinary__SignedUrlExpiresInSeconds"),
                ResourceType = ReadNonSecretEnvironmentVariable("Cloudinary__ResourceType"),
                DeliveryType = ReadNonSecretEnvironmentVariable("Cloudinary__DeliveryType")
            },
            ValidationErrors = validationErrors
        });
    }

    [HttpPost("signed-url")]
    [ProducesResponseType(typeof(CreateSignedMediaUrlResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status502BadGateway)]
    public async Task<ActionResult<CreateSignedMediaUrlResponse>> CreateSignedUrl(
        CreateSignedMediaUrlRequest request,
        CancellationToken cancellationToken)
    {
        var validationErrors = ValidateOptions(_options);
        if (validationErrors.Count > 0)
        {
            if (_environment.IsDevelopment())
            {
                return await CreateDevelopmentMediaResponseAsync(request.StepId, cancellationToken);
            }

            _logger.LogError(
                "Cloudinary is not configured correctly: {Errors}",
                string.Join("; ", validationErrors));
            return Problem(
                title: "Cloudinary is not configured.",
                detail: string.Join("; ", validationErrors),
                statusCode: StatusCodes.Status500InternalServerError);
        }

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

        if (!TryGetObjectPath(media.MediaUrl, out var objectPath))
        {
            _logger.LogError(
                "Invalid Cloudinary media URL/path for step {StepId}: {MediaUrl}",
                media.StepId,
                media.MediaUrl);
            return Problem(
                title: "Media path is invalid.",
                detail: $"Step {media.StepId} has MediaUrl '{media.MediaUrl}', which is not a valid Cloudinary public ID.",
                statusCode: StatusCodes.Status500InternalServerError);
        }

        try
        {
            var signedUrl = await _cloudinaryMediaService.CreateSignedDownloadUrlAsync(
                media.MediaUrl,
                _options.ResourceType,
                "mp4",
                _options.SignedUrlExpiresInSeconds,
                cancellationToken);

            return Ok(new CreateSignedMediaUrlResponse
            {
                StepId = media.StepId,
                Bucket = _options.CloudName,
                Path = objectPath,
                SignedUrl = signedUrl,
                ExpiresInSeconds = _options.SignedUrlExpiresInSeconds,
                ExpiresAtUtc = DateTime.UtcNow.AddSeconds(_options.SignedUrlExpiresInSeconds)
            });
        }
        catch (CloudinaryMediaException ex)
        {
            _logger.LogError(ex, "Could not create signed URL for step {StepId}.", media.StepId);
            return Problem(
                title: "Could not create signed media URL.",
                detail: ex.Message,
                statusCode: StatusCodes.Status502BadGateway);
        }
    }

    [HttpGet("development/{stepId:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetDevelopmentMedia(
        int stepId,
        CancellationToken cancellationToken)
    {
        if (!_environment.IsDevelopment())
        {
            return NotFound();
        }

        var mediaUrl = await GetPublishedMediaUrlAsync(stepId, cancellationToken);
        if (!TryResolveDevelopmentMediaPath(mediaUrl, out var mediaPath, out _))
        {
            return NotFound(new { message = "Development media was not found." });
        }

        return PhysicalFile(mediaPath, "video/mp4", enableRangeProcessing: true);
    }

    [HttpPost("signed-voice-url")]
    [ProducesResponseType(typeof(CreateSignedVoiceUrlResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status502BadGateway)]
    public async Task<ActionResult<CreateSignedVoiceUrlResponse>> CreateSignedVoiceUrl(
        CreateSignedVoiceUrlRequest request,
        CancellationToken cancellationToken)
    {
        var validationErrors = ValidateOptions(_options);
        if (validationErrors.Count > 0)
        {
            _logger.LogError(
                "Cloudinary is not configured correctly: {Errors}",
                string.Join("; ", validationErrors));
            return Problem(
                title: "Cloudinary is not configured.",
                detail: string.Join("; ", validationErrors),
                statusCode: StatusCodes.Status500InternalServerError);
        }

        if (!TryGetObjectPath(request.MediaUrl, out var objectPath))
        {
            _logger.LogError("Invalid voice media URL/path: {MediaUrl}", request.MediaUrl);
            return Problem(
                title: "Voice media path is invalid.",
                detail: $"MediaUrl '{request.MediaUrl}' is not a valid Cloudinary public ID.",
                statusCode: StatusCodes.Status400BadRequest);
        }

        var isPublishedFlashcardVoice = await _dbContext.Flashcards
            .AsNoTracking()
            .AnyAsync(flashcard =>
                flashcard.Situation.Status == "Published" &&
                flashcard.Situation.Island.Status == "Active" &&
                (flashcard.QuestionVoiceUrl == objectPath ||
                    flashcard.OptionAVoiceUrl == objectPath ||
                    flashcard.OptionBVoiceUrl == objectPath),
                cancellationToken);

        if (!isPublishedFlashcardVoice)
        {
            return NotFound(new { message = "Voice media was not found." });
        }

        try
        {
            var signedUrl = await _cloudinaryMediaService.CreateSignedDownloadUrlAsync(
                request.MediaUrl,
                _options.ResourceType,
                "mp3",
                _options.SignedUrlExpiresInSeconds,
                cancellationToken);

            return Ok(new CreateSignedVoiceUrlResponse
            {
                Bucket = _options.CloudName,
                Path = objectPath,
                SignedUrl = signedUrl,
                ExpiresInSeconds = _options.SignedUrlExpiresInSeconds,
                ExpiresAtUtc = DateTime.UtcNow.AddSeconds(_options.SignedUrlExpiresInSeconds)
            });
        }
        catch (CloudinaryMediaException ex)
        {
            _logger.LogError(ex, "Could not create signed voice URL for {MediaUrl}.", request.MediaUrl);
            return Problem(
                title: "Could not create signed voice URL.",
                detail: ex.Message,
                statusCode: StatusCodes.Status502BadGateway);
        }
    }

    private async Task<ActionResult<CreateSignedMediaUrlResponse>> CreateDevelopmentMediaResponseAsync(
        int stepId,
        CancellationToken cancellationToken)
    {
        var mediaUrl = await GetPublishedMediaUrlAsync(stepId, cancellationToken);
        if (!TryResolveDevelopmentMediaPath(mediaUrl, out var mediaPath, out var relativePath))
        {
            return NotFound(new { message = "Development media was not found." });
        }

        var requestBaseUrl = $"{Request.Scheme}://{Request.Host}";
        return Ok(new CreateSignedMediaUrlResponse
        {
            StepId = stepId,
            Bucket = "local-development",
            Path = relativePath,
            SignedUrl = $"{requestBaseUrl}/api/media/development/{stepId}",
            ExpiresInSeconds = _options.SignedUrlExpiresInSeconds,
            ExpiresAtUtc = DateTime.UtcNow.AddSeconds(_options.SignedUrlExpiresInSeconds)
        });
    }

    private async Task<string?> GetPublishedMediaUrlAsync(
        int stepId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.SituationSteps
            .AsNoTracking()
            .Where(step =>
                step.StepId == stepId
                && step.Situation.Status == "Published"
                && step.Situation.Island.Status == "Active")
            .Select(step => step.MediaUrl)
            .SingleOrDefaultAsync(cancellationToken);
    }

    private bool TryResolveDevelopmentMediaPath(
        string? mediaUrl,
        out string mediaPath,
        out string relativePath)
    {
        mediaPath = string.Empty;
        relativePath = string.Empty;
        if (string.IsNullOrWhiteSpace(mediaUrl)
            || string.IsNullOrWhiteSpace(_options.DevelopmentMediaRoot))
        {
            return false;
        }

        if (!TryGetObjectPath(mediaUrl, out relativePath))
        {
            return false;
        }

        var rootPath = Path.GetFullPath(
            Path.Combine(_environment.ContentRootPath, _options.DevelopmentMediaRoot));
        var candidatePath = Path.GetFullPath(Path.Combine(rootPath, relativePath));

        if (!candidatePath.StartsWith(rootPath + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase)
            || !System.IO.File.Exists(candidatePath))
        {
            return false;
        }

        mediaPath = candidatePath;
        return true;
    }

    private static List<string> ValidateOptions(CloudinaryMediaOptions options)
    {
        var results = new List<ValidationResult>();
        var context = new ValidationContext(options);
        Validator.TryValidateObject(options, context, results, validateAllProperties: true);

        if (string.IsNullOrWhiteSpace(options.CloudName))
        {
            results.Add(new ValidationResult("Cloudinary:CloudName is required."));
        }

        if (string.IsNullOrWhiteSpace(options.ResourceType))
        {
            results.Add(new ValidationResult("Cloudinary:ResourceType is required."));
        }

        if (!string.Equals(options.ResourceType, "video", StringComparison.OrdinalIgnoreCase))
        {
            results.Add(new ValidationResult("Cloudinary:ResourceType must be 'video' for the current media pipeline."));
        }

        return results
            .Where(result => !string.IsNullOrWhiteSpace(result.ErrorMessage))
            .Select(result => result.ErrorMessage!)
            .ToList();
    }

    private static bool TryGetObjectPath(
        string mediaUrl,
        out string objectPath)
    {
        objectPath = string.Empty;
        var value = mediaUrl.Trim();

        if (Uri.TryCreate(value, UriKind.Absolute, out var uri))
        {
            if (string.Equals(uri.Host, "api.cloudinary.com", StringComparison.OrdinalIgnoreCase)
                || string.Equals(uri.Host, "res.cloudinary.com", StringComparison.OrdinalIgnoreCase))
            {
                return TryExtractCloudinaryObjectPath(uri, out objectPath);
            }

            value = uri.AbsolutePath;
        }

        var queryIndex = value.IndexOfAny(new[] { '?', '#' });
        if (queryIndex >= 0)
        {
            value = value[..queryIndex];
        }

        value = value.Replace('\\', '/').TrimStart('/');
        if (!IsSafePublicId(value))
        {
            return false;
        }

        objectPath = value;
        return true;
    }

    private static bool TryExtractCloudinaryObjectPath(
        Uri uri,
        out string objectPath)
    {
        objectPath = string.Empty;
        if (string.Equals(uri.Host, "api.cloudinary.com", StringComparison.OrdinalIgnoreCase))
        {
            var query = uri.Query.TrimStart('?');
            var parameters = query.Split('&', StringSplitOptions.RemoveEmptyEntries)
                .Select(part => part.Split('=', 2))
                .Where(part => part.Length == 2)
                .ToDictionary(
                    part => Uri.UnescapeDataString(part[0]),
                    part => Uri.UnescapeDataString(part[1]),
                    StringComparer.OrdinalIgnoreCase);

            if (parameters.TryGetValue("public_id", out var publicId)
                && !string.IsNullOrWhiteSpace(publicId))
            {
                var format = parameters.TryGetValue("format", out var queryFormat) && !string.IsNullOrWhiteSpace(queryFormat)
                    ? queryFormat
                    : null;

                objectPath = string.IsNullOrWhiteSpace(format)
                    ? publicId
                    : $"{publicId}.{format}";
                return true;
            }

            return false;
        }

        var segments = uri.AbsolutePath
            .Split('/', StringSplitOptions.RemoveEmptyEntries)
            .Select(Uri.UnescapeDataString)
            .ToArray();

        var resourceTypeIndex = Array.FindIndex(segments, segment =>
            string.Equals(segment, "image", StringComparison.OrdinalIgnoreCase)
            || string.Equals(segment, "video", StringComparison.OrdinalIgnoreCase)
            || string.Equals(segment, "raw", StringComparison.OrdinalIgnoreCase));

        if (resourceTypeIndex < 0 || resourceTypeIndex + 2 >= segments.Length)
        {
            return false;
        }

        var candidate = string.Join("/", segments.Skip(resourceTypeIndex + 2));
        if (!IsSafePublicId(candidate))
        {
            return false;
        }

        objectPath = candidate;
        return true;
    }

    private static bool IsSafePublicId(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        var segments = value.Split('/', StringSplitOptions.RemoveEmptyEntries);
        return segments.Length > 0
            && segments.All(segment => segment is not "." and not "..");
    }

    private static EnvironmentVariableDiagnostics ReadNonSecretEnvironmentVariable(string name)
    {
        var value = Environment.GetEnvironmentVariable(name);
        return new EnvironmentVariableDiagnostics
        {
            IsSet = !string.IsNullOrWhiteSpace(value),
            Value = value
        };
    }

    private static EnvironmentVariableDiagnostics ReadSecretEnvironmentVariable(string name)
    {
        var value = Environment.GetEnvironmentVariable(name);
        return new EnvironmentVariableDiagnostics
        {
            IsSet = !string.IsNullOrWhiteSpace(value)
        };
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

public sealed class CloudinaryConfigDiagnosticsResponse
{
    public string EnvironmentName { get; set; } = string.Empty;

    public EffectiveCloudinaryConfig Effective { get; set; } = new();

    public CloudinaryEnvironmentVariables EnvironmentVariables { get; set; } = new();

    public List<string> ValidationErrors { get; set; } = new();
}

public sealed class EffectiveCloudinaryConfig
{
    public string CloudName { get; set; } = string.Empty;

    public bool ApiKeyConfigured { get; set; }

    public int SignedUrlExpiresInSeconds { get; set; }

    public string ResourceType { get; set; } = string.Empty;

    public string DeliveryType { get; set; } = string.Empty;
}

public sealed class CloudinaryEnvironmentVariables
{
    public EnvironmentVariableDiagnostics CloudName { get; set; } = new();

    public EnvironmentVariableDiagnostics ApiKey { get; set; } = new();

    public EnvironmentVariableDiagnostics ApiSecret { get; set; } = new();

    public EnvironmentVariableDiagnostics SignedUrlExpiresInSeconds { get; set; } = new();

    public EnvironmentVariableDiagnostics ResourceType { get; set; } = new();

    public EnvironmentVariableDiagnostics DeliveryType { get; set; } = new();
}

public sealed class EnvironmentVariableDiagnostics
{
    public bool IsSet { get; set; }

    public string? Value { get; set; }
}
