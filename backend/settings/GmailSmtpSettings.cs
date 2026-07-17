namespace backend.settings;

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
