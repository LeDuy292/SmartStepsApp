using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SmartStepsServer.Data;
using SmartStepsServer.Data.Models;
using SmartStepsServer.Options;
using SmartStepsServer.Services;

namespace SmartStepsServer.Controllers;

[ApiController]
[Route("api/premium")]
public sealed class PremiumController : ControllerBase
{
    private const string MvpPremiumCode = "PREMIUM";
    private const string CodePlanCode = "MVP_PREMIUM_CODE";

    private static readonly IReadOnlyDictionary<string, PremiumPlanDefinition> Plans =
        new Dictionary<string, PremiumPlanDefinition>(StringComparer.OrdinalIgnoreCase)
        {
            ["PRO_MONTHLY"] = new(
                "PRO_MONTHLY",
                "PRO Monthly",
                "Unlock all premium lessons for one month.",
                199000,
                "VND",
                1,
                false),
            ["PRO_YEARLY"] = new(
                "PRO_YEARLY",
                "PRO Yearly",
                "Unlock all premium lessons for one year.",
                1299000,
                "VND",
                12,
                false),
            ["MAX_LIFETIME"] = new(
                "MAX_LIFETIME",
                "MAX Lifetime",
                "Lifetime SmartSteps premium access.",
                2999999,
                "VND",
                null,
                true)
        };

    private readonly SmartStepsDbContext _dbContext;
    private readonly IPayOsService _payOsService;
    private readonly PayOsOptions _payOsOptions;
    private readonly IWebHostEnvironment _environment;

    public PremiumController(
        SmartStepsDbContext dbContext,
        IPayOsService payOsService,
        IOptions<PayOsOptions> payOsOptions,
        IWebHostEnvironment environment)
    {
        _dbContext = dbContext;
        _payOsService = payOsService;
        _payOsOptions = payOsOptions.Value;
        _environment = environment;
    }

    [HttpGet("plans")]
    [ProducesResponseType(typeof(IReadOnlyList<PremiumPlanResponse>), StatusCodes.Status200OK)]
    public ActionResult<IReadOnlyList<PremiumPlanResponse>> GetPlans()
    {
        return Ok(Plans.Values.Select(PremiumPlanResponse.FromDefinition).ToList());
    }

    [HttpPost("account")]
    [Authorize]
    [ProducesResponseType(typeof(PremiumAccountResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PremiumAccountResponse>> EnsureAccount(
        PremiumAccountRequest request,
        CancellationToken cancellationToken)
    {
        if (!TryGetCurrentUserId(out var currentUserId))
        {
            return Forbid();
        }
        var user = await _dbContext.Users.SingleOrDefaultAsync(
            item => item.UserId == currentUserId,
            cancellationToken);
        if (user is null)
        {
            return NotFound(new { message = "Premium account was not found." });
        }
        if (!EmailMatchesUser(request.Email, user))
        {
            return Forbid();
        }

        return Ok(new PremiumAccountResponse(user.UserId, user.Email, user.FullName));
    }

    [HttpGet("status/{userId:int}")]
    [Authorize]
    [ProducesResponseType(typeof(PremiumStatusResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PremiumStatusResponse>> GetStatus(
        int userId,
        CancellationToken cancellationToken)
    {
        if (!CanAccessUser(userId))
        {
            return Forbid();
        }

        var userExists = await _dbContext.Users
            .AsNoTracking()
            .AnyAsync(user => user.UserId == userId, cancellationToken);

        if (!userExists)
        {
            return NotFound(new { message = "Premium account was not found." });
        }

        return Ok(await BuildStatusResponseAsync(userId, cancellationToken));
    }

    [HttpPost("redeem-code")]
    [Authorize]
    [ProducesResponseType(typeof(PremiumStatusResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<PremiumStatusResponse>> RedeemCode(
        RedeemPremiumCodeRequest request,
        CancellationToken cancellationToken)
    {
        if (!TryResolveRequestedUserId(request.UserId, out var targetUserId))
        {
            return Forbid();
        }
        var user = await _dbContext.Users.SingleOrDefaultAsync(
            item => item.UserId == targetUserId,
            cancellationToken);
        if (user is null)
        {
            return NotFound(new { message = "Premium account was not found." });
        }
        if (!EmailMatchesUser(request.Email, user))
        {
            return Forbid();
        }

        var normalizedCode = NormalizeCode(request.Code);

        if (!string.Equals(normalizedCode, MvpPremiumCode, StringComparison.Ordinal))
        {
            return BadRequest(new { message = "Invalid premium code." });
        }

        var alreadyRedeemed = await _dbContext.PremiumCodeRedemptions
            .AnyAsync(
                redemption => redemption.UserId == user.UserId && redemption.Code == normalizedCode,
                cancellationToken);

        if (alreadyRedeemed)
        {
            return Conflict(new { message = "This premium code was already used by this account." });
        }

        var now = DateTime.UtcNow;
        await ExpireSubscriptionsAsync(user.UserId, now, cancellationToken);
        var startBase = await GetExtensionBaseAsync(user.UserId, now, cancellationToken);
        var subscription = new PremiumSubscription
        {
            UserId = user.UserId,
            PlanCode = CodePlanCode,
            Status = "Active",
            Source = "Code",
            StartedAt = now,
            ExpiresAt = startBase.AddMonths(1),
            CreatedAt = now
        };

        _dbContext.PremiumSubscriptions.Add(subscription);
        _dbContext.PremiumCodeRedemptions.Add(new PremiumCodeRedemption
        {
            UserId = user.UserId,
            Code = normalizedCode,
            Subscription = subscription,
            RedeemedAt = now,
            CreatedAt = now
        });

        await _dbContext.SaveChangesAsync(cancellationToken);
        return Ok(await BuildStatusResponseAsync(user.UserId, cancellationToken));
    }

    [HttpPost("payments")]
    [Authorize]
    [ProducesResponseType(typeof(CreatePremiumPaymentResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<CreatePremiumPaymentResponse>> CreatePayment(
        CreatePremiumPaymentRequest request,
        CancellationToken cancellationToken)
    {
        if (!Plans.TryGetValue(request.PlanCode, out var plan))
        {
            return BadRequest(new { message = "Unknown premium plan." });
        }

        if (!TryResolveRequestedUserId(request.UserId, out var targetUserId))
        {
            return Forbid();
        }
        var user = await _dbContext.Users.SingleOrDefaultAsync(
            item => item.UserId == targetUserId,
            cancellationToken);
        if (user is null)
        {
            return NotFound(new { message = "Premium account was not found." });
        }
        if (!EmailMatchesUser(request.Email, user))
        {
            return Forbid();
        }

        var orderCode = await GenerateOrderCodeAsync(cancellationToken);
        var returnUrl = BuildRedirectUrl(
            request.ReturnUrl,
            _payOsOptions.ReturnUrl,
            orderCode,
            user.UserId);
        var cancelUrl = BuildRedirectUrl(
            request.CancelUrl,
            _payOsOptions.CancelUrl,
            orderCode,
            user.UserId);
        var description = $"SSPREM{orderCode % 10000000000L:D10}";
        var expiredAt = DateTimeOffset.UtcNow.AddMinutes(Math.Max(5, _payOsOptions.PaymentLinkTtlMinutes));

        if (!_payOsService.IsConfigured)
        {
            if (CanUseMockPayments())
            {
                return Ok(await CreateMockPaymentAsync(
                    user,
                    plan,
                    orderCode,
                    returnUrl,
                    cancelUrl,
                    description,
                    cancellationToken));
            }

            return StatusCode(
                StatusCodes.Status503ServiceUnavailable,
                new
                {
                    message = "payOS is not configured on SmartStepsServer. Set PayOS__ClientId, PayOS__ApiKey, and PayOS__ChecksumKey."
                });
        }

        PayOsCreatePaymentResult payOsResult;
        try
        {
            payOsResult = await _payOsService.CreatePaymentLinkAsync(
                new PayOsCreatePaymentRequest(
                    orderCode,
                    plan.Amount,
                    description,
                    returnUrl,
                    cancelUrl,
                    expiredAt),
                cancellationToken);
        }
        catch (PayOsException ex)
        {
            return StatusCode(StatusCodes.Status502BadGateway, new { message = ex.Message });
        }

        var now = DateTime.UtcNow;
        var payment = new PremiumPayment
        {
            UserId = user.UserId,
            PlanCode = plan.PlanCode,
            OrderCode = orderCode,
            Amount = plan.Amount,
            Currency = plan.Currency,
            Description = description,
            Status = "Pending",
            PaymentLinkId = payOsResult.PaymentLinkId,
            CheckoutUrl = payOsResult.CheckoutUrl,
            QrCode = payOsResult.QrCode,
            ReturnUrl = returnUrl,
            CancelUrl = cancelUrl,
            CreatedAt = now
        };

        _dbContext.PremiumPayments.Add(payment);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new CreatePremiumPaymentResponse(
            payment.PaymentId,
            payment.OrderCode,
            payment.PlanCode,
            payment.Amount,
            payment.Currency,
            payment.Status,
            payment.CheckoutUrl ?? string.Empty,
            payment.QrCode,
            payment.PaymentLinkId));
    }

    private async Task<CreatePremiumPaymentResponse> CreateMockPaymentAsync(
        User user,
        PremiumPlanDefinition plan,
        long orderCode,
        string returnUrl,
        string cancelUrl,
        string description,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var payment = new PremiumPayment
        {
            UserId = user.UserId,
            PlanCode = plan.PlanCode,
            OrderCode = orderCode,
            Amount = plan.Amount,
            Currency = plan.Currency,
            Description = description,
            Status = "Pending",
            PaymentLinkId = $"mock-{orderCode}",
            CheckoutUrl = returnUrl,
            ReturnUrl = returnUrl,
            CancelUrl = cancelUrl,
            CreatedAt = now
        };

        _dbContext.PremiumPayments.Add(payment);
        await _dbContext.SaveChangesAsync(cancellationToken);
        await ActivateSubscriptionFromPaymentAsync(payment, now, cancellationToken);

        return new CreatePremiumPaymentResponse(
            payment.PaymentId,
            payment.OrderCode,
            payment.PlanCode,
            payment.Amount,
            payment.Currency,
            payment.Status,
            payment.CheckoutUrl ?? returnUrl,
            payment.QrCode,
            payment.PaymentLinkId);
    }

    [HttpPost("payments/{orderCode:long}/confirm")]
    [Authorize]
    [ProducesResponseType(typeof(PremiumStatusResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PremiumStatusResponse>> ConfirmPayment(
        long orderCode,
        ConfirmPremiumPaymentRequest request,
        CancellationToken cancellationToken)
    {
        if (!TryGetCurrentUserId(out var currentUserId))
        {
            return Forbid();
        }
        var isAdmin = User.IsInRole("Admin");
        if (request.UserId is not null && request.UserId != currentUserId && !isAdmin)
        {
            return Forbid();
        }

        var payment = await _dbContext.PremiumPayments
            .SingleOrDefaultAsync(
                item => item.OrderCode == orderCode &&
                    (isAdmin || item.UserId == currentUserId) &&
                    (request.UserId == null || item.UserId == request.UserId.Value),
                cancellationToken);

        if (payment is null)
        {
            return NotFound(new { message = "Premium payment was not found." });
        }

        if (_payOsService.IsConfigured && payment.Status == "Pending")
        {
            var paymentInfo = await _payOsService.GetPaymentInfoAsync(orderCode, cancellationToken);
            if (paymentInfo is not null)
            {
                await ApplyPayOsStatusAsync(payment, paymentInfo.Status, DateTime.UtcNow, cancellationToken);
            }
        }

        return Ok(await BuildStatusResponseAsync(payment.UserId, cancellationToken));
    }

    [HttpPost("payos/webhook")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> HandlePayOsWebhook(
        PayOsWebhookRequest request,
        CancellationToken cancellationToken)
    {
        if (request.Data.ValueKind != JsonValueKind.Object ||
            string.IsNullOrWhiteSpace(request.Signature))
        {
            return BadRequest(new { message = "Invalid payOS webhook payload." });
        }

        if (!_payOsService.VerifyPaymentWebhook(request.Data, request.Signature))
        {
            return BadRequest(new { message = "Invalid payOS webhook signature." });
        }

        var orderCode = GetLong(request.Data, "orderCode");
        if (orderCode <= 0)
        {
            return Ok(new { received = true, matched = false });
        }

        var payment = await _dbContext.PremiumPayments
            .SingleOrDefaultAsync(item => item.OrderCode == orderCode, cancellationToken);

        if (payment is null)
        {
            return Ok(new { received = true, matched = false });
        }

        var amount = GetInt(request.Data, "amount");
        if (amount > 0 && amount != payment.Amount)
        {
            payment.Status = "Failed";
            payment.UpdatedAt = DateTime.UtcNow;
            await _dbContext.SaveChangesAsync(cancellationToken);
            return BadRequest(new { message = "payOS webhook amount does not match the payment." });
        }

        var status = GetString(request.Data, "status") ?? (request.Success ? "PAID" : "FAILED");
        await ApplyPayOsStatusAsync(payment, status, DateTime.UtcNow, cancellationToken);

        return Ok(new { received = true, matched = true });
    }

    [HttpPost("payos/confirm-webhook")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(typeof(PayOsWebhookConfirmationResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<PayOsWebhookConfirmationResult>> ConfirmPayOsWebhook(
        ConfirmPayOsWebhookRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.WebhookUrl))
        {
            return BadRequest(new { message = "WebhookUrl is required." });
        }

        if (!_payOsService.IsConfigured)
        {
            return StatusCode(
                StatusCodes.Status503ServiceUnavailable,
                new { message = "payOS is not configured on SmartStepsServer." });
        }

        try
        {
            return Ok(await _payOsService.ConfirmWebhookAsync(request.WebhookUrl, cancellationToken));
        }
        catch (PayOsException ex)
        {
            return StatusCode(StatusCodes.Status502BadGateway, new { message = ex.Message });
        }
    }

    private bool TryGetCurrentUserId(out int userId)
    {
        return int.TryParse(
            User.FindFirstValue("UserId") ?? User.FindFirstValue(ClaimTypes.NameIdentifier),
            out userId);
    }

    private bool CanAccessUser(int userId)
    {
        return TryGetCurrentUserId(out var currentUserId) &&
            (currentUserId == userId || User.IsInRole("Admin"));
    }

    private bool TryResolveRequestedUserId(int? requestedUserId, out int targetUserId)
    {
        targetUserId = 0;
        if (!TryGetCurrentUserId(out var currentUserId))
        {
            return false;
        }
        if (requestedUserId is not null && requestedUserId != currentUserId && !User.IsInRole("Admin"))
        {
            return false;
        }
        targetUserId = requestedUserId ?? currentUserId;
        return true;
    }

    private static bool EmailMatchesUser(string? requestedEmail, User user)
    {
        return string.IsNullOrWhiteSpace(requestedEmail) ||
            string.Equals(requestedEmail.Trim(), user.Email, StringComparison.OrdinalIgnoreCase);
    }

    private async Task<PremiumStatusResponse> BuildStatusResponseAsync(
        int userId,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        await ExpireSubscriptionsAsync(userId, now, cancellationToken);

        var activeSubscriptions = await _dbContext.PremiumSubscriptions
            .AsNoTracking()
            .Where(subscription =>
                subscription.UserId == userId &&
                subscription.Status == "Active" &&
                (subscription.ExpiresAt == null || subscription.ExpiresAt > now))
            .OrderByDescending(subscription => subscription.ExpiresAt == null)
            .ThenByDescending(subscription => subscription.ExpiresAt)
            .ToListAsync(cancellationToken);

        var activeSubscription = activeSubscriptions.FirstOrDefault();
        var canRedeemPremiumCode = !await _dbContext.PremiumCodeRedemptions
            .AsNoTracking()
            .AnyAsync(
                redemption => redemption.UserId == userId && redemption.Code == MvpPremiumCode,
                cancellationToken);

        return new PremiumStatusResponse(
            userId,
            activeSubscription is not null,
            activeSubscription?.PlanCode,
            activeSubscription?.Source,
            activeSubscription?.ExpiresAt,
            canRedeemPremiumCode,
            now);
    }

    private async Task ExpireSubscriptionsAsync(
        int userId,
        DateTime now,
        CancellationToken cancellationToken)
    {
        var expiredSubscriptions = await _dbContext.PremiumSubscriptions
            .Where(subscription =>
                subscription.UserId == userId &&
                subscription.Status == "Active" &&
                subscription.ExpiresAt != null &&
                subscription.ExpiresAt <= now)
            .ToListAsync(cancellationToken);

        if (expiredSubscriptions.Count == 0)
        {
            return;
        }

        foreach (var subscription in expiredSubscriptions)
        {
            subscription.Status = "Expired";
            subscription.UpdatedAt = now;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<DateTime> GetExtensionBaseAsync(
        int userId,
        DateTime now,
        CancellationToken cancellationToken)
    {
        var activeUntil = await _dbContext.PremiumSubscriptions
            .AsNoTracking()
            .Where(subscription =>
                subscription.UserId == userId &&
                subscription.Status == "Active" &&
                subscription.ExpiresAt != null &&
                subscription.ExpiresAt > now)
            .MaxAsync(subscription => (DateTime?)subscription.ExpiresAt, cancellationToken);

        return activeUntil is not null && activeUntil > now ? activeUntil.Value : now;
    }

    private async Task ApplyPayOsStatusAsync(
        PremiumPayment payment,
        string status,
        DateTime now,
        CancellationToken cancellationToken)
    {
        if (IsPaidStatus(status))
        {
            await ActivateSubscriptionFromPaymentAsync(payment, now, cancellationToken);
            return;
        }

        if (IsCancelledStatus(status))
        {
            payment.Status = "Cancelled";
            payment.UpdatedAt = now;
        }
        else if (IsExpiredStatus(status))
        {
            payment.Status = "Expired";
            payment.UpdatedAt = now;
        }
        else if (IsFailedStatus(status))
        {
            payment.Status = "Failed";
            payment.UpdatedAt = now;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task ActivateSubscriptionFromPaymentAsync(
        PremiumPayment payment,
        DateTime now,
        CancellationToken cancellationToken)
    {
        if (!Plans.TryGetValue(payment.PlanCode, out var plan))
        {
            payment.Status = "Failed";
            payment.UpdatedAt = now;
            await _dbContext.SaveChangesAsync(cancellationToken);
            return;
        }

        var alreadyActivated = await _dbContext.PremiumSubscriptions
            .AnyAsync(subscription => subscription.PaymentId == payment.PaymentId, cancellationToken);

        if (alreadyActivated)
        {
            payment.Status = "Paid";
            payment.PaidAt ??= now;
            payment.UpdatedAt = now;
            await _dbContext.SaveChangesAsync(cancellationToken);
            return;
        }

        await ExpireSubscriptionsAsync(payment.UserId, now, cancellationToken);
        var expiresAt = plan.IsLifetime
            ? null
            : (DateTime?)((await GetExtensionBaseAsync(payment.UserId, now, cancellationToken))
                .AddMonths(plan.DurationMonths ?? 1));

        payment.Status = "Paid";
        payment.PaidAt ??= now;
        payment.UpdatedAt = now;
        _dbContext.PremiumSubscriptions.Add(new PremiumSubscription
        {
            UserId = payment.UserId,
            PlanCode = payment.PlanCode,
            Status = "Active",
            Source = "Payment",
            PaymentId = payment.PaymentId,
            StartedAt = now,
            ExpiresAt = expiresAt,
            CreatedAt = now
        });

        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<long> GenerateOrderCodeAsync(CancellationToken cancellationToken)
    {
        for (var attempt = 0; attempt < 5; attempt++)
        {
            var orderCode = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000L +
                Random.Shared.Next(100, 999);
            var exists = await _dbContext.PremiumPayments
                .AnyAsync(payment => payment.OrderCode == orderCode, cancellationToken);

            if (!exists)
            {
                return orderCode;
            }
        }

        throw new InvalidOperationException("Could not generate a unique payOS order code.");
    }

    private bool CanUseMockPayments()
    {
        return _environment.IsDevelopment() && _payOsOptions.AllowMockPaymentsWhenUnconfigured;
    }

    private static string NormalizeCode(string? code)
    {
        return code?.Trim().ToUpperInvariant() ?? string.Empty;
    }

    private static string BuildRedirectUrl(
        string? requestedUrl,
        string fallbackUrl,
        long orderCode,
        int userId)
    {
        var baseUrl = string.IsNullOrWhiteSpace(requestedUrl) ? fallbackUrl : requestedUrl.Trim();
        var separator = baseUrl.Contains('?', StringComparison.Ordinal) ? "&" : "?";
        return $"{baseUrl}{separator}orderCode={orderCode}&premiumUserId={userId}";
    }

    private static bool IsPaidStatus(string status)
    {
        return string.Equals(status, "PAID", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(status, "Paid", StringComparison.OrdinalIgnoreCase);
    }

    private static bool IsCancelledStatus(string status)
    {
        return string.Equals(status, "CANCELLED", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(status, "CANCELED", StringComparison.OrdinalIgnoreCase);
    }

    private static bool IsExpiredStatus(string status)
    {
        return string.Equals(status, "EXPIRED", StringComparison.OrdinalIgnoreCase);
    }

    private static bool IsFailedStatus(string status)
    {
        return string.Equals(status, "FAILED", StringComparison.OrdinalIgnoreCase);
    }

    private static string? GetString(JsonElement element, string propertyName)
    {
        return element.TryGetProperty(propertyName, out var property) && property.ValueKind == JsonValueKind.String
            ? property.GetString()
            : null;
    }

    private static long GetLong(JsonElement element, string propertyName)
    {
        return element.TryGetProperty(propertyName, out var property) && property.TryGetInt64(out var value)
            ? value
            : 0;
    }

    private static int GetInt(JsonElement element, string propertyName)
    {
        return element.TryGetProperty(propertyName, out var property) && property.TryGetInt32(out var value)
            ? value
            : 0;
    }
}

public sealed record PremiumPlanResponse(
    string PlanCode,
    string Name,
    string Description,
    int Amount,
    string Currency,
    int? DurationMonths,
    bool IsLifetime)
{
    public static PremiumPlanResponse FromDefinition(PremiumPlanDefinition definition)
    {
        return new PremiumPlanResponse(
            definition.PlanCode,
            definition.Name,
            definition.Description,
            definition.Amount,
            definition.Currency,
            definition.DurationMonths,
            definition.IsLifetime);
    }
}

public sealed record PremiumAccountRequest(
    string? Email,
    string? FullName);

public sealed record PremiumAccountResponse(
    int UserId,
    string Email,
    string FullName);

public sealed record PremiumStatusResponse(
    int UserId,
    bool HasPremium,
    string? PlanCode,
    string? Source,
    DateTime? ActiveUntil,
    bool CanRedeemPremiumCode,
    DateTime ServerTime);

public sealed record RedeemPremiumCodeRequest(
    int? UserId,
    string? Email,
    string? FullName,
    string? Code);

public sealed record CreatePremiumPaymentRequest(
    int? UserId,
    string? Email,
    string? FullName,
    string PlanCode,
    string? ReturnUrl,
    string? CancelUrl);

public sealed record CreatePremiumPaymentResponse(
    int PaymentId,
    long OrderCode,
    string PlanCode,
    int Amount,
    string Currency,
    string Status,
    string CheckoutUrl,
    string? QrCode,
    string? PaymentLinkId);

public sealed record ConfirmPremiumPaymentRequest(int? UserId);

public sealed record ConfirmPayOsWebhookRequest(string? WebhookUrl);

public sealed record PayOsWebhookRequest(
    string? Code,
    string? Desc,
    bool Success,
    JsonElement Data,
    string? Signature);

public sealed record PremiumPlanDefinition(
    string PlanCode,
    string Name,
    string Description,
    int Amount,
    string Currency,
    int? DurationMonths,
    bool IsLifetime);
