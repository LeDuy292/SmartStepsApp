using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace SmartStepsServer.Data.Models;

[Table("SituationSkill")]
[PrimaryKey(nameof(SituationId), nameof(SkillId))]
public class SituationSkill
{
    [Column(Order = 0)]
    [Range(1, int.MaxValue)]
    public int SituationId { get; set; }

    [Column(Order = 1)]
    [Range(1, int.MaxValue)]
    public int SkillId { get; set; }

    // Navigation properties
    [ForeignKey(nameof(SituationId))]
    public Situation Situation { get; set; } = null!;

    [ForeignKey(nameof(SkillId))]
    public Skill Skill { get; set; } = null!;
}
