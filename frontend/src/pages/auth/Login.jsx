import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Button, Input } from '../../components/ui';
import { authService, mapAuthError } from '../../services/auth.service';
import { useUiStore } from '../../store/uiStore';
import AuthShell from './AuthShell';

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
    <AuthShell
      eyebrow="Đăng nhập"
      title="Chào mừng trở lại"
      sub="Tiếp tục trò chuyện cùng bạn bè và cộng đồng của bạn."
    >
      <form className="auth-form" onSubmit={onSubmit} noValidate>
        <Input
          label="Email"
          type="email"
          placeholder="ten@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          hint="Nhập đúng email bạn đã dùng khi đăng ký"
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
        {error && <p className="auth-error" role="alert">{error}</p>}
        <div className="auth-submit-row">
          <Button type="submit" variant="primary" size="lg" loading={loading} fullWidth>
            Đăng nhập
          </Button>
        </div>
      </form>

      <div className="auth-divider">hoặc</div>

      <div className="auth-meta" style={{ justifyContent: 'center' }}>
        <span>
          Chưa có tài khoản? <Link to="/sign-up">Tạo tài khoản</Link>
        </span>
      </div>
      <div className="auth-meta" style={{ justifyContent: 'center', marginTop: 8 }}>
        <Link to="/set-password">Quên mật khẩu?</Link>
      </div>
    </AuthShell>
  );
}
