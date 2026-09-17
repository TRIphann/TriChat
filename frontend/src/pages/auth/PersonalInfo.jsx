import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button, Input } from '../../components/ui';
import { authService } from '../../services/auth.service';
import { useAuthStore } from '../../store/authStore';
import AuthShell from './AuthShell';

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
      setDob(profile.date_of_birth || profile.dateOfBirth || profile.dob || '');
    }
  }, [profile]);

  async function next() {
    setLoading(true);
    setError('');
    try {
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

  function skip() {
    nav('/app');
  }

  return (
    <AuthShell
      eyebrow="Bước tuỳ chọn"
      title="Thông tin cá nhân"
      sub="Có thể bỏ qua — bạn có thể cập nhật sau trong phần Hồ sơ."
    >
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
          <span className="field__control" style={{ alignItems: 'flex-start' }}>
            <textarea
              className="field__input"
              style={{ minHeight: 84, resize: 'vertical', padding: 0 }}
              placeholder="Một vài dòng về bạn..."
              value={bio}
              onChange={(e) => setBio(e.target.value)}
              maxLength={200}
            />
          </span>
          <span className="field__hint">{bio.length}/200 ký tự</span>
        </label>
        {error && <p className="auth-error" role="alert">{error}</p>}
        <div className="auth-row" style={{ gridTemplateColumns: '1fr 1fr' }}>
          <Button variant="ghost" size="lg" onClick={skip} fullWidth>Bỏ qua</Button>
          <Button variant="primary" size="lg" loading={loading} onClick={next} fullWidth>
            Tiếp tục
          </Button>
        </div>
      </div>
    </AuthShell>
  );
}
