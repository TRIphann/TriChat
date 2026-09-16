import { useLocation, useNavigate } from 'react-router-dom';
import { useFeedStore } from '../../store/feedStore';

export default function StoryViewer() {
  const loc = useLocation();
  const nav = useNavigate();
  const stories = useFeedStore((s) => s.stories);
  const startId = loc.state?.startId;
  const idx = Math.max(0, stories.findIndex((s) => s.id === startId));
  const story = stories[idx];

  if (!story) return <p>Không có tin nhanh nào.</p>;

  return (
    <div style={{ position: 'fixed', inset: 0, background: '#000', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <button
        onClick={() => nav(-1)}
        style={{ position: 'absolute', top: 16, right: 16, width: 40, height: 40, borderRadius: '50%', background: 'rgba(255,255,255,0.2)', color: '#fff', fontSize: 22 }}
      >×</button>
      {story.mediaUrl && <img src={story.mediaUrl} alt="" style={{ maxHeight: '100vh', maxWidth: '100%', objectFit: 'contain' }} />}
      <div style={{ position: 'absolute', bottom: 30, left: 0, right: 0, textAlign: 'center', color: '#fff', fontFamily: 'var(--font-serif)' }}>
        {story.content && <h2 style={{ margin: 0 }}>{story.content}</h2>}
        <p style={{ marginTop: 8, opacity: 0.7, fontSize: 13 }}>{story.authorName}</p>
      </div>
    </div>
  );
}
