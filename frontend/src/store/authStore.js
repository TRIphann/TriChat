import { create } from 'zustand';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from '../lib/firebase';
import { authService } from '../services/auth.service';

export const useAuthStore = create((set, get) => ({
  user: null,
  ready: false,
  profile: null,

  init() {
    return onAuthStateChanged(auth, async (u) => {
      set({ user: u, ready: true });
      if (u) {
        try {
          const profile = await authService.getMe();
          set({ profile });
        } catch (e) {
          // ignore, profile load fail không block UI
        }
      } else {
        set({ profile: null });
      }
    });
  },

  async signOut() {
    await authService.signOut();
    set({ user: null, profile: null });
  },

  setProfile(profile) {
    set({ profile });
  },
}));
