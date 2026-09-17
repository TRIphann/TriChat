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
const DOB_HINT = 'Bắt buộc — dùng để xác minh tuổi và cá nhân hoá trải nghiệm.';

export default function SignUp() {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  // Backend CreateUserRequestValidator yêu cầu DateOfBirth bắt buộc (yyyy-MM-dd, ngày trong quá khứ).
  // Phải thu thập ngay tại form đăng ký — nếu thiếu sẽ 422.
  const [dateOfBirth, setDateOfBirth] = useState('');
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
  const dobError =
    touched && dateOfBirth
      ? (() => {
          const d = new Date(dateOfBirth);
          const now = new Date();
          if (Number.isNaN(d.getTime())) return 'Ngày sinh không hợp lệ.';
          if (d >= now) return 'Ngày sinh phải là ngày trong quá khứ.';
          if (now.getFullYear() - d.getFullYear() > 100) return 'Ngày sinh không hợp lệ (>100 tuổi).';
          return '';
        })()
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
    if (!dateOfBirth) {
      setError('Vui lòng nhập ngày sinh để hoàn tất đăng ký.');
      return;
    }
    const dobDate = new Date(dateOfBirth);
    if (Number.isNaN(dobDate.getTime()) || dobDate >= new Date()) {
      setError('Ngày sinh phải là ngày hợp lệ trong quá khứ (định dạng yyyy-MM-dd).');
      return;
    }

    setLoading(true);
    try {
      await authService.register({
        email: trimmedEmail,
        password,
        firstName: trimmedFirst,
        lastName: trimmedLast,
        dateOfBirth, // backend yêu cầu DateOfRequest "yyyy-MM-dd"
      });
      showToast('Đăng ký thành công', 'success');
      nav('/app');
    } catch (e) {
      const friendly = mapAuthError(e?.code);
      setError(friendly || e?.message || 'Đăng ký thất bại. Vui lòng kiểm tra thông tin và thử lại.');
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
          <Input
            label="Ngày sinh"
            type="date"
            value={dateOfBirth}
            onChange={(e) => setDateOfBirth(e.target.value)}
            onBlur={() => setTouched(true)}
            hint={DOB_HINT}
            error={dobError || undefined}
            autoComplete="bday"
            max={new Date().toISOString().slice(0, 10)}
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
