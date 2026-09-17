import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button, Input } from '../../components/ui';
import { useFeedStore } from '../../store/feedStore';
import { pickFile, readAsDataUrl } from '../../lib/format';
import { useUiStore } from '../../store/uiStore';

export default function CreatePost() {
  const nav = useNavigate();
  const showToast = useUiStore((s) => s.showToast);
  const createPost = useFeedStore((s) => s.createPost);
  const [content, setContent] = useState('');
  const [media, setMedia] = useState(null);
  const [loading, setLoading] = useState(false);

  async function pickImage() {
    const file = await pickFile('image/*');
    if (!file) return;
    setMedia({ file, preview: await readAsDataUrl(file) });
  }

  async function submit() {
    if (!content.trim() && !media) return;
    setLoading(true);
    try {
      await createPost({ content, mediaUrl: media?.preview });
      showToast('Đã đăng bài viết', 'success');
      nav('/newfeed');
    } catch (e) {
      showToast(e.message, 'error');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div style={{ maxWidth: 600, margin: '0 auto' }}>
      <button className="chat-list__new" onClick={() => nav(-1)} style={{ marginBottom: 16 }}>← Quay lại</button>
      <h1 className="text-serif" style={{ fontSize: 28, margin: '0 0 20px' }}>Tạo bài viết</h1>
      <textarea
        value={content}
        onChange={(e) => setContent(e.target.value)}
        placeholder="Bạn đang nghĩ gì?"
        style={{
          width: '100%',
          minHeight: 160,
          padding: 18,
          borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--hairline)',
          background: 'var(--card)',
          color: 'var(--text)',
          fontSize: 15,
          resize: 'vertical',
          outline: 'none',
        }}
      />
      {media && (
        <div style={{ position: 'relative', marginTop: 12 }}>
          <img src={media.preview} alt="" style={{ width: '100%', borderRadius: 'var(--radius-lg)' }} />
          <button
            onClick={() => setMedia(null)}
            style={{ position: 'absolute', top: 8, right: 8, width: 32, height: 32, borderRadius: '50%', background: 'rgba(0,0,0,0.6)', color: '#fff' }}
          >×</button>
        </div>
      )}
      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 16 }}>
        <Button variant="secondary" onClick={pickImage}>📷 Thêm ảnh</Button>
        <Button variant="primary" loading={loading} onClick={submit}>Đăng</Button>
      </div>
    </div>
  );
}
