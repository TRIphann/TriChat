import { create } from 'zustand';
import { friendService } from '../services/friend.service';
import { createFriendConnection } from '../lib/signalr';

// Phân trang hợp nhất — bạn bè lấy 20/lần (infinite scroll),
// còn gợi ý / pending requests dùng nút "Xem thêm": lần đầu 3, các lần sau 10/lần.
export const FRIENDS_PAGE_SIZE = 20;
export const SUGGESTION_INITIAL_SIZE = 3;
export const SUGGESTION_PAGE_SIZE = 10;
export const REQUESTS_PAGE_SIZE = 10;

export const useFriendStore = create((set, get) => ({
  // ── Bạn bè (paginated, infinite-scroll) ────────────────────
  friends: [],
  friendsTotal: 0,
  friendsHasMore: false,
  friendsState: 'idle', // 'idle' | 'loading' | 'success' | 'error'

  // ── Lời mời nhận (paginated, nút Xem thêm 10/lần) ───────────
  pendingReceived: [],
  pendingReceivedTotal: 0,
  pendingReceivedHasMore: false,
  pendingReceivedState: 'idle',

  // ── Lời mời đã gửi (paginated, nút Xem thêm 10/lần) ──────────
  pendingSent: [],
  pendingSentTotal: 0,
  pendingSentHasMore: false,
  pendingSentState: 'idle',

  // ── Gợi ý kết bạn (paginated, nút Xem thêm 10/lần) ──────────
  suggestions: [],
  suggestionsTotal: 0,
  suggestionsHasMore: false,
  suggestionsState: 'idle', // 'idle' | 'loading' | 'success' | 'error'

  // ── Tìm kiếm người để kết bạn ───────────────────────────────
  searchResults: [],
  searchQuery: '',
  searchState: 'idle',

  connection: null,
  currentUid: null,

  async init(uid) {
    // Tránh re-init khi uid không đổi (giống chatStore.init)
    if (get().connection && get().currentUid === uid) return;
    set({ currentUid: uid });
    // Dispose connection cũ (nếu có) trước khi tạo cái mới — tránh leak khi đổi user
    if (get().connection) {
      try { await get().connection.stop(); } catch {}
      set({ connection: null });
    }
    await get().loadAll();
    const conn = createFriendConnection();

    conn.on('FriendRequestReceived', (fs) => {
      set((s) => ({
        // Tăng tổng + chèn vào đầu nếu chưa có trong page hiện tại
        pendingReceived: [fs, ...s.pendingReceived.filter((f) => f.id !== fs.id)],
        pendingReceivedTotal: s.pendingReceivedTotal + 1,
      }));
      window.dispatchEvent(new CustomEvent('trichat:friend-realtime', { detail: { type: 'received' } }));
    });
    conn.on('FriendRequestAccepted', (fs) => {
      const myId = get().currentUid;
      const friendId = myId === fs.addresseeId ? fs.senderId : fs.addresseeId;
      set((s) => ({
        pendingSent: s.pendingSent.filter((f) => f.id !== fs.id),
        pendingReceived: s.pendingReceived.filter((f) => f.id !== fs.id),
        friends: s.friends.some((f) => f.friendId === friendId)
          ? s.friends
          : [mapFriend(fs, myId), ...s.friends],
        friendsTotal: s.friendsTotal + 1,
      }));
      // Refresh suggestions (đã có bạn → sort theo mutualCount)
      get().loadSuggestions({ reset: true, limit: SUGGESTION_INITIAL_SIZE });
    });
    conn.on('FriendRequestDeclined', (fs) => {
      set((s) => ({
        pendingSent: s.pendingSent.filter((f) => f.id !== fs.id),
        pendingSentTotal: Math.max(0, s.pendingSentTotal - 1),
      }));
    });
    conn.on('FriendRequestCancelled', (fs) => {
      set((s) => ({
        pendingReceived: s.pendingReceived.filter((f) => f.id !== fs.id),
        pendingReceivedTotal: Math.max(0, s.pendingReceivedTotal - 1),
      }));
    });
    conn.on('FriendUnfriended', () => {
      // Reload page đầu của bạn bè để đảm bảo sort đúng
      get().loadFriendsPage({ reset: true });
    });

    try {
      await conn.start();
      set({ connection: conn });
    } catch (e) {
      console.warn('[friend] signalr connect failed:', e);
    }
  },

  async loadAll() {
    // Reset tất cả state về idle rồi load page đầu song song
    set({
      friendsState: 'loading',
      pendingReceivedState: 'loading',
      pendingSentState: 'loading',
    });
    await Promise.all([
      get().loadFriendsPage({ reset: true }),
      get().loadPendingReceivedPage({ reset: true, limit: REQUESTS_PAGE_SIZE }),
      get().loadPendingSentPage({ reset: true, limit: REQUESTS_PAGE_SIZE }),
    ]);
  },

  /**
   * Load page bạn bè theo offset (infinite scroll).
   * @param {object} opts
   * @param {boolean} opts.reset — true = thay thế page đầu.
   * @param {number}  opts.offset — vị trí bắt đầu. Mặc định = số item đang có.
   */
  async loadFriendsPage({ reset = true, limit = FRIENDS_PAGE_SIZE, offset } = {}) {
    if (offset == null) offset = reset ? 0 : get().friends.length;
    set({ friendsState: 'loading' });
    try {
      const page = await friendService.getFriends({ limit, offset });
      const items = page?.items ?? [];
      set((s) => ({
        friends: reset
          ? items
          : [...s.friends, ...items.filter((i) => !s.friends.some((f) => f.friendId === i.friendId))],
        friendsTotal: page?.total ?? 0,
        friendsHasMore: page?.hasMore ?? false,
        friendsState: 'success',
      }));
    } catch (e) {
      console.warn('[friend] loadFriendsPage failed:', e);
      set({ friendsState: 'error' });
    }
  },

  async loadPendingReceivedPage({ reset = true, limit = REQUESTS_PAGE_SIZE, offset } = {}) {
    if (offset == null) offset = reset ? 0 : get().pendingReceived.length;
    set({ pendingReceivedState: 'loading' });
    try {
      const page = await friendService.getPendingReceived({ limit, offset });
      const items = page?.items ?? [];
      set((s) => ({
        pendingReceived: reset
          ? items
          : [...s.pendingReceived, ...items.filter((i) => !s.pendingReceived.some((r) => r.id === i.id))],
        pendingReceivedTotal: page?.total ?? 0,
        pendingReceivedHasMore: page?.hasMore ?? false,
        pendingReceivedState: 'success',
      }));
    } catch (e) {
      console.warn('[friend] loadPendingReceivedPage failed:', e);
      set({ pendingReceivedState: 'error' });
    }
  },

  async loadPendingSentPage({ reset = true, limit = REQUESTS_PAGE_SIZE, offset } = {}) {
    if (offset == null) offset = reset ? 0 : get().pendingSent.length;
    set({ pendingSentState: 'loading' });
    try {
      const page = await friendService.getPendingSent({ limit, offset });
      const items = page?.items ?? [];
      set((s) => ({
        pendingSent: reset
          ? items
          : [...s.pendingSent, ...items.filter((i) => !s.pendingSent.some((r) => r.id === i.id))],
        pendingSentTotal: page?.total ?? 0,
        pendingSentHasMore: page?.hasMore ?? false,
        pendingSentState: 'success',
      }));
    } catch (e) {
      console.warn('[friend] loadPendingSentPage failed:', e);
      set({ pendingSentState: 'error' });
    }
  },

  /**
   * Load gợi ý kết bạn — nút "Xem thêm".
   * Component gọi:
   *   - Lần đầu:    loadSuggestions({ reset: true,  limit: SUGGESTION_INITIAL_SIZE })
   *   - Xem thêm:   loadSuggestions({ reset: false, limit: SUGGESTION_PAGE_SIZE })
   */
  async loadSuggestions({ reset = true, limit = SUGGESTION_PAGE_SIZE, offset } = {}) {
    if (offset == null) offset = reset ? 0 : get().suggestions.length;
    if (get().suggestionsState === 'loading') return;
    set({ suggestionsState: 'loading' });
    try {
      const page = await friendService.getSuggestions({ limit, offset });
      const items = page?.items ?? [];
      set((s) => ({
        suggestions: reset
          ? items
          : [...s.suggestions, ...items.filter((i) => !s.suggestions.some((u) => u.id === i.id))],
        suggestionsTotal: page?.total ?? 0,
        suggestionsHasMore: page?.hasMore ?? false,
        suggestionsState: 'success',
      }));
    } catch (e) {
      console.warn('[friend] loadSuggestions failed:', e);
      set({ suggestions: [], suggestionsState: 'error' });
    }
  },

  async search(keyword) {
    set({ searchQuery: keyword });
    if (!keyword || keyword.length < 2) {
      set({ searchResults: [], searchState: 'idle' });
      return;
    }
    set({ searchState: 'loading' });
    try {
      const list = await friendService.searchUsers(keyword);
      set({ searchResults: list || [], searchState: 'success' });
    } catch (e) {
      set({ searchState: 'error' });
    }
  },

  async sendRequest(userId) {
    const res = await friendService.sendRequest(userId);
    set((s) => ({
      pendingSent: [res, ...s.pendingSent.filter((f) => f.id !== res.id)],
      pendingSentTotal: s.pendingSentTotal + 1,
      suggestions: s.suggestions.filter((u) => u.id !== userId),
    }));
    return res;
  },

  async respond(friendshipId, accept) {
    const res = await friendService.respondRequest(friendshipId, accept);
    if (accept) {
      const myId = get().currentUid;
      const friend = mapFriend(res, myId);
      set((s) => ({
        pendingReceived: s.pendingReceived.filter((f) => f.id !== friendshipId),
        pendingReceivedTotal: Math.max(0, s.pendingReceivedTotal - 1),
        friends: [friend, ...s.friends.filter((f) => f.friendId !== friend.friendId)],
        friendsTotal: s.friendsTotal + 1,
      }));
      // Reload suggestions (đã có bạn → đổi chiến lược sort)
      get().loadSuggestions({ reset: true, limit: SUGGESTION_INITIAL_SIZE });
    } else {
      set((s) => ({
        pendingReceived: s.pendingReceived.filter((f) => f.id !== friendshipId),
        pendingReceivedTotal: Math.max(0, s.pendingReceivedTotal - 1),
      }));
    }
    return res;
  },

  async cancelRequest(friendshipId) {
    await friendService.cancelRequest(friendshipId);
    set((s) => {
      const cancelled = s.pendingSent.find((r) => r.id === friendshipId);
      const cancelledAddresseeId = cancelled?.addresseeId || cancelled?.addressee_id;
      // Trả lại user vào suggestions nếu còn thiếu bạn
      const newSuggestions = cancelled && s.friendsTotal === 0
        ? [
            {
              id: cancelledAddresseeId,
              first_name: '',
              last_name: '',
              full_name: cancelled.addresseeName || cancelled.addressee_name,
              email: '',
              avatar: cancelled.addresseeAvatar || cancelled.addressee_avatar,
              mutual_count: null,
            },
            ...s.suggestions,
          ]
        : s.suggestions;
      return {
        pendingSent: s.pendingSent.filter((f) => f.id !== friendshipId),
        pendingSentTotal: Math.max(0, s.pendingSentTotal - 1),
        suggestions: newSuggestions,
      };
    });
  },

  async unfriend(targetUserId) {
    await friendService.unfriend(targetUserId);
    set((s) => ({
      friends: s.friends.filter((f) => f.friendId !== targetUserId),
      friendsTotal: Math.max(0, s.friendsTotal - 1),
    }));
  },

  async block(targetUserId) {
    await friendService.block(targetUserId);
    await get().loadAll();
  },

  async unblock(targetUserId) {
    await friendService.unblock(targetUserId);
    await get().loadAll();
  },

  isFriend(userId) {
    return get().friends.some((f) => f.friendId === userId);
  },

  /**
   * Tìm request tôi đã GỬI tới userId.
   * pendingSent: senderId = tôi, addresseeId = user kia.
   * → Chỉ check addresseeId (đúng người nhận), bỏ check senderId (sẽ match sai với received).
   */
  getSentRequest(userId) {
    return get().pendingSent.find(
      (f) => (f.addresseeId || f.addressee_id) === userId,
    );
  },

  /**
   * Tìm request tôi đã NHẬN từ userId.
   * pendingReceived: senderId = user kia, addresseeId = tôi.
   * → Chỉ check senderId (đúng người gửi), bỏ check addresseeId (sẽ match sai với sent).
   */
  getReceivedRequest(userId) {
    return get().pendingReceived.find(
      (f) => (f.senderId || f.sender_id) === userId,
    );
  },

  async dispose() {
    try {
      await get().connection?.stop();
    } catch {}
    set({ connection: null, currentUid: null });
  },
}));

function mapFriend(res, myId) {
  // When we accept a request (we're addressee), the friend is senderId
  // When sender receives SignalR event, the friend is addresseeId
  let friendId, friendName, friendAvatar;
  
  if (myId && res.addresseeId === myId) {
    // We are the addressee → friend is sender
    friendId = res.senderId;
    friendName = res.senderName || '';
    friendAvatar = res.senderAvatar || '';
  } else {
    // We are the sender (or SignalR event) → friend is addressee
    friendId = res.addresseeId;
    friendName = res.addresseeName || '';
    friendAvatar = res.addresseeAvatar || '';
  }
  
  return {
    friendshipId: res.id,
    friendId,
    firstName: friendName.split(' ')[0] || '',
    lastName: friendName.split(' ').slice(1).join(' ') || '',
    avatar: friendAvatar,
    fullName: friendName,
    friendsSince: res.updatedAt || res.createdAt,
  };
}
