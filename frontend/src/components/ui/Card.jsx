import './card.css';

export default function Card({ children, glass, className = '', ...rest }) {
  return (
    <div className={`card ${glass ? 'card--glass' : ''} ${className}`} {...rest}>
      {children}
    </div>
  );
}
