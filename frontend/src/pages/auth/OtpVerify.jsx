import { useState } from 'react';
import { useNavigate, useLocation, Link } from 'react-router-dom';
import { Button, Input, Card } from '../../components/ui';
import { authService, cacheFallbackOtp, getCachedOtp } from '../../services/auth.service';

export default function OtpVerify() {
  const loc = useLocation();
  const nav = useNavigate();
  const email = loc.state?.email || '';
  const purpose = loc.state?.purpose || 'register'; // register | reset
  const [otp, setOtp] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function onSubmit(e) {
    e.preventDefault();
    setError('');
    if (!otp || otp.length < 4) {
      setError('Vui lòng nhập mã OTP');
      return;
    }
    setLoading(true);
    try {
      await authService.verifyOtp(email, otp, getCachedOtp());
      if (purpose === 'register') nav('/enter-name', { state: { email } });
      else nav('/set-password', { state: { email } });
    } catch (e) {
      setError(e.message || 'Mã OTP không hợp lệ');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-page">
      <Card glass className="auth-card page-in">
        <Link to="/sign-up" className="auth-back">← Quay lại</Link>
        <h1 className="auth-title">Xác thực OTP</h1>
        <p className="auth-sub">Nhập mã 6 số đã được gửi tới <strong>{email}</strong></p>

        <form className="auth-form" onSubmit={onSubmit}>
          <Input
            label="Mã OTP"
            value={otp}
            onChange={(e) => setOtp(e.target.value.replace(/\D/g, ''))}
            placeholder="000000"
            maxLength={6}
            inputMode="numeric"
          />
          {error && <p className="auth-error">{error}</p>}
          <Button type="submit" variant="primary" size="lg" loading={loading} fullWidth>
            Xác thực
          </Button>
        </form>
      </Card>
    </div>
  );
}
