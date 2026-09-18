namespace backend.dtos.Response;

/// <summary>
/// Gợi ý kết bạn. Có hai chiến lược:
///  - User hiện tại CHƯA có bạn (0 friends) → sắp xếp theo tài khoản mới tạo,
///    `MutualCount = null` (chưa có ý nghĩa).
///  - User hiện tại ĐÃ có bạn → sắp xếp theo số bạn chung giảm dần,
///    `MutualCount` = số người nằm trong cả friend-set của mình và candidate.
/// </summary>
public class SuggestionResponse
{
    public string Id { get; init; } = string.Empty;
    public string FirstName { get; init; } = string.Empty;
    public string LastName { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Avatar { get; init; } = string.Empty;

    /// <summary>
    /// Số bạn chung. Null khi current user chưa có bạn (gợi ý theo account mới).
    /// </summary>
    public int? MutualCount { get; init; }
}
