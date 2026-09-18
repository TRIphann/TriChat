using Xunit;
using backend.dtos.Request;
using backend.Enums;
using backend.Exceptions;
using backend.Models;
using backend.Services;
using Microsoft.Extensions.Logging;
using Moq;

namespace backend.Tests;

/// <summary>
/// Unit tests cho FriendshipService — dùng InMemoryFriendshipDataStore (không cần Firestore emulator).
///
/// Tests cover:
///  - Paginated friends list: sort by recent chat, fallback to friendsSince
///  - Suggestions: 0-friends (newest users, MutualCount=null) vs has-friends (mutual count DESC)
///  - Suggestions: exclude self, friends, pending requests
///  - Pending received/sent: pagination, sort by created_at DESC
/// </summary>
public class FriendshipServiceTests : IDisposable
{
    private readonly InMemoryFriendshipDataStore _store = new();
    private readonly Mock<ILogger<FriendshipService>> _logger = new();
    private readonly Microsoft.AspNetCore.SignalR.IHubContext<backend.Hubs.FriendHub> _hub;
    private readonly FriendshipService _svc;

    public FriendshipServiceTests()
    {
        // Fake HubContext — service chỉ gọi Clients.Group(name).SendCoreAsync(...)
        var clientProxy = new Moq.Mock<Microsoft.AspNetCore.SignalR.IClientProxy>();
        clientProxy.Setup(x => x.SendCoreAsync(
            Moq.It.IsAny<string>(),
            Moq.It.IsAny<object[]>(),
            Moq.It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var clients = new Moq.Mock<Microsoft.AspNetCore.SignalR.IHubClients>();
        clients.Setup(x => x.Group(Moq.It.IsAny<string>())).Returns(clientProxy.Object);

        var hubCtx = new Moq.Mock<Microsoft.AspNetCore.SignalR.IHubContext<backend.Hubs.FriendHub>>();
        hubCtx.Setup(x => x.Clients).Returns(clients.Object);

        _hub = hubCtx.Object;
        _svc = new FriendshipService(_store, _logger.Object, _hub);
    }

    public void Dispose() => _store.Clear();

    // ══════════════════════════════════════════════════════════════
    // HELPERS — tạo test data nhanh
    // ══════════════════════════════════════════════════════════════

    private void AddUser(string id, string firstName, string lastName, DateTime createdAt, bool status = true)
    {
        _store.AddUser(new UserSnapshot(id, firstName, lastName,
            $"{firstName.ToLower()}{lastName.ToLower()}@test.com", "", status, createdAt));
    }

    private void AddFriend(string a, string b, DateTime since)
    {
        var f = new Friendship
        {
            Id = Guid.NewGuid().ToString(),
            SenderId    = a,
            AddresseeId = b,
            Status      = "accepted",
            CreatedAt   = since,
            UpdatedAt   = since,
        };
        _store.AddFriendship(f);
    }

    private void AddPending(string from, string to, DateTime createdAt)
    {
        var f = new Friendship
        {
            Id = Guid.NewGuid().ToString(),
            SenderId    = from,
            AddresseeId = to,
            Status      = "pending",
            CreatedAt   = createdAt,
            UpdatedAt   = createdAt,
        };
        _store.AddFriendship(f);
    }

    private void AddConversation(string convId, string user1, string user2, DateTime updatedAt)
    {
        _store.AddConversation(new ConversationSnapshot(convId, "private",
            new List<string> { user1, user2 }, updatedAt));
    }

    // ══════════════════════════════════════════════════════════════
    // SECTION 1: GetFriendsPagedAsync — sort by recent chat
    // ══════════════════════════════════════════════════════════════

    [Fact]
    public async Task GetFriendsPagedAsync_Empty_ReturnsZeroTotal()
    {
        AddUser("u1", "Alice", "Smith", DateTime.UtcNow);
        AddUser("u2", "Bob", "Jones", DateTime.UtcNow);

        var (items, total) = await _svc.GetFriendsPagedAsync("u1", limit: 20, offset: 0);

        Assert.Empty(items);
        Assert.Equal(0, total);
    }

    [Fact]
    public async Task GetFriendsPagedAsync_TwoFriends_SortedByRecentChatFirst()
    {
        // u1 có 2 bạn: f1 và f2
        // f1: nhắn lần cuối 2024-01-01
        // f2: nhắn lần cuối 2024-06-01  (gần hơn → lên đầu)
        AddUser("me",  "Me",     "User", DateTime.UtcNow);
        AddUser("f1",  "Friend", "One",  DateTime.UtcNow);
        AddUser("f2",  "Friend", "Two",  DateTime.UtcNow);
        AddUser("old", "Old",     "Guy",  DateTime.UtcNow);

        AddFriend("me", "f1", new DateTime(2024, 1, 1)); // kết bạn trước nhưng chat sau
        AddFriend("me", "f2", new DateTime(2024, 1, 1)); // kết bạn cùng lúc

        AddConversation("c1", "me", "f1", new DateTime(2024, 1, 1)); // chat f1 lúc 2024-01-01
        AddConversation("c2", "me", "f2", new DateTime(2024, 6, 1)); // chat f2 lúc 2024-06-01 (gần hơn)

        var (items, total) = await _svc.GetFriendsPagedAsync("me", limit: 20, offset: 0);

        Assert.Equal(2, total);
        Assert.Equal(2, items.Count);
        Assert.Equal("f2", items[0].FriendId); // f2 nhắn gần nhất
        Assert.Equal("f1", items[1].FriendId);
    }

    [Fact]
    public async Task GetFriendsPagedAsync_NoConversations_FallbackToFriendsSince()
    {
        // Không có conversation → sort theo UpdatedAt (friendsSince)
        AddUser("me",  "Me",    "User", DateTime.UtcNow);
        AddUser("old", "Old",   "User", DateTime.UtcNow);
        AddUser("new", "New",   "User", DateTime.UtcNow);

        AddFriend("me", "old", new DateTime(2023, 1, 1)); // kết bạn lâu rồi
        AddFriend("me", "new", new DateTime(2024, 6, 1)); // kết bạn gần đây

        var (items, total) = await _svc.GetFriendsPagedAsync("me", limit: 20, offset: 0);

        Assert.Equal(2, total);
        Assert.Equal("new", items[0].FriendId); // kết bạn gần hơn → lên đầu (DESC)
        Assert.Equal("old", items[1].FriendId);
    }

    [Fact]
    public async Task GetFriendsPagedAsync_Pagination_ReturnsCorrectPage()
    {
        // Tạo 5 bạn: f1..f5, mỗi người chat ở thời điểm khác nhau
        AddUser("me", "Me", "User", DateTime.UtcNow);
        for (int i = 1; i <= 5; i++)
        {
            var fid = $"f{i}";
            AddUser(fid, $"F{i}", "Friend", DateTime.UtcNow);
            AddFriend("me", fid, DateTime.UtcNow.AddDays(-i));
            AddConversation($"c{i}", "me", fid, DateTime.UtcNow.AddDays(-i));
        }

        // Page 1: lấy 2
        var (page1, total1) = await _svc.GetFriendsPagedAsync("me", limit: 2, offset: 0);
        Assert.Equal(5, total1);
        Assert.Equal(2, page1.Count);
        Assert.True(page1.All(x => x.FriendId.StartsWith("f")));
        Assert.True(total1 > page1.Count); // HasMore

        // Page 2: lấy 2 tiếp
        var (page2, _) = await _svc.GetFriendsPagedAsync("me", limit: 2, offset: 2);
        Assert.Equal(2, page2.Count);

        // Page 3: lấy 1 cuối
        var (page3, _) = await _svc.GetFriendsPagedAsync("me", limit: 2, offset: 4);
        Assert.Single(page3);

        // Page 4 (vượt quá): lấy 0
        var (page4, _) = await _svc.GetFriendsPagedAsync("me", limit: 2, offset: 6);
        Assert.Empty(page4);
    }

    // ══════════════════════════════════════════════════════════════
    // SECTION 2: GetSuggestionsPagedAsync — chiến lược 0-friends
    // ══════════════════════════════════════════════════════════════

    [Fact]
    public async Task GetSuggestions_ZeroFriends_ReturnsNewestUsers_MutualCountNull()
    {
        // me chưa có bạn → gợi ý theo account mới nhất
        AddUser("me",  "Me",    "User", DateTime.UtcNow);
        AddUser("old", "Old",   "User", new DateTime(2020, 1, 1)); // tạo lâu
        AddUser("new", "New",   "User", DateTime.UtcNow);           // tạo gần đây

        var (items, total) = await _svc.GetSuggestionsPagedAsync("me", limit: 10, offset: 0);

        Assert.Equal(2, total);
        Assert.Equal(2, items.Count);
        Assert.Equal("new", items[0].Id);  // mới nhất lên đầu
        Assert.Equal("old", items[1].Id);
        Assert.All(items, x => Assert.Null(x.MutualCount));
    }

    [Fact]
    public async Task GetSuggestions_ZeroFriends_ExcludesSelf()
    {
        AddUser("me", "Me", "User", DateTime.UtcNow);
        AddUser("u1", "U1", "User", DateTime.UtcNow);

        var (items, total) = await _svc.GetSuggestionsPagedAsync("me", limit: 10, offset: 0);

        Assert.Single(items);
        Assert.Equal("u1", items[0].Id);
        Assert.DoesNotContain(items, x => x.Id == "me");
    }

    // ══════════════════════════════════════════════════════════════
    // SECTION 3: GetSuggestionsPagedAsync — chiến lược có-friends
    // ══════════════════════════════════════════════════════════════

    [Fact]
    public async Task GetSuggestions_HasFriends_ReturnsByMutualCountDesc()
    {
        // me có bạn: f1, f2
        // candidate c1 có 2 bạn chung với me (f1, f2)
        // candidate c2 có 0 bạn chung
        // → c1 phải lên đầu
        AddUser("me",  "Me",  "User", DateTime.UtcNow);
        AddUser("f1",  "F1",  "User", DateTime.UtcNow);
        AddUser("f2",  "F2",  "User", DateTime.UtcNow);
        AddUser("c1",  "C1",  "User", DateTime.UtcNow);
        AddUser("c2",  "C2",  "User", DateTime.UtcNow);

        // me kết bạn với f1, f2
        AddFriend("me", "f1", DateTime.UtcNow);
        AddFriend("me", "f2", DateTime.UtcNow);

        // c1 kết bạn với f1, f2 (2 bạn chung)
        AddFriend("c1", "f1", DateTime.UtcNow);
        AddFriend("c1", "f2", DateTime.UtcNow);

        // c2 kết bạn với ai đó khác (0 bạn chung với me)
        AddFriend("c2", "f1", DateTime.UtcNow);

        var (items, total) = await _svc.GetSuggestionsPagedAsync("me", limit: 10, offset: 0);

        Assert.Equal(2, total);
        Assert.Equal("c1", items[0].Id); // 2 bạn chung → lên đầu
        Assert.Equal("c2", items[1].Id); // 1 bạn chung
        Assert.Equal(2, items[0].MutualCount);
        Assert.Equal(1, items[1].MutualCount);
    }

    [Fact]
    public async Task GetSuggestions_ExcludesExistingFriends()
    {
        AddUser("me",  "Me",  "User", DateTime.UtcNow);
        AddUser("f1",  "F1",  "User", DateTime.UtcNow);
        AddUser("cand","Cand","User", DateTime.UtcNow);

        AddFriend("me", "f1", DateTime.UtcNow); // f1 đã là bạn

        var (items, _) = await _svc.GetSuggestionsPagedAsync("me", limit: 10, offset: 0);

        Assert.Single(items);
        Assert.Equal("cand", items[0].Id);
        Assert.DoesNotContain(items, x => x.Id == "f1");
    }

    [Fact]
    public async Task GetSuggestions_ExcludesPendingSent()
    {
        // me đã gửi lời mời cho cand → cand không hiện trong suggestions
        AddUser("me",  "Me",   "User", DateTime.UtcNow);
        AddUser("cand","Cand", "User", DateTime.UtcNow);

        AddPending("me", "cand", DateTime.UtcNow);

        var (items, _) = await _svc.GetSuggestionsPagedAsync("me", limit: 10, offset: 0);

        Assert.Empty(items); // cand đang pending (đã gửi)
    }

    [Fact]
    public async Task GetSuggestions_ExcludesPendingReceived()
    {
        // cand đã gửi lời mời cho me → cand không hiện trong suggestions
        AddUser("me",  "Me",   "User", DateTime.UtcNow);
        AddUser("cand","Cand", "User", DateTime.UtcNow);

        AddPending("cand", "me", DateTime.UtcNow);

        var (items, _) = await _svc.GetSuggestionsPagedAsync("me", limit: 10, offset: 0);

        Assert.Empty(items); // cand đang pending (đã nhận)
    }

    [Fact]
    public async Task GetSuggestions_Pagination_RespectsLimitOffset()
    {
        AddUser("me", "Me", "User", DateTime.UtcNow);
        for (int i = 1; i <= 15; i++)
            AddUser($"u{i}", $"U{i}", "User", DateTime.UtcNow.AddMinutes(-i));

        var (page1, total) = await _svc.GetSuggestionsPagedAsync("me", limit: 5, offset: 0);
        Assert.Equal(15, total);
        Assert.Equal(5, page1.Count);
        Assert.True(total > page1.Count); // HasMore

        var (page2, _) = await _svc.GetSuggestionsPagedAsync("me", limit: 5, offset: 5);
        Assert.Equal(5, page2.Count);

        var (page3, _) = await _svc.GetSuggestionsPagedAsync("me", limit: 5, offset: 10);
        Assert.Equal(5, page3.Count);

        var (page4, _) = await _svc.GetSuggestionsPagedAsync("me", limit: 5, offset: 15);
        Assert.Empty(page4); // vượt quá
    }

    // ══════════════════════════════════════════════════════════════
    // SECTION 4: GetPendingReceivedPagedAsync
    // ══════════════════════════════════════════════════════════════

    [Fact]
    public async Task GetPendingReceived_Empty_ReturnsZeroTotal()
    {
        AddUser("me", "Me", "User", DateTime.UtcNow);
        AddUser("u1", "U1", "User", DateTime.UtcNow);

        var (items, total) = await _svc.GetPendingReceivedPagedAsync("me", limit: 10, offset: 0);

        Assert.Empty(items);
        Assert.Equal(0, total);
    }

    [Fact]
    public async Task GetPendingReceived_SortedByCreatedAtDesc_NewestFirst()
    {
        AddUser("me",  "Me",  "User", DateTime.UtcNow);
        AddUser("old", "Old", "User", DateTime.UtcNow);
        AddUser("new", "New", "User", DateTime.UtcNow);

        // old gửi trước, new gửi sau
        AddPending("old", "me", new DateTime(2024, 1, 1));
        AddPending("new", "me", new DateTime(2024, 6, 1));

        var (items, total) = await _svc.GetPendingReceivedPagedAsync("me", limit: 10, offset: 0);

        Assert.Equal(2, total);
        Assert.Equal("new", items[0].SenderId); // mới nhất lên đầu
        Assert.Equal("old", items[1].SenderId);
    }

    [Fact]
    public async Task GetPendingReceived_Pagination_RespectsLimitOffset()
    {
        AddUser("me", "Me", "User", DateTime.UtcNow);
        for (int i = 1; i <= 5; i++)
        {
            AddUser($"u{i}", $"U{i}", "User", DateTime.UtcNow.AddMinutes(-i));
            AddPending($"u{i}", "me", DateTime.UtcNow.AddMinutes(-i));
        }

        var (page1, total) = await _svc.GetPendingReceivedPagedAsync("me", limit: 2, offset: 0);
        Assert.Equal(5, total);
        Assert.Equal(2, page1.Count);

        var (page2, _) = await _svc.GetPendingReceivedPagedAsync("me", limit: 2, offset: 2);
        Assert.Equal(2, page2.Count);

        var (page3, _) = await _svc.GetPendingReceivedPagedAsync("me", limit: 2, offset: 4);
        Assert.Single(page3);
    }

    [Fact]
    public async Task GetPendingReceived_EnrichesSenderNameAndAvatar()
    {
        AddUser("me",  "Me",  "User", DateTime.UtcNow);
        AddUser("req", "Req", "User", DateTime.UtcNow);

        AddPending("req", "me", DateTime.UtcNow);

        var (items, _) = await _svc.GetPendingReceivedPagedAsync("me", limit: 10, offset: 0);

        Assert.Single(items);
        Assert.Equal("Req User", items[0].SenderName);
    }

    // ══════════════════════════════════════════════════════════════
    // SECTION 5: GetPendingSentPagedAsync
    // ══════════════════════════════════════════════════════════════

    [Fact]
    public async Task GetPendingSent_SortedByCreatedAtDesc_NewestFirst()
    {
        AddUser("me",  "Me",  "User", DateTime.UtcNow);
        AddUser("old", "Old", "User", DateTime.UtcNow);
        AddUser("new", "New", "User", DateTime.UtcNow);

        AddPending("me", "old", new DateTime(2024, 1, 1));
        AddPending("me", "new", new DateTime(2024, 6, 1));

        var (items, total) = await _svc.GetPendingSentPagedAsync("me", limit: 10, offset: 0);

        Assert.Equal(2, total);
        Assert.Equal("new", items[0].AddresseeId);
        Assert.Equal("old", items[1].AddresseeId);
    }

    [Fact]
    public async Task GetPendingSent_Pagination_RespectsLimitOffset()
    {
        AddUser("me", "Me", "User", DateTime.UtcNow);
        for (int i = 1; i <= 5; i++)
        {
            AddUser($"u{i}", $"U{i}", "User", DateTime.UtcNow.AddMinutes(-i));
            AddPending("me", $"u{i}", DateTime.UtcNow.AddMinutes(-i));
        }

        var (page1, total) = await _svc.GetPendingSentPagedAsync("me", limit: 2, offset: 0);
        Assert.Equal(5, total);
        Assert.Equal(2, page1.Count);

        var (page2, _) = await _svc.GetPendingSentPagedAsync("me", limit: 2, offset: 2);
        Assert.Equal(2, page2.Count);

        var (page3, _) = await _svc.GetPendingSentPagedAsync("me", limit: 2, offset: 4);
        Assert.Single(page3);
    }

    [Fact]
    public async Task GetPendingSent_EnrichesAddresseeName()
    {
        AddUser("me",  "Me",  "User", DateTime.UtcNow);
        AddUser("to",  "To",  "User", DateTime.UtcNow);

        AddPending("me", "to", DateTime.UtcNow);

        var (items, _) = await _svc.GetPendingSentPagedAsync("me", limit: 10, offset: 0);

        Assert.Single(items);
        Assert.Equal("To User", items[0].AddresseeName);
    }

    // ══════════════════════════════════════════════════════════════
    // SECTION 6: Edge cases
    // ══════════════════════════════════════════════════════════════

    [Fact]
    public async Task GetFriendsPagedAsync_ExcludeDeletedUsers()
    {
        // f1 là user bị xóa (không có trong _users)
        AddUser("me", "Me", "User", DateTime.UtcNow);
        AddUser("f2", "F2", "User", DateTime.UtcNow);

        AddFriend("me", "f1_ghost", DateTime.UtcNow); // f1 đã xóa account
        AddFriend("me", "f2", DateTime.UtcNow);

        var (items, total) = await _svc.GetFriendsPagedAsync("me", limit: 20, offset: 0);

        // Chỉ f2 còn (f1 đã bị xóa khỏi users collection → bị bỏ qua trong Enrich)
        Assert.Single(items);
        Assert.Equal("f2", items[0].FriendId);
    }

    [Fact]
    public async Task GetSuggestions_DisabledUsers_Excluded()
    {
        // cand bị disabled (status=false) → không hiện trong suggestions
        AddUser("me",   "Me",    "User", DateTime.UtcNow, status: true);
        AddUser("cand", "Cand",  "User", DateTime.UtcNow, status: false);

        var (items, _) = await _svc.GetSuggestionsPagedAsync("me", limit: 10, offset: 0);

        Assert.Empty(items);
    }

    // ══════════════════════════════════════════════════════════════
    // SECTION 7: SendRequestAsync — business rules
    // ══════════════════════════════════════════════════════════════

    [Fact]
    public async Task SendRequest_SelfRequest_ThrowsCannotSelfFriend()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            _svc.SendRequestAsync("alice", new SendFriendRequestDto { AddresseeId = "alice" }));

        Assert.Equal(ErrorCode.CANNOT_SELF_FRIEND, ex.ErrorCode);
    }

    [Fact]
    public async Task SendRequest_NonExistentUser_ThrowsUserNotFound()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            _svc.SendRequestAsync("alice", new SendFriendRequestDto { AddresseeId = "ghost" }));

        Assert.Equal(ErrorCode.USER_NOT_FOUND, ex.ErrorCode);
    }

    [Fact]
    public async Task SendRequest_AlreadyFriends_ThrowsAlreadyFriends()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        AddFriend("alice", "bob", DateTime.UtcNow);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            _svc.SendRequestAsync("alice", new SendFriendRequestDto { AddresseeId = "bob" }));

        Assert.Equal(ErrorCode.ALREADY_FRIENDS, ex.ErrorCode);
    }

    [Fact]
    public async Task SendRequest_PendingSent_ThrowsAlreadySent()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        AddPending("alice", "bob", DateTime.UtcNow);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            _svc.SendRequestAsync("alice", new SendFriendRequestDto { AddresseeId = "bob" }));

        Assert.Equal(ErrorCode.FRIEND_REQUEST_ALREADY_SENT, ex.ErrorCode);
    }

    [Fact]
    public async Task SendRequest_PendingReceived_AutoAccepts()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        AddPending("bob", "alice", DateTime.UtcNow); // bob → alice pending

        // alice gửi lại bob → tự động accept
        var result = await _svc.SendRequestAsync("alice", new SendFriendRequestDto { AddresseeId = "bob" });

        Assert.Equal("accepted", result.Status);
    }

    [Fact]
    public async Task SendRequest_YouBlockedUser_ThrowsYouBlockedUser()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        _store.AddFriendship(new Friendship
        {
            Id = Guid.NewGuid().ToString(),
            SenderId = "alice",
            AddresseeId = "bob",
            Status = "blocked",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            _svc.SendRequestAsync("alice", new SendFriendRequestDto { AddresseeId = "bob" }));

        Assert.Equal(ErrorCode.YOU_BLOCKED_USER, ex.ErrorCode);
    }

    [Fact]
    public async Task SendRequest_BlockedByUser_ThrowsBlockedByUser()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        _store.AddFriendship(new Friendship
        {
            Id = Guid.NewGuid().ToString(),
            SenderId = "bob",
            AddresseeId = "alice",
            Status = "blocked",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            _svc.SendRequestAsync("alice", new SendFriendRequestDto { AddresseeId = "bob" }));

        Assert.Equal(ErrorCode.BLOCKED_BY_USER, ex.ErrorCode);
    }

    [Fact]
    public async Task SendRequest_DeclinedBefore_DeletesOldAndCreatesNew()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        var oldId = Guid.NewGuid().ToString();
        _store.AddFriendship(new Friendship
        {
            Id = oldId,
            SenderId = "alice",
            AddresseeId = "bob",
            Status = "declined",
            CreatedAt = DateTime.UtcNow.AddDays(-1),
            UpdatedAt = DateTime.UtcNow.AddDays(-1)
        });

        var result = await _svc.SendRequestAsync("alice", new SendFriendRequestDto { AddresseeId = "bob" });

        Assert.Equal("pending", result.Status);
        Assert.NotEqual(oldId, result.Id);
        Assert.Null(await _store.GetFriendshipByIdAsync(oldId));
    }

    [Fact]
    public async Task SendRequest_Success_CreatesPendingDoc()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);

        var result = await _svc.SendRequestAsync("alice", new SendFriendRequestDto { AddresseeId = "bob", SourceType = "search" });

        Assert.Equal("pending", result.Status);
        Assert.Equal("alice", result.SenderId);
        Assert.Equal("bob", result.AddresseeId);
        Assert.Equal("search", result.SourceType);
    }

    // ══════════════════════════════════════════════════════════════
    // SECTION 8: RespondAsync — accept/decline
    // ══════════════════════════════════════════════════════════════

    [Fact]
    public async Task Respond_Accept_UpdatesStatusToAccepted()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        var reqId = Guid.NewGuid().ToString();
        _store.AddFriendship(new Friendship
        {
            Id = reqId,
            SenderId = "alice",
            AddresseeId = "bob",
            Status = "pending",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        var result = await _svc.RespondAsync("bob", reqId, new RespondFriendRequestDto { Accept = true });

        Assert.Equal("accepted", result.Status);
        var stored = await _store.GetFriendshipByIdAsync(reqId);
        Assert.Equal("accepted", stored!.Status);
    }

    [Fact]
    public async Task Respond_Decline_UpdatesStatusToDeclined()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        var reqId = Guid.NewGuid().ToString();
        _store.AddFriendship(new Friendship
        {
            Id = reqId,
            SenderId = "alice",
            AddresseeId = "bob",
            Status = "pending",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        var result = await _svc.RespondAsync("bob", reqId, new RespondFriendRequestDto { Accept = false });

        Assert.Equal("declined", result.Status);
    }

    [Fact]
    public async Task Respond_NotRecipient_ThrowsNotRecipient()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        var reqId = Guid.NewGuid().ToString();
        _store.AddFriendship(new Friendship
        {
            Id = reqId,
            SenderId = "alice",
            AddresseeId = "bob",
            Status = "pending",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            _svc.RespondAsync("alice", reqId, new RespondFriendRequestDto { Accept = true }));

        Assert.Equal(ErrorCode.NOT_REQUEST_RECIPIENT, ex.ErrorCode);
    }

    [Fact]
    public async Task Respond_AlreadyAccepted_ThrowsRequestNotPending()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        var reqId = Guid.NewGuid().ToString();
        _store.AddFriendship(new Friendship
        {
            Id = reqId,
            SenderId = "alice",
            AddresseeId = "bob",
            Status = "accepted",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            _svc.RespondAsync("bob", reqId, new RespondFriendRequestDto { Accept = true }));

        Assert.Equal(ErrorCode.REQUEST_NOT_PENDING, ex.ErrorCode);
    }

    // ══════════════════════════════════════════════════════════════
    // SECTION 9: CancelRequestAsync & UnfriendAsync
    // ══════════════════════════════════════════════════════════════

    [Fact]
    public async Task Cancel_Success_DeletesDoc()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        var reqId = Guid.NewGuid().ToString();
        _store.AddFriendship(new Friendship
        {
            Id = reqId,
            SenderId = "alice",
            AddresseeId = "bob",
            Status = "pending",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        await _svc.CancelRequestAsync("alice", reqId);

        Assert.Null(await _store.GetFriendshipByIdAsync(reqId));
    }

    [Fact]
    public async Task Cancel_NotSender_ThrowsNotSender()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        var reqId = Guid.NewGuid().ToString();
        _store.AddFriendship(new Friendship
        {
            Id = reqId,
            SenderId = "alice",
            AddresseeId = "bob",
            Status = "pending",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            _svc.CancelRequestAsync("bob", reqId));

        Assert.Equal(ErrorCode.NOT_REQUEST_SENDER, ex.ErrorCode);
    }

    [Fact]
    public async Task Unfriend_Success_DeletesAcceptedDoc()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        var friendId = Guid.NewGuid().ToString();
        _store.AddFriendship(new Friendship
        {
            Id = friendId,
            SenderId = "alice",
            AddresseeId = "bob",
            Status = "accepted",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        await _svc.UnfriendAsync("alice", "bob");

        Assert.Null(await _store.GetFriendshipByIdAsync(friendId));
    }

    [Fact]
    public async Task Unfriend_NotFriends_ThrowsAlreadyFriends()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            _svc.UnfriendAsync("alice", "bob"));

        Assert.Equal(ErrorCode.ALREADY_FRIENDS, ex.ErrorCode);
    }

    // ══════════════════════════════════════════════════════════════
    // SECTION 10: BlockAsync & UnblockAsync
    // ══════════════════════════════════════════════════════════════

    [Fact]
    public async Task Block_Success_CreatesBlockedDoc()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);

        var result = await _svc.BlockAsync("alice", "bob");

        Assert.Equal("blocked", result.Status);
        Assert.Equal("alice", result.SenderId);
        Assert.Equal("bob", result.AddresseeId);
    }

    [Fact]
    public async Task Block_AlreadyBlocked_ThrowsAlreadyBlocked()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        _store.AddFriendship(new Friendship
        {
            Id = Guid.NewGuid().ToString(),
            SenderId = "alice",
            AddresseeId = "bob",
            Status = "blocked",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            _svc.BlockAsync("alice", "bob"));

        Assert.Equal(ErrorCode.ALREADY_BLOCKED, ex.ErrorCode);
    }

    [Fact]
    public async Task Block_ExistingFriendship_UpdatesToBlocked()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        var docId = Guid.NewGuid().ToString();
        _store.AddFriendship(new Friendship
        {
            Id = docId,
            SenderId = "alice",
            AddresseeId = "bob",
            Status = "accepted",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        var result = await _svc.BlockAsync("alice", "bob");

        Assert.Equal("blocked", result.Status);
        var stored = await _store.GetFriendshipByIdAsync(docId);
        Assert.Equal("blocked", stored!.Status);
    }

    [Fact]
    public async Task Block_Self_ThrowsCannotSelfBlock()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            _svc.BlockAsync("alice", "alice"));

        Assert.Equal(ErrorCode.CANNOT_SELF_BLOCK, ex.ErrorCode);
    }

    [Fact]
    public async Task Unblock_Success_DeletesBlockedDoc()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        var blockId = Guid.NewGuid().ToString();
        _store.AddFriendship(new Friendship
        {
            Id = blockId,
            SenderId = "alice",
            AddresseeId = "bob",
            Status = "blocked",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        await _svc.UnblockAsync("alice", "bob");

        Assert.Null(await _store.GetFriendshipByIdAsync(blockId));
    }

    [Fact]
    public async Task Unblock_NotBlocked_ThrowsNotFound()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            _svc.UnblockAsync("alice", "bob"));

        Assert.Equal(ErrorCode.FRIEND_REQUEST_NOT_FOUND, ex.ErrorCode);
    }

    [Fact]
    public async Task Unblock_NotBlocker_ThrowsForbidden()
    {
        AddUser("alice", "Alice", "W", DateTime.UtcNow);
        AddUser("bob", "Bob", "J", DateTime.UtcNow);
        var blockId = Guid.NewGuid().ToString();
        _store.AddFriendship(new Friendship
        {
            Id = blockId,
            SenderId = "alice",
            AddresseeId = "bob",
            Status = "blocked",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            _svc.UnblockAsync("bob", "alice"));

        Assert.Equal(ErrorCode.FORBIDDEN, ex.ErrorCode);
    }
}
