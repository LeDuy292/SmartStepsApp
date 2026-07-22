using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("SituationStep")]
public class SituationStep
{
    [Key]
    public int StepId { get; set; }

    [Range(1, int.MaxValue)]
    public int SituationId { get; set; }

    public string? Content { get; set; }

    [StringLength(500)]
    [Column(TypeName = "varchar(500)")]
    public string? MediaUrl { get; set; }

    [Required]
    [StringLength(30)]
    [RegularExpression("^(Intro|Story|Flashcard|Result)$")]
    [Column(TypeName = "varchar(30)")]
    public string StepType { get; set; } = null!; // Intro, Story, Flashcard, Result

    public int OrderIndex { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    [ForeignKey(nameof(SituationId))]
    [System.Text.Json.Serialization.JsonIgnore]
    public Situation Situation { get; set; } = null!;

    public ICollection<UserProgress> UserProgresses { get; set; } = new List<UserProgress>();
}
