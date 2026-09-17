import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Button, Input, Card } from '../../components/ui';
import { authService, mapAuthError } from '../../services/auth.service';
import { useUiStore } from '../../store/uiStore';

const PWD_HINT = 'Mật khẩu phân biệt HOA/thường. Tắt Caps Lock và không có khoảng trắng thừa.';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const nav = useNavigate();
  const showToast = useUiStore((s) => s.showToast);

  async function onSubmit(e) {
    e.preventDefault();
    setError('');
    const trimmedEmail = email.trim();
    if (!trimmedEmail || !password) {
      setError('Vui lòng nhập email và mật khẩu để đăng nhập.');
      return;
    }
    setLoading(true);
    try {
      await authService.signIn(trimmedEmail, password);
      showToast('Đăng nhập thành công', 'success');
      nav('/app');
    } catch (e) {
      const friendly = mapAuthError(e?.code);
      setError(
        friendly ||
          e?.message ||
          'Không thể đăng nhập. Vui lòng kiểm tra email, mật khẩu và kết nối mạng rồi thử lại.',
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-page">
      <Card glass className="auth-card page-in">
        <Link to="/" className="auth-back">← Về trang chính</Link>
        <h1 className="auth-title">Chào mừng trở lại</h1>
        <p className="auth-sub">Đăng nhập để tiếp tục trò chuyện cùng bạn bè.</p>

        <form className="auth-form" onSubmit={onSubmit} noValidate>
          <Input
            label="Email"
            type="email"
            placeholder="ten@example.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            hint="Nhập đúng email bạn đã dùng khi đăng ký, ví dụ ten@example.com"
            autoComplete="email"
          />
          <Input
            label="Mật khẩu"
            type="password"
            placeholder="••••••••"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            hint={PWD_HINT}
            autoComplete="current-password"
          />
          {error && <p className="auth-error">{error}</p>}
          <Button type="submit" variant="primary" size="lg" loading={loading} fullWidth>
            Đăng nhập
          </Button>
        </form>

        <div className="auth-meta">
          <Link to="/set-password">Quên mật khẩu?</Link>
          <span>Chưa có tài khoản? <Link to="/sign-up">Đăng ký</Link></span>
        </div>
      </Card>
    </div>
  );
}
