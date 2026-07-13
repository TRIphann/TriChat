using backend.Attributes;
using backend.Interfaces;

namespace backend.Services
{
    [ScopedService]
    public class RedisService
    {
        private const string OnlineKeyPrefix = "online:";
        private const string LastSeenKeyPrefix = "last_seen:";
        private static readonly TimeSpan OnlineTtl = TimeSpan.FromMinutes(5);

        private readonly IKeyValueStore _kv;
        private readonly ILogger<RedisService> _logger;

        public RedisService(IKeyValueStore kv, ILogger<RedisService> logger)
        {
            _kv = kv;
            _logger = logger;
        }

        // ── Generic ────────────────────────────────────────────

        public async Task<string?> GetAsync(string key)
        {
            try { return await _kv.GetAsync(key); }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "KeyValueStore GET failed for {Key}", key);
                return null;
            }
        }

        public async Task SetAsync(string key, string value, TimeSpan expiry)
        {
            try { await _kv.SetAsync(key, value, expiry); }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "KeyValueStore SET failed for {Key}", key);
            }
        }

        public async Task DeleteAsync(string key)
        {
            try { await _kv.DeleteAsync(key); }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "KeyValueStore DEL failed for {Key}", key);
            }
        }

        public async Task<bool> KeyExistsAsync(string key)
        {
            try { return await _kv.KeyExistsAsync(key); }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "KeyValueStore EXISTS failed for {Key}", key);
                return false;
            }
        }

        // ── Online status ───────────────────────────────────────

        public async Task SetOnlineAsync(string userId)
        {
            await SetAsync($"{OnlineKeyPrefix}{userId}", "1", OnlineTtl);
        }

        public async Task RefreshOnlineTtlAsync(string userId)
        {
            // Re-SET là cách portable nhất qua REST API (không phụ thuộc EXPIRE)
            await SetAsync($"{OnlineKeyPrefix}{userId}", "1", OnlineTtl);
        }

        public async Task SetOfflineAsync(string userId)
        {
            await SetAsync($"{LastSeenKeyPrefix}{userId}", DateTime.UtcNow.ToString("O"), TimeSpan.FromDays(30));
            await DeleteAsync($"{OnlineKeyPrefix}{userId}");
        }

        public async Task<bool> IsOnlineAsync(string userId) =>
            await KeyExistsAsync($"{OnlineKeyPrefix}{userId}");

        public async Task<DateTime?> GetLastSeenAsync(string userId)
        {
            var raw = await GetAsync($"{LastSeenKeyPrefix}{userId}");
            if (string.IsNullOrEmpty(raw)) return null;
            if (DateTime.TryParse(raw, null, System.Globalization.DateTimeStyles.RoundtripKind, out var dt))
                return dt;
            return null;
        }
    }
}
