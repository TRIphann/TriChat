using System.Net.Http.Json;
using System.Text.Json.Serialization;
using backend.Attributes;
using backend.settings;
using Microsoft.Extensions.Options;

namespace backend.Services
{
    /// <summary>
    /// Sends OTP / transactional email via the Resend HTTPS API.
    ///
    /// Why Resend and not raw SMTP (System.Net.Mail.SmtpClient)?
    /// Render's free tier blocks outbound TCP 25/465/587 (email egress) at the
    /// network layer — see https://render.com/docs/smtp. Restarts / repacking
    /// the Docker image does NOT lift this restriction. Resend exposes its API
    /// over HTTPS on port 443, which Render always allows.
    ///
    /// The public surface used by callers (<see cref="SendOtpEmailAsync"/>) is
    /// unchanged so <c>OtpService</c> doesn't need touching.
    /// </summary>
    [ScopedService]
    public class EmailService
    {
        private const int MaxAttempts = 3;
        private const int InitialBackoffMs = 1000;

        private readonly IHttpClientFactory _httpFactory;
        private readonly ResendSettings _settings;
        private readonly ILogger<EmailService> _logger;

        public EmailService(
            IHttpClientFactory httpFactory,
            IOptions<ResendSettings> settings,
            ILogger<EmailService> logger)
        {
            _httpFactory = httpFactory;
            _settings = settings.Value;
            _logger = logger;
        }

        public async Task<bool> SendOtpEmailAsync(string toEmail, string otp)
        {
            if (string.IsNullOrWhiteSpace(_settings.ApiKey) ||
                string.IsNullOrWhiteSpace(_settings.From))
            {
                _logger.LogError(
                    "Resend config missing — check Resend__ApiKey / Resend__From env vars.");
                return false;
            }

            var body = new ResendEmailRequest
            {
                From = $"{_settings.FromName} <{_settings.From}>",
                To = new[] { toEmail },
                Subject = "Your TriChat OTP Code",
                Text = $"""
                    Your TriChat OTP code is: {otp}

                    This code will expire in 60 seconds.
                    Do not share this code with anyone.
                    """,
            };

            for (var attempt = 1; attempt <= MaxAttempts; attempt++)
            {
                try
                {
                    var http = _httpFactory.CreateClient("resend");
                    using var req = new HttpRequestMessage(HttpMethod.Post, "/emails")
                    {
                        Content = JsonContent.Create(body),
                    };
                    req.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue(
                        "Bearer", _settings.ApiKey);

                    using var resp = await http.SendAsync(req);

                    if (resp.IsSuccessStatusCode)
                    {
                        _logger.LogInformation(
                            "OTP email sent to {Email} on attempt {Attempt}/{Max}",
                            toEmail, attempt, MaxAttempts);
                        return true;
                    }

                    var errBody = await resp.Content.ReadAsStringAsync();
                    // 4xx -> do not retry (config / auth / validation problem).
                    if ((int)resp.StatusCode >= 400 && (int)resp.StatusCode < 500)
                    {
                        _logger.LogError(
                            "Resend rejected request for {Email} with {Status}: {Body}",
                            toEmail, (int)resp.StatusCode, errBody);
                        return false;
                    }

                    throw new HttpRequestException(
                        $"Resend {(int)resp.StatusCode}: {errBody}");
                }
                catch (Exception ex) when (attempt < MaxAttempts)
                {
                    var backoff = InitialBackoffMs * (int)Math.Pow(2, attempt - 1);
                    _logger.LogWarning(
                        ex,
                        "Resend attempt {Attempt}/{Max} failed for {Email}; retrying in {Backoff}ms",
                        attempt, MaxAttempts, toEmail, backoff);
                    await Task.Delay(backoff);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex,
                        "Resend delivery failed permanently for {Email} after {Max} attempts",
                        toEmail, MaxAttempts);
                    return false;
                }
            }

            return false;
        }

        private sealed class ResendEmailRequest
        {
            [JsonPropertyName("from")]
            public string From { get; set; } = string.Empty;

            [JsonPropertyName("to")]
            public string[] To { get; set; } = Array.Empty<string>();

            [JsonPropertyName("subject")]
            public string Subject { get; set; } = string.Empty;

            [JsonPropertyName("text")]
            public string Text { get; set; } = string.Empty;
        }
    }
}
