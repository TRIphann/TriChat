namespace backend.dtos.Request
{
    public class VerifyOtpRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Otp { get; set; } = string.Empty;
        public string? CachedOtp { get; set; } // OTP from generate response when Redis failed
    }
}
