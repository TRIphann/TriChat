import { useUiStore } from '../../store/uiStore';
import './toast.css';

export default function Toast() {
  const toast = useUiStore((s) => s.toast);
  if (!toast) return null;
  return (
    <div className={`toast toast--${toast.type}`} key={toast.id}>
      <span>{toast.message}</span>
    </div>
  );
}
