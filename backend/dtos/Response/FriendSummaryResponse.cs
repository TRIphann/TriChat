namespace backend.dtos.Response;

/// <summary>
/// Thông tin bạn bè kèm avatar/tên — dùng trong danh sách bạn bè.
/// `LastMessageAt` được populate khi bạn bè này đã có conversation riêng với user hiện tại;
/// dùng để sort "bạn nhắn tin gần đây nhất" lên đầu.
/// </summary>
public class FriendSummaryResponse
{
    public string FriendshipId { get; init; } = string.Empty;
    public string FriendId { get; init; } = string.Empty;
    public string FirstName { get; init; } = string.Empty;
    public string LastName { get; init; } = string.Empty;
    public string Avatar { get; init; } = string.Empty;
    public DateTime FriendsSince { get; init; }

    /// <summary>Thời điểm nhắn tin gần nhất trong conversation riêng với friend này. Null khi chưa chat.</summary>
    public DateTime? LastMessageAt { get; init; }
}
