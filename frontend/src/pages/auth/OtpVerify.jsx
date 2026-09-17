import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Button, Input } from '../../components/ui';
import { authService, cacheFallbackOtp, getCachedOtp } from '../../services/auth.service';
import AuthShell from './AuthShell';

export default function OtpVerify() {
  const loc = useLocation();
  const nav = useNavigate();
  const email = loc.state?.email || '';
  const purpose = loc.state?.purpose || 'register';
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
      setError(e?.message || 'Mã OTP không hợp lệ');
    } finally {
      setLoading(false);
    }
  }

  return (
    <AuthShell
      eyebrow="Xác thực"
      title="Nhập mã OTP"
      sub={`Mã 6 số đã được gửi tới ${email || 'email của bạn'}. Kiểm tra cả hộp thư spam.`}
    >
      <form className="auth-form" onSubmit={onSubmit}>
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
    </AuthShell>
  );
}
