// Service Worker محسن للموقع
const CACHE_NAME = 'montajati-web-v1.0.0';
const API_CACHE_NAME = 'montajati-api-v1.0.0';

// الملفات المطلوب تخزينها مؤقتاً
const STATIC_CACHE_URLS = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/flutter.js',
  '/flutter_bootstrap.js',
  '/manifest.json',
  '/js/web-config.js',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png'
];

// تثبيت Service Worker
self.addEventListener('install', (event) => {
  console.log('🔧 تثبيت Service Worker للموقع');
  
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('📦 تخزين الملفات الأساسية');
        return cache.addAll(STATIC_CACHE_URLS);
      })
      .then(() => {
        console.log('✅ تم تثبيت Service Worker بنجاح');
        return self.skipWaiting();
      })
  );
});

// تفعيل Service Worker
self.addEventListener('activate', (event) => {
  console.log('⚡ تفعيل Service Worker');
  
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME && cacheName !== API_CACHE_NAME) {
            console.log('🗑️ حذف cache قديم:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      console.log('✅ تم تفعيل Service Worker بنجاح');
      return self.clients.claim();
    })
  );
});

// التعامل مع الطلبات
self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);
  
  // تجاهل طلبات Chrome extensions
  if (url.protocol === 'chrome-extension:') {
    return;
  }
  
  // التعامل مع طلبات API
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(handleApiRequest(request));
    return;
  }
  
  // التعامل مع الملفات الثابتة
  event.respondWith(handleStaticRequest(request));
});

// التعامل مع طلبات API
async function handleApiRequest(request) {
  try {
    // محاولة الحصول على الاستجابة من الشبكة أولاً
    const networkResponse = await fetch(request);
    
    // تخزين الاستجابة الناجحة مؤقتاً
    if (networkResponse.ok) {
      const cache = await caches.open(API_CACHE_NAME);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
  } catch (error) {
    console.log('🌐 فشل طلب الشبكة، محاولة استخدام Cache:', request.url);
    
    // في حالة فشل الشبكة، استخدم Cache
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    // إرجاع استجابة خطأ مخصصة
    return new Response(JSON.stringify({
      success: false,
      message: 'لا يوجد اتصال بالإنترنت',
      cached: false
    }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// التعامل مع الملفات الثابتة
async function handleStaticRequest(request) {
  try {
    // محاولة الحصول من Cache أولاً
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    // إذا لم توجد في Cache، جلب من الشبكة
    const networkResponse = await fetch(request);
    
    // تخزين الاستجابة في Cache
    if (networkResponse.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
  } catch (error) {
    console.log('❌ فشل في جلب الملف:', request.url);
    
    // إرجاع صفحة offline مخصصة
    if (request.destination === 'document') {
      return caches.match('/index.html');
    }
    
    return new Response('الملف غير متاح', { status: 404 });
  }
}

// التعامل مع رسائل من التطبيق الرئيسي
self.addEventListener('message', (event) => {
  console.log('📨 رسالة من التطبيق:', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'CLEAR_CACHE') {
    clearAllCaches();
  }
});

// مسح جميع الـ Caches
async function clearAllCaches() {
  try {
    const cacheNames = await caches.keys();
    await Promise.all(
      cacheNames.map(cacheName => caches.delete(cacheName))
    );
    console.log('🗑️ تم مسح جميع الـ Caches');
  } catch (error) {
    console.error('❌ خطأ في مسح الـ Caches:', error);
  }
}

console.log('✅ تم تحميل Enhanced Service Worker للموقع');
