import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  authService,
  mapAuthError,
  friendlyAuthError,
  cacheFallbackOtp,
  getCachedOtp,
  clearCachedOtp,
} from '@/services/auth.service';
import { http } from '@/lib/httpClient';
import { auth } from '@/lib/firebase';
import { signInWithEmailAndPassword, createUserWithEmailAndPassword } from 'firebase/auth';

vi.mock('@/lib/httpClient', () => ({
  http: {
    post: vi.fn(),
    patch: vi.fn(),
    get: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
    upload: vi.fn(),
  },
}));

vi.mock('@/lib/firebase', () => ({
  auth: {
    signOut: vi.fn(),
  },
}));

vi.mock('firebase/auth', () => ({
  signInWithEmailAndPassword: vi.fn(),
  createUserWithEmailAndPassword: vi.fn(),
}));

describe('auth.service', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    clearCachedOtp();
  });

  describe('mapAuthError', () => {
    it('returns empty string for falsy code', () => {
      expect(mapAuthError(null)).toBe('');
      expect(mapAuthError(undefined)).toBe('');
      expect(mapAuthError('')).toBe('');
    });

    it('maps known Firebase error codes with "auth/" prefix', () => {
      expect(mapAuthError('auth/email-already-in-use')).toContain('đã có tài khoản');
      expect(mapAuthError('auth/weak-password')).toContain('quá yếu');
      expect(mapAuthError('auth/invalid-email')).toContain('chưa đúng định dạng');
      expect(mapAuthError('auth/user-not-found')).toContain('chưa đăng ký');
      expect(mapAuthError('auth/wrong-password')).toContain('Sai mật khẩu');
      expect(mapAuthError('auth/too-many-requests')).toContain('Quá nhiều lần thử sai');
      expect(mapAuthError('auth/network-request-failed')).toContain('Không kết nối được');
    });

    it('maps codes without prefix as well', () => {
      expect(mapAuthError('invalid-credential')).toContain('không đúng');
    });

    it('returns empty string for unknown codes', () => {
      expect(mapAuthError('auth/some-unknown-code')).toBe('');
    });
  });

  describe('friendlyAuthError', () => {
    it('returns mapped friendly message when code is known', () => {
      const err = { code: 'auth/user-disabled' };
      expect(friendlyAuthError(err)).toContain('vô hiệu hóa');
    });

    it('falls back to error.message when code is unknown', () => {
      const err = { message: 'Something broke' };
      expect(friendlyAuthError(err)).toBe('Something broke');
    });

    it('falls back to default fallback message when nothing usable', () => {
      expect(friendlyAuthError({})).toBe('Đã có lỗi xảy ra. Vui lòng thử lại.');
    });

    it('accepts a custom fallback message', () => {
      expect(friendlyAuthError({}, 'Custom fallback')).toBe('Custom fallback');
    });
  });

  describe('OTP cache helpers', () => {
    it('caches and retrieves an OTP within TTL', () => {
      cacheFallbackOtp('123456');
      expect(getCachedOtp()).toBe('123456');
    });

    it('returns null when nothing cached', () => {
      expect(getCachedOtp()).toBeNull();
    });

    it('clears the cached OTP', () => {
      cacheFallbackOtp('654321');
      clearCachedOtp();
      expect(getCachedOtp()).toBeNull();
    });

    it('expires cached OTP after TTL', () => {
      vi.useFakeTimers();
      const now = new Date('2026-01-01T00:00:00Z');
      vi.setSystemTime(now);
      cacheFallbackOtp('111111');
      expect(getCachedOtp()).toBe('111111');

      vi.setSystemTime(new Date(now.getTime() + 6 * 60000));
      expect(getCachedOtp()).toBeNull();
      vi.useRealTimers();
    });
  });

  describe('signIn', () => {
    it('should sign in with email/password via Firebase', async () => {
      const mockUser = { uid: 'uid-1', email: 'a@test.com' };
      signInWithEmailAndPassword.mockResolvedValue({ user: mockUser });

      const result = await authService.signIn('a@test.com', 'pass123');

      expect(signInWithEmailAndPassword).toHaveBeenCalledWith(auth, 'a@test.com', 'pass123');
      expect(result).toEqual(mockUser);
    });

    it('should propagate Firebase sign-in errors', async () => {
      const err = { code: 'auth/wrong-password' };
      signInWithEmailAndPassword.mockRejectedValue(err);

      await expect(authService.signIn('a@test.com', 'bad')).rejects.toEqual(err);
    });
  });

  describe('signOut', () => {
    it('should call firebase auth signOut', async () => {
      auth.signOut.mockResolvedValue(undefined);
      await authService.signOut();
      expect(auth.signOut).toHaveBeenCalled();
    });
  });

  describe('register', () => {
    it('should create Firebase user then create backend profile', async () => {
      const mockUser = { uid: 'uid-2', delete: vi.fn() };
      createUserWithEmailAndPassword.mockResolvedValue({ user: mockUser });
      http.post.mockResolvedValue({ id: 'uid-2' });

      const req = {
        email: 'b@test.com',
        password: 'Passw0rd!',
        firstName: 'John',
        lastName: 'Doe',
        dateOfBirth: '1990-01-01',
        bio: 'hello',
      };

      const uid = await authService.register(req);

      expect(createUserWithEmailAndPassword).toHaveBeenCalledWith(auth, req.email, req.password);
      expect(http.post).toHaveBeenCalledWith('/api/user', {
        id: 'uid-2',
        first_name: 'John',
        last_name: 'Doe',
        email: 'b@test.com',
        password: 'Passw0rd!',
        date_of_birth: '1990-01-01',
        bio: 'hello',
      });
      expect(uid).toBe('uid-2');
    });

    it('should accept snake_case date_of_birth as fallback', async () => {
      const mockUser = { uid: 'uid-3', delete: vi.fn() };
      createUserWithEmailAndPassword.mockResolvedValue({ user: mockUser });
      http.post.mockResolvedValue({ id: 'uid-3' });

      await authService.register({
        email: 'c@test.com',
        password: 'pw',
        date_of_birth: '1995-05-05',
      });

      expect(http.post).toHaveBeenCalledWith(
        '/api/user',
        expect.objectContaining({ date_of_birth: '1995-05-05' })
      );
    });

    it('should rollback (delete) Firebase user and throw when date of birth missing', async () => {
      const mockUser = { uid: 'uid-4', delete: vi.fn().mockResolvedValue(undefined) };
      createUserWithEmailAndPassword.mockResolvedValue({ user: mockUser });

      await expect(
        authService.register({ email: 'd@test.com', password: 'pw' })
      ).rejects.toThrow('Ngày sinh là bắt buộc để tạo tài khoản.');

      expect(mockUser.delete).toHaveBeenCalled();
      expect(http.post).not.toHaveBeenCalled();
    });

    it('should not throw if rollback delete itself fails', async () => {
      const mockUser = { uid: 'uid-5', delete: vi.fn().mockRejectedValue(new Error('delete failed')) };
      createUserWithEmailAndPassword.mockResolvedValue({ user: mockUser });

      await expect(
        authService.register({ email: 'e@test.com', password: 'pw' })
      ).rejects.toThrow('Ngày sinh là bắt buộc để tạo tài khoản.');
    });
  });

  describe('sendOtp', () => {
    it('should request OTP generation for an email', async () => {
      const mockResponse = { sent: true };
      http.post.mockResolvedValue(mockResponse);

      const result = await authService.sendOtp('a@test.com');

      expect(http.post).toHaveBeenCalledWith('/api/otp/generate', { email: 'a@test.com' });
      expect(result).toEqual(mockResponse);
    });
  });

  describe('verifyOtp', () => {
    it('should verify OTP without cached otp', async () => {
      const mockResponse = { valid: true };
      http.post.mockResolvedValue(mockResponse);

      const result = await authService.verifyOtp('a@test.com', '123456');

      expect(http.post).toHaveBeenCalledWith('/api/otp/verify', {
        email: 'a@test.com',
        otp: '123456',
      });
      expect(result).toEqual(mockResponse);
    });

    it('should include cached_otp when provided', async () => {
      http.post.mockResolvedValue({ valid: true });

      await authService.verifyOtp('a@test.com', '123456', '999999');

      expect(http.post).toHaveBeenCalledWith('/api/otp/verify', {
        email: 'a@test.com',
        otp: '123456',
        cached_otp: '999999',
      });
    });
  });

  describe('getMe / getById / search', () => {
    it('should fetch current user profile', async () => {
      const mockResponse = { id: 'uid-1', email: 'a@test.com' };
      http.get.mockResolvedValue(mockResponse);

      const result = await authService.getMe();

      expect(http.get).toHaveBeenCalledWith('/api/user/me');
      expect(result).toEqual(mockResponse);
    });

    it('should fetch a user by id', async () => {
      http.get.mockResolvedValue({ id: 'uid-9' });
      await authService.getById('uid-9');
      expect(http.get).toHaveBeenCalledWith('/api/user/uid-9');
    });

    it('should search users by keyword', async () => {
      http.get.mockResolvedValue([{ id: 'u1' }]);
      await authService.search('john');
      expect(http.get).toHaveBeenCalledWith('/api/user/search', { q: 'john' });
    });
  });

  describe('updateMe', () => {
    it('should PUT partial profile updates', async () => {
      const payload = { bio: 'new bio' };
      http.put.mockResolvedValue({ id: 'uid-1', ...payload });

      const result = await authService.updateMe(payload);

      expect(http.put).toHaveBeenCalledWith('/api/user/me', payload);
      expect(result.bio).toBe('new bio');
    });
  });

  describe('updateAvatar', () => {
    it('should upload avatar as FormData under "File" key', async () => {
      const file = new File(['data'], 'avatar.png', { type: 'image/png' });
      http.upload.mockResolvedValue({ avatar_url: 'https://cdn/a.png' });

      const result = await authService.updateAvatar(file);

      expect(http.upload).toHaveBeenCalledWith('/api/user/avatar', expect.any(FormData));
      const fdArg = http.upload.mock.calls[0][1];
      expect(fdArg.get('File')).toBe(file);
      expect(result).toEqual({ avatar_url: 'https://cdn/a.png' });
    });
  });

  describe('deleteMe', () => {
    it('should delete a user by id', async () => {
      http.delete.mockResolvedValue(undefined);
      await authService.deleteMe('uid-1');
      expect(http.delete).toHaveBeenCalledWith('/api/user/uid-1');
    });
  });

  describe('Error handling', () => {
    it('should propagate network errors from sendOtp', async () => {
      const networkError = new Error('network_error');
      http.post.mockRejectedValue(networkError);

      await expect(authService.sendOtp('a@test.com')).rejects.toThrow('network_error');
    });

    it('should propagate server errors from getMe', async () => {
      const serverError = new Error('HTTP 500');
      serverError.status = 500;
      http.get.mockRejectedValue(serverError);

      await expect(authService.getMe()).rejects.toThrow('HTTP 500');
    });
  });
});
