using System.Security.Cryptography;
using System.Text;
using backend.Attributes;
using backend.Exceptions;
using backend.Interfaces;

namespace backend.Services
{
    [ScopedService]
    public class OtpService
    {
        private readonly IKeyValueStore _kv;
        private readonly EmailService _emailService;
        private readonly ILogger<OtpService> _logger;

        public OtpService(
            IKeyValueStore kv,
            EmailService emailService,
            ILogger<OtpService> logger)
        {
            _kv = kv;
            _emailService = emailService;
            _logger = logger;
        }

        private const int MaxAttempts = 3;
        private const int InitialBackoffMs = 600;

        public async Task<(string Otp, bool EmailSent)> GenerateOtpAsync(string email)
        {
            var otpBytes = new byte[4];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(otpBytes);
            }
            var otp = (BitConverter.ToUInt32(otpBytes, 0) % 900_000 + 100_000).ToString();

            _logger.LogInformation(
                "Generated OTP for {Email}: {Otp} (expires in 60s)",
                email, otp);

            var hashedOtp = HashOtp(otp);
            var key = $"otp:{email}";

            try
            {
                await ExecuteWithRetryAsync(
                    key,
                    async () => await _kv.SetAsync(key, hashedOtp, TimeSpan.FromSeconds(60)),
                    "OTP cache");
                _logger.LogInformation("OTP cached successfully for {Email}", email);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to cache OTP for {Email} - continuing without cache", email);
            }

            var emailSent = await _emailService.SendOtpEmailAsync(email, otp);
            if (!emailSent)
            {
                _logger.LogWarning(
                    "Email delivery failed for {Email} - OTP will be returned in response. " +
                    "Check Resend config (ApiKey, From domain verification) on Render.",
                    email);
                try { await _kv.DeleteAsync(key); } catch { }
            }
            else
            {
                _logger.LogInformation("OTP email sent successfully to {Email}", email);
            }

            return (otp, emailSent);
        }

        public async Task<bool> VerifyOtpAsync(string email, string otp, string? cachedOtp = null)
        {
            var key = $"otp:{email}";
            string? storedHash = null;
            bool usedCachedOtp = false;

            try
            {
                await ExecuteWithRetryAsync(
                    key,
                    async () => { storedHash = await _kv.GetAsync(key); },
                    "OTP lookup");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to lookup OTP for {Email} - using cached OTP if provided", email);
            }

            // If no stored hash but we have cached OTP (from when Redis was down during generation)
            if (storedHash is null && !string.IsNullOrEmpty(cachedOtp))
            {
                storedHash = HashOtp(cachedOtp);
                usedCachedOtp = true;
            }

            if (storedHash is null)
            {
                _logger.LogWarning("OTP not found or expired for {Email}", email);
                throw new AppException(backend.Enums.ErrorCode.INVALID_TOKEN);
            }

            var inputHash = HashOtp(otp);

            if (storedHash != inputHash)
            {
                _logger.LogWarning("OTP mismatch for {Email}", email);
                throw new AppException(backend.Enums.ErrorCode.INVALID_TOKEN);
            }

            if (!usedCachedOtp)
            {
                try { await _kv.DeleteAsync(key); } catch { }
            }
            _logger.LogInformation("OTP verified successfully for {Email}", email);
            return true;
        }

        private async Task ExecuteWithRetryAsync(string key, Func<Task> op, string purpose)
        {
            Exception? last = null;
            for (var attempt = 1; attempt <= MaxAttempts; attempt++)
            {
                try
                {
                    await op();
                    return;
                }
                catch (Exception ex) when (attempt < MaxAttempts)
                {
                    last = ex;
                    var backoff = InitialBackoffMs * (int)Math.Pow(2, attempt - 1);
                    _logger.LogWarning(ex,
                        "KeyValueStore {Purpose} attempt {Attempt}/{Max} for {Key} failed; retrying in {Backoff}ms",
                        purpose, attempt, MaxAttempts, key, backoff);
                    await Task.Delay(backoff);
                }
                catch (Exception ex)
                {
                    last = ex;
                    break;
                }
            }

            _logger.LogError(last,
                "KeyValueStore {Purpose} permanently failed for {Key} after {Max} attempts",
                purpose, key, MaxAttempts);
            throw last ?? new Exception($"KeyValueStore {purpose} failed");
        }

        private string HashOtp(string otp)
        {
            using var sha = SHA256.Create();
            var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(otp));
            return Convert.ToBase64String(bytes);
        }
    }
}
