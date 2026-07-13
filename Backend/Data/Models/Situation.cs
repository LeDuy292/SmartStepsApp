using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("Situation")]
public class Situation
{
    [Key]
    public int SituationId { get; set; }

    [Range(1, int.MaxValue)]
    public int IslandId { get; set; }

    [Required]
    [StringLength(200)]
    public string Title { get; set; } = null!;

    public string? Intro { get; set; }

    public int OrderIndex { get; set; }

    [Required]
    [StringLength(30)]
    [RegularExpression("^(Draft|Pending|Approved|Rejected|Published|Hidden)$")]
    [Column(TypeName = "varchar(30)")]
    public string Status { get; set; } = null!; // Draft, Pending, Approved, Rejected, Published, Hidden

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    [ForeignKey(nameof(IslandId))]
    public Island Island { get; set; } = null!;

    public ICollection<SituationStep> SituationSteps { get; set; } = new List<SituationStep>();
    public ICollection<Flashcard> Flashcards { get; set; } = new List<Flashcard>();
    public ICollection<SituationSkill> SituationSkills { get; set; } = new List<SituationSkill>();
    public ICollection<UserProgress> UserProgresses { get; set; } = new List<UserProgress>();
    public ICollection<ParentReviewQuestion> ParentReviewQuestions { get; set; } = new List<ParentReviewQuestion>();
    public ICollection<LessonRecommendation> LessonRecommendations { get; set; } =
        new List<LessonRecommendation>();
}
