using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("PremiumCodeRedemption")]
public class PremiumCodeRedemption
{
    [Key]
    public int RedemptionId { get; set; }

    public int UserId { get; set; }

    public int SubscriptionId { get; set; }

    [Required]
    [StringLength(50)]
    [Column(TypeName = "varchar(50)")]
    public string Code { get; set; } = null!;

    public DateTime RedeemedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    [ForeignKey(nameof(UserId))]
    public User User { get; set; } = null!;

    [ForeignKey(nameof(SubscriptionId))]
    public PremiumSubscription Subscription { get; set; } = null!;
}
