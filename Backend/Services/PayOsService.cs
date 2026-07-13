using System.Globalization;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;
using SmartStepsServer.Options;

namespace SmartStepsServer.Services;

public sealed class PayOsService : IPayOsService
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private readonly HttpClient _httpClient;
    private readonly PayOsOptions _options;
    private readonly ILogger<PayOsService> _logger;

    public PayOsService(
        HttpClient httpClient,
        IOptions<PayOsOptions> options,
        ILogger<PayOsService> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
    }

    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(_options.ClientId) &&
        !string.IsNullOrWhiteSpace(_options.ApiKey) &&
        !string.IsNullOrWhiteSpace(_options.ChecksumKey);

    public async Task<PayOsCreatePaymentResult> CreatePaymentLinkAsync(
        PayOsCreatePaymentRequest request,
        CancellationToken cancellationToken)
    {
        EnsureConfigured();

        var payload = new SortedDictionary<string, object?>
        {
            ["amount"] = request.Amount,
            ["cancelUrl"] = request.CancelUrl,
            ["description"] = request.Description,
            ["orderCode"] = request.OrderCode,
            ["returnUrl"] = request.ReturnUrl
        };

        if (request.ExpiredAt is not null)
        {
            payload["expiredAt"] = request.ExpiredAt.Value.ToUnixTimeSeconds();
        }

        payload["signature"] = CreateCreatePaymentSignature(request);

        using var httpRequest = CreateJsonRequest(
            HttpMethod.Post,
            "/v2/payment-requests",
            payload);

        using var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogWarning(
                "payOS create payment link failed with status {StatusCode}: {Body}",
                (int)response.StatusCode,
                body);
            throw new PayOsException("payOS could not create a payment link.");
        }

        using var document = JsonDocument.Parse(body);
        var root = document.RootElement;
        var code = GetString(root, "code");
        if (!string.Equals(code, "00", StringComparison.OrdinalIgnoreCase))
        {
            var description = GetString(root, "desc") ?? "Unknown payOS response.";
            _logger.LogWarning("payOS create payment link returned code {Code}: {Description}", code, description);
            throw new PayOsException(description);
        }

        var data = root.GetProperty("data");
        return new PayOsCreatePaymentResult(
            GetRequiredString(data, "paymentLinkId"),
            GetRequiredString(data, "checkoutUrl"),
            GetString(data, "qrCode"),
            GetString(data, "status") ?? "PENDING");
    }

    public async Task<PayOsPaymentInfo?> GetPaymentInfoAsync(
        long orderCode,
        CancellationToken cancellationToken)
    {
        EnsureConfigured();

        using var httpRequest = CreateJsonRequest(
            HttpMethod.Get,
            $"/v2/payment-requests/{orderCode.ToString(CultureInfo.InvariantCulture)}");

        using var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogWarning(
                "payOS payment lookup failed with status {StatusCode}: {Body}",
                (int)response.StatusCode,
                body);
            return null;
        }

        using var document = JsonDocument.Parse(body);
        var root = document.RootElement;
        if (!string.Equals(GetString(root, "code"), "00", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var data = root.GetProperty("data");
        return new PayOsPaymentInfo(
            GetInt64(data, "orderCode"),
            GetInt32(data, "amount"),
            GetString(data, "status") ?? string.Empty,
            GetString(data, "id"));
    }

    public bool VerifyPaymentWebhook(JsonElement data, string signature)
    {
        if (string.IsNullOrWhiteSpace(signature) || !IsConfigured)
        {
            return false;
        }

        var expectedSignature = CreateSignature(ConvertJsonObjectToSortedDictionary(data));
        return CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(expectedSignature.ToLowerInvariant()),
            Encoding.UTF8.GetBytes(signature.ToLowerInvariant()));
    }

    public async Task<PayOsWebhookConfirmationResult> ConfirmWebhookAsync(
        string webhookUrl,
        CancellationToken cancellationToken)
    {
        EnsureConfigured();

        using var httpRequest = CreateJsonRequest(
            HttpMethod.Post,
            "/confirm-webhook",
            new { webhookUrl });

        using var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogWarning(
                "payOS confirm webhook failed with status {StatusCode}: {Body}",
                (int)response.StatusCode,
                body);
            throw new PayOsException("payOS could not confirm the webhook URL.");
        }

        using var document = JsonDocument.Parse(body);
        var root = document.RootElement;
        if (!string.Equals(GetString(root, "code"), "00", StringComparison.OrdinalIgnoreCase))
        {
            throw new PayOsException(GetString(root, "desc") ?? "payOS webhook confirmation failed.");
        }

        var data = root.GetProperty("data");
        return new PayOsWebhookConfirmationResult(
            GetRequiredString(data, "webhookUrl"),
            GetString(data, "accountNumber"),
            GetString(data, "accountName"),
            GetString(data, "name"),
            GetString(data, "shortName"));
    }

    private HttpRequestMessage CreateJsonRequest(HttpMethod method, string path, object? body = null)
    {
        var baseUri = new Uri(_options.BaseUrl.TrimEnd('/') + "/");
        var request = new HttpRequestMessage(method, new Uri(baseUri, path.TrimStart('/')));
        request.Headers.Add("x-client-id", _options.ClientId);
        request.Headers.Add("x-api-key", _options.ApiKey);

        if (body is not null)
        {
            var json = JsonSerializer.Serialize(body, JsonOptions);
            request.Content = new StringContent(json, Encoding.UTF8, "application/json");
        }

        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        return request;
    }

    private void EnsureConfigured()
    {
        if (!IsConfigured)
        {
            throw new PayOsException("payOS is not configured. Set PayOS__ClientId, PayOS__ApiKey, and PayOS__ChecksumKey.");
        }
    }

    private string CreateSignature(IReadOnlyDictionary<string, object?> data)
    {
        var signatureData = string.Join(
            "&",
            data
                .Where(item => item.Key != "signature")
                .OrderBy(item => item.Key, StringComparer.Ordinal)
                .Select(item => $"{item.Key}={FormatSignatureValue(item.Value)}"));

        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(_options.ChecksumKey));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(signatureData));
        return Convert.ToHexString(hash).ToLowerInvariant();
    }

    private string CreateCreatePaymentSignature(PayOsCreatePaymentRequest request)
    {
        return CreateSignature(new SortedDictionary<string, object?>(StringComparer.Ordinal)
        {
            ["amount"] = request.Amount,
            ["cancelUrl"] = request.CancelUrl,
            ["description"] = request.Description,
            ["orderCode"] = request.OrderCode,
            ["returnUrl"] = request.ReturnUrl
        });
    }

    private static SortedDictionary<string, object?> ConvertJsonObjectToSortedDictionary(JsonElement element)
    {
        var result = new SortedDictionary<string, object?>(StringComparer.Ordinal);

        foreach (var property in element.EnumerateObject())
        {
            result[property.Name] = property.Value.ValueKind switch
            {
                JsonValueKind.Null or JsonValueKind.Undefined => null,
                JsonValueKind.Number when property.Value.TryGetInt64(out var longValue) => longValue,
                JsonValueKind.Number when property.Value.TryGetDouble(out var doubleValue) => doubleValue,
                JsonValueKind.True => true,
                JsonValueKind.False => false,
                JsonValueKind.String => property.Value.GetString(),
                _ => property.Value.Clone()
            };
        }

        return result;
    }

    private static string FormatSignatureValue(object? value)
    {
        return value switch
        {
            null => string.Empty,
            string stringValue when stringValue is "undefined" or "null" => string.Empty,
            string stringValue => stringValue,
            bool boolValue => boolValue ? "true" : "false",
            int intValue => intValue.ToString(CultureInfo.InvariantCulture),
            long longValue => longValue.ToString(CultureInfo.InvariantCulture),
            double doubleValue => doubleValue.ToString(CultureInfo.InvariantCulture),
            decimal decimalValue => decimalValue.ToString(CultureInfo.InvariantCulture),
            JsonElement jsonElement => FormatJsonElement(jsonElement),
            _ => Convert.ToString(value, CultureInfo.InvariantCulture) ?? string.Empty
        };
    }

    private static string FormatJsonElement(JsonElement element)
    {
        return element.ValueKind switch
        {
            JsonValueKind.Null or JsonValueKind.Undefined => string.Empty,
            JsonValueKind.String => element.GetString() ?? string.Empty,
            JsonValueKind.True => "true",
            JsonValueKind.False => "false",
            JsonValueKind.Number => element.GetRawText(),
            _ => JsonSerializer.Serialize(element, JsonOptions)
        };
    }

    private static string? GetString(JsonElement element, string propertyName)
    {
        return element.TryGetProperty(propertyName, out var property) && property.ValueKind == JsonValueKind.String
            ? property.GetString()
            : null;
    }

    private static string GetRequiredString(JsonElement element, string propertyName)
    {
        return GetString(element, propertyName)
            ?? throw new PayOsException($"payOS response is missing '{propertyName}'.");
    }

    private static long GetInt64(JsonElement element, string propertyName)
    {
        return element.TryGetProperty(propertyName, out var property) && property.TryGetInt64(out var value)
            ? value
            : 0;
    }

    private static int GetInt32(JsonElement element, string propertyName)
    {
        return element.TryGetProperty(propertyName, out var property) && property.TryGetInt32(out var value)
            ? value
            : 0;
    }
}
