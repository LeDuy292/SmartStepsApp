using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("Flashcard")]
public class Flashcard
{
    [Key]
    public int FlashcardId { get; set; }

    [Range(1, int.MaxValue)]
    public int SituationId { get; set; }

    [Required]
    public string Question { get; set; } = null!;

    [Required]
    [StringLength(500)]
    public string OptionA { get; set; } = null!;

    [Required]
    [StringLength(500)]
    public string OptionB { get; set; } = null!;

    [StringLength(500)]
    public string? QuestionVoiceUrl { get; set; }

    [StringLength(500)]
    public string? OptionAVoiceUrl { get; set; }

    [StringLength(500)]
    public string? OptionBVoiceUrl { get; set; }

    [Required]
    [StringLength(1, MinimumLength = 1)]
    [RegularExpression("^[AB]$")]
    [Column(TypeName = "char(1)")]
    public string CorrectAnswer { get; set; } = null!; // A or B

    public string? CorrectFeedback { get; set; }

    public string? WrongFeedback { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    [ForeignKey(nameof(SituationId))]
    public Situation Situation { get; set; } = null!;

    public ICollection<UserAnswer> UserAnswers { get; set; } = new List<UserAnswer>();
}
