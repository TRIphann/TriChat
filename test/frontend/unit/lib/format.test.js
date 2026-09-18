import { describe, it, expect, vi } from 'vitest';
import {
  formatTime,
  formatDateTime,
  formatLastSeen,
  formatRelativeShort,
  formatFileSize,
  debounce,
  pickFile,
  blobToFile,
  readAsDataUrl,
} from '@/lib/format';

describe('format.js', () => {
  describe('formatTime()', () => {
    it('should format time as HH:mm', () => {
      const date = new Date('2026-09-18T14:30:00');
      expect(formatTime(date)).toBe('14:30');
    });

    it('should pad single digit hours and minutes', () => {
      const date = new Date('2026-09-18T09:05:00');
      expect(formatTime(date)).toBe('09:05');
    });

    it('should handle midnight', () => {
      const date = new Date('2026-09-18T00:00:00');
      expect(formatTime(date)).toBe('00:00');
    });

    it('should handle noon', () => {
      const date = new Date('2026-09-18T12:00:00');
      expect(formatTime(date)).toBe('12:00');
    });
  });

  describe('formatDateTime()', () => {
    it('should format full datetime', () => {
      const date = new Date('2026-09-18T14:30:45');
      expect(formatDateTime(date)).toBe('14:30 18/9/2026');
    });

    it('should pad time but not date', () => {
      const date = new Date('2026-01-05T09:05:00');
      expect(formatDateTime(date)).toBe('09:05 5/1/2026');
    });
  });

  describe('formatLastSeen()', () => {
    it('should return "Vừa xong" for less than 1 minute', () => {
      const now = Date.now();
      const recent = new Date(now - 30000); // 30 seconds ago
      expect(formatLastSeen(recent)).toBe('Vừa xong');
    });

    it('should return minutes for less than 1 hour', () => {
      const now = Date.now();
      const recent = new Date(now - 15 * 60 * 1000); // 15 minutes ago
      expect(formatLastSeen(recent)).toBe('15 phút trước');
    });

    it('should return hours for less than 1 day', () => {
      const now = Date.now();
      const recent = new Date(now - 5 * 60 * 60 * 1000); // 5 hours ago
      expect(formatLastSeen(recent)).toBe('5 giờ trước');
    });

    it('should return days for 1+ days', () => {
      const now = Date.now();
      const recent = new Date(now - 3 * 24 * 60 * 60 * 1000); // 3 days ago
      expect(formatLastSeen(recent)).toBe('3 ngày trước');
    });

    it('should return empty string for null/undefined', () => {
      expect(formatLastSeen(null)).toBe('');
      expect(formatLastSeen(undefined)).toBe('');
    });

    it('should handle future dates (return "Vừa xong")', () => {
      const future = new Date(Date.now() + 5000);
      expect(formatLastSeen(future)).toBe('Vừa xong');
    });
  });

  describe('formatRelativeShort()', () => {
    it('should return time for same day', () => {
      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 14, 30);
      expect(formatRelativeShort(today)).toBe('14:30');
    });

    it('should return weekday for within 7 days', () => {
      const now = new Date('2026-09-18T12:00:00');
      const threeDaysAgo = new Date('2026-09-15T10:00:00');
      
      // Mock the current date for this test
      const originalDate = global.Date;
      global.Date = class extends originalDate {
        constructor(...args) {
          if (args.length === 0) {
            return now;
          }
          return new originalDate(...args);
        }
      };

      const result = formatRelativeShort(threeDaysAgo);
      // toLocaleDateString returns abbreviated weekday which varies by locale
      // Just check it's not a time format and not dd/mm format
      expect(result).not.toMatch(/^\d{2}:\d{2}$/);
      expect(result).not.toMatch(/^\d{2}\/\d{2}$/);

      global.Date = originalDate;
    });

    it('should return dd/mm for older than 7 days', () => {
      const now = new Date('2026-09-18T12:00:00');
      const tenDaysAgo = new Date('2026-09-08T10:00:00');

      const originalDate = global.Date;
      global.Date = class extends originalDate {
        constructor(...args) {
          if (args.length === 0) {
            return now;
          }
          return new originalDate(...args);
        }
      };

      const result = formatRelativeShort(tenDaysAgo);
      // toLocaleDateString format varies, just check it includes day and month
      expect(result).toMatch(/08/);
      expect(result).toMatch(/09/);

      global.Date = originalDate;
    });
  });

  describe('formatFileSize()', () => {
    it('should format bytes', () => {
      expect(formatFileSize(0)).toBe('0 B');
      expect(formatFileSize(512)).toBe('512 B');
      expect(formatFileSize(1023)).toBe('1023 B');
    });

    it('should format KB', () => {
      expect(formatFileSize(1024)).toBe('1.0 KB');
      expect(formatFileSize(5120)).toBe('5.0 KB');
      expect(formatFileSize(10240)).toBe('10.0 KB');
      expect(formatFileSize(512 * 1024)).toBe('512.0 KB');
    });

    it('should format MB', () => {
      expect(formatFileSize(1024 * 1024)).toBe('1.0 MB');
      expect(formatFileSize(5 * 1024 * 1024)).toBe('5.0 MB');
      expect(formatFileSize(1536 * 1024)).toBe('1.5 MB');
      expect(formatFileSize(100 * 1024 * 1024)).toBe('100.0 MB');
    });

    it('should return empty string for null/undefined', () => {
      expect(formatFileSize(null)).toBe('');
      expect(formatFileSize(undefined)).toBe('');
    });
  });

  describe('debounce()', () => {
    it('should debounce function calls', async () => {
      vi.useFakeTimers();
      const fn = vi.fn();
      const debounced = debounce(fn, 300);

      debounced('call1');
      debounced('call2');
      debounced('call3');

      expect(fn).not.toHaveBeenCalled();

      vi.advanceTimersByTime(300);
      expect(fn).toHaveBeenCalledTimes(1);
      expect(fn).toHaveBeenCalledWith('call3');

      vi.useRealTimers();
    });

    it('should call function after wait period', async () => {
      vi.useFakeTimers();
      const fn = vi.fn();
      const debounced = debounce(fn, 500);

      debounced('test');
      vi.advanceTimersByTime(499);
      expect(fn).not.toHaveBeenCalled();

      vi.advanceTimersByTime(1);
      expect(fn).toHaveBeenCalledWith('test');

      vi.useRealTimers();
    });

    it('should use default wait of 300ms', async () => {
      vi.useFakeTimers();
      const fn = vi.fn();
      const debounced = debounce(fn);

      debounced();
      vi.advanceTimersByTime(299);
      expect(fn).not.toHaveBeenCalled();

      vi.advanceTimersByTime(1);
      expect(fn).toHaveBeenCalledTimes(1);

      vi.useRealTimers();
    });
  });

  describe('pickFile()', () => {
    it('should return selected file', async () => {
      const mockFile = new File(['content'], 'test.txt', { type: 'text/plain' });
      
      // Mock createElement and click
      const mockInput = {
        type: '',
        accept: '',
        multiple: false,
        files: [mockFile],
        click: vi.fn(),
        onchange: null,
      };

      const originalCreateElement = document.createElement;
      document.createElement = vi.fn((tag) => {
        if (tag === 'input') return mockInput;
        return originalCreateElement.call(document, tag);
      });

      const promise = pickFile('image/*', false);
      
      // Trigger onchange
      mockInput.onchange();

      const result = await promise;
      expect(result).toBe(mockFile);
      expect(mockInput.accept).toBe('image/*');
      expect(mockInput.multiple).toBe(false);

      document.createElement = originalCreateElement;
    });

    it('should return multiple files when multiple=true', async () => {
      const mockFiles = [
        new File(['1'], 'file1.txt', { type: 'text/plain' }),
        new File(['2'], 'file2.txt', { type: 'text/plain' }),
      ];

      const mockInput = {
        type: '',
        accept: '',
        multiple: false,
        files: mockFiles,
        click: vi.fn(),
        onchange: null,
      };

      const originalCreateElement = document.createElement;
      document.createElement = vi.fn((tag) => {
        if (tag === 'input') return mockInput;
        return originalCreateElement.call(document, tag);
      });

      const promise = pickFile('*/*', true);
      mockInput.onchange();

      const result = await promise;
      expect(result).toEqual(mockFiles);
      expect(mockInput.multiple).toBe(true);

      document.createElement = originalCreateElement;
    });

    it('should return null when no file selected', async () => {
      const mockInput = {
        type: '',
        accept: '',
        multiple: false,
        files: [],
        click: vi.fn(),
        onchange: null,
      };

      const originalCreateElement = document.createElement;
      document.createElement = vi.fn((tag) => {
        if (tag === 'input') return mockInput;
        return originalCreateElement.call(document, tag);
      });

      const promise = pickFile();
      mockInput.onchange();

      const result = await promise;
      expect(result).toBeNull();

      document.createElement = originalCreateElement;
    });
  });

  describe('blobToFile()', () => {
    it('should convert blob to file', async () => {
      const blob = new Blob(['test content'], { type: 'text/plain' });
      const file = await blobToFile(blob, 'test.txt');

      expect(file).toBeInstanceOf(File);
      expect(file.name).toBe('test.txt');
      expect(file.type).toBe('text/plain');
    });

    it('should preserve blob type', async () => {
      const blob = new Blob(['<svg></svg>'], { type: 'image/svg+xml' });
      const file = await blobToFile(blob, 'icon.svg');

      expect(file.type).toBe('image/svg+xml');
      expect(file.name).toBe('icon.svg');
    });
  });

  describe('readAsDataUrl()', () => {
    it('should read file as data URL', async () => {
      const file = new File(['hello'], 'test.txt', { type: 'text/plain' });
      
      // Mock FileReader
      const mockReader = {
        readAsDataURL: vi.fn(function() {
          this.onload();
        }),
        result: 'data:text/plain;base64,aGVsbG8=',
        onload: null,
        onerror: null,
      };

      global.FileReader = vi.fn(() => mockReader);

      const result = await readAsDataUrl(file);

      expect(result).toBe('data:text/plain;base64,aGVsbG8=');
      expect(mockReader.readAsDataURL).toHaveBeenCalledWith(file);
    });

    it('should reject on read error', async () => {
      const file = new File(['test'], 'test.txt');
      const mockError = new Error('Read failed');

      const mockReader = {
        readAsDataURL: vi.fn(function() {
          this.onerror(mockError);
        }),
        result: null,
        onload: null,
        onerror: null,
      };

      global.FileReader = vi.fn(() => mockReader);

      await expect(readAsDataUrl(file)).rejects.toThrow();
    });
  });
});
