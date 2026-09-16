import { create } from 'zustand';
import { authService } from '../services/auth.service';

export const useProfileStore = create((set) => ({
  myProfile: null,
  byUserId: {},

  async loadMyProfile() {
    try {
      const p = await authService.getMe();
      set({ myProfile: p });
      return p;
    } catch (e) {
      return null;
    }
  },

  async loadUser(userId) {
    try {
      const p = await authService.getById(userId);
      set((s) => ({ byUserId: { ...s.byUserId, [userId]: p } }));
      return p;
    } catch (e) {
      return null;
    }
  },

  async updateMe(payload) {
    const p = await authService.updateMe(payload);
    set({ myProfile: p });
    return p;
  },

  async updateAvatar(file) {
    const res = await authService.updateAvatar(file);
    set((s) => ({ myProfile: { ...s.myProfile, avatar: res?.avatar || s.myProfile?.avatar } }));
    return res;
  },
}));
