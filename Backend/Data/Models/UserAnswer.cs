using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("UserAnswer")]
public class UserAnswer
{
    [Key]
    public int AnswerId { get; set; }

    [Range(1, int.MaxValue)]
    public int UserId { get; set; }

    [Range(1, int.MaxValue)]
    public int FlashcardId { get; set; }

    [Required]
    [StringLength(1, MinimumLength = 1)]
    [RegularExpression("^[AB]$")]
    [Column(TypeName = "char(1)")]
    public string SelectedAnswer { get; set; } = null!; // A or B

    public bool IsCorrect { get; set; }

    [Range(1, int.MaxValue)]
    public int AttemptCount { get; set; }

    public DateTime? AnsweredAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    [ForeignKey(nameof(UserId))]
    public User User { get; set; } = null!;

    [ForeignKey(nameof(FlashcardId))]
    public Flashcard Flashcard { get; set; } = null!;
}
