import { describe, it, expect, vi, beforeEach } from 'vitest';
import { friendService } from '@/services/friend.service';
import { http } from '@/lib/httpClient';

// Mock httpClient
vi.mock('@/lib/httpClient', () => ({
  http: {
    get: vi.fn(),
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}));

describe('friend.service', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getFriends', () => {
    it('should fetch friends with default pagination', async () => {
      const mockResponse = {
        items: [
          {
            friendId: 'user1',
            fullName: 'John Doe',
            avatar: 'avatar1.jpg',
            isOnline: true,
          },
        ],
        total: 1,
        hasMore: false,
      };

      http.get.mockResolvedValue(mockResponse);

      const result = await friendService.getFriends();

      expect(http.get).toHaveBeenCalledWith('/api/friends', { limit: 20, offset: 0 });
      expect(result).toEqual(mockResponse);
    });

    it('should fetch friends with custom pagination', async () => {
      const mockResponse = { items: [], total: 0, hasMore: false };
      http.get.mockResolvedValue(mockResponse);

      await friendService.getFriends({ limit: 10, offset: 20 });

      expect(http.get).toHaveBeenCalledWith('/api/friends', { limit: 10, offset: 20 });
    });
  });

  describe('getPendingReceived', () => {
    it('should fetch pending received requests', async () => {
      const mockResponse = {
        items: [
          {
            id: 'req1',
            senderId: 'user2',
            senderName: 'Jane Smith',
            senderAvatar: 'avatar2.jpg',
            createdAt: '2026-09-18T10:00:00Z',
          },
        ],
        total: 1,
        hasMore: false,
      };

      http.get.mockResolvedValue(mockResponse);

      const result = await friendService.getPendingReceived({ limit: 10, offset: 0 });

      expect(http.get).toHaveBeenCalledWith('/api/friends/requests/received', { limit: 10, offset: 0 });
      expect(result).toEqual(mockResponse);
    });
  });

  describe('getPendingSent', () => {
    it('should fetch pending sent requests', async () => {
      const mockResponse = {
        items: [
          {
            id: 'req1',
            addresseeId: 'user3',
            addresseeName: 'Alice',
            addresseeAvatar: 'avatar3.jpg',
            createdAt: '2026-09-18T09:00:00Z',
          },
        ],
        total: 1,
        hasMore: false,
      };

      http.get.mockResolvedValue(mockResponse);

      const result = await friendService.getPendingSent({ limit: 10, offset: 0 });

      expect(http.get).toHaveBeenCalledWith('/api/friends/requests/sent', { limit: 10, offset: 0 });
      expect(result).toEqual(mockResponse);
    });
  });

  describe('getSuggestions', () => {
    it('should fetch friend suggestions', async () => {
      const mockResponse = {
        items: [
          {
            id: 'user4',
            full_name: 'Bob',
            avatar: 'avatar4.jpg',
            mutual_count: 5,
          },
          {
            id: 'user5',
            full_name: 'Charlie',
            avatar: null,
            mutual_count: null,
          },
        ],
        total: 2,
        hasMore: true,
      };

      http.get.mockResolvedValue(mockResponse);

      const result = await friendService.getSuggestions({ limit: 15, offset: 5 });

      expect(http.get).toHaveBeenCalledWith('/api/friends/suggestions', { limit: 15, offset: 5 });
      expect(result).toEqual(mockResponse);
    });
  });

  describe('getBlocked', () => {
    it('should fetch blocked users', async () => {
      const mockResponse = [
        {
          user_id: 'user6',
          display_name: 'Blocked User',
          avatar_url: 'avatar6.jpg',
        },
      ];

      http.get.mockResolvedValue(mockResponse);

      const result = await friendService.getBlocked();

      expect(http.get).toHaveBeenCalledWith('/api/friends/blocked');
      expect(result).toEqual(mockResponse);
    });
  });

  describe('getUserFriends', () => {
    it('should fetch friends of a specific user', async () => {
      const mockResponse = {
        items: [{ friendId: 'user7', fullName: 'Dave' }],
        total: 1,
        hasMore: false,
      };

      http.get.mockResolvedValue(mockResponse);

      const result = await friendService.getUserFriends('user123', { limit: 10, offset: 0 });

      expect(http.get).toHaveBeenCalledWith('/api/friends/user/user123', { limit: 10, offset: 0 });
      expect(result).toEqual(mockResponse);
    });
  });

  describe('getStatus', () => {
    it('should get relationship status for friends', async () => {
      const mockResponse = {
        status: 'accepted',
        is_blocker: false,
        friends_since: '2026-09-01T00:00:00Z',
      };
      http.get.mockResolvedValue(mockResponse);

      const result = await friendService.getStatus('user8');

      expect(http.get).toHaveBeenCalledWith('/api/friends/status/user8');
      expect(result).toEqual(mockResponse);
    });

    it('should get relationship status for blocked user', async () => {
      const mockResponse = {
        status: 'blocked',
        is_blocker: true,
      };
      http.get.mockResolvedValue(mockResponse);

      const result = await friendService.getStatus('user9');

      expect(result.status).toBe('blocked');
      expect(result.is_blocker).toBe(true);
    });

    it('should get relationship status for pending request', async () => {
      const mockResponse = {
        status: 'pending',
        is_blocker: false,
      };
      http.get.mockResolvedValue(mockResponse);

      const result = await friendService.getStatus('user10');

      expect(result.status).toBe('pending');
    });

    it('should get relationship status for no relationship', async () => {
      const mockResponse = {
        status: null,
        is_blocker: false,
      };
      http.get.mockResolvedValue(mockResponse);

      const result = await friendService.getStatus('user11');

      expect(result.status).toBeNull();
    });
  });

  describe('sendRequest', () => {
    it('should send friend request successfully with default source_type', async () => {
      const mockResponse = { id: 'req1', status: 'pending', addresseeId: 'user12' };
      http.post.mockResolvedValue(mockResponse);

      const result = await friendService.sendRequest('user12');

      expect(http.post).toHaveBeenCalledWith('/api/friends/requests', {
        addressee_id: 'user12',
        source_type: 'search',
      });
      expect(result).toEqual(mockResponse);
    });

    it('should send friend request with custom source_type', async () => {
      const mockResponse = { id: 'req2', status: 'pending' };
      http.post.mockResolvedValue(mockResponse);

      const result = await friendService.sendRequest('user13', 'suggestion');

      expect(http.post).toHaveBeenCalledWith('/api/friends/requests', {
        addressee_id: 'user13',
        source_type: 'suggestion',
      });
      expect(result).toEqual(mockResponse);
    });

    it('should handle errors when sending request', async () => {
      const mockError = new Error('User not found');
      http.post.mockRejectedValue(mockError);

      await expect(
        friendService.sendRequest('invalid')
      ).rejects.toThrow('User not found');
    });
  });

  describe('respondRequest', () => {
    it('should accept friend request', async () => {
      const mockResponse = { id: 'req1', status: 'accepted' };
      http.patch.mockResolvedValue(mockResponse);

      const result = await friendService.respondRequest('req1', true);

      expect(http.patch).toHaveBeenCalledWith('/api/friends/requests/req1', { accept: true });
      expect(result).toEqual(mockResponse);
    });

    it('should decline friend request', async () => {
      const mockResponse = { id: 'req2', status: 'declined' };
      http.patch.mockResolvedValue(mockResponse);

      const result = await friendService.respondRequest('req2', false);

      expect(http.patch).toHaveBeenCalledWith('/api/friends/requests/req2', { accept: false });
      expect(result).toEqual(mockResponse);
    });
  });

  describe('cancelRequest', () => {
    it('should cancel sent friend request', async () => {
      http.delete.mockResolvedValue(undefined);

      await friendService.cancelRequest('req3');

      expect(http.delete).toHaveBeenCalledWith('/api/friends/requests/req3');
    });
  });

  describe('unfriend', () => {
    it('should remove friend successfully', async () => {
      http.delete.mockResolvedValue(undefined);

      await friendService.unfriend('user14');

      expect(http.delete).toHaveBeenCalledWith('/api/friends/user14');
    });
  });

  describe('block', () => {
    it('should block user successfully', async () => {
      http.post.mockResolvedValue(undefined);

      await friendService.block('user15');

      expect(http.post).toHaveBeenCalledWith('/api/friends/block/user15');
    });
  });

  describe('unblock', () => {
    it('should unblock user successfully', async () => {
      http.delete.mockResolvedValue(undefined);

      await friendService.unblock('user16');

      expect(http.delete).toHaveBeenCalledWith('/api/friends/block/user16');
    });
  });

  describe('searchUsers', () => {
    it('should search users by keyword', async () => {
      const mockResponse = [
        { id: 'user17', full_name: 'Alice Wonder', avatar: 'avatar17.jpg' },
        { id: 'user18', full_name: 'Alice Cooper', avatar: 'avatar18.jpg' },
      ];
      http.get.mockResolvedValue(mockResponse);

      const result = await friendService.searchUsers('alice');

      expect(http.get).toHaveBeenCalledWith('/api/user/search', { q: 'alice' });
      expect(result).toEqual(mockResponse);
    });
  });

  describe('Error Handling', () => {
    it('should handle network errors', async () => {
      const networkError = new Error('Network Error');
      http.get.mockRejectedValue(networkError);

      await expect(friendService.getFriends()).rejects.toThrow('Network Error');
    });

    it('should handle 404 errors', async () => {
      const notFoundError = new Error('User not found');
      notFoundError.response = { status: 404 };
      http.post.mockRejectedValue(notFoundError);

      await expect(
        friendService.sendRequest('nonexistent')
      ).rejects.toThrow('User not found');
    });

    it('should handle 400 bad request errors', async () => {
      const badRequestError = new Error('Invalid request');
      badRequestError.response = { status: 400 };
      http.patch.mockRejectedValue(badRequestError);

      await expect(
        friendService.respondRequest('invalid-id', 'invalid_response')
      ).rejects.toThrow('Invalid request');
    });
  });
});
