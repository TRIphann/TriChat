import { avatarColorFor } from '../../theme/tokens';
import './avatar.css';

export default function Avatar({ src, name, size = 40, ring, online, onClick }) {
  const letter = (name || '?').trim().charAt(0).toUpperCase();
  const bg = avatarColorFor(name || '?');
  const style = {
    width: size,
    height: size,
    fontSize: Math.round(size * 0.4),
    background: src ? 'transparent' : bg,
  };

  return (
    <span
      className={`avatar ${ring ? 'avatar--ring' : ''}`}
      style={style}
      onClick={onClick}
      role={onClick ? 'button' : undefined}
      tabIndex={onClick ? 0 : undefined}
    >
      {src ? (
        <img src={src} alt={name || ''} loading="lazy" />
      ) : (
        <span className="avatar__letter">{letter}</span>
      )}
      {online != null && (
        <span className={`avatar__dot ${online ? 'is-online' : 'is-offline'}`} />
      )}
    </span>
  );
}
