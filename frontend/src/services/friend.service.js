import { http } from '../lib/httpClient';

// Tất cả payload gửi backend dùng snake_case (ASP.NET Core SnakeCaseLower JSON).
export const friendService = {
  /**
   * Lấy danh sách bạn bè (sort theo "bạn nhắn tin gần đây nhất").
   * Hỗ trợ phân trang qua limit + offset. Trả về { items, total, hasMore }.
   */
  async getFriends({ limit = 20, offset = 0 } = {}) {
    return http.get('/api/friends', { limit, offset });
  },

  /**
   * Lấy bạn bè của một user cụ thể (paginated).
   */
  async getUserFriends(userId, { limit = 20, offset = 0 } = {}) {
    return http.get(`/api/friends/user/${userId}`, { limit, offset });
  },

  async getPendingReceived({ limit = 10, offset = 0 } = {}) {
    return http.get('/api/friends/requests/received', { limit, offset });
  },
  async getPendingSent({ limit = 10, offset = 0 } = {}) {
    return http.get('/api/friends/requests/sent', { limit, offset });
  },
  async getBlocked() {
    return http.get('/api/friends/blocked');
  },
  async getStatus(targetUserId) {
    return http.get(`/api/friends/status/${targetUserId}`);
  },
  async sendRequest(addresseeId, sourceType = 'search') {
    // SendFriendRequestDto: AddresseeId, SourceType → snake_case
    return http.post('/api/friends/requests', {
      addressee_id: addresseeId,
      source_type: sourceType,
    });
  },
  async respondRequest(friendshipId, accept) {
    // RespondFriendRequestDto.Accept → "accept"
    return http.patch(`/api/friends/requests/${friendshipId}`, { accept });
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
   * Gợi ý kết bạn — backend tự chọn chiến lược:
   *  - User chưa có bạn → sort theo tài khoản mới tạo (MutualCount = null).
   *  - User đã có bạn → sort theo số bạn chung giảm dần (MutualCount có giá trị).
   * Endpoint: GET /api/friends/suggestions?limit=N&offset=N
   */
  async getSuggestions({ limit = 10, offset = 0 } = {}) {
    return http.get('/api/friends/suggestions', { limit, offset });
  },
};
