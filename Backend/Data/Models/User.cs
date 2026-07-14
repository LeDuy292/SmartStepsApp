using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("Users")]
public class User
{
    [Key]
    public int UserId { get; set; }

    [Required]
    [StringLength(100)]
    public string FullName { get; set; } = null!;

    [Required]
    [EmailAddress]
    [StringLength(255)]
    [Column(TypeName = "varchar(255)")]
    public string Email { get; set; } = null!;

    [Required]
    [StringLength(255)]
    [Column(TypeName = "varchar(255)")]
    public string Password { get; set; } = null!;

    [Required]
    [StringLength(30)]
    [RegularExpression("^(Child|Parent|Admin|ContentCreator)$")]
    [Column(TypeName = "varchar(30)")]
    public string Role { get; set; } = null!; // Child, Parent, Admin, ContentCreator

    [Required]
    [StringLength(20)]
    [RegularExpression("^(Active|Locked|Inactive)$")]
    [Column(TypeName = "varchar(20)")]
    public string Status { get; set; } = "Active";

    public int? ParentId { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    [ForeignKey(nameof(ParentId))]
    public User? Parent { get; set; }

    public ICollection<User> Children { get; set; } = new List<User>();
    public ICollection<UserProgress> UserProgresses { get; set; } = new List<UserProgress>();
    public ICollection<UserAnswer> UserAnswers { get; set; } = new List<UserAnswer>();
    public ICollection<PremiumSubscription> PremiumSubscriptions { get; set; } =
        new List<PremiumSubscription>();
    public ICollection<PremiumPayment> PremiumPayments { get; set; } = new List<PremiumPayment>();
    public ICollection<PremiumCodeRedemption> PremiumCodeRedemptions { get; set; } =
        new List<PremiumCodeRedemption>();
    public ICollection<LearningReport> LearningReports { get; set; } = new List<LearningReport>();
    public ICollection<LessonRecommendation> LessonRecommendations { get; set; } =
        new List<LessonRecommendation>();
    public ICollection<SkillAssessment> SkillAssessments { get; set; } = new List<SkillAssessment>();
    public ICollection<AIAnalysisLog> AIAnalysisLogs { get; set; } = new List<AIAnalysisLog>();
}
