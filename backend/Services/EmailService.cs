using backend.Attributes;
using backend.settings;
using Microsoft.Extensions.Options;

namespace backend.Services;

/// <summary>
/// Sends OTP email via Gmail SMTP using an App Password.
/// Requires: GMAIL_SMTP__USERNAME and GMAIL_SMTP__PASSWORD on Render.
/// </summary>
[ScopedService]
public class EmailService
{
    private readonly GmailSmtpSettings _settings;
    private readonly ILogger<EmailService> _logger;

    public EmailService(
        IOptions<GmailSmtpSettings> settings,
        ILogger<EmailService> logger)
    {
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task<bool> SendOtpEmailAsync(string toEmail, string otp)
    {
        _logger.LogInformation(
            "Sending OTP via Gmail SMTP. To: {Email}, Username: {Username}",
            toEmail, _settings.Username);

        if (string.IsNullOrWhiteSpace(_settings.Username) ||
            string.IsNullOrWhiteSpace(_settings.Password))
        {
            _logger.LogError(
                "Gmail SMTP not configured. Set GMAIL_SMTP__USERNAME and " +
                "GMAIL_SMTP__PASSWORD on Render.");
            return false;
        }

        try
        {
            var from = string.IsNullOrWhiteSpace(_settings.FromEmail)
                ? _settings.Username
                : _settings.FromEmail;

            using var smtp = new System.Net.Mail.SmtpClient
            {
                Host = _settings.SmtpHost,
                Port = _settings.Port,
                EnableSsl = _settings.EnableSsl,
                DeliveryMethod = System.Net.Mail.SmtpDeliveryMethod.Network,
                Credentials = new System.Net.NetworkCredential(
                    _settings.Username,
                    _settings.Password),
                Timeout = 30000,
            };

            using var msg = new System.Net.Mail.MailMessage
            {
                From = new System.Net.Mail.MailAddress(from, _settings.FromName),
                Subject = "Your TriChat OTP Code",
                IsBodyHtml = true,
                Body = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <style>
        body {{ font-family: Arial, sans-serif; background-color: #1a1a2e; color: #ffffff; margin: 0; padding: 20px; }}
        .container {{ max-width: 500px; margin: 0 auto; background: #16213e; border-radius: 16px; padding: 30px; text-align: center; }}
        .otp {{ font-size: 36px; font-weight: bold; color: #e94560; letter-spacing: 8px; margin: 20px 0; }}
        .warning {{ color: #ffd700; font-size: 12px; margin-top: 20px; }}
        .brand {{ color: #e94560; font-weight: bold; }}
    </style>
</head>
<body>
    <div class='container'>
        <h2>Your <span class='brand'>TriChat</span> OTP Code</h2>
        <div class='otp'>{otp}</div>
        <p>This code expires in <strong>60 seconds</strong>.</p>
        <p class='warning'>Do not share this code with anyone!</p>
    </div>
</body>
</html>",
            };
            msg.To.Add(toEmail);

            await smtp.SendMailAsync(msg);

            _logger.LogInformation(
                "Gmail SMTP: OTP email sent to {Email}", toEmail);
            return true;
        }
        catch (System.Net.Mail.SmtpException ex)
        {
            _logger.LogError(ex,
                "Gmail SMTP failed for {Email}. Status: {StatusCode}, Message: {Message}",
                toEmail, ex.StatusCode, ex.Message);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Unexpected error sending OTP email via Gmail SMTP to {Email}", toEmail);
            return false;
        }
    }
}
