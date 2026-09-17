import { http } from '../lib/httpClient';

export const friendService = {
  async getFriends() {
    return http.get('/api/friends');
  },
  async getUserFriends(userId) {
    return http.get(`/api/friends/user/${userId}`);
  },
  async getPendingReceived() {
    return http.get('/api/friends/requests/received');
  },
  async getPendingSent() {
    return http.get('/api/friends/requests/sent');
  },
  async getBlocked() {
    return http.get('/api/friends/blocked');
  },
  async getStatus(targetUserId) {
    return http.get(`/api/friends/status/${targetUserId}`);
  },
  async sendRequest(addresseeId, sourceType = 'search') {
    return http.post('/api/friends/requests', {
      AddresseeId: addresseeId,
      SourceType: sourceType,
    });
  },
  async respondRequest(friendshipId, accept) {
    return http.patch(`/api/friends/requests/${friendshipId}`, { Accept: accept });
  },
  async cancelRequest(friendshipId) {
    return http.delete(`/api/friends/requests/${friendshipId}`);
  },
  async unfriend(targetUserId) {
    return http.delete(`/api/friends/${targetUserId}`);
  },
  async block(targetUserId) {
    return http.post(`/api/friends/block/${targetUserId}`);
  },
  async unblock(targetUserId) {
    return http.delete(`/api/friends/block/${targetUserId}`);
  },
  async searchUsers(keyword) {
    return http.get('/api/user/search', { q: keyword });
  },

  /**
   * Lấy danh sách người dùng trong hệ thống để gợi ý kết bạn.
   * Endpoint: GET /api/user (trả về toàn bộ user).
   * Frontend sẽ tự lọc trừ current user + đã là bạn + đang pending.
   */
  async discoverUsers() {
    return http.get('/api/user');
  },
};
