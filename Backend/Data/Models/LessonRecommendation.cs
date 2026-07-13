using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("LessonRecommendation")]
public class LessonRecommendation
{
    [Key]
    public int RecommendationId { get; set; }

    public int ChildId { get; set; }

    public int SituationId { get; set; }

    [StringLength(30)]
    public string RecommendationType { get; set; } = null!;

    public string Reason { get; set; } = string.Empty;

    public int Priority { get; set; }

    [StringLength(30)]
    public string Status { get; set; } = "Pending";

    public DateTime CreatedAt { get; set; }

    public DateTime? CompletedAt { get; set; }

    [ForeignKey(nameof(ChildId))]
    public User Child { get; set; } = null!;

    [ForeignKey(nameof(SituationId))]
    public Situation Situation { get; set; } = null!;
}
