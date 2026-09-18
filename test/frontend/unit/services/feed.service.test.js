import { describe, it, expect, vi, beforeEach } from 'vitest';
import { feedService, storyService } from '@/services/feed.service';
import { http } from '@/lib/httpClient';

vi.mock('@/lib/httpClient', () => ({
  http: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
    upload: vi.fn(),
  },
}));

describe('feedService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getAll', () => {
    it('should fetch all feeds', async () => {
      const mockFeeds = [{ id: 'f1' }, { id: 'f2' }];
      http.get.mockResolvedValue(mockFeeds);

      const result = await feedService.getAll();

      expect(http.get).toHaveBeenCalledWith('/api/feed');
      expect(result).toEqual(mockFeeds);
    });
  });

  describe('getNewsfeed', () => {
    it('should fetch newsfeed', async () => {
      const mockFeed = [{ id: 'f1', type: 'post' }];
      http.get.mockResolvedValue(mockFeed);

      const result = await feedService.getNewsfeed();

      expect(http.get).toHaveBeenCalledWith('/api/feed/newsfeed');
      expect(result).toEqual(mockFeed);
    });
  });

  describe('getStories', () => {
    it('should fetch stories', async () => {
      const mockStories = [{ id: 's1', type: 'story' }];
      http.get.mockResolvedValue(mockStories);

      const result = await feedService.getStories();

      expect(http.get).toHaveBeenCalledWith('/api/feed/stories');
      expect(result).toEqual(mockStories);
    });
  });

  describe('createFeed', () => {
    it('should create a text post', async () => {
      const mockFeed = { id: 'f-new', content: 'New post' };
      http.upload.mockResolvedValue(mockFeed);

      const result = await feedService.createFeed({
        content: 'New post',
        type: 'post',
      });

      expect(http.upload).toHaveBeenCalledWith('/api/feed', expect.any(FormData));
      const fd = http.upload.mock.calls[0][1];
      expect(fd.get('Type')).toBe('post');
      expect(fd.get('Content.Caption')).toBe('New post');
      expect(result).toEqual(mockFeed);
    });

    it('should create a feed with media URL', async () => {
      http.upload.mockResolvedValue({ id: 'f2' });

      await feedService.createFeed({
        content: 'Check this out',
        type: 'post',
        mediaUrl: 'https://cdn/photo.jpg',
        privacy: 'public',
      });

      const fd = http.upload.mock.calls[0][1];
      expect(fd.get('Type')).toBe('post');
      expect(fd.get('Content.Caption')).toBe('Check this out');
      expect(fd.get('MediaUrl')).toBe('https://cdn/photo.jpg');
      expect(fd.get('Privacy')).toBe('public');
    });
  });

  describe('updateFeed', () => {
    it('should update a feed', async () => {
      const updated = { id: 'f1', content: 'Updated' };
      http.put.mockResolvedValue(updated);

      const result = await feedService.updateFeed('f1', {
        content: 'Updated',
      });

      expect(http.put).toHaveBeenCalledWith('/api/feed/f1', {
        content: 'Updated',
      });
      expect(result).toEqual(updated);
    });
  });

  describe('deleteFeed', () => {
    it('should delete a feed', async () => {
      http.delete.mockResolvedValue(undefined);

      await feedService.deleteFeed('f1');

      expect(http.delete).toHaveBeenCalledWith('/api/feed/f1');
    });
  });

  describe('like / unlike', () => {
    it('should toggle like on a feed', async () => {
      http.post.mockResolvedValue({ liked: true });

      await feedService.like('f1');

      expect(http.post).toHaveBeenCalledWith('/api/feed/f1/like');
    });

    it('should toggle unlike on a feed', async () => {
      http.post.mockResolvedValue({ liked: false });

      await feedService.unlike('f1');

      expect(http.post).toHaveBeenCalledWith('/api/feed/f1/like');
    });
  });

  describe('comment', () => {
    it('should add a comment to a feed', async () => {
      const mockComment = { id: 'c1', content: 'Nice!' };
      http.post.mockResolvedValue(mockComment);

      const result = await feedService.comment('f1', {
        content: 'Nice!',
      });

      expect(http.post).toHaveBeenCalledWith('/api/feed/f1/comments', {
        content: 'Nice!',
      });
      expect(result).toEqual(mockComment);
    });
  });

  describe('deleteComment', () => {
    it('should delete a comment', async () => {
      http.delete.mockResolvedValue(undefined);

      await feedService.deleteComment('f1', 'c1');

      expect(http.delete).toHaveBeenCalledWith('/api/feed/f1/comments/c1');
    });
  });

  describe('hide', () => {
    it('should hide a feed', async () => {
      http.post.mockResolvedValue({ success: true });

      await feedService.hide('f1');

      expect(http.post).toHaveBeenCalledWith('/api/feed/f1/hide');
    });
  });

  describe('view', () => {
    it('should mark a feed as viewed', async () => {
      http.post.mockResolvedValue({ success: true });

      await feedService.view('f1');

      expect(http.post).toHaveBeenCalledWith('/api/feed/f1/view');
    });
  });

  describe('Error handling', () => {
    it('should propagate errors from getAll', async () => {
      http.get.mockRejectedValue(new Error('Fetch failed'));

      await expect(feedService.getAll()).rejects.toThrow('Fetch failed');
    });

    it('should propagate errors from createFeed', async () => {
      http.upload.mockRejectedValue(new Error('Create failed'));

      await expect(feedService.createFeed({ content: 'test' })).rejects.toThrow('Create failed');
    });
  });
});

describe('storyService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getAll', () => {
    it('should fetch all stories', async () => {
      const mockStories = [{ id: 's1' }, { id: 's2' }];
      http.get.mockResolvedValue(mockStories);

      const result = await storyService.getAll();

      expect(http.get).toHaveBeenCalledWith('/api/feed/stories');
      expect(result).toEqual(mockStories);
    });
  });

  describe('create', () => {
    it('should create a story', async () => {
      const mockStory = { id: 's-new', type: 'story' };
      http.post.mockResolvedValue(mockStory);

      const result = await storyService.create({
        content: 'My story',
        media_url: 'https://cdn/story.jpg',
      });

      expect(http.post).toHaveBeenCalledWith('/api/feed/stories', {
        content: 'My story',
        media_url: 'https://cdn/story.jpg',
      });
      expect(result).toEqual(mockStory);
    });
  });

  describe('Error handling', () => {
    it('should propagate errors from getAll', async () => {
      http.get.mockRejectedValue(new Error('Fetch failed'));

      await expect(storyService.getAll()).rejects.toThrow('Fetch failed');
    });

    it('should propagate errors from create', async () => {
      http.post.mockRejectedValue(new Error('Create failed'));

      await expect(storyService.create({ content: 'test' })).rejects.toThrow('Create failed');
    });
  });
});
