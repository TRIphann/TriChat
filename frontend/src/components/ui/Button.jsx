import './button.css';

export default function Button({
  variant = 'primary',
  size = 'md',
  loading,
  iconLeft,
  iconRight,
  children,
  className = '',
  fullWidth,
  ...rest
}) {
  return (
    <button
      className={`btn btn--${variant} btn--${size} ${fullWidth ? 'btn--full' : ''} ${loading ? 'is-loading' : ''} ${className}`}
      disabled={loading || rest.disabled}
      {...rest}
    >
      {loading && <span className="btn__spinner" aria-hidden />}
      {iconLeft && <span className="btn__icon">{iconLeft}</span>}
      <span className="btn__label">{children}</span>
      {iconRight && <span className="btn__icon">{iconRight}</span>}
    </button>
  );
}
