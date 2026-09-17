import { http } from '../lib/httpClient';

// Backend dùng SnakeCaseLower cho JSON + multipart field names.
export const feedService = {
  async getAll() {
    return http.get('/api/feed');
  },
  async getNewsfeed() {
    return http.get('/api/feed/newsfeed');
  },
  async getStories() {
    return http.get('/api/feed/stories');
  },
  async createFeed(payload) {
    // Backend CreateFeed dùng [FromForm] FormData — multipart field names phải snake_case.
    const fd = new FormData();
    fd.append('Type', payload.type || 'post');
    fd.append('Content.Caption', payload.content || '');
    if (payload.mediaUrl) fd.append('MediaUrl', payload.mediaUrl);
    if (payload.privacy) fd.append('Privacy', payload.privacy);
    return http.upload('/api/feed', fd);
  },
  async updateFeed(id, payload) {
    return http.put(`/api/feed/${id}`, payload);
  },
  async deleteFeed(id) {
    return http.delete(`/api/feed/${id}`);
  },
  async like(id) {
    return http.post(`/api/feed/${id}/like`);
  },
  async unlike(id) {
    // Backend dùng POST toggle endpoint — unlike = gọi lại toggle khi đã like
    return http.post(`/api/feed/${id}/like`);
  },
  async comment(id, payload) {
    return http.post(`/api/feed/${id}/comments`, payload);
  },
  async deleteComment(feedId, commentId) {
    return http.delete(`/api/feed/${feedId}/comments/${commentId}`);
  },
  async hide(id) {
    return http.post(`/api/feed/${id}/hide`);
  },
  async view(id) {
    return http.post(`/api/feed/${id}/view`);
  },
};

export const storyService = {
  async getAll() {
    return http.get('/api/feed/stories');
  },
  async create(payload) {
    return http.post('/api/feed/stories', payload);
  },
};
