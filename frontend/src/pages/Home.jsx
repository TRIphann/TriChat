import { useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { staggerCards, pageIn } from '../lib/anime';
import Button from '../components/ui/Button';
import './home.css';

export default function Home() {
  const ref = useRef(null);
  const cardsRef = useRef(null);

  useEffect(() => {
    pageIn(ref.current);
    if (cardsRef.current) {
      staggerCards(cardsRef.current.querySelectorAll('.feature-card'), { gap: 100, dur: 700 });
    }
  }, []);

  return (
    <div className="home" ref={ref}>
      <div className="home__hero">
        <span className="home__eyebrow">TriChat · 2026</span>
        <h1 className="home__title">
          Kết nối <em>mọi khoảnh khắc</em>,<br />
          <span className="home__title-accent">trên mọi thiết bị.</span>
        </h1>
        <p className="home__lede">
          TriChat — chat 1-1, nhóm, gọi thoại &amp; video, bảng tin, stories, kết bạn.
          Thiết kế cao cấp theo phong cách editorial, animation mượt mà nhờ Anime.js v4.
        </p>
        <div className="home__cta">
          <Link to="/sign-up">
            <Button variant="primary" size="lg">Tạo tài khoản</Button>
          </Link>
          <Link to="/login">
            <Button variant="ghost" size="lg">Đăng nhập</Button>
          </Link>
        </div>
      </div>

      <section className="home__features" ref={cardsRef}>
        <Feature icon="💬" title="Trò chuyện" body="Tin nhắn real-time qua SignalR, reaction, reply, ghim, thu hồi." />
        <Feature icon="📞" title="Cuộc gọi" body="Voice + video chất lượng cao với Agora RTC, signaling qua SignalR." />
        <Feature icon="🌿" title="Bảng tin" body="Posts, stories 24h, like, comment, share — phong cách modern." />
        <Feature icon="👥" title="Bạn bè" body="Friend request realtime, block, unfriend, tìm kiếm nâng cao." />
        <Feature icon="🎨" title="Thiết kế" body="High-end editorial palette, glass blur, aurora shadows, animation chỉn chu." />
        <Feature icon="⚡" title="Hiệu năng" body="React 18 + Vite, code-splitting, lazy loading, dark/light mode." />
      </section>
    </div>
  );
}

function Feature({ icon, title, body }) {
  return (
    <article className="feature-card card">
      <span className="feature-card__icon" aria-hidden>{icon}</span>
      <h3>{title}</h3>
      <p>{body}</p>
    </article>
  );
}
