import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '../../components/ui';
import { pickFile, readAsDataUrl } from '../../lib/format';
import { useUiStore } from '../../store/uiStore';
import { useFeedStore } from '../../store/feedStore';

export default function CreateStory() {
  const nav = useNavigate();
  const showToast = useUiStore((s) => s.showToast);
  const createStory = useFeedStore((s) => s.createStory);
  const [media, setMedia] = useState(null);
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(false);

  async function pick() {
    const file = await pickFile('image/*');
    if (!file) return;
    setMedia({ file, preview: await readAsDataUrl(file) });
  }

  async function submit() {
    if (!media) return;
    setLoading(true);
    try {
      await createStory({ mediaUrl: media.preview, content: text });
      showToast('Đã đăng tin nhanh', 'success');
      nav('/newfeed');
    } catch (e) {
      showToast(e.message, 'error');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div style={{ maxWidth: 480, margin: '0 auto' }}>
      <button className="chat-list__new" onClick={() => nav(-1)} style={{ marginBottom: 16 }}>← Quay lại</button>
      <h1 className="text-serif" style={{ fontSize: 28, margin: '0 0 20px' }}>Tạo tin nhanh</h1>
      <div
        style={{
          aspectRatio: '9/16',
          background: media ? '#000' : 'var(--surface)',
          borderRadius: 'var(--radius-xl)',
          overflow: 'hidden',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          position: 'relative',
        }}
      >
        {media ? (
          <>
            <img src={media.preview} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
            <input
              value={text}
              onChange={(e) => setText(e.target.value)}
              placeholder="Gõ văn bản..."
              style={{
                position: 'absolute',
                top: '50%',
                left: '50%',
                transform: 'translate(-50%, -50%)',
                background: 'rgba(0,0,0,0.4)',
                border: 'none',
                padding: '10px 16px',
                color: '#fff',
                fontSize: 20,
                borderRadius: 'var(--radius-pill)',
                outline: 'none',
                minWidth: 240,
                textAlign: 'center',
              }}
            />
          </>
        ) : (
          <Button onClick={pick} variant="primary" size="lg">+ Chọn ảnh</Button>
        )}
      </div>
      {media && (
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 16 }}>
          <Button variant="ghost" onClick={() => setMedia(null)}>Đổi ảnh</Button>
          <Button variant="primary" loading={loading} onClick={submit}>Đăng tin</Button>
        </div>
      )}
    </div>
  );
}
