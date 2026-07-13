namespace backend.Interfaces;

public interface IKeyValueStore
{
    Task<string?> GetAsync(string key);
    Task SetAsync(string key, string value, TimeSpan expiry);
    Task DeleteAsync(string key);
    Task<bool> KeyExistsAsync(string key);
}
