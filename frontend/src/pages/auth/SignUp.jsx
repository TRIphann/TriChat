import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Button, Input, Card } from '../../components/ui';
import { authService } from '../../services/auth.service';
import { useUiStore } from '../../store/uiStore';

export default function SignUp() {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const nav = useNavigate();
  const showToast = useUiStore((s) => s.showToast);

  async function onSubmit(e) {
    e.preventDefault();
    setError('');
    if (!firstName || !lastName || !email || password.length < 8) {
      setError('Vui lòng nhập đầy đủ thông tin (mật khẩu ≥ 8 ký tự)');
      return;
    }
    setLoading(true);
    try {
      await authService.register({ email: email.trim(), password, firstName, lastName });
      showToast('Đăng ký thành công', 'success');
      nav('/chat-list');
    } catch (e) {
      const code = e?.code || '';
      const map = {
        'email-already-in-use': 'Email này đã được đăng ký',
        'weak-password': 'Mật khẩu yếu, cần ít nhất 8 ký tự gồm chữ hoa + thường',
      };
      setError(map[code] || e?.message || 'Đăng ký thất bại');
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

        <form className="auth-form" onSubmit={onSubmit}>
          <div style={{ display: 'flex', gap: 12 }}>
            <Input label="Họ" value={lastName} onChange={(e) => setLastName(e.target.value)} placeholder="Nguyễn" />
            <Input label="Tên" value={firstName} onChange={(e) => setFirstName(e.target.value)} placeholder="An" />
          </div>
          <Input label="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" />
          <Input label="Mật khẩu" type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Ít nhất 8 ký tự" />
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
