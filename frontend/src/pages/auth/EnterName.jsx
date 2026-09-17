import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Button, Input, Card } from '../../components/ui';
import { authService } from '../../services/auth.service';

export default function EnterName() {
  const loc = useLocation();
  const nav = useNavigate();
  const email = loc.state?.email || '';
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function next() {
    if (!firstName || !lastName) {
      setError('Vui lòng nhập đầy đủ họ tên');
      return;
    }
    setLoading(true);
    try {
      await authService.register({
        email: email.trim(),
        password: loc.state?.password || '',
        firstName,
        lastName,
      });
      nav('/update-avatar');
    } catch (e) {
      setError(e.message || 'Không thể tạo tài khoản');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-page">
      <Card glass className="auth-card page-in">
        <h1 className="auth-title">Cho chúng tôi biết về bạn</h1>
        <p className="auth-sub">Tên của bạn sẽ hiển thị với mọi người trên TriChat.</p>
        <div className="auth-form">
          <Input label="Họ" value={lastName} onChange={(e) => setLastName(e.target.value)} placeholder="Nguyễn" />
          <Input label="Tên" value={firstName} onChange={(e) => setFirstName(e.target.value)} placeholder="An" />
          {error && <p className="auth-error">{error}</p>}
          <Button onClick={next} variant="primary" size="lg" loading={loading} fullWidth>
            Tiếp tục
          </Button>
        </div>
      </Card>
    </div>
  );
}
