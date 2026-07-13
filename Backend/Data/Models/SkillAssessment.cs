using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("SkillAssessment")]
public class SkillAssessment
{
    [Key]
    public int AssessmentId { get; set; }

    public int ChildId { get; set; }

    public int SkillId { get; set; }

    public int TotalAttempts { get; set; }

    public int CorrectAttempts { get; set; }

    public decimal CorrectRate { get; set; }

    [StringLength(30)]
    public string MasteryLevel { get; set; } = null!;

    public DateTime LastAssessedAt { get; set; }

    [ForeignKey(nameof(ChildId))]
    public User Child { get; set; } = null!;

    [ForeignKey(nameof(SkillId))]
    public Skill Skill { get; set; } = null!;
}
