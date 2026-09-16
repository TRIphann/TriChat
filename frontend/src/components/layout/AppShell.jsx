import { Outlet, useLocation } from 'react-router-dom';
import { useEffect, useRef } from 'react';
import { pageIn } from '../../lib/anime';
import TopBar from './TopBar';
import BottomNav from './BottomNav';
import './appShell.css';

export default function AppShell() {
  const ref = useRef(null);
  const loc = useLocation();

  useEffect(() => {
    pageIn(ref.current);
  }, [loc.pathname]);

  return (
    <div className="app-shell">
      <TopBar />
      <main ref={ref} className="app-shell__main">
        <Outlet />
      </main>
      <BottomNav />
    </div>
  );
}
