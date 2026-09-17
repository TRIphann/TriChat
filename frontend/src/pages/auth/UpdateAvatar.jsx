import { useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button, Avatar } from '../../components/ui';
import { authService } from '../../services/auth.service';
import { useUiStore } from '../../store/uiStore';
import { readAsDataUrl } from '../../lib/format';
import AuthShell from './AuthShell';

export default function UpdateAvatar() {
  const nav = useNavigate();
  const showToast = useUiStore((s) => s.showToast);
  const fileRef = useRef(null);
  const [preview, setPreview] = useState(null);
  const [loading, setLoading] = useState(false);

  async function onPick(e) {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type?.startsWith?.('image/')) {
      showToast('Vui lòng chọn file ảnh', 'error');
      return;
    }
    setPreview(await readAsDataUrl(file));
  }

  async function save() {
    if (!preview) {
      nav('/app');
      return;
    }
    setLoading(true);
    try {
      const blob = await (await fetch(preview)).blob();
      const mime = blob.type || 'image/jpeg';
      const file = new File([blob], 'avatar.jpg', { type: mime });
      await authService.updateAvatar(file);
      showToast('Đã cập nhật ảnh đại diện', 'success');
      nav('/app');
    } catch (e) {
      showToast(e?.message || 'Cập nhật thất bại', 'error');
    } finally {
      setLoading(false);
    }
  }

  return (
    <AuthShell
      eyebrow="Bước cuối"
      title="Chọn ảnh đại diện"
      sub="Ảnh đại diện giúp bạn bè dễ nhận ra bạn trong cuộc trò chuyện."
    >
      <div className="auth-form" style={{ alignItems: 'center', textAlign: 'center' }}>
        <button
          type="button"
          onClick={() => fileRef.current?.click()}
          style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: 0 }}
          aria-label="Chọn ảnh đại diện"
        >
          <Avatar src={preview} name="?" size={140} ring />
        </button>
        <input
          ref={fileRef}
          type="file"
          accept="image/*"
          onChange={onPick}
          style={{ display: 'none' }}
        />
        <span style={{ color: 'var(--text-3)', fontSize: 13 }}>
          Nhấn vào ảnh để chọn từ thiết bị
        </span>
        <div className="auth-row" style={{ gridTemplateColumns: '1fr 1fr', marginTop: 8 }}>
          <Button variant="ghost" size="lg" onClick={() => nav('/app')} fullWidth>Bỏ qua</Button>
          <Button variant="primary" size="lg" loading={loading} onClick={save} fullWidth>Lưu</Button>
        </div>
      </div>
    </AuthShell>
  );
}
