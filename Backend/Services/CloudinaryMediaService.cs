using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;
using SmartStepsServer.Options;

namespace SmartStepsServer.Services;

public sealed class CloudinaryMediaService : ICloudinaryMediaService
{
    private readonly HttpClient _httpClient;
    private readonly CloudinaryMediaOptions _options;

    public CloudinaryMediaService(
        HttpClient httpClient,
        IOptions<CloudinaryMediaOptions> options)
    {
        _httpClient = httpClient;
        _options = options.Value;
    }

    public Task<string> CreateSignedDownloadUrlAsync(
        string mediaReference,
        string resourceType,
        string defaultFormat,
        int expiresInSeconds,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();

        var asset = ResolveAssetReference(mediaReference, defaultFormat);
        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var expiresAt = DateTimeOffset.UtcNow.AddSeconds(expiresInSeconds).ToUnixTimeSeconds();

        var signedParameters = new SortedDictionary<string, string>(StringComparer.Ordinal)
        {
            ["expires_at"] = expiresAt.ToString(CultureInfo.InvariantCulture),
            ["format"] = asset.Format,
            ["public_id"] = asset.PublicId,
            ["timestamp"] = timestamp.ToString(CultureInfo.InvariantCulture)
        };

        var signature = CreateSignature(signedParameters, _options.ApiSecret);

        var builder = new UriBuilder("https", "api.cloudinary.com")
        {
            Path = $"/v1_1/{Uri.EscapeDataString(_options.CloudName)}/{Uri.EscapeDataString(resourceType)}/download",
            Query = string.Join(
                "&",
                signedParameters
                    .Append(new KeyValuePair<string, string>("api_key", _options.ApiKey))
                    .Append(new KeyValuePair<string, string>("signature", signature))
                    .Select(parameter =>
                        $"{Uri.EscapeDataString(parameter.Key)}={Uri.EscapeDataString(parameter.Value)}"))
        };

        return Task.FromResult(builder.Uri.ToString());
    }

    private static string CreateSignature(
        IReadOnlyDictionary<string, string> parameters,
        string apiSecret)
    {
        var payload = string.Join(
            "&",
            parameters.OrderBy(parameter => parameter.Key, StringComparer.Ordinal)
                .Select(parameter => $"{parameter.Key}={parameter.Value}"));

        var bytes = SHA1.HashData(Encoding.UTF8.GetBytes(payload + apiSecret));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }

    private static AssetReference ResolveAssetReference(string mediaReference, string defaultFormat)
    {
        var value = mediaReference.Trim();
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new CloudinaryMediaException("Cloudinary media reference cannot be empty.");
        }

        if (Uri.TryCreate(value, UriKind.Absolute, out var uri))
        {
            if (string.Equals(uri.Host, "api.cloudinary.com", StringComparison.OrdinalIgnoreCase))
            {
                return ResolveFromDownloadApiUrl(uri, defaultFormat);
            }

            if (string.Equals(uri.Host, "res.cloudinary.com", StringComparison.OrdinalIgnoreCase))
            {
                return ResolveFromDeliveryUrl(uri, defaultFormat);
            }
        }

        return ResolveFromRelativePath(value, defaultFormat);
    }

    private static AssetReference ResolveFromDownloadApiUrl(Uri uri, string defaultFormat)
    {
        var query = ParseQueryString(uri.Query);

        if (query.TryGetValue("public_id", out var publicId)
            && !string.IsNullOrWhiteSpace(publicId))
        {
            return new AssetReference(publicId, ResolveFormat(query.TryGetValue("format", out var format) ? format : null, defaultFormat));
        }

        return ResolveFromRelativePath(uri.AbsolutePath, defaultFormat);
    }

    private static AssetReference ResolveFromDeliveryUrl(Uri uri, string defaultFormat)
    {
        var segments = uri.AbsolutePath.Split('/', StringSplitOptions.RemoveEmptyEntries);
        if (segments.Length < 4)
        {
            return ResolveFromRelativePath(uri.AbsolutePath, defaultFormat);
        }

        var resourceTypeIndex = Array.FindIndex(segments, segment =>
            string.Equals(segment, "image", StringComparison.OrdinalIgnoreCase)
            || string.Equals(segment, "video", StringComparison.OrdinalIgnoreCase)
            || string.Equals(segment, "raw", StringComparison.OrdinalIgnoreCase));

        if (resourceTypeIndex < 0 || resourceTypeIndex + 2 >= segments.Length)
        {
            return ResolveFromRelativePath(uri.AbsolutePath, defaultFormat);
        }

        var publicIdSegments = segments.Skip(resourceTypeIndex + 3).ToArray();
        if (publicIdSegments.Length == 0)
        {
            return ResolveFromRelativePath(uri.AbsolutePath, defaultFormat);
        }

        return BuildAssetReferenceFromSegments(publicIdSegments, defaultFormat);
    }

    private static AssetReference ResolveFromRelativePath(string value, string defaultFormat)
    {
        var sanitizedValue = value
            .Split('?', '#')[0]
            .Replace('\\', '/')
            .Trim('/');

        if (string.IsNullOrWhiteSpace(sanitizedValue))
        {
            throw new CloudinaryMediaException("Cloudinary media reference cannot be empty.");
        }

        var segments = sanitizedValue.Split('/', StringSplitOptions.RemoveEmptyEntries);
        return BuildAssetReferenceFromSegments(segments, defaultFormat);
    }

    private static AssetReference BuildAssetReferenceFromSegments(
        IReadOnlyList<string> segments,
        string defaultFormat)
    {
        var publicIdSegments = segments.ToArray();
        var lastSegment = publicIdSegments[^1];
        var fileName = lastSegment;
        var format = defaultFormat;

        var extensionIndex = lastSegment.LastIndexOf('.');
        if (extensionIndex > 0 && extensionIndex < lastSegment.Length - 1)
        {
            format = lastSegment[(extensionIndex + 1)..];
            fileName = lastSegment[..extensionIndex];
        }

        publicIdSegments[^1] = fileName;
        var publicId = string.Join("/", publicIdSegments.Where(segment => !string.IsNullOrWhiteSpace(segment)));

        if (string.IsNullOrWhiteSpace(publicId))
        {
            throw new CloudinaryMediaException("Cloudinary media reference cannot be resolved to a public ID.");
        }

        return new AssetReference(publicId, ResolveFormat(format, defaultFormat));
    }

    private static string ResolveFormat(string? format, string defaultFormat)
    {
        var resolvedFormat = string.IsNullOrWhiteSpace(format) ? defaultFormat : format.Trim();

        if (string.IsNullOrWhiteSpace(resolvedFormat))
        {
            throw new CloudinaryMediaException("Cloudinary format cannot be empty.");
        }

        return resolvedFormat;
    }

    private static Dictionary<string, string> ParseQueryString(string query)
    {
        var results = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        if (string.IsNullOrWhiteSpace(query))
        {
            return results;
        }

        foreach (var part in query.TrimStart('?').Split('&', StringSplitOptions.RemoveEmptyEntries))
        {
            var separatorIndex = part.IndexOf('=');
            if (separatorIndex <= 0)
            {
                continue;
            }

            var key = Uri.UnescapeDataString(part[..separatorIndex]);
            var value = Uri.UnescapeDataString(part[(separatorIndex + 1)..]);
            if (!string.IsNullOrWhiteSpace(key))
            {
                results[key] = value;
            }
        }

        return results;
    }

    private sealed record AssetReference(string PublicId, string Format);
}
