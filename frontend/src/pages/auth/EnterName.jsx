import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Button, Input, Card } from '../../components/ui';
import { authService } from '../../services/auth.service';

export default function EnterName() {
  const loc = useLocation();
  const nav = useNavigate();
  const email = loc.state?.email || '';
  const password = loc.state?.password || '';
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  // OTP signup flow cũng phải có DOB — backend validator yêu cầu bắt buộc.
  const [dateOfBirth, setDateOfBirth] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function next() {
    const trimmedFirst = firstName.trim();
    const trimmedLast = lastName.trim();

    if (!trimmedLast || !trimmedFirst) {
      setError('Vui lòng nhập đầy đủ họ tên (không để trống, không chỉ khoảng trắng).');
      return;
    }
    if (!dateOfBirth) {
      setError('Vui lòng nhập ngày sinh để hoàn tất đăng ký.');
      return;
    }
    if (!password) {
      setError('Thiếu mật khẩu — vui lòng quay lại bước trước và nhập mật khẩu.');
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
    <div className="auth-page">
      <Card glass className="auth-card page-in">
        <h1 className="auth-title">Cho chúng tôi biết về bạn</h1>
        <p className="auth-sub">Tên và ngày sinh của bạn sẽ hiển thị với mọi người trên TriChat.</p>
        <div className="auth-form">
          <Input label="Họ" value={lastName} onChange={(e) => setLastName(e.target.value)} placeholder="Nguyễn" autoComplete="family-name" />
          <Input label="Tên" value={firstName} onChange={(e) => setFirstName(e.target.value)} placeholder="An" autoComplete="given-name" />
          <Input
            label="Ngày sinh"
            type="date"
            value={dateOfBirth}
            onChange={(e) => setDateOfBirth(e.target.value)}
            hint="Bắt buộc — định dạng yyyy-MM-dd, ngày trong quá khứ."
            max={new Date().toISOString().slice(0, 10)}
          />
          {error && <p className="auth-error">{error}</p>}
          <Button onClick={next} variant="primary" size="lg" loading={loading} fullWidth>
            Tiếp tục
          </Button>
        </div>
      </Card>
    </div>
  );
}
