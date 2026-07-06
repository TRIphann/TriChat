// Minimal service worker so firebase_messaging can register it on web.
// FCM posts messages to this worker when the tab is closed; we just forward
// them to all clients. Browsers require a real SW file — even a no-op works.
self.addEventListener('push', (event) => {
  const data = event.data ? event.data.json() : {};
  const title = data.notification?.title || 'TriChat';
  const options = {
    body: data.notification?.body || '',
    icon: '/icons/Icon-192.png',
    data: data.data || {},
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(clients.openWindow('/'));
});
