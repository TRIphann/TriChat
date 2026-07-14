namespace backend.settings;

public class ResendSettings
{
    /// <summary>
    /// Resend API key (format: re_xxxxxxxxxxxxxxxxxxxx).
    /// Get one at https://resend.com/api-keys.
    /// </summary>
    public string ApiKey { get; set; } = string.Empty;

    /// <summary>
    /// Verified sender. Resend requires every "from" address to be on a verified domain
    /// (or use the onboarding@resend.dev shared address during local sandbox).
    /// </summary>
    public string From { get; set; } = string.Empty;

    /// <summary>
    /// Optional display name. Falls back to <see cref="From"/> when empty.
    /// </summary>
    public string FromName { get; set; } = "TriChat";
}
