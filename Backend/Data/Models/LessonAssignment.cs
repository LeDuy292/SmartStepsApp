using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("LessonAssignment")]
public sealed class LessonAssignment
{
    [Key]
    public int AssignmentId { get; set; }
    public int ParentId { get; set; }
    public int ChildId { get; set; }
    public int SituationId { get; set; }
    [Required, MaxLength(20)]
    public string Status { get; set; } = "Assigned";
    [MaxLength(500)]
    public string Note { get; set; } = string.Empty;
    public DateTime AssignedAt { get; set; }
    public DateTime? DueAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    [ForeignKey(nameof(ParentId))]
    public User Parent { get; set; } = null!;
    [ForeignKey(nameof(ChildId))]
    public User Child { get; set; } = null!;
    [ForeignKey(nameof(SituationId))]
    public Situation Situation { get; set; } = null!;
}
