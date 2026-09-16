import { NavLink } from 'react-router-dom';
import './bottomNav.css';

const tabs = [
  { to: '/chat-list', label: 'Chat', icon: '💬' },
  { to: '/newfeed', label: 'Feed', icon: '🌿' },
  { to: '/friends', label: 'Bạn bè', icon: '👥' },
  { to: '/contacts', label: 'Liên hệ', icon: '📇' },
  { to: '/my-profile', label: 'Tôi', icon: '🌸' },
];

export default function BottomNav() {
  return (
    <nav className="bottom-nav glass">
      {tabs.map((t) => (
        <NavLink
          key={t.to}
          to={t.to}
          className={({ isActive }) => `bottom-nav__item ${isActive ? 'is-active' : ''}`}
        >
          <span className="bottom-nav__icon" aria-hidden>{t.icon}</span>
          <span className="bottom-nav__label">{t.label}</span>
        </NavLink>
      ))}
    </nav>
  );
}
