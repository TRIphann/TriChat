import { useEffect, useRef, useState } from 'react';
import './resizeHandle.css';

/**
 * ResizeHandle — drag để chỉnh width giữa 2 panel.
 *
 * Props:
 *  - onDelta(dx): callback khi user kéo, nhận dx pixel (âm hoặc dương)
 *  - direction: 'left' | 'right' — handle nằm bên trái hay phải
 *               (kéo handle bên trái sang phải → panel bên trái nhỏ lại → dx > 0)
 */
export default function ResizeHandle({ onDelta, direction = 'left', title = 'Kéo để chỉnh kích thước' }) {
  const [dragging, setDragging] = useState(false);
  const lastX = useRef(0);
  const handleRef = useRef(null);

  useEffect(() => {
    if (!dragging) return;
    function onMove(e) {
      const x = e.clientX;
      const dx = x - lastX.current;
      lastX.current = x;
      onDelta(dx);
    }
    function onUp() {
      setDragging(false);
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
    }
    window.addEventListener('pointermove', onMove);
    window.addEventListener('pointerup', onUp);
    window.addEventListener('pointercancel', onUp);
    return () => {
      window.removeEventListener('pointermove', onMove);
      window.removeEventListener('pointerup', onUp);
      window.removeEventListener('pointercancel', onUp);
    };
  }, [dragging, onDelta]);

  function onPointerDown(e) {
    e.preventDefault();
    lastX.current = e.clientX;
    setDragging(true);
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';
    handleRef.current?.setPointerCapture?.(e.pointerId);
  }

  function onDoubleClick() {
    // double-click để reset về default
    onDelta(NaN);
  }

  return (
    <div
      ref={handleRef}
      className={`resize-handle resize-handle--${direction} ${dragging ? 'is-dragging' : ''}`}
      onPointerDown={onPointerDown}
      onDoubleClick={onDoubleClick}
      title={title}
      role="separator"
      aria-orientation="vertical"
    >
      <span className="resize-handle__grip" aria-hidden />
    </div>
  );
}
