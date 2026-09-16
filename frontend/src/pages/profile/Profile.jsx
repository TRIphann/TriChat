import { useEffect, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { authService } from '../../services/auth.service';
import { Avatar, Button } from '../../components/ui';

export default function Profile() {
  const nav = useNavigate();
  const loc = useLocation();
  const targetUserId = loc.state?.targetUserId;
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const me = JSON.parse(localStorage.getItem('trichat-me') || 'null');
  const isMe = !targetUserId || targetUserId === me?.uid;

  useEffect(() => {
    setLoading(true);
    (isMe ? authService.getMe() : authService.getById(targetUserId))
      .then((p) => setProfile(p))
      .finally(() => setLoading(false));
  }, [targetUserId, isMe]);

  if (loading) return <p>Đang tải...</p>;
  if (!profile) return <p>Không tìm thấy.</p>;

  const fullName = profile.fullName || `${profile.firstName || ''} ${profile.lastName || ''}`.trim();

  return (
    <div style={{ maxWidth: 720, margin: '0 auto' }}>
      <button className="chat-list__new" onClick={() => nav(-1)} style={{ marginBottom: 16 }}>← Quay lại</button>
      <header style={{ display: 'flex', alignItems: 'center', gap: 24, marginBottom: 32 }}>
        <Avatar src={profile.avatar} name={fullName} size={120} ring />
        <div>
          <h1 className="text-serif" style={{ fontSize: 32, margin: 0 }}>{fullName}</h1>
          <p style={{ color: 'var(--text-2)', margin: '6px 0' }}>{profile.email}</p>
          {profile.bio && <p style={{ color: 'var(--text-3)' }}>{profile.bio}</p>}
        </div>
      </header>

      {!isMe && (
        <div style={{ display: 'flex', gap: 12, marginBottom: 32 }}>
          <Button variant="primary">💬 Nhắn tin</Button>
          <Button variant="ghost">Gửi lời mời</Button>
        </div>
      )}

      <section>
        <h2 style={{ fontSize: 18, marginBottom: 12 }}>Bài viết</h2>
        <p style={{ color: 'var(--text-3)' }}>Chưa có bài viết nào.</p>
      </section>
    </div>
  );
}
