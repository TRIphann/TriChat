import { useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useFeedStore } from '../../store/feedStore';
import { Avatar, Button } from '../ui';
import { staggerCards, likeBounce } from '../../lib/anime';
import { formatRelativeShort } from '../../lib/format';
import './newsfeedView.css';

/**
 * NewsfeedView — có thể dùng full-page hoặc embedded trong panel.
 * Props:
 *  - embedded: true → không có header (panel đã có), không có padding ngoài
 *  - scope: 'global' | 'group' | 'user' (filter theo id)
 *  - scopeId: id của group/user (khi scope != 'global')
 */
export default function NewsfeedView({ embedded = false, scope = 'global', scopeId = null }) {
  const posts = useFeedStore((s) => s.posts);
  const stories = useFeedStore((s) => s.stories);
  const loadPosts = useFeedStore((s) => s.loadPosts);
  const loadStories = useFeedStore((s) => s.loadStories);
  const nav = useNavigate();
  const listRef = useRef(null);

  useEffect(() => {
    loadPosts();
    loadStories();
  }, [loadPosts, loadStories]);

  useEffect(() => {
    if (listRef.current && posts.length) {
      staggerCards(listRef.current.querySelectorAll('.post-card'), { gap: 70, dur: 540, y: 16 });
    }
  }, [posts.length]);

  const filteredPosts = scope === 'global'
    ? posts
    : posts.filter((p) => (scope === 'group' ? p.groupId === scopeId : p.authorId === scopeId));

  return (
    <div className={`newsfeed-view ${embedded ? 'is-embedded' : ''}`}>
      {!embedded && (
        <header className="newsfeed-view__header">
          <h1 className="newsfeed-view__title text-serif">Bảng tin</h1>
          <div className="newsfeed-view__actions">
            <Button variant="secondary" size="md" onClick={() => nav('/create-story')}>
              + Tin nhanh
            </Button>
            <Button variant="primary" size="md" onClick={() => nav('/create-post')}>
              + Bài viết
            </Button>
          </div>
        </header>
      )}

      {stories.length > 0 && (
        <div className="newsfeed-view__stories no-scrollbar">
          {stories.map((s) => (
            <button
              key={s.id}
              className="story-chip"
              onClick={() => nav('/story-viewer', { state: { startId: s.id } })}
            >
              <Avatar
                src={s.mediaUrl || s.thumbnailUrl}
                name={s.authorName}
                size={64}
                ring
              />
              <span className="story-chip__name">
                {s.authorName?.split(' ')[0] || '...'}
              </span>
            </button>
          ))}
        </div>
      )}

      <div className="newsfeed-view__list" ref={listRef}>
        {filteredPosts.length === 0 ? (
          <div className="empty-state empty-state--compact">
            <div className="empty-state__icon">🌿</div>
            <h3>Chưa có bài viết nào</h3>
            <p>Hãy là người đầu tiên chia sẻ khoảnh khắc!</p>
          </div>
        ) : (
          filteredPosts.map((p) => <PostCard key={p.id} post={p} />)
        )}
      </div>
    </div>
  );
}

function PostCard({ post }) {
  const toggleLike = useFeedStore((s) => s.toggleLike);
  const onLikeClick = (e) => {
    likeBounce(e.currentTarget);
    toggleLike(post.id);
  };
  return (
    <article className="post-card">
      <header className="post-card__header">
        <Avatar src={post.authorAvatar} name={post.authorName} size={44} />
        <div>
          <div className="post-card__name">{post.authorName}</div>
          <div className="post-card__time">
            {formatRelativeShort(post.createdAt)}
          </div>
        </div>
      </header>
      <p className="post-card__content">{post.content}</p>
      {post.mediaUrl && (
        <img src={post.mediaUrl} alt="" className="post-card__media" loading="lazy" />
      )}
      <footer className="post-card__footer">
        <button
          className={`post-card__like ${post.isLiked ? 'is-liked' : ''}`}
          onClick={onLikeClick}
        >
          {post.isLiked ? '❤️' : '🤍'} {post.likeCount || 0}
        </button>
        <button className="post-card__comment">💬 {post.commentCount || 0}</button>
        <button className="post-card__share">↗ Chia sẻ</button>
      </footer>
    </article>
  );
}
