import { create } from 'zustand';

const LS_KEY = 'trichat-layout-v1';

const DEFAULTS = {
  leftWidth: 320,
  rightWidth: 340,
  leftVisible: true,
  rightVisible: true,
  centerMode: 'chat', // 'chat' | 'feed'
  leftTab: 'chats',   // 'chats' | 'friends' | 'requests'
  rightTab: 'info',   // 'info' | 'profile'  (không còn 'feed')
  activeConvId: null, // current opened conversation id
  activeUserId: null, // user profile shown in right panel (null = auto from conv)
  collapsed: false,   // mini mode toggle (mobile-ish)
};

function load() {
  try {
    const raw = localStorage.getItem(LS_KEY);
    if (!raw) return DEFAULTS;
    const parsed = JSON.parse(raw);
    return { ...DEFAULTS, ...parsed };
  } catch {
    return DEFAULTS;
  }
}

function persist(state) {
  try {
    const subset = {
      leftWidth: state.leftWidth,
      rightWidth: state.rightWidth,
      leftVisible: state.leftVisible,
      rightVisible: state.rightVisible,
      leftTab: state.leftTab,
      rightTab: state.rightTab,
      centerMode: state.centerMode,
    };
    localStorage.setItem(LS_KEY, JSON.stringify(subset));
  } catch {}
}

export const useUiStore = create((set, get) => ({
  ...load(),

  setLeftWidth: (w) => {
    set({ leftWidth: clamp(w, 240, 460) });
    persist(get());
  },
  setRightWidth: (w) => {
    set({ rightWidth: clamp(w, 280, 460) });
    persist(get());
  },
  toggleLeft: () => {
    set({ leftVisible: !get().leftVisible });
    persist(get());
  },
  toggleRight: () => {
    set({ rightVisible: !get().rightVisible });
    persist(get());
  },
  setLeftTab: (t) => set({ leftTab: t }),
  setRightTab: (t) => set({ rightTab: t }),
  setCenterMode: (m) => set({ centerMode: m }),

  openConversation: (convId) => {
    set({
      activeConvId: convId,
      centerMode: 'chat',
      rightTab: 'info',
      rightVisible: true,
    });
  },
  closeConversation: () => set({ activeConvId: null }),

  setActiveUserId: (uid) => {
    set({ activeUserId: uid, rightTab: 'profile', rightVisible: true });
  },
  openProfileInCenter: (uid) => {
    set({
      activeUserId: uid,
      centerMode: 'profile',
      rightVisible: false,
    });
  },
  closeProfileInCenter: () => {
    set({
      centerMode: 'chat',
      activeUserId: null,
    });
  },
  setRightFeedId: (id) => {
    // Backwards-compat: tab feed đã bỏ khỏi right panel — giữ stub cho code cũ không vỡ.
    // Center vẫn có chế độ 'feed' render NewsfeedView global; hành vi này không còn ảnh hưởng.
    if (typeof window !== 'undefined' && import.meta?.env?.DEV) {
      // eslint-disable-next-line no-console
      console.debug('[uiStore] setRightFeedId đã deprecated — right panel chỉ còn Thông tin / Hồ sơ');
    }
  },
  resetLayout: () => {
    set({ ...DEFAULTS });
    persist(get());
  },

  toast: null,
  showToast: (message, type = 'info', ttl = 3000) => {
    set({ toast: { message, type, id: Date.now() } });
    setTimeout(() => set({ toast: null }), ttl);
  },
  hideToast: () => set({ toast: null }),

  locale: localStorage.getItem('trichat-locale') || 'vi',
  setLocale: (locale) => {
    localStorage.setItem('trichat-locale', locale);
    set({ locale });
  },
}));

function clamp(v, min, max) {
  return Math.min(max, Math.max(min, v));
}
