using backend.Models;
using backend.Models.Conversation;
using backend.Services;

namespace backend.Tests;

/// <summary>
/// In-memory fake của <see cref="IFriendshipDataStore"/> — dùng cho unit tests.
/// Thread-safe via <c>ConcurrentDictionary</c>.
/// </summary>
public sealed class InMemoryFriendshipDataStore : IFriendshipDataStore
{
    // Collections
    private readonly System.Collections.Concurrent.ConcurrentDictionary<string, UserSnapshot> _users = new();
    private readonly System.Collections.Concurrent.ConcurrentDictionary<string, Friendship> _friendships = new();
    private readonly System.Collections.Concurrent.ConcurrentDictionary<string, ConversationSnapshot> _conversations = new();

    // ID generators
    private int _friendshipCounter;
    private int _convCounter;

    // ── Setup helpers ──────────────────────────────────────────────

    public void AddUser(UserSnapshot user) =>
        _users[user.Id] = user;

    public void AddFriendship(Friendship f) =>
        _friendships[f.Id ?? (_friendshipCounter++).ToString()] = f;

    public void AddConversation(ConversationSnapshot c) =>
        _conversations[c.Id] = c;

    public void Clear()
    {
        _users.Clear();
        _friendships.Clear();
        _conversations.Clear();
        _friendshipCounter = 0;
        _convCounter = 0;
    }

    // ── IFriendshipDataStore impl ──────────────────────────────────

    public Task<UserSnapshot?> GetUserAsync(string uid)
    {
        _users.TryGetValue(uid, out var u);
        return Task.FromResult(u);
    }

    public Task<IReadOnlyList<UserSnapshot>> GetAllUsersOrderedByCreatedAtDescAsync()
    {
        var list = _users.Values
            .Where(u => u.Status) // match Firestore: bỏ user bị disabled
            .OrderByDescending(u => u.CreateAt)
            .ToList();
        return Task.FromResult<IReadOnlyList<UserSnapshot>>(list);
    }

    public Task<Friendship?> GetRelationshipAsync(string a, string b)
    {
        var rel = _friendships.Values.FirstOrDefault(f =>
            (f.SenderId == a && f.AddresseeId == b) ||
            (f.SenderId == b && f.AddresseeId == a));
        return Task.FromResult(rel);
    }

    public Task<(IReadOnlyList<Friendship>, IReadOnlyList<Friendship>)> FetchBothSidesByStatusAsync(
        string userId, string status)
    {
        var sender   = _friendships.Values.Where(f => f.SenderId == userId    && f.Status == status).ToList();
        var addressee = _friendships.Values.Where(f => f.AddresseeId == userId && f.Status == status).ToList();
        return Task.FromResult<(IReadOnlyList<Friendship>, IReadOnlyList<Friendship>)>((sender, addressee));
    }

    public Task<IReadOnlyList<Friendship>> FetchPendingSentBySenderAsync(string userId)
    {
        var list = _friendships.Values
            .Where(f => f.SenderId == userId && f.Status == "pending")
            .OrderByDescending(f => f.CreatedAt)
            .ToList();
        return Task.FromResult<IReadOnlyList<Friendship>>(list);
    }

    public Task<IReadOnlyList<Friendship>> FetchPendingReceivedByAddresseeAsync(string userId)
    {
        var list = _friendships.Values
            .Where(f => f.AddresseeId == userId && f.Status == "pending")
            .OrderByDescending(f => f.CreatedAt)
            .ToList();
        return Task.FromResult<IReadOnlyList<Friendship>>(list);
    }

    public Task<IReadOnlyList<Friendship>> FetchAllPendingAsync()
    {
        var list = _friendships.Values.Where(f => f.Status == "pending").ToList();
        return Task.FromResult<IReadOnlyList<Friendship>>(list);
    }

    public Task<Friendship?> GetFriendshipByIdAsync(string friendshipId)
    {
        _friendships.TryGetValue(friendshipId, out var f);
        return Task.FromResult(f);
    }

    public Task<string> AddFriendshipAsync(Friendship friendship)
    {
        var id = friendship.Id ?? $"fs_{Interlocked.Increment(ref _friendshipCounter)}";
        friendship.Id = id;
        _friendships[id] = friendship;
        return Task.FromResult(id);
    }

    public Task DeleteFriendshipAsync(string friendshipId)
    {
        _friendships.TryRemove(friendshipId, out _);
        return Task.CompletedTask;
    }

    public Task SetFriendshipAsync(string id, Friendship friendship)
    {
        friendship.Id = id;
        _friendships[id] = friendship;
        return Task.CompletedTask;
    }

    public Task<IReadOnlyList<ConversationSnapshot>> GetPrivateConversationsForUserAsync(string userId)
    {
        var list = _conversations.Values
            .Where(c => c.Type == "private" && c.ParticipantIds.Contains(userId))
            .ToList();
        return Task.FromResult<IReadOnlyList<ConversationSnapshot>>(list);
    }
}
