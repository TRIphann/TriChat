import { useEffect, useRef } from 'react';
import { sheetIn } from '../../lib/anime';
import './modal.css';

export default function Modal({ open, onClose, children, title, fullscreen }) {
  const ref = useRef(null);

  useEffect(() => {
    if (open) sheetIn(ref.current);
  }, [open]);

  useEffect(() => {
    if (!open) return;
    function onKey(e) { if (e.key === 'Escape') onClose?.(); }
    document.addEventListener('keydown', onKey);
    document.body.style.overflow = 'hidden';
    return () => {
      document.removeEventListener('keydown', onKey);
      document.body.style.overflow = '';
    };
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="modal-root" role="dialog" aria-modal>
      <div className="modal__backdrop" onClick={onClose} />
      <div ref={ref} className={`modal ${fullscreen ? 'modal--full' : ''}`}>
        {title && (
          <header className="modal__header">
            <h3>{title}</h3>
            <button className="modal__close" onClick={onClose} aria-label="Đóng">×</button>
          </header>
        )}
        <div className="modal__body">{children}</div>
      </div>
    </div>
  );
}
