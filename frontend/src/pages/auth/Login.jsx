import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Button, Input, Card } from '../../components/ui';
import { authService } from '../../services/auth.service';
import { useUiStore } from '../../store/uiStore';
import './auth.css';

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
    if (!email || !password) {
      setError('Vui lòng nhập email và mật khẩu');
      return;
    }
    setLoading(true);
    try {
      await authService.signIn(email.trim(), password);
      showToast('Đăng nhập thành công', 'success');
      nav('/chat-list');
    } catch (e) {
      const msg = mapAuthError(e?.code) || e?.message || 'Đăng nhập thất bại';
      setError(msg);
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

        <form className="auth-form" onSubmit={onSubmit}>
          <Input
            label="Email"
            type="email"
            placeholder="you@example.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            autoComplete="email"
          />
          <Input
            label="Mật khẩu"
            type="password"
            placeholder="••••••••"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
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

function mapAuthError(code) {
  const map = {
    'user-not-found': 'Email không tồn tại',
    'wrong-password': 'Sai mật khẩu',
    'invalid-email': 'Email không hợp lệ',
    'user-disabled': 'Tài khoản đã bị vô hiệu hóa',
    'too-many-requests': 'Quá nhiều lần thử, thử lại sau',
    'network-request-failed': 'Lỗi kết nối mạng',
    'invalid-credential': 'Email hoặc mật khẩu không đúng',
  };
  return map[code] || '';
}
