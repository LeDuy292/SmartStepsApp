using System.ComponentModel.DataAnnotations;

namespace SmartStepsServer.Data.DTOs;

public class CreateRewardDto
{
    public int? ParentId { get; set; }

    [Required]
    [StringLength(150)]
    public string Title { get; set; } = null!;

    [StringLength(500)]
    public string? Description { get; set; }

    public int CostPoints { get; set; } = 50;

    [Required]
    public string RewardType { get; set; } = "Virtual"; // Virtual, Real

    public string? IconUrl { get; set; }
}

public class RedeemRewardDto
{
    [Required]
    public int ChildId { get; set; }
}

public class RewardResponseDto
{
    public int RewardId { get; set; }
    public int? ParentId { get; set; }
    public string Title { get; set; } = null!;
    public string? Description { get; set; }
    public int CostPoints { get; set; }
    public string RewardType { get; set; } = null!;
    public string? IconUrl { get; set; }
    public bool IsActive { get; set; }
}

public class RewardRedemptionDto
{
    public int RedemptionId { get; set; }
    public int RewardId { get; set; }
    public string RewardTitle { get; set; } = null!;
    public int ChildId { get; set; }
    public int PointsSpent { get; set; }
    public string Status { get; set; } = null!;
    public DateTime RedeemedAt { get; set; }
}
