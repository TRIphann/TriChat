using Microsoft.AspNetCore.SignalR;
using FirebaseAdmin.Auth;

namespace backend.Hubs;

/// <summary>
/// SignalR Hub cho realtime kết bạn.
///
/// Client kết nối với token Firebase qua Authorization header:
///   Authorization: Bearer &lt;firebase_id_token&gt;
///
/// Hoặc có thể dùng query string nếu header không khả dụng:
///   ?access_token=&lt;firebase_id_token&gt;
///
/// Mỗi user được join vào group riêng tên "user_{uid}" để nhận push.
/// </summary>
public class FriendHub : Hub
{
    private readonly ILogger<FriendHub> _logger;

    public FriendHub(ILogger<FriendHub> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Khi client kết nối → xác thực token → join group cá nhân.
    /// Hỗ trợ cả Authorization header (Bearer token) và query string access_token.
    /// Ưu tiên header vì bảo mật hơn (không bị log trong URL).
    /// </summary>
    public override async Task OnConnectedAsync()
    {
        var token = ExtractToken();

        if (string.IsNullOrWhiteSpace(token))
        {
            _logger.LogWarning("FriendHub: connection rejected — no token. ConnectionId={Id}", Context.ConnectionId);
            Context.Abort();
            return;
        }

        try
        {
            var decoded = await FirebaseAuth.DefaultInstance.VerifyIdTokenAsync(token, true);
            var uid = decoded.Uid;

            // Lưu uid vào context để dùng khi disconnect
            Context.Items["uid"] = uid;

            // Join group cá nhân
            await Groups.AddToGroupAsync(Context.ConnectionId, GroupName(uid));

            _logger.LogInformation("FriendHub: {Uid} connected [{ConnectionId}]", uid, Context.ConnectionId);
        }
        catch (Exception ex)
        {
            _logger.LogWarning("FriendHub: invalid token — {Msg}", ex.Message);
            Context.Abort();
            return;
        }

        await base.OnConnectedAsync();
    }

    /// <summary>
    /// Trích xuất token từ Authorization header (Bearer) hoặc query string.
    /// Header được ưu tiên vì bảo mật hơn.
    /// </summary>
    private string? ExtractToken()
    {
        var httpContext = Context.GetHttpContext();
        if (httpContext == null) return null;

        // Ưu tiên Authorization header (Bearer token)
        var authHeader = httpContext.Request.Headers["Authorization"].FirstOrDefault();
        if (!string.IsNullOrWhiteSpace(authHeader) && authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        {
            return authHeader.Substring(7).Trim();
        }

        // Fallback: query string access_token (duy trì tương thích ngược)
        var queryToken = httpContext.Request.Query["access_token"].FirstOrDefault();
        return queryToken;
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        if (Context.Items.TryGetValue("uid", out var uid) && uid is string uidStr)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, GroupName(uidStr));
            _logger.LogInformation("FriendHub: {Uid} disconnected", uidStr);
        }
        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>Tên group SignalR của một user</summary>
    public static string GroupName(string uid) => $"user_{uid}";
}
