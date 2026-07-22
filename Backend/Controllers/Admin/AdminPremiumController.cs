using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;

namespace SmartStepsServer.Controllers.Admin;

[ApiController]
[Authorize(Roles = "Admin")]
[Route("api/admin/premium")]
public sealed class AdminPremiumController(SmartStepsDbContext dbContext) : ControllerBase
{
    [HttpGet("payments")]
    public async Task<IActionResult> GetPayments(
        [FromQuery] string? status,
        [FromQuery] int? userId,
        CancellationToken cancellationToken)
    {
        var query = dbContext.PremiumPayments.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(status)) query = query.Where(item => item.Status == status);
        if (userId is not null) query = query.Where(item => item.UserId == userId);
        return Ok(await query.OrderByDescending(item => item.CreatedAt).Select(item => new
        {
            item.PaymentId, item.OrderCode, item.UserId, item.User.FullName, item.User.Email,
            item.PlanCode, item.Amount, item.Currency, item.Status, item.PaidAt,
            item.CreatedAt, item.UpdatedAt
        }).ToListAsync(cancellationToken));
    }

    [HttpGet("subscriptions")]
    public async Task<IActionResult> GetSubscriptions(CancellationToken cancellationToken) => Ok(
        await dbContext.PremiumSubscriptions.AsNoTracking()
            .OrderByDescending(item => item.CreatedAt)
            .Select(item => new
            {
                item.SubscriptionId, item.UserId, item.User.FullName, item.User.Email,
                item.PlanCode, item.Status, item.Source, item.StartedAt, item.ExpiresAt,
                item.PaymentId, item.CreatedAt
            }).ToListAsync(cancellationToken));

    [HttpPost("payments/{paymentId:int}/refund")]
    public async Task<IActionResult> MarkRefunded(int paymentId, CancellationToken cancellationToken)
    {
        var payment = await dbContext.PremiumPayments
            .Include(item => item.PremiumSubscriptions)
            .SingleOrDefaultAsync(item => item.PaymentId == paymentId, cancellationToken);
        if (payment is null) return NotFound();
        if (payment.Status == "Refunded") return Ok(new { payment.PaymentId, payment.Status });
        if (payment.Status != "Paid") return Conflict(new { message = "Chỉ giao dịch đã thanh toán mới có thể hoàn tiền." });

        var now = DateTime.UtcNow;
        payment.Status = "Refunded";
        payment.UpdatedAt = now;
        foreach (var subscription in payment.PremiumSubscriptions.Where(item => item.Status == "Active"))
        {
            subscription.Status = "Cancelled";
            subscription.UpdatedAt = now;
            subscription.ExpiresAt = now;
        }
        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(new { payment.PaymentId, payment.Status, RefundedAt = now });
    }
}
