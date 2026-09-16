import { http } from '../lib/httpClient';

export const chatService = {
  // Conversations
  async getConversations() {
    return http.get('/api/chat/conversations');
  },

  async getConversation(id) {
    return http.get(`/api/chat/conversations/${id}`);
  },

  async createConversation(payload) {
    // PascalCase: CreateConversationRequest
    return http.post('/api/chat/conversations', payload);
  },

  async updateGroup(payload) {
    return http.put('/api/chat/conversations/group', payload);
  },

  async addParticipants(payload) {
    return http.post('/api/chat/conversations/participants', payload);
  },

  async deleteConversation(id) {
    return http.delete(`/api/chat/conversations/${id}`);
  },

  async updateGroupSettings(id, payload) {
    return http.put(`/api/chat/conversations/${id}/group-settings`, payload);
  },

  async createJoinRequest(id) {
    return http.post(`/api/chat/conversations/${id}/join-requests`);
  },

  async getJoinRequests(id) {
    return http.get(`/api/chat/conversations/${id}/join-requests`);
  },

  async approveJoinRequest(cid, uid) {
    return http.post(`/api/chat/conversations/${cid}/join-requests/${uid}/approve`);
  },

  async rejectJoinRequest(cid, uid) {
    return http.post(`/api/chat/conversations/${cid}/join-requests/${uid}/reject`);
  },

  // Messages
  async getMessages(conversationId, { limit = 50, beforeMessageId } = {}) {
    const q = { limit };
    if (beforeMessageId) q.beforeMessageId = beforeMessageId;
    return http.get(`/api/chat/conversations/${conversationId}/messages`, q);
  },

  async sendMessage(payload) {
    return http.post('/api/chat/messages', payload);
  },

  async updateMessage(payload) {
    return http.put('/api/chat/messages', payload);
  },

  async deleteMessage(conversationId, messageId) {
    return http.delete(`/api/chat/conversations/${conversationId}/messages/${messageId}`);
  },

  async reactToMessage(payload) {
    return http.post('/api/chat/messages/react', payload);
  },

  async markAsRead(conversationId, messageId) {
    return http.post(`/api/chat/conversations/${conversationId}/messages/${messageId}/read`);
  },

  async markAsDelivered(conversationId, messageId) {
    return http.post(`/api/chat/conversations/${conversationId}/messages/${messageId}/delivered`);
  },

  async hideMessageForMe(conversationId, messageId) {
    return http.post(`/api/chat/conversations/${conversationId}/messages/${messageId}/hide`);
  },

  async pinMessage(conversationId, messageId) {
    return http.post(`/api/chat/conversations/${conversationId}/pin/${messageId}`);
  },

  async unpinMessage(conversationId) {
    return http.delete(`/api/chat/conversations/${conversationId}/pin`);
  },

  async getSettings(conversationId) {
    return http.get(`/api/chat/conversations/${conversationId}/settings`);
  },

  async updateSettings(conversationId, payload) {
    return http.put(`/api/chat/conversations/${conversationId}/settings`, payload);
  },

  async setDisappearing(conversationId, durationSeconds) {
    return http.put(`/api/chat/conversations/${conversationId}/settings/disappearing`, {
      DurationSeconds: durationSeconds,
    });
  },

  async setNickname(conversationId, userId, nickname) {
    return http.put(
      `/api/chat/conversations/${conversationId}/members/${userId}/nickname`,
      { Nickname: nickname },
    );
  },

  async uploadMedia(conversationId, file) {
    const fd = new FormData();
    fd.append('ConversationId', conversationId);
    fd.append('file', file);
    return http.upload('/api/chat/upload', fd);
  },

  async getUserProfile(userId) {
    return http.get(`/api/user/${userId}`);
  },

  async saveFcmToken(token) {
    return http.post('/api/user/fcm-token', { Token: token });
  },
};
