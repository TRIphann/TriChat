import { Link } from 'react-router-dom';
import { useTheme } from '../../theme/ThemeProvider';
import './auth.css';

/**
 * Layout chia đôi: brand panel (trái) + form panel (phải).
 * - left = nội dung quảng bá, hero
 * - right = form (children)
 * - eyebrow: nhãn nhỏ phía trên title (vd: "Đăng nhập")
 * - title: tiêu đề chính (serif lớn)
 * - sub: mô tả ngắn dưới title
 */
export default function AuthShell({ eyebrow, title, sub, children, backTo = '/' }) {
  const { theme, toggle } = useTheme();

  return (
    <div className="auth-shell">
      {/* Brand panel — editorial hero */}
      <aside className="auth-brand" aria-hidden="false">
        <div className="auth-brand__top">
          <div className="auth-brand__logo">
            <span className="auth-brand__mark">T</span>
            <span>TriChat</span>
          </div>
          <span className="auth-brand__tag">v 2026</span>
        </div>

        <div className="auth-brand__hero">
          <span className="auth-brand__eyebrow">TriChat · Editorial</span>
          <h1 className="auth-brand__title">
            Kết nối <em>mọi khoảnh khắc</em>,<br />
            trên mọi thiết bị.
          </h1>
          <p className="auth-brand__lede">
            Trò chuyện 1-1, nhóm, gọi thoại &amp; video. Bảng tin và stories.
            Thiết kế cao cấp theo phong cách editorial, animation mượt mà.
          </p>

          <ul className="auth-brand__features" style={{ listStyle: 'none', padding: 0 }}>
            <li className="auth-brand__feature">
              <span className="auth-brand__feature-dot">💬</span>
              Tin nhắn realtime qua SignalR · reaction · reply · ghim
            </li>
            <li className="auth-brand__feature">
              <span className="auth-brand__feature-dot">📞</span>
              Gọi thoại &amp; video chất lượng cao với Agora RTC
            </li>
            <li className="auth-brand__feature">
              <span className="auth-brand__feature-dot">🌿</span>
              Posts · stories 24h · like · comment · share
            </li>
          </ul>
        </div>

        <div className="auth-brand__footer">
          © 2026 TriChat · Crafted with care in Vietnam
        </div>
      </aside>

      {/* Form panel */}
      <main className="auth-form-panel">
        <button
          type="button"
          className="auth-theme-toggle"
          onClick={toggle}
          aria-label="Chuyển giao diện sáng/tối"
          title={theme === 'dark' ? 'Chuyển sang giao diện sáng' : 'Chuyển sang giao diện tối'}
        >
          {theme === 'dark' ? '☀️' : '🌙'}
        </button>

        <div className="auth-form-panel__inner">
          <Link to={backTo} className="auth-mobile-back">← Về trang chính</Link>

          {eyebrow && <span className="auth-eyebrow">{eyebrow}</span>}
          {title && <h2 className="auth-title">{title}</h2>}
          {sub && <p className="auth-sub">{sub}</p>}

          {children}
        </div>
      </main>
    </div>
  );
}
