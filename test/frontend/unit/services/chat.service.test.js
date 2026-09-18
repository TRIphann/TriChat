import { describe, it, expect, vi, beforeEach } from 'vitest';
import { chatService } from '@/services/chat.service';
import { http } from '@/lib/httpClient';

vi.mock('@/lib/httpClient', () => ({
  http: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
    upload: vi.fn(),
  },
}));

describe('chatService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getConversations', () => {
    it('should fetch all conversations', async () => {
      const mockConvs = [{ id: 'c1' }, { id: 'c2' }];
      http.get.mockResolvedValue(mockConvs);

      const result = await chatService.getConversations();

      expect(http.get).toHaveBeenCalledWith('/api/chat/conversations');
      expect(result).toEqual(mockConvs);
    });
  });

  describe('getConversation', () => {
    it('should fetch a single conversation by id', async () => {
      const mockConv = { id: 'c1', name: 'Test Chat' };
      http.get.mockResolvedValue(mockConv);

      const result = await chatService.getConversation('c1');

      expect(http.get).toHaveBeenCalledWith('/api/chat/conversations/c1');
      expect(result).toEqual(mockConv);
    });
  });

  describe('createConversation', () => {
    it('should create a conversation', async () => {
      const mockConv = { id: 'c-new', is_group: false };
      http.post.mockResolvedValue(mockConv);

      const result = await chatService.createConversation({
        participant_ids: ['user1', 'user2'],
        is_group: false,
      });

      expect(http.post).toHaveBeenCalledWith('/api/chat/conversations', {
        participant_ids: ['user1', 'user2'],
        is_group: false,
      });
      expect(result).toEqual(mockConv);
    });
  });

  describe('updateGroup', () => {
    it('should update group info', async () => {
      const updated = { id: 'g1', name: 'New Name' };
      http.put.mockResolvedValue(updated);

      const result = await chatService.updateGroup({
        conversation_id: 'g1',
        name: 'New Name',
      });

      expect(http.put).toHaveBeenCalledWith('/api/chat/conversations/group', {
        conversation_id: 'g1',
        name: 'New Name',
      });
      expect(result).toEqual(updated);
    });
  });

  describe('addParticipants', () => {
    it('should add participants to group', async () => {
      http.post.mockResolvedValue({ success: true });

      await chatService.addParticipants({
        conversation_id: 'g1',
        user_ids: ['u4', 'u5'],
      });

      expect(http.post).toHaveBeenCalledWith('/api/chat/conversations/participants', {
        conversation_id: 'g1',
        user_ids: ['u4', 'u5'],
      });
    });
  });

  describe('getMessages', () => {
    it('should fetch messages with default limit', async () => {
      const mockMessages = [{ id: 'm1' }, { id: 'm2' }];
      http.get.mockResolvedValue(mockMessages);

      const result = await chatService.getMessages('conv1');

      expect(http.get).toHaveBeenCalledWith('/api/chat/conversations/conv1/messages', {
        limit: 50,
      });
      expect(result).toEqual(mockMessages);
    });

    it('should fetch messages with pagination', async () => {
      http.get.mockResolvedValue([]);

      await chatService.getMessages('conv1', { limit: 20, beforeMessageId: 'msg99' });

      expect(http.get).toHaveBeenCalledWith('/api/chat/conversations/conv1/messages', {
        limit: 20,
        before_message_id: 'msg99',
      });
    });
  });

  describe('sendMessage', () => {
    it('should send a message', async () => {
      const mockMsg = { id: 'm-sent', content: 'Hello' };
      http.post.mockResolvedValue(mockMsg);

      const result = await chatService.sendMessage({
        conversation_id: 'conv1',
        content: 'Hello',
        type: 'text',
      });

      expect(http.post).toHaveBeenCalledWith('/api/chat/messages', {
        conversation_id: 'conv1',
        content: 'Hello',
        type: 'text',
      });
      expect(result).toEqual(mockMsg);
    });
  });

  describe('updateMessage', () => {
    it('should update a message', async () => {
      const updated = { id: 'msg1', content: 'Edited' };
      http.put.mockResolvedValue(updated);

      const result = await chatService.updateMessage({
        message_id: 'msg1',
        content: 'Edited',
      });

      expect(http.put).toHaveBeenCalledWith('/api/chat/messages', {
        message_id: 'msg1',
        content: 'Edited',
      });
      expect(result).toEqual(updated);
    });
  });

  describe('deleteMessage', () => {
    it('should delete a message', async () => {
      http.delete.mockResolvedValue(undefined);

      await chatService.deleteMessage('conv1', 'msg1');

      expect(http.delete).toHaveBeenCalledWith('/api/chat/conversations/conv1/messages/msg1');
    });
  });

  describe('reactToMessage', () => {
    it('should react to a message', async () => {
      http.post.mockResolvedValue({ success: true });

      await chatService.reactToMessage({
        message_id: 'msg1',
        emoji: '❤️',
      });

      expect(http.post).toHaveBeenCalledWith('/api/chat/messages/react', {
        message_id: 'msg1',
        emoji: '❤️',
      });
    });
  });

  describe('markAsRead', () => {
    it('should mark a message as read', async () => {
      http.post.mockResolvedValue(undefined);

      await chatService.markAsRead('conv1', 'msg1');

      expect(http.post).toHaveBeenCalledWith('/api/chat/conversations/conv1/messages/msg1/read');
    });
  });

  describe('markAsDelivered', () => {
    it('should mark a message as delivered', async () => {
      http.post.mockResolvedValue(undefined);

      await chatService.markAsDelivered('conv1', 'msg1');

      expect(http.post).toHaveBeenCalledWith(
        '/api/chat/conversations/conv1/messages/msg1/delivered'
      );
    });
  });

  describe('Settings', () => {
    it('should get conversation settings', async () => {
      const settings = { muted: false };
      http.get.mockResolvedValue(settings);

      const result = await chatService.getSettings('conv1');

      expect(http.get).toHaveBeenCalledWith('/api/chat/conversations/conv1/settings');
      expect(result).toEqual(settings);
    });

    it('should update conversation settings', async () => {
      http.put.mockResolvedValue({ success: true });

      await chatService.updateSettings('conv1', { muted: true });

      expect(http.put).toHaveBeenCalledWith('/api/chat/conversations/conv1/settings', {
        muted: true,
      });
    });

    it('should set disappearing messages', async () => {
      http.put.mockResolvedValue({ success: true });

      await chatService.setDisappearing('conv1', 3600);

      expect(http.put).toHaveBeenCalledWith(
        '/api/chat/conversations/conv1/settings/disappearing',
        { duration_seconds: 3600 }
      );
    });

    it('should set nickname for user', async () => {
      http.put.mockResolvedValue({ success: true });

      await chatService.setNickname('conv1', 'user1', 'Johnny');

      expect(http.put).toHaveBeenCalledWith(
        '/api/chat/conversations/conv1/members/user1/nickname',
        { nickname: 'Johnny' }
      );
    });
  });

  describe('uploadMedia', () => {
    it('should upload media file', async () => {
      const file = new File(['data'], 'photo.jpg', { type: 'image/jpeg' });
      http.upload.mockResolvedValue({ url: 'https://cdn/photo.jpg' });

      const result = await chatService.uploadMedia('conv1', file);

      expect(http.upload).toHaveBeenCalledWith('/api/chat/upload', expect.any(FormData));
      const fd = http.upload.mock.calls[0][1];
      expect(fd.get('ConversationId')).toBe('conv1');
      expect(fd.get('File')).toBe(file);
      expect(result).toEqual({ url: 'https://cdn/photo.jpg' });
    });
  });

  describe('saveFcmToken', () => {
    it('should save FCM token', async () => {
      http.post.mockResolvedValue({ success: true });

      await chatService.saveFcmToken('fcm-token-123');

      expect(http.post).toHaveBeenCalledWith('/api/user/fcm-token', { token: 'fcm-token-123' });
    });
  });

  describe('Error handling', () => {
    it('should propagate errors from getConversations', async () => {
      const error = new Error('Network error');
      http.get.mockRejectedValue(error);

      await expect(chatService.getConversations()).rejects.toThrow('Network error');
    });

    it('should propagate errors from sendMessage', async () => {
      http.post.mockRejectedValue(new Error('Send failed'));

      await expect(chatService.sendMessage({ content: 'test' })).rejects.toThrow('Send failed');
    });
  });
});
