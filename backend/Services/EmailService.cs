using System.Net;
using System.Net.Mail;
using backend.Attributes;

namespace backend.Services
{
    [ScopedService]
    public class EmailService(IConfiguration configuration, ILogger<EmailService> logger)
    {
        // 3 attempts total. Keep worst-case wall time under ~45s so it fits inside
        // the mobile/web Dio default timeout (60s) with margin for cold-start.
        private const int MaxAttempts = 3;
        private const int InitialBackoffMs = 1000;

        public async Task<bool> SendOtpEmailAsync(string toEmail, string otp)
        {
            var host = configuration["Email:SmtpHost"];
            var port = configuration["Email:Port"];
            var username = configuration["Email:Username"];
            var password = configuration["Email:Password"];

            if (string.IsNullOrEmpty(host) ||
                string.IsNullOrEmpty(port) ||
                string.IsNullOrEmpty(username) ||
                string.IsNullOrEmpty(password))
            {
                logger.LogError("Email config missing — check Email:SmtpHost/Port/Username/Password env vars.");
                return false;
            }

            // Retry tăng dần backoff (1s, 2s) — KHÔNG đệ quy để tránh stack
            // overflow nếu SMTP server liên tục từ chối.
            for (var attempt = 1; attempt <= MaxAttempts; attempt++)
            {
                try
                {
                    var mail = new MailMessage
                    {
                        From = new MailAddress(username, "TriChat"),
                        Subject = "Your TriChat OTP Code",
                        Body = $"""
                        Your TriChat OTP code is: {otp}

                        This code will expire in 60 seconds.
                        Do not share this code with anyone.
                        """,
                        IsBodyHtml = false,
                    };
                    mail.To.Add(toEmail);

                    using var smtp = new SmtpClient(host)
                    {
                        Port = int.Parse(port),
                        Credentials = new NetworkCredential(username, password),
                        EnableSsl = true,
                        // 15s là đủ cho hầu hết SMTP server; Raise từ 10s vì
                        // Render network đôi khi cold-start chậm.
                        Timeout = 15_000,
                        DeliveryMethod = SmtpDeliveryMethod.Network,
                        UseDefaultCredentials = false,
                    };

                    await smtp.SendMailAsync(mail);
                    logger.LogInformation(
                        "OTP email sent to {Email} on attempt {Attempt}/{Max}",
                        toEmail, attempt, MaxAttempts);
                    return true;
                }
                catch (Exception ex) when (attempt < MaxAttempts)
                {
                    var backoff = InitialBackoffMs * (int)Math.Pow(2, attempt - 1);
                    logger.LogWarning(
                        ex,
                        "SMTP attempt {Attempt}/{Max} failed for {Email}; retrying in {Backoff}ms",
                        attempt, MaxAttempts, toEmail, backoff);
                    await Task.Delay(backoff);
                }
                catch (Exception ex)
                {
                    logger.LogError(ex,
                        "SMTP delivery failed permanently for {Email} after {Max} attempts",
                        toEmail, MaxAttempts);
                    return false;
                }
            }

            return false;
        }
    }
}
