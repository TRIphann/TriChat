import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useFriendStore, FRIENDS_PAGE_SIZE, SUGGESTION_INITIAL_SIZE, SUGGESTION_PAGE_SIZE, REQUESTS_PAGE_SIZE } from '@/store/friendStore';
import { friendService } from '@/services/friend.service';

// Mock the friend service — factory only, no closure over outer vars.
vi.mock('@/services/friend.service', () => ({
  friendService: {
    getFriends: vi.fn(),
    getPendingReceived: vi.fn(),
    getPendingSent: vi.fn(),
    getSuggestions: vi.fn(),
    searchUsers: vi.fn(),
    sendRequest: vi.fn(),
    respondRequest: vi.fn(),
    cancelRequest: vi.fn(),
    unfriend: vi.fn(),
    block: vi.fn(),
    unblock: vi.fn(),
  },
}));

// Mock signalr connection creation — avoid real websocket attempts in init()
vi.mock('@/lib/signalr', () => ({
  createFriendConnection: vi.fn(() => ({
    on: vi.fn(),
    start: vi.fn().mockResolvedValue(undefined),
    stop: vi.fn().mockResolvedValue(undefined),
  })),
}));

function resetStore() {
  useFriendStore.setState({
    friends: [],
    friendsTotal: 0,
    friendsHasMore: false,
    friendsState: 'idle',
    pendingReceived: [],
    pendingReceivedTotal: 0,
    pendingReceivedHasMore: false,
    pendingReceivedState: 'idle',
    pendingSent: [],
    pendingSentTotal: 0,
    pendingSentHasMore: false,
    pendingSentState: 'idle',
    suggestions: [],
    suggestionsTotal: 0,
    suggestionsHasMore: false,
    suggestionsState: 'idle',
    searchResults: [],
    searchQuery: '',
    searchState: 'idle',
    connection: null,
    currentUid: null,
  });
}

describe('useFriendStore', () => {
  beforeEach(() => {
    resetStore();
    vi.clearAllMocks();
  });

  // ═══════════════════════════════════════════════════════════
  // loadFriendsPage — pagination (infinite scroll, 20/page)
  // ═══════════════════════════════════════════════════════════
  describe('loadFriendsPage', () => {
    it('loads first page and replaces friends on reset:true', async () => {
      friendService.getFriends.mockResolvedValue({
        items: [{ friendId: 'u1', fullName: 'Alice' }],
        total: 1,
        hasMore: false,
      });

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.loadFriendsPage({ reset: true });
      });

      expect(friendService.getFriends).toHaveBeenCalledWith({ limit: FRIENDS_PAGE_SIZE, offset: 0 });
      expect(result.current.friends).toHaveLength(1);
      expect(result.current.friendsTotal).toBe(1);
      expect(result.current.friendsHasMore).toBe(false);
      expect(result.current.friendsState).toBe('success');
    });

    it('appends unique items and computes offset from current length when reset:false', async () => {
      useFriendStore.setState({ friends: [{ friendId: 'u1' }, { friendId: 'u2' }] });
      friendService.getFriends.mockResolvedValue({
        items: [{ friendId: 'u3' }],
        total: 3,
        hasMore: false,
      });

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.loadFriendsPage({ reset: false });
      });

      expect(friendService.getFriends).toHaveBeenCalledWith({ limit: FRIENDS_PAGE_SIZE, offset: 2 });
      expect(result.current.friends.map((f) => f.friendId)).toEqual(['u1', 'u2', 'u3']);
    });

    it('deduplicates items already present when appending', async () => {
      useFriendStore.setState({ friends: [{ friendId: 'u1' }] });
      friendService.getFriends.mockResolvedValue({
        items: [{ friendId: 'u1' }, { friendId: 'u2' }],
        total: 2,
        hasMore: false,
      });

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.loadFriendsPage({ reset: false });
      });

      expect(result.current.friends.map((f) => f.friendId)).toEqual(['u1', 'u2']);
    });

    it('sets friendsState to error and keeps prior list on failure', async () => {
      useFriendStore.setState({ friends: [{ friendId: 'existing' }] });
      friendService.getFriends.mockRejectedValue(new Error('network down'));

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.loadFriendsPage({ reset: true });
      });

      expect(result.current.friendsState).toBe('error');
      // store doesn't clear friends on error — only marks error state
      expect(result.current.friends).toEqual([{ friendId: 'existing' }]);
    });

    it('respects an explicit offset override', async () => {
      friendService.getFriends.mockResolvedValue({ items: [], total: 0, hasMore: false });
      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.loadFriendsPage({ reset: false, offset: 40 });
      });
      expect(friendService.getFriends).toHaveBeenCalledWith({ limit: FRIENDS_PAGE_SIZE, offset: 40 });
    });
  });

  // ═══════════════════════════════════════════════════════════
  // loadPendingReceivedPage / loadPendingSentPage — "Xem thêm" pagination
  // ═══════════════════════════════════════════════════════════
  describe('loadPendingReceivedPage', () => {
    it('loads first page with REQUESTS_PAGE_SIZE default', async () => {
      friendService.getPendingReceived.mockResolvedValue({
        items: [{ id: 'r1' }],
        total: 1,
        hasMore: false,
      });
      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.loadPendingReceivedPage({ reset: true });
      });
      expect(friendService.getPendingReceived).toHaveBeenCalledWith({ limit: REQUESTS_PAGE_SIZE, offset: 0 });
      expect(result.current.pendingReceived).toHaveLength(1);
      expect(result.current.pendingReceivedState).toBe('success');
    });

    it('appends and dedupes by id on "Xem thêm"', async () => {
      useFriendStore.setState({ pendingReceived: [{ id: 'r1' }] });
      friendService.getPendingReceived.mockResolvedValue({
        items: [{ id: 'r1' }, { id: 'r2' }],
        total: 2,
        hasMore: true,
      });
      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.loadPendingReceivedPage({ reset: false, limit: 10 });
      });
      expect(friendService.getPendingReceived).toHaveBeenCalledWith({ limit: 10, offset: 1 });
      expect(result.current.pendingReceived.map((r) => r.id)).toEqual(['r1', 'r2']);
      expect(result.current.pendingReceivedHasMore).toBe(true);
    });

    it('marks error state on failure without throwing', async () => {
      friendService.getPendingReceived.mockRejectedValue(new Error('boom'));
      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.loadPendingReceivedPage({ reset: true });
      });
      expect(result.current.pendingReceivedState).toBe('error');
    });
  });

  describe('loadPendingSentPage', () => {
    it('loads first page', async () => {
      friendService.getPendingSent.mockResolvedValue({
        items: [{ id: 's1' }],
        total: 1,
        hasMore: false,
      });
      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.loadPendingSentPage({ reset: true });
      });
      expect(result.current.pendingSent).toHaveLength(1);
      expect(result.current.pendingSentState).toBe('success');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // loadSuggestions — "Xem thêm": lần đầu 3, sau đó 10/lần
  // ═══════════════════════════════════════════════════════════
  describe('loadSuggestions', () => {
    it('loads initial page with SUGGESTION_INITIAL_SIZE', async () => {
      friendService.getSuggestions.mockResolvedValue({
        items: [{ id: 'a' }, { id: 'b' }, { id: 'c' }],
        total: 20,
        hasMore: true,
      });
      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.loadSuggestions({ reset: true, limit: SUGGESTION_INITIAL_SIZE });
      });
      expect(friendService.getSuggestions).toHaveBeenCalledWith({ limit: SUGGESTION_INITIAL_SIZE, offset: 0 });
      expect(result.current.suggestions).toHaveLength(3);
      expect(result.current.suggestionsHasMore).toBe(true);
      expect(result.current.suggestionsTotal).toBe(20);
    });

    it('"Xem thêm" appends 10 more starting at current offset', async () => {
      useFriendStore.setState({ suggestions: [{ id: 'a' }, { id: 'b' }, { id: 'c' }] });
      friendService.getSuggestions.mockResolvedValue({
        items: Array.from({ length: 10 }, (_, i) => ({ id: `x${i}` })),
        total: 20,
        hasMore: true,
      });
      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.loadSuggestions({ reset: false, limit: SUGGESTION_PAGE_SIZE });
      });
      expect(friendService.getSuggestions).toHaveBeenCalledWith({ limit: SUGGESTION_PAGE_SIZE, offset: 3 });
      expect(result.current.suggestions).toHaveLength(13);
    });

    it('ignores a duplicate call while already loading', async () => {
      let resolveFirst;
      friendService.getSuggestions.mockImplementation(
        () => new Promise((resolve) => { resolveFirst = resolve; }),
      );
      const { result } = renderHook(() => useFriendStore());

      let firstCall;
      act(() => {
        firstCall = result.current.loadSuggestions({ reset: true });
      });
      expect(result.current.suggestionsState).toBe('loading');

      // Second call while first still in-flight should be a no-op
      let secondCall;
      act(() => {
        secondCall = result.current.loadSuggestions({ reset: true });
      });

      await act(async () => {
        resolveFirst({ items: [{ id: 'a' }], total: 1, hasMore: false });
        await firstCall;
        await secondCall;
      });

      expect(friendService.getSuggestions).toHaveBeenCalledTimes(1);
    });

    it('clears suggestions and sets error state on failure', async () => {
      useFriendStore.setState({ suggestions: [{ id: 'stale' }] });
      friendService.getSuggestions.mockRejectedValue(new Error('fail'));
      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.loadSuggestions({ reset: true });
      });
      expect(result.current.suggestions).toEqual([]);
      expect(result.current.suggestionsState).toBe('error');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // search
  // ═══════════════════════════════════════════════════════════
  describe('search', () => {
    it('does not call API and resets results for short keywords', async () => {
      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.search('a');
      });
      expect(friendService.searchUsers).not.toHaveBeenCalled();
      expect(result.current.searchResults).toEqual([]);
      expect(result.current.searchState).toBe('idle');
    });

    it('calls searchUsers and stores results for valid keyword', async () => {
      friendService.searchUsers.mockResolvedValue([{ id: 'u1' }]);
      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.search('alice');
      });
      expect(friendService.searchUsers).toHaveBeenCalledWith('alice');
      expect(result.current.searchResults).toEqual([{ id: 'u1' }]);
      expect(result.current.searchState).toBe('success');
    });

    it('sets error state when search fails', async () => {
      friendService.searchUsers.mockRejectedValue(new Error('fail'));
      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.search('alice');
      });
      expect(result.current.searchState).toBe('error');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // sendRequest / respond / cancelRequest / unfriend / block / unblock
  // ═══════════════════════════════════════════════════════════
  describe('sendRequest', () => {
    it('adds to pendingSent, increments total, removes from suggestions', async () => {
      useFriendStore.setState({
        suggestions: [{ id: 'bob' }, { id: 'carl' }],
        suggestionsTotal: 2,
      });
      friendService.sendRequest.mockResolvedValue({ id: 'req1', addresseeId: 'bob', status: 'pending' });

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.sendRequest('bob');
      });

      expect(result.current.pendingSent).toHaveLength(1);
      expect(result.current.pendingSentTotal).toBe(1);
      expect(result.current.suggestions.map((s) => s.id)).toEqual(['carl']);
    });
  });

  describe('respond', () => {
    it('accept: moves request into friends (friend = sender when we are addressee), increments friendsTotal, removes from pendingReceived', async () => {
      // currentUid = 'me' — we are the addressee accepting alice's request.
      // Regression test: mapFriend() used to compute friendId as
      // `addresseeId || senderId`, which returned OUR OWN id ('me') instead
      // of the friend's id ('alice') whenever addresseeId was present.
      useFriendStore.setState({
        pendingReceived: [{ id: 'req1' }],
        pendingReceivedTotal: 1,
        friends: [],
        friendsTotal: 0,
        currentUid: 'me',
      });
      friendService.respondRequest.mockResolvedValue({
        id: 'req1',
        senderId: 'alice',      // This is the friend
        addresseeId: 'me',      // This is us
        senderName: 'Alice W',
        senderAvatar: 'avatar.jpg',
        status: 'accepted',
        updatedAt: '2026-01-01T00:00:00Z',
      });
      // loadSuggestions is called internally on accept — must not throw
      friendService.getSuggestions.mockResolvedValue({ items: [], total: 0, hasMore: false });

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.respond('req1', true);
      });

      expect(result.current.pendingReceived).toEqual([]);
      expect(result.current.pendingReceivedTotal).toBe(0);
      expect(result.current.friends).toHaveLength(1);
      // Must be 'alice' (the friend), not 'me' (ourselves) — this is the bug fix.
      expect(result.current.friends[0].friendId).toBe('alice');
      expect(result.current.friends[0].fullName).toBe('Alice W');
      expect(result.current.friendsTotal).toBe(1);
    });

    it('decline: removes from pendingReceived, decrements total, does not touch friends', async () => {
      useFriendStore.setState({
        pendingReceived: [{ id: 'req1' }],
        pendingReceivedTotal: 1,
      });
      friendService.respondRequest.mockResolvedValue({ id: 'req1', status: 'declined' });

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.respond('req1', false);
      });

      expect(result.current.pendingReceived).toEqual([]);
      expect(result.current.pendingReceivedTotal).toBe(0);
      expect(result.current.friends).toEqual([]);
    });

    it('pendingReceivedTotal never goes negative', async () => {
      useFriendStore.setState({ pendingReceived: [], pendingReceivedTotal: 0 });
      friendService.respondRequest.mockResolvedValue({ id: 'ghost', status: 'declined' });
      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.respond('ghost', false);
      });
      expect(result.current.pendingReceivedTotal).toBe(0);
    });
  });

  describe('cancelRequest', () => {
    it('removes request from pendingSent and decrements total', async () => {
      useFriendStore.setState({
        pendingSent: [{ id: 'req1', addresseeId: 'bob' }],
        pendingSentTotal: 1,
        friendsTotal: 5,
      });
      friendService.cancelRequest.mockResolvedValue(undefined);

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.cancelRequest('req1');
      });

      expect(result.current.pendingSent).toEqual([]);
      expect(result.current.pendingSentTotal).toBe(0);
    });

    it('re-adds the cancelled user to suggestions when user currently has zero friends', async () => {
      useFriendStore.setState({
        pendingSent: [{ id: 'req1', addresseeId: 'bob', addresseeName: 'Bob J' }],
        pendingSentTotal: 1,
        friendsTotal: 0,
        suggestions: [],
      });
      friendService.cancelRequest.mockResolvedValue(undefined);

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.cancelRequest('req1');
      });

      expect(result.current.suggestions).toHaveLength(1);
      expect(result.current.suggestions[0].id).toBe('bob');
    });

    it('does not touch suggestions when user already has friends', async () => {
      useFriendStore.setState({
        pendingSent: [{ id: 'req1', addresseeId: 'bob' }],
        pendingSentTotal: 1,
        friendsTotal: 3,
        suggestions: [],
      });
      friendService.cancelRequest.mockResolvedValue(undefined);

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.cancelRequest('req1');
      });

      expect(result.current.suggestions).toEqual([]);
    });
  });

  describe('unfriend', () => {
    it('removes friend from list and decrements total (floored at 0)', async () => {
      useFriendStore.setState({
        friends: [{ friendId: 'bob' }],
        friendsTotal: 1,
      });
      friendService.unfriend.mockResolvedValue(undefined);

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.unfriend('bob');
      });

      expect(result.current.friends).toEqual([]);
      expect(result.current.friendsTotal).toBe(0);
    });
  });

  describe('block / unblock', () => {
    it('block calls service then reloads all lists', async () => {
      friendService.block.mockResolvedValue(undefined);
      friendService.getFriends.mockResolvedValue({ items: [], total: 0, hasMore: false });
      friendService.getPendingReceived.mockResolvedValue({ items: [], total: 0, hasMore: false });
      friendService.getPendingSent.mockResolvedValue({ items: [], total: 0, hasMore: false });

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.block('bob');
      });

      expect(friendService.block).toHaveBeenCalledWith('bob');
      expect(friendService.getFriends).toHaveBeenCalled();
      expect(friendService.getPendingReceived).toHaveBeenCalled();
      expect(friendService.getPendingSent).toHaveBeenCalled();
    });

    it('unblock calls service then reloads all lists', async () => {
      friendService.unblock.mockResolvedValue(undefined);
      friendService.getFriends.mockResolvedValue({ items: [], total: 0, hasMore: false });
      friendService.getPendingReceived.mockResolvedValue({ items: [], total: 0, hasMore: false });
      friendService.getPendingSent.mockResolvedValue({ items: [], total: 0, hasMore: false });

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.unblock('bob');
      });

      expect(friendService.unblock).toHaveBeenCalledWith('bob');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Selector helpers
  // ═══════════════════════════════════════════════════════════
  describe('isFriend / getSentRequest / getReceivedRequest', () => {
    it('isFriend returns true only when friendId matches', () => {
      useFriendStore.setState({ friends: [{ friendId: 'bob' }] });
      const { result } = renderHook(() => useFriendStore());
      expect(result.current.isFriend('bob')).toBe(true);
      expect(result.current.isFriend('carl')).toBe(false);
    });

    it('getSentRequest matches by addresseeId (camelCase or snake_case)', () => {
      useFriendStore.setState({
        pendingSent: [{ id: 'r1', addresseeId: 'bob' }, { id: 'r2', addressee_id: 'carl' }],
      });
      const { result } = renderHook(() => useFriendStore());
      expect(result.current.getSentRequest('bob')?.id).toBe('r1');
      expect(result.current.getSentRequest('carl')?.id).toBe('r2');
      expect(result.current.getSentRequest('dave')).toBeUndefined();
    });

    it('getReceivedRequest matches by senderId (camelCase or snake_case)', () => {
      useFriendStore.setState({
        pendingReceived: [{ id: 'r1', senderId: 'alice' }, { id: 'r2', sender_id: 'eve' }],
      });
      const { result } = renderHook(() => useFriendStore());
      expect(result.current.getReceivedRequest('alice')?.id).toBe('r1');
      expect(result.current.getReceivedRequest('eve')?.id).toBe('r2');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // init / dispose lifecycle
  // ═══════════════════════════════════════════════════════════
  describe('init / dispose', () => {
    it('init loads all lists and stores currentUid + connection', async () => {
      friendService.getFriends.mockResolvedValue({ items: [], total: 0, hasMore: false });
      friendService.getPendingReceived.mockResolvedValue({ items: [], total: 0, hasMore: false });
      friendService.getPendingSent.mockResolvedValue({ items: [], total: 0, hasMore: false });

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.init('me-uid');
      });

      expect(result.current.currentUid).toBe('me-uid');
      expect(result.current.connection).toBeTruthy();
    });

    it('init is a no-op when called again with the same uid and an existing connection', async () => {
      friendService.getFriends.mockResolvedValue({ items: [], total: 0, hasMore: false });
      friendService.getPendingReceived.mockResolvedValue({ items: [], total: 0, hasMore: false });
      friendService.getPendingSent.mockResolvedValue({ items: [], total: 0, hasMore: false });

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.init('me-uid');
      });
      const callsAfterFirstInit = friendService.getFriends.mock.calls.length;

      await act(async () => {
        await result.current.init('me-uid');
      });

      expect(friendService.getFriends.mock.calls.length).toBe(callsAfterFirstInit);
    });

    it('dispose stops connection and clears currentUid', async () => {
      friendService.getFriends.mockResolvedValue({ items: [], total: 0, hasMore: false });
      friendService.getPendingReceived.mockResolvedValue({ items: [], total: 0, hasMore: false });
      friendService.getPendingSent.mockResolvedValue({ items: [], total: 0, hasMore: false });

      const { result } = renderHook(() => useFriendStore());
      await act(async () => {
        await result.current.init('me-uid');
      });
      await act(async () => {
        await result.current.dispose();
      });

      expect(result.current.connection).toBeNull();
      expect(result.current.currentUid).toBeNull();
    });
  });
});
