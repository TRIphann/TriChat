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
        // Upstash Redis chỉ bật `IsConnected = true` SAU khi đã có ít nhất một
        // round-trip thành công. Trên Render free-tier, instance thường được
        // tái sử dụng nhưng multiplexer vẫn lazy-connect, nên kiểm tra
        // `IsConnected` TRƯỚC lần đầu sẽ luôn trả về `false` và ta bị INTERNAL_ERROR
        // dù server thực sự vẫn khả dụng. Vì vậy ta chỉ gọi trực tiếp
        // `_redis.GetDatabase()`; StackExchange.Redis tự auto-connect / reconnect.
        private readonly IConnectionMultiplexer _redis;
        private readonly EmailService _emailService;
        private readonly ILogger<OtpService> _logger;

        public OtpService(
            IConnectionMultiplexer redis,
            EmailService emailService,
            ILogger<OtpService> logger)
        {
            _redis = redis;
            _emailService = emailService;
            _logger = logger;
        }

        private IDatabase Db => _redis.GetDatabase();

        // Lệnh được phép tạm dừng tối đa ~8s để Upstash kịp khởi tạo kết nối
        // (cold start) — đồng thời retry khi gặp `RedisConnectionException`.
        private const int MaxAttempts = 3;
        private const int InitialBackoffMs = 600;

        public async Task<string> GenerateOtpAsync(string email)
        {
            // 6-digit OTP — dùng RandomNumberGenerator thay vì Random để tránh
            // duplicate khi gọi liên tục trong cùng millisecond.
            var otpBytes = new byte[4];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(otpBytes);
            }
            var otp = (BitConverter.ToUInt32(otpBytes, 0) % 900_000 + 100_000).ToString();
            var hashedOtp = HashOtp(otp);

            await ExecuteWithRetryAsync(
                $"otp:{email}",
                async () =>
                {
                    await Db.StringSetAsync(
                        $"otp:{email}",
                        hashedOtp,
                        TimeSpan.FromSeconds(60));
                },
                "OTP cache");

            var emailSent = await _emailService.SendOtpEmailAsync(email, otp);
            if (!emailSent)
            {
                // Dọn dẹp key đã lưu để user có thể retry ngay, tránh kẹt 60s
                try { await Db.KeyDeleteAsync($"otp:{email}"); } catch { }
                _logger.LogError("Email delivery failed for {Email}", email);
                throw new AppException(backend.Enums.ErrorCode.INTERNAL_ERROR);
            }

            return otp;
        }

        public async Task VerifyOtpAsync(string email, string otp)
        {
            var key = $"otp:{email}";
            string? storedHash = null;

            await ExecuteWithRetryAsync(
                key,
                async () =>
                {
                    var v = await Db.StringGetAsync(key);
                    storedHash = v.IsNullOrEmpty ? null : v.ToString();
                },
                "OTP lookup");

            if (storedHash is null)
                throw new AppException(backend.Enums.ErrorCode.INVALID_TOKEN);

            var inputHash = HashOtp(otp);

            if (storedHash != inputHash)
                throw new AppException(backend.Enums.ErrorCode.INVALID_TOKEN);

            try { await Db.KeyDeleteAsync(key); } catch { }
        }

        /// Retry logic cho Redis: chỉ retry với exception kết nối thoáng qua
        /// (RedisConnectionException, RedisTimeoutException, SocketException).
        /// Không retry với logic error khác để tránh nuốt bug.
        private async Task ExecuteWithRetryAsync(string key, Func<Task> op, string purpose)
        {
            Exception? last = null;
            for (var attempt = 1; attempt <= MaxAttempts; attempt++)
            {
                try
                {
                    await op();
                    if (attempt > 1)
                    {
                        _logger.LogInformation(
                            "Redis {Purpose} succeeded on attempt {Attempt}/{Max} for {Key}",
                            purpose, attempt, MaxAttempts, key);
                    }
                    return;
                }
                catch (Exception ex) when (IsTransient(ex) && attempt < MaxAttempts)
                {
                    last = ex;
                    var backoff = InitialBackoffMs * (int)Math.Pow(2, attempt - 1);
                    _logger.LogWarning(
                        ex,
                        "Redis {Purpose} transient error on attempt {Attempt}/{Max} for {Key}; retrying in {Backoff}ms",
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
                "Redis {Purpose} failed permanently for {Key} after {Max} attempts",
                purpose, key, MaxAttempts);
            throw new AppException(backend.Enums.ErrorCode.INTERNAL_ERROR);
        }

        private static bool IsTransient(Exception ex)
        {
            for (var e = ex; e != null; e = e.InnerException!)
            {
                if (e is RedisConnectionException
                    || e is RedisTimeoutException
                    || e is System.Net.Sockets.SocketException)
                {
                    return true;
                }
            }
            return false;
        }

        private string HashOtp(string otp)
        {
            using var sha = SHA256.Create();
            var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(otp));
            return Convert.ToBase64String(bytes);
        }
    }
}