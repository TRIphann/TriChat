import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { api, http } from '@/lib/httpClient';
import { auth } from '@/lib/firebase';

// Mock fetch
global.fetch = vi.fn();

// Mock firebase auth
vi.mock('@/lib/firebase', () => ({
  auth: {
    currentUser: null,
  },
}));

describe('httpClient', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    auth.currentUser = null;
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('api()', () => {
    it('should make GET request without auth', async () => {
      const mockData = { result: { id: '1', name: 'Test' } };
      global.fetch.mockResolvedValue({
        ok: true,
        status: 200,
        text: async () => JSON.stringify(mockData),
      });

      const result = await api('/test');

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:5244/test',
        expect.objectContaining({
          method: 'GET',
          headers: {},
        })
      );
      expect(result).toEqual(mockData.result);
    });

    it('should add Authorization header when user is logged in', async () => {
      auth.currentUser = {
        getIdToken: vi.fn().mockResolvedValue('mock-token-123'),
      };

      global.fetch.mockResolvedValue({
        ok: true,
        status: 200,
        text: async () => JSON.stringify({ result: { success: true } }),
      });

      await api('/protected');

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:5244/protected',
        expect.objectContaining({
          headers: expect.objectContaining({
            Authorization: 'Bearer mock-token-123',
          }),
        })
      );
    });

    it('should make POST request with JSON body', async () => {
      auth.currentUser = {
        getIdToken: vi.fn().mockResolvedValue('token'),
      };

      const payload = { name: 'John', email: 'john@test.com' };

      global.fetch.mockResolvedValue({
        ok: true,
        status: 201,
        text: async () => JSON.stringify({ result: { id: '1' } }),
      });

      const result = await api('/users', { method: 'POST', body: payload });

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:5244/users',
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'Content-Type': 'application/json',
          }),
          body: JSON.stringify(payload),
        })
      );
      expect(result).toEqual({ id: '1' });
    });

    it('should handle FormData upload', async () => {
      auth.currentUser = {
        getIdToken: vi.fn().mockResolvedValue('token'),
      };

      const formData = new FormData();
      formData.append('file', new Blob(['test']), 'test.txt');

      global.fetch.mockResolvedValue({
        ok: true,
        status: 200,
        text: async () => JSON.stringify({ result: { url: 'https://cdn.test/file.txt' } }),
      });

      const result = await api('/upload', { method: 'POST', body: formData, isForm: true });

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:5244/upload',
        expect.objectContaining({
          method: 'POST',
          body: formData,
        })
      );
      expect(result).toEqual({ url: 'https://cdn.test/file.txt' });
    });

    it('should retry with refreshed token on 401', async () => {
      auth.currentUser = {
        getIdToken: vi
          .fn()
          .mockResolvedValueOnce('old-token')
          .mockResolvedValueOnce('new-token'),
      };

      global.fetch
        .mockResolvedValueOnce({
          ok: false,
          status: 401,
          text: async () => JSON.stringify({ message: 'Unauthorized' }),
        })
        .mockResolvedValueOnce({
          ok: true,
          status: 200,
          text: async () => JSON.stringify({ result: { data: 'success' } }),
        });

      const result = await api('/protected');

      expect(global.fetch).toHaveBeenCalledTimes(2);
      expect(auth.currentUser.getIdToken).toHaveBeenCalledWith(true);
      expect(result).toEqual({ data: 'success' });
    });

    it('should throw network_error on fetch failure', async () => {
      global.fetch.mockRejectedValue(new Error('Network down'));

      await expect(api('/test')).rejects.toThrow('network_error');
    });

    it('should throw error on 404', async () => {
      global.fetch.mockResolvedValue({
        ok: false,
        status: 404,
        text: async () => JSON.stringify({ message: 'Not found' }),
      });

      await expect(api('/missing')).rejects.toThrow('Not found');
    });

    it('should throw error on 500', async () => {
      global.fetch.mockResolvedValue({
        ok: false,
        status: 500,
        text: async () => 'Internal Server Error',
      });

      await expect(api('/error')).rejects.toThrow('Internal Server Error');
    });

    it('should handle plain text response', async () => {
      global.fetch.mockResolvedValue({
        ok: true,
        status: 200,
        text: async () => 'plain text',
      });

      const result = await api('/text');

      expect(result).toBe('plain text');
    });

    it('should handle empty response', async () => {
      global.fetch.mockResolvedValue({
        ok: true,
        status: 204,
        text: async () => '',
      });

      const result = await api('/no-content');

      expect(result).toBeNull();
    });
  });

  describe('http.get()', () => {
    it('should build query string from object', async () => {
      global.fetch.mockResolvedValue({
        ok: true,
        status: 200,
        text: async () => JSON.stringify({ result: [] }),
      });

      await http.get('/api/friends', { limit: 20, offset: 10, status: 'active' });

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:5244/api/friends?limit=20&offset=10&status=active',
        expect.any(Object)
      );
    });

    it('should work without query params', async () => {
      global.fetch.mockResolvedValue({
        ok: true,
        status: 200,
        text: async () => JSON.stringify({ result: {} }),
      });

      await http.get('/api/profile');

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:5244/api/profile',
        expect.any(Object)
      );
    });
  });

  describe('http.post()', () => {
    it('should POST with JSON body', async () => {
      global.fetch.mockResolvedValue({
        ok: true,
        status: 201,
        text: async () => JSON.stringify({ result: { id: '123' } }),
      });

      const result = await http.post('/api/messages', { content: 'Hello' });

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:5244/api/messages',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify({ content: 'Hello' }),
        })
      );
      expect(result).toEqual({ id: '123' });
    });
  });

  describe('http.put()', () => {
    it('should PUT with JSON body', async () => {
      global.fetch.mockResolvedValue({
        ok: true,
        status: 200,
        text: async () => JSON.stringify({ result: { updated: true } }),
      });

      const result = await http.put('/api/profile', { displayName: 'New Name' });

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:5244/api/profile',
        expect.objectContaining({
          method: 'PUT',
        })
      );
      expect(result).toEqual({ updated: true });
    });
  });

  describe('http.patch()', () => {
    it('should PATCH with JSON body', async () => {
      global.fetch.mockResolvedValue({
        ok: true,
        status: 200,
        text: async () => JSON.stringify({ result: { patched: true } }),
      });

      await http.patch('/api/messages/1', { read: true });

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:5244/api/messages/1',
        expect.objectContaining({
          method: 'PATCH',
        })
      );
    });
  });

  describe('http.delete()', () => {
    it('should DELETE resource', async () => {
      global.fetch.mockResolvedValue({
        ok: true,
        status: 204,
        text: async () => '',
      });

      await http.delete('/api/friends/123');

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:5244/api/friends/123',
        expect.objectContaining({
          method: 'DELETE',
        })
      );
    });
  });

  describe('http.upload()', () => {
    it('should upload FormData', async () => {
      const fd = new FormData();
      fd.append('avatar', new Blob(['img']), 'avatar.png');

      global.fetch.mockResolvedValue({
        ok: true,
        status: 200,
        text: async () => JSON.stringify({ result: { url: 'https://cdn/avatar.png' } }),
      });

      const result = await http.upload('/api/profile/avatar', fd);

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:5244/api/profile/avatar',
        expect.objectContaining({
          method: 'POST',
          body: fd,
        })
      );
      expect(result).toEqual({ url: 'https://cdn/avatar.png' });
    });
  });

  describe('Error message extraction', () => {
    it('should extract message field', async () => {
      global.fetch.mockResolvedValue({
        ok: false,
        status: 400,
        text: async () => JSON.stringify({ message: 'Invalid input' }),
      });

      await expect(api('/test')).rejects.toThrow('Invalid input');
    });

    it('should extract Message field (PascalCase)', async () => {
      global.fetch.mockResolvedValue({
        ok: false,
        status: 400,
        text: async () => JSON.stringify({ Message: 'PascalCase message' }),
      });

      await expect(api('/test')).rejects.toThrow('PascalCase message');
    });

    it('should extract error field', async () => {
      global.fetch.mockResolvedValue({
        ok: false,
        status: 500,
        text: async () => JSON.stringify({ error: 'Server crashed' }),
      });

      await expect(api('/test')).rejects.toThrow('Server crashed');
    });

    it('should fall back to HTTP status', async () => {
      global.fetch.mockResolvedValue({
        ok: false,
        status: 403,
        text: async () => JSON.stringify({}),
      });

      await expect(api('/test')).rejects.toThrow('HTTP 403');
    });

    it('should handle string response', async () => {
      global.fetch.mockResolvedValue({
        ok: false,
        status: 400,
        text: async () => 'Bad Request',
      });

      await expect(api('/test')).rejects.toThrow('Bad Request');
    });
  });
});
