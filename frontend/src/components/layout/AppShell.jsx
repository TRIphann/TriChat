import { Outlet, useNavigate } from 'react-router-dom';
import { useEffect } from 'react';

// Compatibility shim — các page cũ đang dùng AppShell nên redirect về /app.
// Tất cả UI thật giờ nằm trong TriChatLayout.
export default function AppShell() {
  const nav = useNavigate();
  useEffect(() => {
    nav('/app', { replace: true });
  }, [nav]);
  return <Outlet />;
}
