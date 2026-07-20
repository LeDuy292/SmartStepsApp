using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Configuration;
using MimeKit;
using System.Threading.Tasks;

namespace SmartStepsServer.Services
{
    public interface IEmailService
    {
        Task SendEmailAsync(string toEmail, string subject, string body);
    }

    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;

        public EmailService(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public async Task SendEmailAsync(string toEmail, string subject, string body)
        {
            var emailSettings = _configuration.GetSection("EmailSettings");
            var from = RequiredSetting(emailSettings, "From");
            var password = RequiredSetting(emailSettings, "Password");
            var host = RequiredSetting(emailSettings, "Host");
            var portValue = RequiredSetting(emailSettings, "Port");
            if (!int.TryParse(portValue, out var port) || port is < 1 or > 65535)
            {
                throw new InvalidOperationException("EmailSettings:Port must be a valid TCP port.");
            }

            var email = new MimeMessage();
            email.Sender = MailboxAddress.Parse(from);
            email.To.Add(MailboxAddress.Parse(toEmail));
            email.Subject = subject;

            var builder = new BodyBuilder { HtmlBody = body };
            email.Body = builder.ToMessageBody();

            using var smtp = new SmtpClient();
            await smtp.ConnectAsync(host, port, SecureSocketOptions.StartTls);
            await smtp.AuthenticateAsync(from, password);
            await smtp.SendAsync(email);
            await smtp.DisconnectAsync(true);
        }

        private static string RequiredSetting(IConfigurationSection section, string key)
        {
            var value = section[key]?.Trim();
            return string.IsNullOrWhiteSpace(value)
                ? throw new InvalidOperationException($"EmailSettings:{key} is required to send email.")
                : value;
        }
    }
}
