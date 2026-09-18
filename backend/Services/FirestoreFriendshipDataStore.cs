using backend.Attributes;
using backend.Models;
using backend.Models.Conversation;
using Google.Cloud.Firestore;

namespace backend.Services;

/// <summary>
/// Firestore implementation của <see cref="IFriendshipDataStore"/>.
/// Di chuyển các Firestore query từ FriendshipService ra đây.
/// </summary>
[ScopedService]
public class FirestoreFriendshipDataStore : IFriendshipDataStore
{
    private readonly FirestoreDb _db;
    private const string Col = "friendships";
    private const string UsersCol = "users";
    private const string ConvsCol = "conversations";

    public FirestoreFriendshipDataStore(FirestoreDb db) => _db = db;

    public async Task<UserSnapshot?> GetUserAsync(string uid)
    {
        var snap = await _db.Collection(UsersCol).Document(uid).GetSnapshotAsync();
        if (!snap.Exists) return null;
        var u = snap.ConvertTo<User>();
        return new UserSnapshot(u.Id, u.FirstName, u.LastName, u.Email, u.Avatar, u.Status, u.CreateAt);
    }

    public async Task<IReadOnlyList<UserSnapshot>> GetAllUsersOrderedByCreatedAtDescAsync()
    {
        var snap = await _db.Collection(UsersCol)
            .OrderByDescending("created_at")
            .GetSnapshotAsync();

        var result = new List<UserSnapshot>();
        foreach (var d in snap.Documents)
        {
            if (!d.Exists) continue;
            var u = d.ConvertTo<User>();
            if (!u.Status) continue; // bỏ user bị disabled
            result.Add(new UserSnapshot(u.Id, u.FirstName, u.LastName, u.Email, u.Avatar, u.Status, u.CreateAt));
        }
        return result;
    }

    public async Task<Friendship?> GetRelationshipAsync(string a, string b)
    {
        var t1 = _db.Collection(Col)
            .WhereEqualTo("sender_id", a)
            .WhereEqualTo("addressee_id", b)
            .Limit(1)
            .GetSnapshotAsync();

        var t2 = _db.Collection(Col)
            .WhereEqualTo("sender_id", b)
            .WhereEqualTo("addressee_id", a)
            .Limit(1)
            .GetSnapshotAsync();

        await Task.WhenAll(t1, t2);
        var doc = t1.Result.Documents.FirstOrDefault() ?? t2.Result.Documents.FirstOrDefault();
        return doc?.ConvertTo<Friendship>();
    }

    public async Task<(IReadOnlyList<Friendship>, IReadOnlyList<Friendship>)> FetchBothSidesByStatusAsync(
        string userId, string status)
    {
        var t1 = _db.Collection(Col)
            .WhereEqualTo("sender_id", userId)
            .WhereEqualTo("status", status)
            .GetSnapshotAsync();

        var t2 = _db.Collection(Col)
            .WhereEqualTo("addressee_id", userId)
            .WhereEqualTo("status", status)
            .GetSnapshotAsync();

        await Task.WhenAll(t1, t2);
        return (
            ToList(t1.Result),
            ToList(t2.Result)
        );
    }

    public async Task<IReadOnlyList<Friendship>> FetchPendingSentBySenderAsync(string userId)
    {
        var snap = await _db.Collection(Col)
            .WhereEqualTo("sender_id", userId)
            .WhereEqualTo("status", "pending")
            .GetSnapshotAsync();
        return ToListOrderedDesc(snap, f => f.CreatedAt);
    }

    public async Task<IReadOnlyList<Friendship>> FetchPendingReceivedByAddresseeAsync(string userId)
    {
        var snap = await _db.Collection(Col)
            .WhereEqualTo("addressee_id", userId)
            .WhereEqualTo("status", "pending")
            .GetSnapshotAsync();
        return ToListOrderedDesc(snap, f => f.CreatedAt);
    }

    public async Task<IReadOnlyList<Friendship>> FetchAllPendingAsync()
    {
        var snap = await _db.Collection(Col)
            .WhereEqualTo("status", "pending")
            .GetSnapshotAsync();
        return ToList(snap);
    }

    public async Task<Friendship?> GetFriendshipByIdAsync(string friendshipId)
    {
        var snap = await _db.Collection(Col).Document(friendshipId).GetSnapshotAsync();
        return snap.Exists ? snap.ConvertTo<Friendship>() : null;
    }

    public async Task<string> AddFriendshipAsync(Friendship friendship)
    {
        var docRef = await _db.Collection(Col).AddAsync(friendship);
        return docRef.Id;
    }

    public async Task DeleteFriendshipAsync(string friendshipId)
    {
        await _db.Collection(Col).Document(friendshipId).DeleteAsync();
    }

    public async Task SetFriendshipAsync(string id, Friendship friendship)
    {
        await _db.Collection(Col).Document(id).SetAsync(friendship);
    }

    public async Task<IReadOnlyList<ConversationSnapshot>> GetPrivateConversationsForUserAsync(string userId)
    {
        var snap = await _db.Collection(ConvsCol)
            .WhereEqualTo("type", "private")
            .WhereArrayContains("participant_ids", userId)
            .GetSnapshotAsync();

        var result = new List<ConversationSnapshot>();
        foreach (var d in snap.Documents)
        {
            if (!d.Exists) continue;
            try
            {
                var participants = d.GetValue<List<string>>("participant_ids") ?? new List<string>();
                DateTime updated;
                try { updated = d.GetValue<DateTime>("updated_at"); }
                catch { updated = d.ConvertTo<Conversation>().UpdatedAt; }

                result.Add(new ConversationSnapshot(d.Id, "private", participants, updated));
            }
            catch
            {
                // Bỏ qua doc lỗi shape
            }
        }
        return result;
    }

    // ── Helpers ──────────────────────────────────────────────────
    private static IReadOnlyList<Friendship> ToList(QuerySnapshot snap)
    {
        var list = new List<Friendship>(snap.Documents.Count);
        foreach (var d in snap.Documents)
        {
            if (d.Exists) list.Add(d.ConvertTo<Friendship>());
        }
        return list;
    }

    private static IReadOnlyList<Friendship> ToListOrderedDesc(QuerySnapshot snap, Func<Friendship, DateTime> key)
    {
        return ToList(snap).OrderByDescending(key).ToList();
    }
}
