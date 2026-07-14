using System.ComponentModel.DataAnnotations;

namespace SmartStepsServer.Data.Models;

public sealed class AppFeedback
{
    [Key]
    public int FeedbackId { get; set; }

    public int UserId { get; set; }

    [MaxLength(100)]
    public string ClientId { get; set; } = string.Empty;

    [MaxLength(50)]
    public string Source { get; set; } = string.Empty;

    public int ExperienceRating { get; set; }
    public int ChildEngagementRating { get; set; }
    public int EffectivenessRating { get; set; }

    [MaxLength(50)]
    public string AgeFit { get; set; } = string.Empty;

    [MaxLength(2000)]
    public string ImprovementNote { get; set; } = string.Empty;

    public DateTime SubmittedAt { get; set; }
    public DateTime CreatedAt { get; set; }

    public User User { get; set; } = null!;
}
