import { create } from 'zustand';
import { friendService } from '../services/friend.service';
import { createFriendConnection } from '../lib/signalr';
import { useAuthStore } from './authStore';

export const useFriendStore = create((set, get) => ({
  friends: [],
  pendingReceived: [],
  pendingSent: [],
  searchResults: [],
  searchQuery: '',

  // Gợi ý kết bạn — user chưa có bạn sẽ thấy danh sách này
  suggestions: [],
  suggestionsState: 'idle', // 'idle' | 'loading' | 'success' | 'error'

  friendsState: 'idle',
  requestsState: 'idle',
  searchState: 'idle',

  connection: null,

  async init(uid) {
    if (get().connection) return;
    await get().loadAll();
    const conn = createFriendConnection();

    conn.on('FriendRequestReceived', (fs) => {
      set((s) => ({
        pendingReceived: [fs, ...s.pendingReceived.filter((f) => f.id !== fs.id)],
      }));
      window.dispatchEvent(new CustomEvent('trichat:friend-realtime', { detail: { type: 'received' } }));
    });
    conn.on('FriendRequestAccepted', (fs) => {
      set((s) => ({
        pendingSent: s.pendingSent.filter((f) => f.id !== fs.id),
        pendingReceived: s.pendingReceived.filter((f) => f.id !== fs.id),
        friends: s.friends.some((f) => f.friendId === (fs.addresseeId || fs.senderId))
          ? s.friends
          : [mapFriend(fs), ...s.friends],
      }));
    });
    conn.on('FriendRequestDeclined', (fs) => {
      set((s) => ({
        pendingSent: s.pendingSent.filter((f) => f.id !== fs.id),
      }));
    });
    conn.on('FriendRequestCancelled', (fs) => {
      set((s) => ({
        pendingReceived: s.pendingReceived.filter((f) => f.id !== fs.id),
      }));
    });
    conn.on('FriendUnfriended', () => {
      get().loadAll();
    });

    try {
      await conn.start();
      set({ connection: conn });
    } catch (e) {
      console.warn('[friend] signalr connect failed:', e);
    }
  },

  async loadAll() {
    set({ friendsState: 'loading', requestsState: 'loading' });
    try {
      const [friends, received, sent] = await Promise.all([
        friendService.getFriends(),
        friendService.getPendingReceived(),
        friendService.getPendingSent(),
      ]);
      set({
        friends: friends || [],
        pendingReceived: received || [],
        pendingSent: sent || [],
        friendsState: 'success',
        requestsState: 'success',
      });
      // Khi load xong, nếu chưa có bạn thì tải luôn gợi ý
      if (!friends || friends.length === 0) {
        get().loadSuggestions();
      }
    } catch (e) {
      set({ friendsState: 'error', requestsState: 'error' });
    }
  },

  /**
   * Lấy gợi ý kết bạn — gọi GET /api/user rồi lọc trừ current user + đã là bạn + đang pending.
   * Chỉ chạy khi user chưa có bạn để tránh tải thừa.
   */
  async loadSuggestions() {
    if (get().suggestionsState === 'loading') return;
    set({ suggestionsState: 'loading' });
    try {
      const all = await friendService.discoverUsers();
      const myUid = useAuthStore.getState().user?.uid;
      const friendIds = new Set(get().friends.map((f) => f.friendId));
      const pendingIds = new Set([
        ...get().pendingSent.map((r) => r.addresseeId),
        ...get().pendingReceived.map((r) => r.senderId),
      ]);
      const filtered = (all || [])
        .filter((u) => u.id !== myUid)
        .filter((u) => !friendIds.has(u.id))
        .filter((u) => !pendingIds.has(u.id))
        .slice(0, 8);
      set({ suggestions: filtered, suggestionsState: 'success' });
    } catch (e) {
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
      suggestions: s.suggestions.filter((u) => u.id !== userId),
    }));
    return res;
  },

  async respond(friendshipId, accept) {
    const res = await friendService.respondRequest(friendshipId, accept);
    if (accept) {
      const friend = mapFriend(res);
      set((s) => ({
        pendingReceived: s.pendingReceived.filter((f) => f.id !== friendshipId),
        friends: [friend, ...s.friends.filter((f) => f.friendId !== friend.friendId)],
        // Sau khi đã có bạn thì không cần suggestions nữa
        suggestions: [],
        suggestionsState: 'idle',
      }));
    } else {
      set((s) => ({
        pendingReceived: s.pendingReceived.filter((f) => f.id !== friendshipId),
      }));
    }
    return res;
  },

  async cancelRequest(friendshipId) {
    await friendService.cancelRequest(friendshipId);
    set((s) => {
      const cancelled = s.pendingSent.find((r) => r.id === friendshipId);
      return {
        pendingSent: s.pendingSent.filter((f) => f.id !== friendshipId),
        // Trả lại user vào suggestions nếu còn thiếu bạn
        suggestions: cancelled && s.friends.length === 0
          ? [{ id: cancelled.addresseeId, fullName: cancelled.addresseeName, avatar: cancelled.addresseeAvatar }, ...s.suggestions]
          : s.suggestions,
      };
    });
  },

  async unfriend(targetUserId) {
    await friendService.unfriend(targetUserId);
    set((s) => ({ friends: s.friends.filter((f) => f.friendId !== targetUserId) }));
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

  getSentRequest(userId) {
    return get().pendingSent.find(
      (f) => f.senderId === userId || f.addresseeId === userId,
    );
  },

  getReceivedRequest(userId) {
    return get().pendingReceived.find(
      (f) => f.senderId === userId || f.addresseeId === userId,
    );
  },

  async dispose() {
    try {
      await get().connection?.stop();
    } catch {}
    set({ connection: null });
  },
}));

function mapFriend(res) {
  return {
    friendshipId: res.id,
    friendId: res.addresseeId || res.senderId,
    firstName: (res.addresseeName || res.senderName || '').split(' ')[0] || '',
    lastName: (res.addresseeName || res.senderName || '').split(' ').slice(1).join(' ') || '',
    avatar: res.senderAvatar || '',
    fullName: res.addresseeName || res.senderName || '',
    friendsSince: res.updatedAt || res.createdAt,
  };
}
