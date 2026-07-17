using System.Net.Http.Headers;
using System.Text;
using backend.Attributes;
using backend.settings;
using Microsoft.Extensions.Options;

namespace backend.Services;

/// <summary>
/// Sends OTP email via Mailgun HTTP API.
/// Requires: MAILGUN_API_KEY and MAILGUN_DOMAIN on Render.
/// </summary>
[ScopedService]
public class EmailService
{
    private readonly MailgunSettings _settings;
    private readonly ILogger<EmailService> _logger;
    private readonly IHttpClientFactory _httpClientFactory;

    public EmailService(
        IOptions<MailgunSettings> settings,
        ILogger<EmailService> logger,
        IHttpClientFactory httpClientFactory)
    {
        _settings = settings.Value;
        _logger = logger;
        _httpClientFactory = httpClientFactory;
    }

    public async Task<bool> SendOtpEmailAsync(string toEmail, string otp)
    {
        _logger.LogInformation(
            "Sending OTP via Mailgun. To: {Email}, Domain: {Domain}",
            toEmail, _settings.Domain);

        if (string.IsNullOrWhiteSpace(_settings.ApiKey) ||
            string.IsNullOrWhiteSpace(_settings.Domain))
        {
            _logger.LogError(
                "Mailgun not configured. Set MAILGUN_API_KEY and MAILGUN_DOMAIN on Render.");
            return false;
        }

        var from = string.IsNullOrWhiteSpace(_settings.FromEmail)
            ? $"postmaster@{_settings.Domain}"
            : _settings.FromEmail;

        var htmlBody = $@"
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
</html>";

        try
        {
            var client = _httpClientFactory.CreateClient("mailgun");

            var content = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                { "from", $"{_settings.FromName} <{from}>" },
                { "to", toEmail },
                { "subject", "Your TriChat OTP Code" },
                { "html", htmlBody }
            });

            var credentials = Convert.ToBase64String(
                Encoding.UTF8.GetBytes($"api:{_settings.ApiKey}"));

            var request = new HttpRequestMessage(HttpMethod.Post,
                $"{_settings.BaseUrl}/{_settings.Domain}/messages")
            {
                Content = content
            };
            request.Headers.Authorization =
                new AuthenticationHeaderValue("Basic", credentials);

            var response = await client.SendAsync(request);
            var body = await response.Content.ReadAsStringAsync();

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation(
                    "Mailgun: OTP email sent to {Email}. Response: {Response}",
                    toEmail, body);
                return true;
            }

            _logger.LogError(
                "Mailgun API error. Status: {StatusCode}, Body: {Body}",
                response.StatusCode, body);
            return false;
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex,
                "Mailgun HTTP error sending OTP to {Email}", toEmail);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Unexpected error sending OTP via Mailgun to {Email}", toEmail);
            return false;
        }
    }
}
