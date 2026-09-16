import { Link } from 'react-router-dom';

export default function NotFound() {
  return (
    <div className="home">
      <div className="home__hero">
        <span className="home__eyebrow">404</span>
        <h1 className="home__title">Trang không tồn tại</h1>
        <p className="home__lede">Liên kết có thể đã hết hạn hoặc bạn gõ sai đường dẫn.</p>
        <Link to="/chat-list" className="home__cta">
          <button className="btn btn--primary btn--lg">Về trang chính</button>
        </Link>
      </div>
    </div>
  );
}
