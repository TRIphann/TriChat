import { useEffect } from 'react';
import { useAuthStore } from '../store/authStore';
import { useChatStore } from '../store/chatStore';
import { useFriendStore } from '../store/friendStore';

export function useAppBootstrap() {
  const user = useAuthStore((s) => s.user);

  // Bootstrap realtime services on login, dispose on logout (uid change)
  useEffect(() => {
    if (!user) return;
    const uid = user.uid;
    const chat = useChatStore.getState();
    const friend = useFriendStore.getState();
    chat.init(uid);
    friend.init(uid);
    return () => {
      // Dispose both SignalR connections khi logout
      useChatStore.getState().dispose?.();
      useFriendStore.getState().dispose?.();
    };
  }, [user?.uid]);

  // Visibility-based online/offline
  useEffect(() => {
    if (!user) return;
    function onVis() {
      const conn = useChatStore.getState().signalR;
      if (!conn) return;
      if (document.visibilityState === 'visible') {
        conn.invoke('SetOnline').catch(() => {});
      } else {
        conn.invoke('SetOffline').catch(() => {});
      }
    }
    document.addEventListener('visibilitychange', onVis);
    return () => document.removeEventListener('visibilitychange', onVis);
  }, [user?.uid]);
}
