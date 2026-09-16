import { useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useFeedStore } from '../../store/feedStore';
import { Avatar, Button } from '../../components/ui';
import { staggerCards, likeBounce } from '../../lib/anime';
import { formatRelativeShort } from '../../lib/format';
import './newsfeed.css';

export default function Newsfeed() {
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
      staggerCards(listRef.current.querySelectorAll('.post-card'), { gap: 80, dur: 600 });
    }
  }, [posts.length]);

  return (
    <div className="newsfeed">
      <header className="newsfeed__header">
        <h1 className="newsfeed__title text-serif">Bảng tin</h1>
        <div className="newsfeed__actions">
          <Button variant="secondary" size="md" onClick={() => nav('/create-story')}>+ Tin nhanh</Button>
          <Button variant="primary" size="md" onClick={() => nav('/create-post')}>+ Bài viết</Button>
        </div>
      </header>

      {stories.length > 0 && (
        <div className="newsfeed__stories no-scrollbar">
          {stories.map((s) => (
            <button key={s.id} className="story-chip" onClick={() => nav('/story-viewer', { state: { startId: s.id } })}>
              <Avatar src={s.mediaUrl || s.thumbnailUrl} name={s.authorName} size={64} ring />
              <span className="story-chip__name">{s.authorName?.split(' ')[0] || '...'}</span>
            </button>
          ))}
        </div>
      )}

      <div className="newsfeed__list" ref={listRef}>
        {posts.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state__icon">🌿</div>
            <h3>Chưa có bài viết nào</h3>
            <p>Hãy là người đầu tiên chia sẻ khoảnh khắc!</p>
          </div>
        ) : (
          posts.map((p) => <PostCard key={p.id} post={p} />)
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
          <div className="post-card__time">{formatRelativeShort(post.createdAt)}</div>
        </div>
      </header>
      <p className="post-card__content">{post.content}</p>
      {post.mediaUrl && <img src={post.mediaUrl} alt="" className="post-card__media" loading="lazy" />}
      <footer className="post-card__footer">
        <button className={`post-card__like ${post.isLiked ? 'is-liked' : ''}`} onClick={onLikeClick}>
          {post.isLiked ? '❤️' : '🤍'} {post.likeCount || 0}
        </button>
        <button className="post-card__comment">💬 {post.commentCount || 0}</button>
        <button className="post-card__share">↗ Chia sẻ</button>
      </footer>
    </article>
  );
}
