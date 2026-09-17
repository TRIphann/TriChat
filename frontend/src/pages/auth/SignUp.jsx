import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Button, Input, Card } from '../../components/ui';
import { authService, mapAuthError } from '../../services/auth.service';
import { useUiStore } from '../../store/uiStore';

// Quy tắc email & mật khẩu — dùng cho cả client validation và thông điệp hướng dẫn
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PWD_RE = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
const EMAIL_HINT = 'Dùng email hợp lệ để nhận mã xác thực. Ví dụ: ten@example.com';
const PWD_HINT = 'Mật khẩu cần ≥ 8 ký tự, bao gồm chữ HOA, chữ thường và số.';

export default function SignUp() {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [touched, setTouched] = useState(false);
  const nav = useNavigate();
  const showToast = useUiStore((s) => s.showToast);

  // Field-level error — chỉ hiện sau khi user đã blur để không nhảy lỗi ngay khi gõ
  const emailError =
    touched && email && !EMAIL_RE.test(email.trim())
      ? 'Email chưa đúng định dạng. Ví dụ hợp lệ: ten@example.com'
      : '';
  const passwordError =
    touched && password && !PWD_RE.test(password)
      ? 'Mật khẩu chưa đúng định dạng. Hãy dùng ≥ 8 ký tự gồm chữ HOA, chữ thường và số.'
      : '';

  async function onSubmit(e) {
    e.preventDefault();
    setTouched(true);
    setError('');

    const trimmedFirst = firstName.trim();
    const trimmedLast = lastName.trim();
    const trimmedEmail = email.trim();

    if (!trimmedLast || !trimmedFirst) {
      setError('Vui lòng nhập đầy đủ Họ và Tên (không để trống, không chỉ khoảng trắng).');
      return;
    }
    if (!EMAIL_RE.test(trimmedEmail)) {
      setError('Email chưa đúng định dạng. Ví dụ hợp lệ: ten@example.com');
      return;
    }
    if (!PWD_RE.test(password)) {
      setError(
        'Mật khẩu chưa đúng định dạng. Hãy dùng ít nhất 8 ký tự gồm chữ HOA, chữ thường và số (ví dụ: Abc12345).',
      );
      return;
    }

    setLoading(true);
    try {
      await authService.register({
        email: trimmedEmail,
        password,
        firstName: trimmedFirst,
        lastName: trimmedLast,
      });
      showToast('Đăng ký thành công', 'success');
      nav('/chat-list');
    } catch (e) {
      const friendly = mapAuthError(e?.code);
      setError(friendly || 'Đăng ký thất bại. Vui lòng kiểm tra thông tin và thử lại.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-page">
      <Card glass className="auth-card page-in">
        <Link to="/" className="auth-back">← Về trang chính</Link>
        <h1 className="auth-title">Tạo tài khoản mới</h1>
        <p className="auth-sub">Bắt đầu kết nối với bạn bè chỉ trong vài giây.</p>

        <form className="auth-form" onSubmit={onSubmit} noValidate>
          <div className="auth-row">
            <Input
              label="Họ"
              value={lastName}
              onChange={(e) => setLastName(e.target.value)}
              onBlur={() => setTouched(true)}
              placeholder="Nguyễn"
              autoComplete="family-name"
            />
            <Input
              label="Tên"
              value={firstName}
              onChange={(e) => setFirstName(e.target.value)}
              onBlur={() => setTouched(true)}
              placeholder="An"
              autoComplete="given-name"
            />
          </div>
          <Input
            label="Email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            onBlur={() => setTouched(true)}
            placeholder="ten@example.com"
            hint={EMAIL_HINT}
            error={emailError || undefined}
            autoComplete="email"
          />
          <Input
            label="Mật khẩu"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            onBlur={() => setTouched(true)}
            placeholder="Ví dụ: Abc12345"
            hint={PWD_HINT}
            error={passwordError || undefined}
            autoComplete="new-password"
          />
          {error && <p className="auth-error">{error}</p>}
          <Button type="submit" variant="primary" size="lg" loading={loading} fullWidth>
            Tạo tài khoản
          </Button>
        </form>

        <div className="auth-meta">
          <span>Đã có tài khoản? <Link to="/login">Đăng nhập</Link></span>
        </div>
      </Card>
    </div>
  );
}
