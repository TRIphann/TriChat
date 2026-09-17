import { forwardRef } from 'react';
import './input.css';

const Input = forwardRef(function Input(
  { label, error, hint, iconLeft, iconRight, className = '', type = 'text', ...rest },
  ref,
) {
  return (
    <label className={`field ${className} ${error ? 'has-error' : ''}`}>
      {label && <span className="field__label">{label}</span>}
      <span className="field__control">
        {iconLeft && <span className="field__icon">{iconLeft}</span>}
        <input ref={ref} type={type} className="field__input" {...rest} />
        {iconRight && <span className="field__icon">{iconRight}</span>}
      </span>
      {hint && !error && <span className="field__hint">{hint}</span>}
      {error && <span className="field__error">{error}</span>}
    </label>
  );
});

export default Input;
