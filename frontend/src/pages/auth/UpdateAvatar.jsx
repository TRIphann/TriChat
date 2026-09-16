import { useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button, Avatar, Card } from '../../components/ui';
import { authService } from '../../services/auth.service';
import { useUiStore } from '../../store/uiStore';
import { readAsDataUrl } from '../../lib/format';

export default function UpdateAvatar() {
  const nav = useNavigate();
  const showToast = useUiStore((s) => s.showToast);
  const fileRef = useRef(null);
  const [preview, setPreview] = useState(null);
  const [loading, setLoading] = useState(false);

  async function onPick(e) {
    const file = e.target.files?.[0];
    if (!file) return;
    setPreview(await readAsDataUrl(file));
  }

  async function save() {
    if (!preview) {
      nav('/chat-list');
      return;
    }
    setLoading(true);
    try {
      const blob = await (await fetch(preview)).blob();
      const file = new File([blob], 'avatar.jpg', { type: blob.type });
      await authService.updateAvatar(file);
      showToast('Đã cập nhật ảnh đại diện', 'success');
      nav('/chat-list');
    } catch (e) {
      showToast('Cập nhật thất bại', 'error');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-page">
      <Card glass className="auth-card page-in" style={{ textAlign: 'center' }}>
        <h1 className="auth-title">Ảnh đại diện</h1>
        <p className="auth-sub">Chọn ảnh đại diện để mọi người dễ nhận ra bạn.</p>
        <div style={{ display: 'flex', justifyContent: 'center', margin: '24px 0' }}>
          <button onClick={() => fileRef.current?.click()} style={{ background: 'transparent', border: 'none' }}>
            <Avatar src={preview} name="?" size={120} ring />
          </button>
          <input ref={fileRef} type="file" accept="image/*" onChange={onPick} style={{ display: 'none' }} />
        </div>
        <div style={{ display: 'flex', gap: 12, justifyContent: 'center' }}>
          <Button variant="ghost" size="md" onClick={() => nav('/chat-list')}>Bỏ qua</Button>
          <Button variant="primary" size="md" loading={loading} onClick={save}>Lưu</Button>
        </div>
      </Card>
    </div>
  );
}
