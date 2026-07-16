namespace backend.dtos.Response
{
    public class OtpResponse
    {
        public string? Otp { get; init; } // Returned only when Redis fails
        public string Email { get; init; } = string.Empty;
    }
}
