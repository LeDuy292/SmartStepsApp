using System.ComponentModel.DataAnnotations;

namespace SmartStepsServer.Options;

public sealed class CloudinaryMediaOptions
{
    public const string SectionName = "Cloudinary";

    [Required]
    public string CloudName { get; set; } = string.Empty;

    [Required]
    public string ApiKey { get; set; } = string.Empty;

    [Required]
    public string ApiSecret { get; set; } = string.Empty;

    [Range(30, 3600)]
    public int SignedUrlExpiresInSeconds { get; set; } = 300;

    public string ResourceType { get; set; } = "video";

    public string DeliveryType { get; set; } = "upload";

    public string? DevelopmentMediaRoot { get; set; }
}
