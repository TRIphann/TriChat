// FCM Web Push
import { maybeGetMessaging } from './firebase';
import { http } from './httpClient';

export async function requestFcmToken() {
  const messaging = await maybeGetMessaging();
  if (!messaging) return null;

  if (typeof Notification === 'undefined') return null;
  const permission = await Notification.requestPermission();
  if (permission !== 'granted') return null;

  const vapidKey = import.meta.env.VITE_FB_VAPID_KEY;
  if (!vapidKey) return null;

  try {
    const { getToken } = await import('firebase/messaging');
    return await getToken(messaging, { vapidKey });
  } catch (e) {
    console.warn('[fcm] getToken failed:', e);
    return null;
  }
}

export async function saveFcmTokenToServer(token) {
  if (!token) return;
  try {
    await http.post('/api/user/fcm-token', { Token: token });
  } catch (e) {
    console.warn('[fcm] save token failed:', e);
  }
}

export async function onFcmMessage(handler) {
  const messaging = await maybeGetMessaging();
  if (!messaging) return () => {};
  const { onMessage } = await import('firebase/messaging');
  return onMessage(messaging, handler);
}
