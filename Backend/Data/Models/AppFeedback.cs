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

    [MaxLength(30)]
    public string Category { get; set; } = "Suggestion";

    [MaxLength(20)]
    public string Status { get; set; } = "New";

    public int? SituationId { get; set; }

    [MaxLength(2000)]
    public string AdminResponse { get; set; } = string.Empty;

    public DateTime SubmittedAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? ResolvedAt { get; set; }

    public User User { get; set; } = null!;
    public Situation? Situation { get; set; }
}
