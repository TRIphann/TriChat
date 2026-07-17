namespace backend.settings;

public class MailgunSettings
{
    public string ApiKey { get; set; } = string.Empty;
    public string Domain { get; set; } = string.Empty;
    public string FromEmail { get; set; } = string.Empty;
    public string FromName { get; set; } = "TriChat";
    public string BaseUrl { get; set; } = "https://api.mailgun.net/v3";
}
