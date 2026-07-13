namespace SmartStepsServer.Services;

public interface ICloudinaryMediaService
{
    Task<string> CreateSignedDownloadUrlAsync(
        string mediaReference,
        string resourceType,
        string defaultFormat,
        int expiresInSeconds,
        CancellationToken cancellationToken);
}
