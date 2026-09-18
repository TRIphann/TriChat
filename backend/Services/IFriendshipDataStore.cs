using backend.Models;
using backend.Models.Conversation;

namespace backend.Services;

/// <summary>
/// Snapshot tối giản của User — chỉ những field FriendshipService cần.
/// Giúp tách business logic khỏi Firestore.ConvertTo&lt;User&gt;() để test được.
/// </summary>
public sealed record UserSnapshot(
    string Id,
    string FirstName,
    string LastName,
    string Email,
    string Avatar,
    bool Status,
    DateTime CreateAt);

/// <summary>
/// Snapshot tối giản của Conversation — chỉ những field cần để sort
/// "bạn nhắn tin gần đây nhất".
/// </summary>
public sealed record ConversationSnapshot(
    string Id,
    string Type,
    IReadOnlyList<string> ParticipantIds,
    DateTime UpdatedAt);

/// <summary>
/// Tầng truy cập dữ liệu cho FriendshipService — cố ý giữ ở mức
/// "raw docs/snapshots" để service xử lý business logic (filter, sort, paginate).
///
/// Interface này cho phép:
///  - Test nhanh với <c>InMemoryFriendshipDataStore</c> (không cần Firestore emulator).
///  - Đổi implementation (Redis cache, Postgres…) mà không sửa service.
/// </summary>
public interface IFriendshipDataStore
{
    // ── Users ────────────────────────────────────────────────────
    Task<UserSnapshot?> GetUserAsync(string uid);
    Task<IReadOnlyList<UserSnapshot>> GetAllUsersOrderedByCreatedAtDescAsync();

    // ── Friendships ──────────────────────────────────────────────
    /// <summary>
    /// Tìm document quan hệ giữa A và B (không phân biệt chiều gửi).
    /// </summary>
    Task<Friendship?> GetRelationshipAsync(string a, string b);

    /// <summary>
    /// Lấy các friendship ở cả 2 phía (sender=userId hoặc addressee=userId) có status.
    /// </summary>
    Task<(IReadOnlyList<Friendship> SenderSide, IReadOnlyList<Friendship> AddresseeSide)>
        FetchBothSidesByStatusAsync(string userId, string status);

    /// <summary>Lấy friendship docs có status=pending, sender=userId (mới nhất trước).</summary>
    Task<IReadOnlyList<Friendship>> FetchPendingSentBySenderAsync(string userId);

    /// <summary>Lấy friendship docs có status=pending, addressee=userId (mới nhất trước).</summary>
    Task<IReadOnlyList<Friendship>> FetchPendingReceivedByAddresseeAsync(string userId);

    /// <summary>Lấy friendship docs có status=pending (dùng cho exclude trong suggestions).</summary>
    Task<IReadOnlyList<Friendship>> FetchAllPendingAsync();

    Task<Friendship?> GetFriendshipByIdAsync(string friendshipId);

    Task<string> AddFriendshipAsync(Friendship friendship);

    Task DeleteFriendshipAsync(string friendshipId);

    /// <summary>Ghi đè toàn bộ friendship (dùng cho Block/Respond).</summary>
    Task SetFriendshipAsync(string id, Friendship friendship);

    // ── Conversations (chỉ để sort recent chat) ────────────────
    Task<IReadOnlyList<ConversationSnapshot>> GetPrivateConversationsForUserAsync(string userId);
}
