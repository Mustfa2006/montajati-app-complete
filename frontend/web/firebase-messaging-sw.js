// Firebase Service Worker للإشعارات في الخلفية

// استيراد Firebase scripts
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// إعدادات Firebase
const firebaseConfig = {
  apiKey: "AIzaSyDkrQtsrzTDMP9OcE8rqKDr9HESxqo-vvM",
  authDomain: "montajati-app-7767d.firebaseapp.com",
  projectId: "montajati-app-7767d",
  storageBucket: "montajati-app-7767d.firebasestorage.app",
  messagingSenderId: "827926006456",
  appId: "1:827926006456:web:YOUR_WEB_APP_ID"
};

// تهيئة Firebase
firebase.initializeApp(firebaseConfig);

// الحصول على messaging service
const messaging = firebase.messaging();

// معالجة الإشعارات في الخلفية
messaging.onBackgroundMessage(function (payload) {
  console.log('📱 وصل إشعار في الخلفية:', payload);

  const notificationTitle = payload.notification.title || 'إشعار جديد';
  const notificationOptions = {
    body: payload.notification.body || 'لديك تحديث جديد',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'withdrawal-notification',
    requireInteraction: true,
    actions: [
      {
        action: 'open',
        title: 'فتح التطبيق'
      },
      {
        action: 'close',
        title: 'إغلاق'
      }
    ],
    data: payload.data
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// معالجة النقر على الإشعار
self.addEventListener('notificationclick', function (event) {
  console.log('👆 تم النقر على إشعار:', event);

  event.notification.close();

  if (event.action === 'open' || !event.action) {
    // فتح التطبيق
    event.waitUntil(
      clients.matchAll({ type: 'window' }).then(function (clientList) {
        // البحث عن نافذة مفتوحة للتطبيق
        for (let i = 0; i < clientList.length; i++) {
          const client = clientList[i];
          if (client.url.includes(self.location.origin) && 'focus' in client) {
            return client.focus();
          }
        }

        // فتح نافذة جديدة إذا لم توجد
        if (clients.openWindow) {
          return clients.openWindow('/');
        }
      })
    );
  }
});

// معالجة إغلاق الإشعار
self.addEventListener('notificationclose', function (event) {
  console.log('❌ تم إغلاق الإشعار:', event);
});
