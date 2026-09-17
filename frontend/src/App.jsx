import { useEffect } from 'react';
import { RouterProvider } from 'react-router-dom';
import { router } from './router';
import { ThemeProvider } from './theme/ThemeProvider';
import { Toast } from './components/ui';
import { useAuthStore } from './store/authStore';
import { useAppBootstrap } from './hooks/useAppBootstrap';
import './i18n';

export default function App() {
  const initAuth = useAuthStore((s) => s.init);

  useEffect(() => {
    const unsub = initAuth();
    return () => unsub && unsub();
  }, [initAuth]);

  return (
    <ThemeProvider>
      <AuthGate>
        <RouterProvider router={router} />
        <Toast />
      </AuthGate>
    </ThemeProvider>
  );
}

function AuthGate({ children }) {
  useAppBootstrap();
  return children;
}
