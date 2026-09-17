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
      // profile.date_of_birth là string ISO date — input[type=date] cũng dùng yyyy-MM-dd
      setDob(profile.date_of_birth || profile.dateOfBirth || profile.dob || '');
    }
  }, [profile]);

  async function next() {
    setLoading(true);
    setError('');
    try {
      // UpdateUserRequest DTO: tất cả field optional, snake_case (SnakeCaseLower JSON config).
      // Chỉ gửi field nào có giá trị để tránh validate DOB lỡ range.
      const payload = {};
      if (dob) payload.date_of_birth = dob;
      payload.bio = bio || '';
      await authService.updateMe(payload);
      nav('/app');
    } catch (e) {
      setError(e?.message || 'Cập nhật thất bại');
    } finally {
      setLoading(false);
    }
  }

  async function skip() {
    nav('/app');
  }

  return (
    <div className="auth-page">
      <Card glass className="auth-card page-in">
        <h1 className="auth-title">Thông tin cá nhân</h1>
        <p className="auth-sub">Có thể bỏ qua — bạn có thể cập nhật sau trong phần Hồ sơ.</p>
        <div className="auth-form">
          <Input
            label="Ngày sinh"
            type="date"
            value={dob}
            onChange={(e) => setDob(e.target.value)}
            max={new Date().toISOString().slice(0, 10)}
          />
          <label className="field">
            <span className="field__label">Tiểu sử</span>
            <textarea
              className="field__control"
              style={{ minHeight: 96, padding: 14, resize: 'vertical' }}
              placeholder="Một vài dòng về bạn..."
              value={bio}
              onChange={(e) => setBio(e.target.value)}
              maxLength={200}
            />
          </label>
          {error && <p className="auth-error">{error}</p>}
          <div style={{ display: 'flex', gap: 12 }}>
            <Button variant="ghost" size="md" onClick={skip} fullWidth>Bỏ qua</Button>
            <Button onClick={next} variant="primary" size="md" loading={loading} fullWidth>
              Tiếp tục
            </Button>
          </div>
        </div>
      </Card>
    </div>
  );
}
