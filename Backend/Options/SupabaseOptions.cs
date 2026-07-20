using System.ComponentModel.DataAnnotations;

namespace SmartStepsServer.Options;

public class SupabaseOptions
{
    [Required]
    public string Url { get; set; } = string.Empty;

    [Required]
    public string AnonKey { get; set; } = string.Empty;

    [Required]
    public string AvatarBucket { get; set; } = string.Empty;

    [Required]
    public string VideoBucket { get; set; } = string.Empty;
}
