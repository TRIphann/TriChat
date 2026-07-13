using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using backend.Interfaces;
using backend.settings;
using Microsoft.Extensions.Options;

namespace backend.Services;

public class UpstashRedisService : IKeyValueStore
{
    private readonly HttpClient _http;
    private readonly JsonSerializerOptions _json = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    public UpstashRedisService(HttpClient http, IOptions<UpstashRedisSettings> settings)
    {
        _http = http;
        var s = settings.Value;
        _http.BaseAddress = new Uri(s.RestUrl.TrimEnd('/'));
        _http.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", s.RestToken);
        _http.Timeout = TimeSpan.FromSeconds(10);
    }

    public async Task<string?> GetAsync(string key)
    {
        var body = JsonSerializer.Serialize(new { key }, _json);
        var resp = await _http.PostAsync("", new StringContent(body, Encoding.UTF8, "application/json"));
        if (!resp.IsSuccessStatusCode) return null;
        var json = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        var result = json.RootElement.GetProperty("result");
        return result.ValueKind == JsonValueKind.Null ? null : result.GetString();
    }

    public async Task SetAsync(string key, string value, TimeSpan expiry)
    {
        var body = JsonSerializer.Serialize(new { key, value, ex = (int)expiry.TotalSeconds }, _json);
        await _http.PostAsync("", new StringContent(body, Encoding.UTF8, "application/json"));
    }

    public async Task DeleteAsync(string key)
    {
        var body = JsonSerializer.Serialize(new { key }, _json);
        await _http.PostAsync("", new StringContent(body, Encoding.UTF8, "application/json"));
    }

    public async Task<bool> KeyExistsAsync(string key)
    {
        var body = JsonSerializer.Serialize(new { key }, _json);
        var resp = await _http.PostAsync("", new StringContent(body, Encoding.UTF8, "application/json"));
        if (!resp.IsSuccessStatusCode) return false;
        var json = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        return json.RootElement.GetProperty("result").GetInt32() == 1;
    }
}
