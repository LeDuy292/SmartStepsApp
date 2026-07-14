namespace SmartStepsServer.Options;

public sealed class DeepSeekOptions
{
    public const string SectionName = "DeepSeek";

    public string ApiKey { get; set; } = string.Empty;

    public string BaseUrl { get; set; } = "https://api.deepseek.com";

    public string Model { get; set; } = "deepseek-v4-flash";

    public int TimeoutSeconds { get; set; } = 30;

    public int MaxOutputTokens { get; set; } = 1200;
}
