import { describe, it, expect, vi, beforeEach } from 'vitest';
import { useAuthStore } from '@/store/authStore';
import { authService } from '@/services/auth.service';
import { auth } from '@/lib/firebase';
import { onAuthStateChanged } from 'firebase/auth';

vi.mock('@/services/auth.service', () => ({
  authService: {
    getMe: vi.fn(),
    signOut: vi.fn(),
  },
}));
vi.mock('@/lib/firebase', () => ({
  auth: {},
}));
vi.mock('firebase/auth', () => ({
  onAuthStateChanged: vi.fn(),
}));

describe('authStore', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useAuthStore.setState({
      user: null,
      ready: false,
      profile: null,
    });
  });

  describe('initial state', () => {
    it('should have correct initial state', () => {
      const state = useAuthStore.getState();
      expect(state.user).toBeNull();
      expect(state.ready).toBe(false);
      expect(state.profile).toBeNull();
    });
  });

  describe('init', () => {
    it('should set user and profile when authenticated', async () => {
      const mockUser = { uid: 'uid-1', email: 'test@test.com' };
      const mockProfile = { id: 'uid-1', displayName: 'Test User' };

      authService.getMe.mockResolvedValue(mockProfile);

      onAuthStateChanged.mockImplementation((auth, callback) => {
        callback(mockUser);
        return vi.fn();
      });

      useAuthStore.getState().init();

      await new Promise((resolve) => setTimeout(resolve, 0));

      const state = useAuthStore.getState();
      expect(state.user).toEqual(mockUser);
      expect(state.ready).toBe(true);
      expect(state.profile).toEqual(mockProfile);
    });

    it('should clear state when user is null', async () => {
      onAuthStateChanged.mockImplementation((auth, callback) => {
        callback(null);
        return vi.fn();
      });

      useAuthStore.getState().init();

      await new Promise((resolve) => setTimeout(resolve, 0));

      const state = useAuthStore.getState();
      expect(state.user).toBeNull();
      expect(state.ready).toBe(true);
      expect(state.profile).toBeNull();
    });

    it('should handle profile load error gracefully', async () => {
      const mockUser = { uid: 'uid-2', email: 'a@test.com' };
      authService.getMe.mockRejectedValue(new Error('Network error'));

      onAuthStateChanged.mockImplementation((auth, callback) => {
        callback(mockUser);
        return vi.fn();
      });

      useAuthStore.getState().init();

      await new Promise((resolve) => setTimeout(resolve, 0));

      const state = useAuthStore.getState();
      expect(state.user).toEqual(mockUser);
      expect(state.ready).toBe(true);
      expect(state.profile).toBeNull();
    });
  });

  describe('signOut', () => {
    it('should clear user and profile on sign out', async () => {
      useAuthStore.setState({
        user: { uid: 'uid-1' },
        profile: { id: 'uid-1', displayName: 'Test' },
      });

      authService.signOut.mockResolvedValue(undefined);

      await useAuthStore.getState().signOut();

      const state = useAuthStore.getState();
      expect(state.user).toBeNull();
      expect(state.profile).toBeNull();
      expect(authService.signOut).toHaveBeenCalled();
    });

    it('should handle sign out error', async () => {
      authService.signOut.mockRejectedValue(new Error('Sign out failed'));

      await expect(useAuthStore.getState().signOut()).rejects.toThrow('Sign out failed');
    });
  });

  describe('setProfile', () => {
    it('should update profile', () => {
      const mockProfile = { id: 'uid-1', displayName: 'Updated User' };
      useAuthStore.getState().setProfile(mockProfile);

      expect(useAuthStore.getState().profile).toEqual(mockProfile);
    });

    it('should clear profile when set to null', () => {
      useAuthStore.setState({ profile: { id: 'uid-1' } });
      useAuthStore.getState().setProfile(null);

      expect(useAuthStore.getState().profile).toBeNull();
    });
  });
});
