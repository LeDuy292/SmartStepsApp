using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("UserProgress")]
public class UserProgress
{
    [Key]
    public int ProgressId { get; set; }

    [Range(1, int.MaxValue)]
    public int UserId { get; set; }

    [Range(1, int.MaxValue)]
    public int IslandId { get; set; }

    [Range(1, int.MaxValue)]
    public int SituationId { get; set; }

    [Range(1, int.MaxValue)]
    public int CurrentStep { get; set; }

    [Required]
    [StringLength(30)]
    [RegularExpression("^(InProgress|Completed)$")]
    [Column(TypeName = "varchar(30)")]
    public string Status { get; set; } = null!; // InProgress, Completed

    public DateTime? LastAccessedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    [ForeignKey(nameof(UserId))]
    public User User { get; set; } = null!;

    [ForeignKey(nameof(IslandId))]
    public Island Island { get; set; } = null!;

    [ForeignKey(nameof(SituationId))]
    public Situation Situation { get; set; } = null!;

    [ForeignKey(nameof(CurrentStep))]
    public SituationStep SituationStep { get; set; } = null!;
}
