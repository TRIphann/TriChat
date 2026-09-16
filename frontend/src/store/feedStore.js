import { create } from 'zustand';
import { feedService } from '../services/feed.service';

export const useFeedStore = create((set, get) => ({
  posts: [],
  stories: [],
  loadingPosts: false,
  loadingStories: false,

  async loadPosts() {
    set({ loadingPosts: true });
    try {
      const list = await feedService.getNewsfeed();
      set({ posts: list || [], loadingPosts: false });
    } catch (e) {
      set({ loadingPosts: false });
    }
  },

  async loadStories() {
    set({ loadingStories: true });
    try {
      const list = await feedService.getStories();
      set({ stories: list || [], loadingStories: false });
    } catch (e) {
      set({ loadingStories: false });
    }
  },

  async toggleLike(postId) {
    const post = get().posts.find((p) => p.id === postId);
    if (!post) return;
    set((s) => ({
      posts: s.posts.map((p) =>
        p.id === postId
          ? { ...p, isLiked: !p.isLiked, likeCount: p.likeCount + (p.isLiked ? -1 : 1) }
          : p,
      ),
    }));
    try {
      if (post.isLiked) await feedService.unlike(postId);
      else await feedService.like(postId);
    } catch (e) {
      // rollback
      set((s) => ({
        posts: s.posts.map((p) =>
          p.id === postId
            ? { ...p, isLiked: post.isLiked, likeCount: post.likeCount }
            : p,
        ),
      }));
    }
  },

  async createPost(payload) {
    const created = await feedService.createFeed(payload);
    set((s) => ({ posts: [created, ...s.posts] }));
    return created;
  },

  async createStory(payload) {
    const created = await feedService.createFeed({ ...payload, type: 'story' });
    return created;
  },
}));
