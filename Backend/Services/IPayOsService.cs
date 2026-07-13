using System.Text.Json;

namespace SmartStepsServer.Services;

public interface IPayOsService
{
    bool IsConfigured { get; }

    Task<PayOsCreatePaymentResult> CreatePaymentLinkAsync(
        PayOsCreatePaymentRequest request,
        CancellationToken cancellationToken);

    Task<PayOsPaymentInfo?> GetPaymentInfoAsync(long orderCode, CancellationToken cancellationToken);

    bool VerifyPaymentWebhook(JsonElement data, string signature);

    Task<PayOsWebhookConfirmationResult> ConfirmWebhookAsync(
        string webhookUrl,
        CancellationToken cancellationToken);
}

public sealed record PayOsCreatePaymentRequest(
    long OrderCode,
    int Amount,
    string Description,
    string ReturnUrl,
    string CancelUrl,
    DateTimeOffset? ExpiredAt = null);

public sealed record PayOsCreatePaymentResult(
    string PaymentLinkId,
    string CheckoutUrl,
    string? QrCode,
    string Status);

public sealed record PayOsPaymentInfo(
    long OrderCode,
    int Amount,
    string Status,
    string? PaymentLinkId);

public sealed record PayOsWebhookConfirmationResult(
    string WebhookUrl,
    string? AccountNumber,
    string? AccountName,
    string? Name,
    string? ShortName);

public sealed class PayOsException : Exception
{
    public PayOsException(string message) : base(message)
    {
    }
}
