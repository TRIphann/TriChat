import { Link, useNavigate } from 'react-router-dom';
import { Avatar } from '../ui';
import { useAuthStore } from '../../store/authStore';
import { useTheme } from '../../theme/ThemeProvider';
import './topBar.css';

export default function TopBar() {
  const { theme, toggle } = useTheme();
  const profile = useAuthStore((s) => s.profile);
  const nav = useNavigate();

  return (
    <header className="topbar glass">
      <Link to="/chat-list" className="topbar__brand">
        <span className="topbar__logo" aria-hidden />
        <span className="topbar__brand-name">TriChat</span>
      </Link>

      <nav className="topbar__nav">
        <NavLink to="/chat-list" label="Trò chuyện" />
        <NavLink to="/newfeed" label="Bảng tin" />
        <NavLink to="/friends" label="Bạn bè" />
      </nav>

      <div className="topbar__actions">
        <button className="topbar__icon-btn" onClick={toggle} aria-label="Toggle theme">
          {theme === 'dark' ? '☀️' : '🌙'}
        </button>
        <button
          className="topbar__icon-btn"
          onClick={() => nav('/my-profile')}
          aria-label="Hồ sơ"
        >
          <Avatar
            src={profile?.avatar || profile?.Avatar}
            name={profile?.fullName || profile?.FullName || profile?.firstName}
            size={36}
          />
        </button>
      </div>
    </header>
  );
}

function NavLink({ to, label }) {
  return (
    <Link to={to} className="topbar__nav-link">
      {label}
    </Link>
  );
}
