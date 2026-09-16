import { create } from 'zustand';
import { useTheme } from '../theme/ThemeProvider';

export const useUiStore = create((set) => ({
  locale: localStorage.getItem('trichat-locale') || 'vi',
  setLocale: (locale) => {
    localStorage.setItem('trichat-locale', locale);
    set({ locale });
  },

  toast: null,
  showToast: (message, type = 'info', ttl = 3000) => {
    set({ toast: { message, type, id: Date.now() } });
    setTimeout(() => set({ toast: null }), ttl);
  },
  hideToast: () => set({ toast: null }),

  modal: null,
  openModal: (modal) => set({ modal }),
  closeModal: () => set({ modal: null }),
}));
