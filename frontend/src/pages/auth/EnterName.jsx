import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Button, Input } from '../../components/ui';
import { authService } from '../../services/auth.service';
import AuthShell from './AuthShell';

export default function EnterName() {
  const loc = useLocation();
  const nav = useNavigate();
  const email = loc.state?.email || '';
  const password = loc.state?.password || '';
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [dateOfBirth, setDateOfBirth] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function next() {
    const trimmedFirst = firstName.trim();
    const trimmedLast = lastName.trim();

    if (!trimmedLast || !trimmedFirst) {
      setError('Vui lòng nhập đầy đủ họ tên.');
      return;
    }
    if (!dateOfBirth) {
      setError('Vui lòng nhập ngày sinh để hoàn tất đăng ký.');
      return;
    }
    if (!password) {
      setError('Thiếu mật khẩu — vui lòng quay lại bước trước.');
      return;
    }
    setLoading(true);
    setError('');
    try {
      await authService.register({
        email: email.trim(),
        password,
        firstName: trimmedFirst,
        lastName: trimmedLast,
        dateOfBirth,
      });
      nav('/app');
    } catch (e) {
      setError(e?.message || 'Không thể tạo tài khoản');
    } finally {
      setLoading(false);
    }
  }

  return (
    <AuthShell
      eyebrow="Hoàn tất đăng ký"
      title="Cho chúng tôi biết về bạn"
      sub="Tên và ngày sinh sẽ hiển thị với mọi người trên TriChat."
    >
      <div className="auth-form">
        <div className="auth-row">
          <Input
            label="Họ"
            value={lastName}
            onChange={(e) => setLastName(e.target.value)}
            placeholder="Nguyễn"
            autoComplete="family-name"
            autoFocus
          />
          <Input
            label="Tên"
            value={firstName}
            onChange={(e) => setFirstName(e.target.value)}
            placeholder="An"
            autoComplete="given-name"
          />
        </div>
        <Input
          label="Ngày sinh"
          type="date"
          value={dateOfBirth}
          onChange={(e) => setDateOfBirth(e.target.value)}
          hint="Định dạng yyyy-MM-dd · ngày trong quá khứ."
          max={new Date().toISOString().slice(0, 10)}
          autoComplete="bday"
        />
        {error && <p className="auth-error" role="alert">{error}</p>}
        <div className="auth-submit-row">
          <Button onClick={next} variant="primary" size="lg" loading={loading} fullWidth>
            Tiếp tục
          </Button>
        </div>
      </div>
    </AuthShell>
  );
}
