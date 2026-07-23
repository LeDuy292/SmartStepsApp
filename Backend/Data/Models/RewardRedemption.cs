using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("RewardRedemptions")]
public class RewardRedemption
{
    [Key]
    public int RedemptionId { get; set; }

    [Required]
    public int RewardId { get; set; }

    [Required]
    public int ChildId { get; set; }

    public int PointsSpent { get; set; }

    [Required]
    [StringLength(20)]
    public string Status { get; set; } = "Pending"; // Pending, Approved, Delivered, Cancelled

    public DateTime RedeemedAt { get; set; } = DateTime.UtcNow;

    public DateTime? ProcessedAt { get; set; }

    // Navigation properties
    [ForeignKey(nameof(RewardId))]
    public RewardItem? Reward { get; set; }

    [ForeignKey(nameof(ChildId))]
    public User? Child { get; set; }
}
