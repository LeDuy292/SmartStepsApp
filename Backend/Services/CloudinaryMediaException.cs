namespace SmartStepsServer.Services;

public sealed class CloudinaryMediaException : Exception
{
    public CloudinaryMediaException(string message) : base(message)
    {
    }
}
