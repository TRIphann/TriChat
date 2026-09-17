import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Button, Input } from '../../components/ui';
import {
  authService,
  cacheFallbackOtp,
  clearCachedOtp,
} from '../../services/auth.service';
import AuthShell from './AuthShell';

export default function SetPassword() {
  const loc = useLocation();
  const nav = useNavigate();
  const email = loc.state?.email || '';
  const purpose = loc.state?.purpose || 'reset';

  const [step, setStep] = useState(email ? 1 : 0);
  const [mail, setMail] = useState(email);
  const [otp, setOtp] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function sendOtp() {
    const trimmed = mail.trim();
    if (!trimmed) {
      setError('Vui lòng nhập email.');
      return;
    }
    setLoading(true);
    setError('');
    try {
      const res = await authService.sendOtp(trimmed);
      const otpValue = res?.result?.otp || res?.otp;
      if (otpValue) cacheFallbackOtp(otpValue);
      setStep(1);
    } catch (e) {
      setError(e?.message || 'Không thể gửi OTP');
    } finally {
      setLoading(false);
    }
  }

  async function verifyOtp() {
    if (!otp || otp.length < 4) {
      setError('Vui lòng nhập mã OTP (≥ 4 số).');
      return;
    }
    setError('');
    setLoading(true);
    try {
      await authService.verifyOtp(mail.trim(), otp);
      clearCachedOtp();
      setStep(2);
    } catch (e) {
      setError(e?.message || 'Mã OTP không hợp lệ');
    } finally {
      setLoading(false);
    }
  }

  async function finish() {
    if (!password || password.length < 8) {
      setError('Mật khẩu mới phải có ít nhất 8 ký tự.');
      return;
    }
    setLoading(true);
    setError('');
    try {
      clearCachedOtp();
      nav('/enter-name', { state: { email: mail.trim(), password } });
    } finally {
      setLoading(false);
    }
  }

  const eyebrowMap = { 0: 'Quên mật khẩu', 1: 'Xác thực', 2: 'Đặt lại' };
  const titleMap = {
    0: 'Khôi phục tài khoản',
    1: 'Nhập mã OTP',
    2: 'Đặt mật khẩu mới',
  };
  const subMap = {
    0: purpose === 'register'
        ? 'Nhập email để bắt đầu đăng ký tài khoản mới.'
        : 'Nhập email của bạn để nhận mã OTP đặt lại mật khẩu.',
    1: `Mã đã được gửi tới ${mail}. Vui lòng kiểm tra hộp thư đến (kể cả spam).`,
    2: 'Chọn mật khẩu mới an toàn cho tài khoản của bạn.',
  };

  return (
    <AuthShell
      eyebrow={eyebrowMap[step]}
      title={titleMap[step]}
      sub={subMap[step]}
    >
      {step === 0 && (
        <form className="auth-form" onSubmit={(e) => { e.preventDefault(); sendOtp(); }}>
          <Input
            label="Email"
            type="email"
            value={mail}
            onChange={(e) => setMail(e.target.value)}
            placeholder="you@example.com"
            autoComplete="email"
            autoFocus
          />
          {error && <p className="auth-error" role="alert">{error}</p>}
          <div className="auth-submit-row">
            <Button type="submit" variant="primary" size="lg" loading={loading} fullWidth>
              Gửi OTP
            </Button>
          </div>
        </form>
      )}
      {step === 1 && (
        <form className="auth-form" onSubmit={(e) => { e.preventDefault(); verifyOtp(); }}>
          <Input
            label="Mã OTP"
            value={otp}
            onChange={(e) => setOtp(e.target.value.replace(/\D/g, ''))}
            placeholder="000000"
            maxLength={6}
            inputMode="numeric"
            autoComplete="one-time-code"
            autoFocus
          />
          {error && <p className="auth-error" role="alert">{error}</p>}
          <div className="auth-submit-row">
            <Button type="submit" variant="primary" size="lg" loading={loading} fullWidth>
              Xác thực
            </Button>
          </div>
        </form>
      )}
      {step === 2 && (
        <form className="auth-form" onSubmit={(e) => { e.preventDefault(); finish(); }}>
          <Input
            label="Mật khẩu mới"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="≥ 8 ký tự"
            autoComplete="new-password"
            autoFocus
          />
          {error && <p className="auth-error" role="alert">{error}</p>}
          <div className="auth-submit-row">
            <Button type="submit" variant="primary" size="lg" loading={loading} fullWidth>
              Hoàn tất
            </Button>
          </div>
        </form>
      )}

      <div className="auth-divider">hoặc</div>
      <div className="auth-meta" style={{ justifyContent: 'center' }}>
        <a href="/login" onClick={(e) => { e.preventDefault(); nav('/login'); }}>← Quay lại đăng nhập</a>
      </div>
    </AuthShell>
  );
}
