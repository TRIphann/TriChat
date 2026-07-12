using StackExchange.Redis;
using backend.Attributes;

namespace backend.Services
{
    [ScopedService]
    public class RedisService
    {
        private const string OnlineKeyPrefix = "online:";
        private const string LastSeenKeyPrefix = "last_seen:";
        private static readonly TimeSpan OnlineTtl = TimeSpan.FromMinutes(5);

        private readonly IConnectionMultiplexer _redis;

        public RedisService(IConnectionMultiplexer redis)
        {
            _redis = redis;
        }

        // NOTE: KHÔNG gate theo `_redis.IsConnected` nữa. StackExchange.Redis
        // với `AbortOnConnectFail = false` sẽ lazy-connect + tự reconnect;
        // cờ `IsConnected` chỉ flip `true` SAU khi có round-trip thành công,
        // nên check trước sẽ luôn trả về `false` trên cold connection — đó
        // chính là nguyên nhân gốc khiến OTP / heartbeat đầu tiên luôn fail.
        // Bây giờ ta chỉ cần gọi trực tiếp; các hàm `*OrNull` đã được wrap
        // với try/catch để tránh nuốt exception vĩnh viễn.
        private IDatabase Db => _redis.GetDatabase();

        // ── Generic ────────────────────────────────────────────

        public async Task<string?> GetAsync(string key)
        {
            try
            {
                var v = await Db.StringGetAsync(key);
                return v.IsNullOrEmpty ? null : v.ToString();
            }
            catch (Exception ex) when (IsTransient(ex))
            {
                // Caller đã có fallback; để chuỗi "best-effort" cho online status
                return null;
            }
        }

        public async Task SetAsync(string key, string value, TimeSpan expiry)
        {
            try { await Db.StringSetAsync(key, value, expiry); }
            catch (Exception ex) when (IsTransient(ex)) { /* best-effort */ }
        }

        public async Task DeleteAsync(string key)
        {
            try { await Db.KeyDeleteAsync(key); }
            catch (Exception ex) when (IsTransient(ex)) { /* best-effort */ }
        }

        public async Task<bool> KeyExistsAsync(string key)
        {
            try { return await Db.KeyExistsAsync(key); }
            catch (Exception ex) when (IsTransient(ex)) { return false; }
        }

        // ── Online status ───────────────────────────────────────

        public async Task SetOnlineAsync(string userId)
        {
            try { await Db.StringSetAsync($"{OnlineKeyPrefix}{userId}", "1", OnlineTtl); }
            catch (Exception ex) when (IsTransient(ex)) { /* best-effort */ }
        }

        public async Task RefreshOnlineTtlAsync(string userId)
        {
            try { await Db.KeyExpireAsync($"{OnlineKeyPrefix}{userId}", OnlineTtl); }
            catch (Exception ex) when (IsTransient(ex)) { /* best-effort */ }
        }

        public async Task SetOfflineAsync(string userId)
        {
            try
            {
                await Db.StringSetAsync($"{LastSeenKeyPrefix}{userId}", DateTime.UtcNow.ToString("O"));
                await Db.KeyDeleteAsync($"{OnlineKeyPrefix}{userId}");
            }
            catch (Exception ex) when (IsTransient(ex)) { /* best-effort */ }
        }

        public async Task<bool> IsOnlineAsync(string userId)
        {
            try { return await Db.KeyExistsAsync($"{OnlineKeyPrefix}{userId}"); }
            catch (Exception ex) when (IsTransient(ex)) { return false; }
        }

        public async Task<DateTime?> GetLastSeenAsync(string userId)
        {
            try
            {
                var raw = await Db.StringGetAsync($"{LastSeenKeyPrefix}{userId}");
                if (raw.IsNullOrEmpty) return null;
                return DateTime.Parse(raw!, null, System.Globalization.DateTimeStyles.RoundtripKind);
            }
            catch (Exception ex) when (IsTransient(ex))
            {
                return null;
            }
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
    }
}