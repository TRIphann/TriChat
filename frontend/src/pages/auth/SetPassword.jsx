import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { Button, Input, Card } from '../../components/ui';
import {
  authService,
  cacheFallbackOtp,
  clearCachedOtp,
} from '../../services/auth.service';
import { useUiStore } from '../../store/uiStore';

export default function SetPassword() {
  const loc = useLocation();
  const nav = useNavigate();
  const showToast = useUiStore((s) => s.showToast);
  const email = loc.state?.email || '';
  const purpose = loc.state?.purpose || 'reset';

  const [step, setStep] = useState(email ? 1 : 0); // 0: enter email, 1: verify otp, 2: new password
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
      // Backend OTP response dùng snake_case → { result: { otp, ... } }
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

  /**
   * Bước cuối — đặt mật khẩu mới.
   * Lưu ý: backend chưa có endpoint /api/auth/reset-password chuẩn.
   * Cách hiện tại: gọi updateMe sau khi login. Nếu user đã verify OTP, mật khẩu cũ vẫn còn
   * → báo lỗi rõ ràng cho user thay vì fake success.
   */
  async function finish() {
    if (!password || password.length < 8) {
      setError('Mật khẩu mới phải có ít nhất 8 ký tự.');
      return;
    }
    setLoading(true);
    setError('');
    try {
      // Chuyển tiếp sang EnterName với đầy đủ { email, password }.
      // EnterName sẽ thu thập thêm dateOfBirth rồi gọi authService.register().
      clearCachedOtp();
      nav('/enter-name', { state: { email: mail.trim(), password } });
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-page">
      <Card glass className="auth-card page-in">
        <Link to="/login" className="auth-back">← Quay lại</Link>
        <h1 className="auth-title">{purpose === 'register' ? 'Đặt mật khẩu' : 'Quên mật khẩu'}</h1>
        <p className="auth-sub">
          {step === 0 && 'Nhập email của bạn để nhận mã OTP.'}
          {step === 1 && 'Nhập mã OTP đã được gửi tới email của bạn.'}
          {step === 2 && 'Đặt mật khẩu mới cho tài khoản.'}
        </p>

        {step === 0 && (
          <form className="auth-form" onSubmit={(e) => { e.preventDefault(); sendOtp(); }}>
            <Input label="Email" type="email" value={mail} onChange={(e) => setMail(e.target.value)} placeholder="you@example.com" autoComplete="email" />
            {error && <p className="auth-error">{error}</p>}
            <Button type="submit" variant="primary" size="lg" loading={loading} fullWidth>Gửi OTP</Button>
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
            />
            {error && <p className="auth-error">{error}</p>}
            <Button type="submit" variant="primary" size="lg" loading={loading} fullWidth>Xác thực</Button>
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
            />
            {error && <p className="auth-error">{error}</p>}
            <Button type="submit" variant="primary" size="lg" loading={loading} fullWidth>Hoàn tất</Button>
          </form>
        )}
      </Card>
    </div>
  );
}
