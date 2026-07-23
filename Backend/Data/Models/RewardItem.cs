using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("RewardItems")]
public class RewardItem
{
    [Key]
    public int RewardId { get; set; }

    public int? ParentId { get; set; } // Null if global system reward

    [Required]
    [StringLength(150)]
    public string Title { get; set; } = null!;

    [StringLength(500)]
    public string? Description { get; set; }

    public int CostPoints { get; set; } = 50;

    [Required]
    [StringLength(20)]
    public string RewardType { get; set; } = "Virtual"; // Virtual, Real

    [StringLength(500)]
    public string? IconUrl { get; set; }

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    [ForeignKey(nameof(ParentId))]
    public User? Parent { get; set; }

    public ICollection<RewardRedemption> Redemptions { get; set; } = new List<RewardRedemption>();
}
