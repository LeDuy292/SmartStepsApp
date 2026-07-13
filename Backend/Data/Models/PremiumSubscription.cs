using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("PremiumSubscription")]
public class PremiumSubscription
{
    [Key]
    public int SubscriptionId { get; set; }

    public int UserId { get; set; }

    [Required]
    [StringLength(50)]
    [Column(TypeName = "varchar(50)")]
    public string PlanCode { get; set; } = null!;

    [Required]
    [StringLength(30)]
    [Column(TypeName = "varchar(30)")]
    public string Status { get; set; } = null!;

    [Required]
    [StringLength(30)]
    [Column(TypeName = "varchar(30)")]
    public string Source { get; set; } = null!;

    public int? PaymentId { get; set; }

    public DateTime StartedAt { get; set; }

    public DateTime? ExpiresAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    [ForeignKey(nameof(UserId))]
    public User User { get; set; } = null!;

    [ForeignKey(nameof(PaymentId))]
    public PremiumPayment? Payment { get; set; }

    public ICollection<PremiumCodeRedemption> CodeRedemptions { get; set; } =
        new List<PremiumCodeRedemption>();
}
