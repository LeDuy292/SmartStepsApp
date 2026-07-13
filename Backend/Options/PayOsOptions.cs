namespace SmartStepsServer.Options;

public sealed class PayOsOptions
{
    public const string SectionName = "PayOS";

    public string ClientId { get; set; } = string.Empty;

    public string ApiKey { get; set; } = string.Empty;

    public string ChecksumKey { get; set; } = string.Empty;

    public string BaseUrl { get; set; } = "https://api-merchant.payos.vn";

    public string ReturnUrl { get; set; } = "http://localhost:3000/learning?premiumPayment=success";

    public string CancelUrl { get; set; } = "http://localhost:3000/learning?premiumPayment=cancel";

    public int PaymentLinkTtlMinutes { get; set; } = 30;

    public bool AllowMockPaymentsWhenUnconfigured { get; set; } = true;
}
