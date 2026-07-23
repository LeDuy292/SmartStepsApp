using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Data.DTOs;
using SmartStepsServer.Data.Models;

namespace SmartStepsServer.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/rewards")]
public sealed class RewardController(SmartStepsDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetRewards(
        [FromQuery] int? parentId,
        [FromQuery] int? childId,
        CancellationToken cancellationToken)
    {
        if (childId.HasValue)
        {
            parentId = await dbContext.Users
                .AsNoTracking()
                .Where(u => u.UserId == childId.Value && u.Role == "Child")
                .Select(u => u.ParentId)
                .FirstOrDefaultAsync(cancellationToken);
        }

        var rewards = await dbContext.RewardItems
            .AsNoTracking()
            .Where(r => r.IsActive && (r.ParentId == null || r.ParentId == parentId))
            .Select(r => new RewardResponseDto
            {
                RewardId = r.RewardId,
                ParentId = r.ParentId,
                Title = r.Title,
                Description = r.Description,
                CostPoints = r.CostPoints,
                RewardType = r.RewardType,
                IconUrl = r.IconUrl,
                IsActive = r.IsActive
            })
            .ToListAsync(cancellationToken);

        return Ok(rewards);
    }

    [HttpPost]
    public async Task<IActionResult> CreateReward([FromBody] CreateRewardDto dto, CancellationToken cancellationToken)
    {
        int? parentId = dto.ParentId;
        if (parentId.HasValue && parentId.Value > 0)
        {
            if (!await dbContext.Users.AnyAsync(u => u.UserId == parentId.Value, cancellationToken))
            {
                parentId = null;
            }
        }

        var reward = new RewardItem
        {
            ParentId = parentId,
            Title = dto.Title,
            Description = dto.Description,
            CostPoints = dto.CostPoints,
            RewardType = dto.RewardType,
            IconUrl = dto.IconUrl,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        dbContext.RewardItems.Add(reward);
        await dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new RewardResponseDto
        {
            RewardId = reward.RewardId,
            ParentId = reward.ParentId,
            Title = reward.Title,
            Description = reward.Description,
            CostPoints = reward.CostPoints,
            RewardType = reward.RewardType,
            IconUrl = reward.IconUrl,
            IsActive = reward.IsActive
        });
    }

    [HttpGet("redemptions")]
    public async Task<IActionResult> GetRedemptions([FromQuery] int? childId, CancellationToken cancellationToken)
    {
        var redemptions = await dbContext.RewardRedemptions
            .AsNoTracking()
            .Where(r => childId == null || r.ChildId == childId)
            .Include(r => r.Reward)
            .OrderByDescending(r => r.RedeemedAt)
            .Select(r => new RewardRedemptionDto
            {
                RedemptionId = r.RedemptionId,
                RewardId = r.RewardId,
                RewardTitle = r.Reward != null ? r.Reward.Title : "Phần thưởng",
                ChildId = r.ChildId,
                PointsSpent = r.PointsSpent,
                Status = r.Status,
                RedeemedAt = r.RedeemedAt
            })
            .ToListAsync(cancellationToken);

        return Ok(redemptions);
    }

    [HttpPost("{rewardId:int}/redeem")]
    public async Task<IActionResult> RedeemReward(int rewardId, [FromBody] RedeemRewardDto dto, CancellationToken cancellationToken)
    {
        var reward = await dbContext.RewardItems.FindAsync([rewardId], cancellationToken);
        if (reward == null || !reward.IsActive) return NotFound("Phần thưởng không khả dụng");

        var redemption = new RewardRedemption
        {
            RewardId = rewardId,
            ChildId = dto.ChildId,
            PointsSpent = reward.CostPoints,
            Status = "Pending",
            RedeemedAt = DateTime.UtcNow
        };

        dbContext.RewardRedemptions.Add(redemption);
        await dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new RewardRedemptionDto
        {
            RedemptionId = redemption.RedemptionId,
            RewardId = redemption.RewardId,
            RewardTitle = reward.Title,
            ChildId = redemption.ChildId,
            PointsSpent = redemption.PointsSpent,
            Status = redemption.Status,
            RedeemedAt = redemption.RedeemedAt
        });
    }

    [HttpPost("redemptions/{redemptionId:int}/approve")]
    public async Task<IActionResult> ApproveRedemption(int redemptionId, CancellationToken cancellationToken)
    {
        var redemption = await dbContext.RewardRedemptions.FindAsync([redemptionId], cancellationToken);
        if (redemption == null) return NotFound("Không tìm thấy thông tin đổi thưởng");

        redemption.Status = "Approved";
        redemption.ProcessedAt = DateTime.UtcNow;

        await dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new { Message = "Đã phê duyệt đổi quà thành công!" });
    }

    [HttpPost("redemptions/{redemptionId:int}/reject")]
    public async Task<IActionResult> RejectRedemption(int redemptionId, CancellationToken cancellationToken)
    {
        var redemption = await dbContext.RewardRedemptions.FindAsync([redemptionId], cancellationToken);
        if (redemption == null) return NotFound("Không tìm thấy thông tin đổi thưởng");

        redemption.Status = "Rejected";
        redemption.ProcessedAt = DateTime.UtcNow;

        await dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new { Message = "Đã từ chối yêu cầu đổi quà." });
    }
}
