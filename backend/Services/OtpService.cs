using System.Security.Cryptography;
using System.Text;
using StackExchange.Redis;
using backend.Attributes;
using backend.Exceptions;

namespace backend.Services
{
    [ScopedService]
    public class OtpService
    {
        private readonly IConnectionMultiplexer _redis;
        private readonly IDatabase _db;
        private readonly EmailService _emailService;
        private readonly ILogger<OtpService> _logger;

        public OtpService(
            IConnectionMultiplexer redis,
            EmailService emailService,
            ILogger<OtpService> logger)
        {
            _redis = redis;
            _db = redis.GetDatabase();
            _emailService = emailService;
            _logger = logger;
        }

        public async Task<string> GenerateOtpAsync(string email)
        {
            if (!_redis.IsConnected)
            {
                _logger.LogError("Redis is not connected; cannot generate OTP for {Email}", email);
                throw new AppException(backend.Enums.ErrorCode.INTERNAL_ERROR);
            }

            var otp = new Random().Next(100000, 999999).ToString();
            var hashedOtp = HashOtp(otp);

            try
            {
                await _db.StringSetAsync(
                    $"otp:{email}",
                    hashedOtp,
                    TimeSpan.FromSeconds(60));
            }
            catch (RedisException ex)
            {
                _logger.LogError(ex, "Redis SET failed while generating OTP for {Email}", email);
                throw new AppException(backend.Enums.ErrorCode.INTERNAL_ERROR);
            }

            var emailSent = await _emailService.SendOtpEmailAsync(email, otp);
            if (!emailSent)
            {
                // Dọn dẹp key đã lưu để user có thể retry ngay, tránh kẹt 60s
                try { await _db.KeyDeleteAsync($"otp:{email}"); } catch { }
                _logger.LogError("Email delivery failed for {Email}", email);
                throw new AppException(backend.Enums.ErrorCode.INTERNAL_ERROR);
            }

            return otp;
        }

        public async Task VerifyOtpAsync(string email, string otp)
        {
            if (!_redis.IsConnected)
                throw new AppException(backend.Enums.ErrorCode.INTERNAL_ERROR);

            var key = $"otp:{email}";
            var storedHash = await _db.StringGetAsync(key);

            if (storedHash.IsNullOrEmpty)
                throw new AppException(backend.Enums.ErrorCode.INVALID_TOKEN);

            var inputHash = HashOtp(otp);

            if (storedHash != inputHash)
                throw new AppException(backend.Enums.ErrorCode.INVALID_TOKEN);

            await _db.KeyDeleteAsync(key);
        }

        private string HashOtp(string otp)
        {
            using var sha = SHA256.Create();
            var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(otp));
            return Convert.ToBase64String(bytes);
        }
    }
}
