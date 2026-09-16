import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button, Input, Card } from '../../components/ui';
import { authService } from '../../services/auth.service';
import { useAuthStore } from '../../store/authStore';

export default function PersonalInfo() {
  const nav = useNavigate();
  const profile = useAuthStore((s) => s.profile);
  const [dob, setDob] = useState('');
  const [bio, setBio] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (profile) {
      setBio(profile.bio || '');
      setDob(profile.dateOfBirth || profile.dob || '');
    }
  }, [profile]);

  async function next() {
    setLoading(true);
    setError('');
    try {
      // Chỉ update Bio + DateOfBirth — KHÔNG xóa FirstName/LastName hiện có.
      await authService.updateMe({
        Bio: bio,
        DateOfBirth: dob || undefined,
      });
      nav('/update-avatar');
    } catch (e) {
      setError(e.message || 'Cập nhật thất bại');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-page">
      <Card glass className="auth-card page-in">
        <h1 className="auth-title">Thông tin cá nhân</h1>
        <p className="auth-sub">Có thể bỏ qua — bạn có thể cập nhật sau.</p>
        <div className="auth-form">
          <Input label="Ngày sinh" type="date" value={dob} onChange={(e) => setDob(e.target.value)} />
          <label className="field">
            <span className="field__label">Tiểu sử</span>
            <textarea
              className="field__control"
              style={{ minHeight: 96, padding: 14, resize: 'vertical' }}
              placeholder="Một vài dòng về bạn..."
              value={bio}
              onChange={(e) => setBio(e.target.value)}
            />
          </label>
          {error && <p className="auth-error">{error}</p>}
          <Button onClick={next} variant="primary" size="lg" loading={loading} fullWidth>Tiếp tục</Button>
        </div>
      </Card>
    </div>
  );
}
