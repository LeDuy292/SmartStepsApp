using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("ParentReviewQuestion")]
public class ParentReviewQuestion
{
    [Key]
    public int QuestionId { get; set; }

    [Range(1, int.MaxValue)]
    public int SkillId { get; set; }

    [Range(1, int.MaxValue)]
    public int SituationId { get; set; }

    [Required]
    public string QuestionText { get; set; } = null!;

    public string? SuggestedActivity { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    [ForeignKey(nameof(SkillId))]
    public Skill Skill { get; set; } = null!;

    [ForeignKey(nameof(SituationId))]
    public Situation Situation { get; set; } = null!;
}
