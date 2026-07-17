namespace backend.settings;

/// <summary>
/// Gmail SMTP configuration for sending OTP emails.
/// Requires an App Password from Google Account → Security → App Passwords.
/// </summary>
public class GmailSmtpSettings
{
    public string SmtpHost { get; set; } = "smtp.gmail.com";
    public int Port { get; set; } = 587;
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string FromEmail { get; set; } = string.Empty;
    public string FromName { get; set; } = "TriChat";
    public bool EnableSsl { get; set; } = true;
}
