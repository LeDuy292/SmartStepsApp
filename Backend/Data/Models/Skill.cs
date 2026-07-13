using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("Skill")]
public class Skill
{
    [Key]
    public int SkillId { get; set; }

    [Required]
    [StringLength(100)]
    public string Name { get; set; } = null!;

    [StringLength(500)]
    public string? Description { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    public ICollection<SituationSkill> SituationSkills { get; set; } = new List<SituationSkill>();
    public ICollection<ParentReviewQuestion> ParentReviewQuestions { get; set; } = new List<ParentReviewQuestion>();
}
