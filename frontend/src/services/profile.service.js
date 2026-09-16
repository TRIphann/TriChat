import { http } from '../lib/httpClient';

export const profileService = {
  async getById(userId) {
    return http.get(`/api/user/${userId}`);
  },
  async getMyPosts(userId) {
    return http.get(`/api/feed/user/${userId}`);
  },
  async getMedia(userId) {
    return http.get(`/api/feed/user/${userId}/media`);
  },
  async getFriends(userId) {
    return http.get(`/api/friends/user/${userId}`);
  },
  async update(payload) {
    return http.put('/api/user/me', payload);
  },
  async updateAvatar(file) {
    const fd = new FormData();
    fd.append('File', file);
    return http.upload('/api/user/avatar', fd);
  },
};
