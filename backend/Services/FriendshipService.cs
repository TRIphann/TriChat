using backend.Attributes;
using backend.dtos.Request;
using backend.dtos.Response;
using backend.Enums;
using backend.Exceptions;
using backend.Hubs;
using backend.Models;
using Mapster;
using Microsoft.AspNetCore.SignalR;

namespace backend.Services;

/// <summary>
/// Quản lý toàn bộ nghiệp vụ kết bạn — business logic thuần, không chạm Firestore trực tiếp.
///
/// Cấu trúc collection Firestore (do <see cref="FirestoreFriendshipDataStore"/> xử lý):
///   friendships/{docId}  — mỗi document là một cạnh quan hệ giữa 2 user,
///   với sender_id, addressee_id, status.
///
/// Quy tắc canonical: để tìm quan hệ giữa A và B, query:
///   (sender_id == A AND addressee_id == B)
///   OR
///   (sender_id == B AND addressee_id == A)
/// </summary>
[ScopedService]
public class FriendshipService(
    IFriendshipDataStore store,
    ILogger<FriendshipService> logger,
    IHubContext<FriendHub> hubContext)
{
    // ─────────────────────────────────────────────────────────────
    // PUBLIC API
    // ─────────────────────────────────────────────────────────────

    /// <summary>
    /// Gửi lời mời kết bạn.
    ///
    /// Kiểm duyệt (theo thứ tự):
    ///  1. Không tự gửi cho bản thân
    ///  2. Người nhận phải tồn tại
    ///  3. Chưa là bạn bè (status == accepted)
    ///  4. Chưa có lời mời đang chờ (status == pending) theo chiều nào
    ///  5. Người nhận chưa block người gửi
    ///  6. Người gửi chưa block người nhận
    ///  7. Nếu người nhận đã bị từ chối trước đó → tạo lại lời mời mới
    /// </summary>
    public async Task<FriendshipResponse> SendRequestAsync(string senderId, SendFriendRequestDto dto)
    {
        var addresseeId = dto.AddresseeId.Trim();

        // 1. Không tự gửi cho bản thân
        if (senderId == addresseeId)
            throw new AppException(ErrorCode.CANNOT_SELF_FRIEND);

        // 2. Người nhận phải tồn tại & active
        await EnsureUserExistsAsync(addresseeId);

        // 3-6. Kiểm tra quan hệ hiện tại
        var existing = await store.GetRelationshipAsync(senderId, addresseeId);

        if (existing is not null)
        {
            switch (existing.Status)
            {
                case "accepted":
                    throw new AppException(ErrorCode.ALREADY_FRIENDS);

                case "pending":
                    if (existing.SenderId == senderId)
                        throw new AppException(ErrorCode.FRIEND_REQUEST_ALREADY_SENT);
                    // Người kia đã gửi cho mình → tự động chấp nhận (UX Zalo)
                    return await AcceptExistingAsync(existing.Id, senderId);

                case "blocked":
                    if (existing.SenderId == senderId)
                        throw new AppException(ErrorCode.YOU_BLOCKED_USER);
                    else
                        throw new AppException(ErrorCode.BLOCKED_BY_USER);

                case "declined":
                    await store.DeleteFriendshipAsync(existing.Id);
                    break;
            }
        }

        // Tạo lời mời mới
        var senderSnap    = await store.GetUserAsync(senderId);
        var addresseeSnap = await store.GetUserAsync(addresseeId);

        string senderName = "";
        string senderAvatar = "";
        string addresseeName = "";

        if (senderSnap is not null)
        {
            senderName   = $"{senderSnap.FirstName} {senderSnap.LastName}".Trim();
            senderAvatar = senderSnap.Avatar;
        }
        if (addresseeSnap is not null)
        {
            addresseeName = $"{addresseeSnap.FirstName} {addresseeSnap.LastName}".Trim();
        }

        var friendship = new Friendship
        {
            SenderId    = senderId,
            AddresseeId = addresseeId,
            Status      = "pending",
            SourceType  = dto.SourceType,
            CreatedAt   = DateTime.UtcNow,
            UpdatedAt   = DateTime.UtcNow,
            AddresseeName = addresseeName
        };

        var newId = await store.AddFriendshipAsync(friendship);
        friendship.Id = newId;

        logger.LogInformation("Friend request sent: {SenderId} → {AddresseeId} [{Id}]",
            senderId, addresseeId, friendship.Id);

        // ── SignalR: notify người nhận có lời mời mới ─────────────
        var enriched = friendship.Adapt<FriendshipResponse>();
        enriched.SenderName = senderName;
        enriched.SenderAvatar = senderAvatar;
        enriched.AddresseeName = addresseeName;

        await hubContext.Clients
            .Group(FriendHub.GroupName(addresseeId))
            .SendAsync("FriendRequestReceived", enriched);

        return enriched;
    }

    /// <summary>
    /// Chấp nhận hoặc từ chối lời mời kết bạn.
    /// </summary>
    public async Task<FriendshipResponse> RespondAsync(
        string currentUserId, string friendshipId, RespondFriendRequestDto dto)
    {
        var friendship = await store.GetFriendshipByIdAsync(friendshipId)
            ?? throw new AppException(ErrorCode.FRIEND_REQUEST_NOT_FOUND);

        if (friendship.AddresseeId != currentUserId)
            throw new AppException(ErrorCode.NOT_REQUEST_RECIPIENT);

        if (friendship.Status != "pending")
            throw new AppException(ErrorCode.REQUEST_NOT_PENDING);

        friendship.Status    = dto.Accept ? "accepted" : "declined";
        friendship.UpdatedAt = DateTime.UtcNow;

        await store.SetFriendshipAsync(friendshipId, friendship);

        logger.LogInformation("Friend request {Id} {Action} by {UserId}",
            friendshipId, friendship.Status, currentUserId);

        var response = friendship.Adapt<FriendshipResponse>();

        if (dto.Accept)
        {
            await hubContext.Clients
                .Group(FriendHub.GroupName(friendship.SenderId))
                .SendAsync("FriendRequestAccepted", response);
        }
        else
        {
            await hubContext.Clients
                .Group(FriendHub.GroupName(friendship.SenderId))
                .SendAsync("FriendRequestDeclined", response);
        }

        return response;
    }

    /// <summary>Huỷ lời mời kết bạn đã gửi (chỉ sender mới được huỷ).</summary>
    public async Task CancelRequestAsync(string currentUserId, string friendshipId)
    {
        var friendship = await store.GetFriendshipByIdAsync(friendshipId)
            ?? throw new AppException(ErrorCode.FRIEND_REQUEST_NOT_FOUND);

        if (friendship.SenderId != currentUserId)
            throw new AppException(ErrorCode.NOT_REQUEST_SENDER);

        if (friendship.Status != "pending")
            throw new AppException(ErrorCode.REQUEST_NOT_PENDING);

        await store.DeleteFriendshipAsync(friendshipId);

        logger.LogInformation("Friend request {Id} cancelled by {UserId}",
            friendshipId, currentUserId);

        var response = friendship.Adapt<FriendshipResponse>();
        await hubContext.Clients
            .Group(FriendHub.GroupName(friendship.AddresseeId))
            .SendAsync("FriendRequestCancelled", response);
    }

    /// <summary>Huỷ kết bạn (unfriend) — xoá document có status == "accepted".</summary>
    public async Task UnfriendAsync(string currentUserId, string targetUserId)
    {
        var existing = await store.GetRelationshipAsync(currentUserId, targetUserId);

        if (existing is null || existing.Status != "accepted")
            throw new AppException(ErrorCode.ALREADY_FRIENDS);

        if (existing.SenderId != currentUserId && existing.AddresseeId != currentUserId)
            throw new AppException(ErrorCode.FORBIDDEN);

        await store.DeleteFriendshipAsync(existing.Id);

        logger.LogInformation("Unfriend: {A} ↔ {B}", currentUserId, targetUserId);

        var otherUserId = existing.SenderId == currentUserId
            ? existing.AddresseeId
            : existing.SenderId;

        var response = existing.Adapt<FriendshipResponse>();
        await hubContext.Clients
            .Group(FriendHub.GroupName(otherUserId))
            .SendAsync("FriendUnfriended", response);
    }

    /// <summary>Block người dùng.</summary>
    public async Task<FriendshipResponse> BlockAsync(string blockerId, string blockedId)
    {
        if (blockerId == blockedId)
            throw new AppException(ErrorCode.CANNOT_SELF_BLOCK);

        await EnsureUserExistsAsync(blockedId);

        var existing = await store.GetRelationshipAsync(blockerId, blockedId);

        if (existing is not null)
        {
            if (existing.Status == "blocked" && existing.SenderId == blockerId)
                throw new AppException(ErrorCode.ALREADY_BLOCKED);

            var blockedSnap = await store.GetUserAsync(blockedId);
            var addresseeName = blockedSnap is null
                ? ""
                : $"{blockedSnap.FirstName} {blockedSnap.LastName}".Trim();

            var updated = new Friendship
            {
                Id          = existing.Id,
                SenderId    = blockerId,
                AddresseeId = blockedId,
                Status      = "blocked",
                SourceType  = existing.SourceType,
                CreatedAt   = existing.CreatedAt,
                UpdatedAt   = DateTime.UtcNow,
                AddresseeName = addresseeName
            };
            await store.SetFriendshipAsync(existing.Id, updated);
            logger.LogInformation("User {BlockerId} blocked {BlockedId} (existing doc updated)", blockerId, blockedId);
            return updated.Adapt<FriendshipResponse>();
        }

        var snap = await store.GetUserAsync(blockedId);
        var name = snap is null ? "" : $"{snap.FirstName} {snap.LastName}".Trim();

        var friendship = new Friendship
        {
            SenderId    = blockerId,
            AddresseeId = blockedId,
            Status      = "blocked",
            SourceType  = "search",
            CreatedAt   = DateTime.UtcNow,
            UpdatedAt   = DateTime.UtcNow,
            AddresseeName = name
        };
        var docRef = await store.AddFriendshipAsync(friendship);
        friendship.Id = docRef;
        logger.LogInformation("User {BlockerId} blocked {BlockedId} (new doc)", blockerId, blockedId);
        return friendship.Adapt<FriendshipResponse>();
    }

    /// <summary>Bỏ block người dùng.</summary>
    public async Task UnblockAsync(string blockerId, string blockedId)
    {
        var existing = await store.GetRelationshipAsync(blockerId, blockedId);

        if (existing is null || existing.Status != "blocked")
            throw new AppException(ErrorCode.FRIEND_REQUEST_NOT_FOUND);

        if (existing.SenderId != blockerId)
            throw new AppException(ErrorCode.FORBIDDEN);

        await store.DeleteFriendshipAsync(existing.Id);
        logger.LogInformation("User {BlockerId} unblocked {BlockedId}", blockerId, blockedId);
    }

    // ─────────────────────────────────────────────────────────────
    // PAGINATED READ API
    // ─────────────────────────────────────────────────────────────

    /// <summary>
    /// Lấy danh sách bạn bè (status == accepted) của user, sort theo "bạn nhắn tin gần đây".
    /// Paginated qua limit + offset.
    /// </summary>
    public async Task<(List<FriendSummaryResponse> Items, int Total)> GetFriendsPagedAsync(
        string userId, int limit, int offset)
    {
        var (senderDocs, addresseeDocs) = await store.FetchBothSidesByStatusAsync(userId, "accepted");

        var all = new List<(string FriendId, string FriendshipId, DateTime Since)>();
        foreach (var f in senderDocs)   all.Add((f.AddresseeId, f.Id, f.UpdatedAt));
        foreach (var f in addresseeDocs) all.Add((f.SenderId,    f.Id, f.UpdatedAt));

        var total = all.Count;
        if (total == 0) return (new List<FriendSummaryResponse>(), 0);

        // Build map friendId → lastMessageAt từ private conversations của user hiện tại
        var lastChatByFriend = await BuildFriendLastChatMapAsync(userId);

        // Sort giảm dần theo (lastMessageAt ?? since)
        all.Sort((a, b) =>
        {
            var aAt = lastChatByFriend.TryGetValue(a.FriendId, out var av) ? av : a.Since;
            var bAt = lastChatByFriend.TryGetValue(b.FriendId, out var bv) ? bv : b.Since;
            return bAt.CompareTo(aAt);
        });

        var page = all.Skip(offset).Take(limit).ToList();
        var items = await EnrichWithUserDataAsync(page, lastChatByFriend);
        return (items, total);
    }

    /// <summary>Backward-compat (admin/debug) — không phân trang.</summary>
    public async Task<List<FriendSummaryResponse>> GetFriendsAsync(string userId)
    {
        var (items, _) = await GetFriendsPagedAsync(userId, int.MaxValue, 0);
        return items;
    }

    /// <summary>
    /// Gợi ý kết bạn.
    ///  - 0 friends → sort theo created_at DESC (account mới nhất), MutualCount = null.
    ///  - Có friends → sort theo MutualCount DESC, kèm số bạn chung.
    /// Luôn loại trừ: chính mình, đã là bạn, đang pending.
    /// </summary>
    public async Task<(List<SuggestionResponse> Items, int Total)> GetSuggestionsPagedAsync(
        string userId, int limit, int offset)
    {
        var (senderDocs, addresseeDocs) = await store.FetchBothSidesByStatusAsync(userId, "accepted");

        var excludeIds = new HashSet<string>(StringComparer.Ordinal) { userId };
        var currentUserFriendIds = new HashSet<string>(StringComparer.Ordinal);

        foreach (var f in senderDocs)
        {
            excludeIds.Add(f.AddresseeId);
            currentUserFriendIds.Add(f.AddresseeId);
        }
        foreach (var f in addresseeDocs)
        {
            excludeIds.Add(f.SenderId);
            currentUserFriendIds.Add(f.SenderId);
        }

        var pendingAll = await store.FetchAllPendingAsync();
        foreach (var f in pendingAll)
        {
            if (f.SenderId == userId)        excludeIds.Add(f.AddresseeId);
            else if (f.AddresseeId == userId) excludeIds.Add(f.SenderId);
        }

        var candidates = await store.GetAllUsersOrderedByCreatedAtDescAsync();
        var filteredCandidates = new List<UserSnapshot>();
        foreach (var u in candidates)
        {
            if (!excludeIds.Contains(u.Id))
                filteredCandidates.Add(u);
        }

        var hasFriends = currentUserFriendIds.Count > 0;

        if (!hasFriends)
        {
            // Chiến lược A: user mới — sort theo created_at DESC (đã OrderByDescending ở store)
            var total = filteredCandidates.Count;
            var pageUsers = filteredCandidates.Skip(offset).Take(limit).ToList();
            var items = pageUsers.Select(ToSuggestionResponse).ToList();
            return (items, total);
        }

        // Chiến lược B: sort theo MutualCount DESC, tie-break created_at DESC (vì store đã sort DESC)
        var ranked = new List<(UserSnapshot U, int MutualCount)>();
        foreach (var u in filteredCandidates)
        {
            var (s1, a1) = await store.FetchBothSidesByStatusAsync(u.Id, "accepted");
            var candidateFriends = new HashSet<string>(StringComparer.Ordinal);
            foreach (var f in s1) candidateFriends.Add(f.AddresseeId);
            foreach (var f in a1) candidateFriends.Add(f.SenderId);

            var mutual = candidateFriends.Intersect(currentUserFriendIds, StringComparer.Ordinal).Count();
            ranked.Add((u, mutual));
        }

        var totalRanked = ranked.Count;
        var pageRanked = ranked
            .OrderByDescending(x => x.MutualCount)
            .ThenBy(x => ranked.IndexOf(x)) // giữ relative order (đã DESC theo created_at)
            .Skip(offset)
            .Take(limit)
            .ToList();

        var itemsB = pageRanked.Select(x => new SuggestionResponse
        {
            Id          = x.U.Id,
            FirstName   = x.U.FirstName,
            LastName    = x.U.LastName,
            FullName    = $"{x.U.FirstName} {x.U.LastName}".Trim(),
            Email       = x.U.Email,
            Avatar      = x.U.Avatar,
            MutualCount = x.MutualCount,
        }).ToList();
        return (itemsB, totalRanked);
    }

    /// <summary>Paginated pending-received (mới nhất trước).</summary>
    public async Task<(List<FriendshipResponse> Items, int Total)> GetPendingReceivedPagedAsync(
        string userId, int limit, int offset)
    {
        userId = userId.Trim();
        var all = await store.FetchPendingReceivedByAddresseeAsync(userId);
        var (pageItems, total) = ApplyPage(all, limit, offset);

        if (pageItems.Count == 0)
            return (new List<FriendshipResponse>(), total);

        var result = await EnrichPendingReceivedAsync(userId, pageItems);
        return (result, total);
    }

    /// <summary>Backward-compat — không phân trang.</summary>
    public async Task<List<FriendshipResponse>> GetPendingReceivedAsync(string userId)
    {
        var (items, _) = await GetPendingReceivedPagedAsync(userId, int.MaxValue, 0);
        return items;
    }

    /// <summary>Paginated pending-sent (mới nhất trước).</summary>
    public async Task<(List<FriendshipResponse> Items, int Total)> GetPendingSentPagedAsync(
        string userId, int limit, int offset)
    {
        var all = await store.FetchPendingSentBySenderAsync(userId);
        var (pageItems, total) = ApplyPage(all, limit, offset);

        if (pageItems.Count == 0)
            return (new List<FriendshipResponse>(), total);

        var result = await EnrichPendingSentAsync(userId, pageItems);
        return (result, total);
    }

    /// <summary>Backward-compat — không phân trang.</summary>
    public async Task<List<FriendshipResponse>> GetPendingSentAsync(string userId)
    {
        var (items, _) = await GetPendingSentPagedAsync(userId, int.MaxValue, 0);
        return items;
    }

    public async Task<List<FriendshipResponse>> GetBlockedUsersAsync(string userId)
    {
        var snapshot = await store.FetchBothSidesByStatusAsync(userId, "blocked");
        var friendships = snapshot.SenderSide; // blocker = sender
        if (friendships.Count == 0) return [];

        var addresseeTasks = friendships
            .Select(f => store.GetUserAsync(f.AddresseeId))
            .ToList();
        var addresseeSnaps = await Task.WhenAll(addresseeTasks);
        var result = new List<FriendshipResponse>();

        for (int i = 0; i < friendships.Count; i++)
        {
            var f = friendships[i];
            var snap = addresseeSnaps[i];
            string addresseeName = "";
            if (snap is not null)
            {
                addresseeName = $"{snap.FirstName} {snap.LastName}".Trim();
            }
            var resp = f.Adapt<FriendshipResponse>();
            resp.AddresseeName = addresseeName;
            result.Add(resp);
        }
        return result;
    }

    public async Task<FriendshipResponse?> GetRelationshipStatusAsync(string currentUserId, string targetUserId)
    {
        var rel = await store.GetRelationshipAsync(currentUserId, targetUserId);
        if (rel is null) return null;

        var addresseeSnap = await store.GetUserAsync(rel.AddresseeId);
        var addresseeName = addresseeSnap is null
            ? ""
            : $"{addresseeSnap.FirstName} {addresseeSnap.LastName}".Trim();

        var resp = rel.Adapt<FriendshipResponse>();
        resp.AddresseeName = addresseeName;
        return resp;
    }

    // ─────────────────────────────────────────────────────────────
    // PRIVATE HELPERS
    // ─────────────────────────────────────────────────────────────

    private async Task<FriendshipResponse> AcceptExistingAsync(string friendshipId, string acceptorId)
    {
        var dto = new RespondFriendRequestDto { Accept = true };
        return await RespondAsync(acceptorId, friendshipId, dto);
    }

    /// <summary>Chắc chắn user tồn tại và đang active.</summary>
    private async Task EnsureUserExistsAsync(string uid)
    {
        var snapshot = await store.GetUserAsync(uid);
        if (snapshot is null)
            throw new AppException(ErrorCode.USER_NOT_FOUND);
        if (!snapshot.Status)
            throw new AppException(ErrorCode.USER_DISABLED);
    }

    /// <summary>
    /// Build map <c>friendId → lastMessageAt</c> từ private conversations của user hiện tại.
    /// </summary>
    private async Task<Dictionary<string, DateTime>> BuildFriendLastChatMapAsync(string userId)
    {
        var map = new Dictionary<string, DateTime>(StringComparer.Ordinal);
        var conversations = await store.GetPrivateConversationsForUserAsync(userId);
        foreach (var c in conversations)
        {
            var otherIds = c.ParticipantIds.Where(p => p != userId).ToList();
            if (otherIds.Count == 0) continue;
            foreach (var otherId in otherIds)
            {
                if (!map.TryGetValue(otherId, out var existing) || c.UpdatedAt > existing)
                {
                    map[otherId] = c.UpdatedAt;
                }
            }
        }
        return map;
    }

    /// <summary>Enrich danh sách bạn bè (đã sort/paginated) với tên/avatar và lastMessageAt.</summary>
    private async Task<List<FriendSummaryResponse>> EnrichWithUserDataAsync(
        List<(string FriendId, string FriendshipId, DateTime Since)> entries,
        Dictionary<string, DateTime>? lastChatByFriend = null)
    {
        if (entries.Count == 0) return [];

        var tasks = entries.Select(e => store.GetUserAsync(e.FriendId));
        var snapshots = await Task.WhenAll(tasks);
        var result = new List<FriendSummaryResponse>();

        for (int i = 0; i < entries.Count; i++)
        {
            var snap = snapshots[i];
            if (snap is null) continue;

            DateTime? lastMessageAt = null;
            if (lastChatByFriend != null &&
                lastChatByFriend.TryGetValue(entries[i].FriendId, out var at))
            {
                lastMessageAt = at;
            }
            result.Add(new FriendSummaryResponse
            {
                FriendshipId  = entries[i].FriendshipId,
                FriendId      = snap.Id,
                FirstName     = snap.FirstName,
                LastName      = snap.LastName,
                Avatar        = snap.Avatar,
                FriendsSince  = entries[i].Since,
                LastMessageAt = lastMessageAt,
            });
        }
        return result;
    }

    /// <summary>Enrich danh sách pending-received.</summary>
    private async Task<List<FriendshipResponse>> EnrichPendingReceivedAsync(
        string userId, List<Friendship> friendships)
    {
        var senderTasks = friendships.Select(f => store.GetUserAsync(f.SenderId)).ToList();
        var addresseeTasks = friendships.Select(f => store.GetUserAsync(f.AddresseeId)).ToList();

        var userSnaps = await Task.WhenAll(senderTasks.Concat(addresseeTasks));
        var result = new List<FriendshipResponse>();

        for (int i = 0; i < friendships.Count; i++)
        {
            var f = friendships[i];
            var senderSnap    = userSnaps[i];
            var addresseeSnap = userSnaps[friendships.Count + i];

            string senderName = senderSnap is null
                ? f.SenderId
                : $"{senderSnap.FirstName} {senderSnap.LastName}".Trim();
            string senderAvatar = senderSnap?.Avatar ?? "";
            string addresseeName = addresseeSnap is null
                ? ""
                : $"{addresseeSnap.FirstName} {addresseeSnap.LastName}".Trim();

            var resp = f.Adapt<FriendshipResponse>();
            resp.SenderName    = senderName;
            resp.SenderAvatar  = senderAvatar;
            resp.AddresseeName = addresseeName;
            result.Add(resp);
        }
        return result;
    }

    /// <summary>Enrich danh sách pending-sent.</summary>
    private async Task<List<FriendshipResponse>> EnrichPendingSentAsync(
        string userId, List<Friendship> friendships)
    {
        var addresseeTasks = friendships.Select(f => store.GetUserAsync(f.AddresseeId)).ToList();
        var addresseeSnaps = await Task.WhenAll(addresseeTasks);
        var result = new List<FriendshipResponse>();

        for (int i = 0; i < friendships.Count; i++)
        {
            var f = friendships[i];
            var snap = addresseeSnaps[i];
            string addresseeName = snap is null ? "" : $"{snap.FirstName} {snap.LastName}".Trim();

            var resp = f.Adapt<FriendshipResponse>();
            resp.AddresseeName = addresseeName;
            result.Add(resp);
        }
        return result;
    }

    private static (List<Friendship> Page, int Total) ApplyPage(
        IReadOnlyList<Friendship> alreadySortedDesc, int limit, int offset)
    {
        var total = alreadySortedDesc.Count;
        var page  = alreadySortedDesc.Skip(offset).Take(limit).ToList();
        return (page, total);
    }

    private static SuggestionResponse ToSuggestionResponse(UserSnapshot u) => new()
    {
        Id          = u.Id,
        FirstName   = u.FirstName,
        LastName    = u.LastName,
        FullName    = $"{u.FirstName} {u.LastName}".Trim(),
        Email       = u.Email,
        Avatar      = u.Avatar,
        MutualCount = null,
    };
}

