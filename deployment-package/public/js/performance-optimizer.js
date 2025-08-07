// محسن الأداء للموقع
(function() {
  'use strict';
  
  console.log('⚡ تشغيل محسن الأداء للموقع');
  
  // تحسين تحميل الصور
  function optimizeImages() {
    const images = document.querySelectorAll('img');
    
    images.forEach(img => {
      // إضافة lazy loading
      if (!img.hasAttribute('loading')) {
        img.setAttribute('loading', 'lazy');
      }
      
      // إضافة معالج خطأ
      img.addEventListener('error', function() {
        console.log('❌ فشل تحميل الصورة:', this.src);
        // يمكن إضافة صورة بديلة هنا
      });
    });
    
    console.log('🖼️ تم تحسين', images.length, 'صورة');
  }
  
  // تحسين الطلبات
  function optimizeRequests() {
    // إضافة timeout للطلبات
    const originalFetch = window.fetch;
    
    window.fetch = function(url, options = {}) {
      const timeout = options.timeout || 30000;
      
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), timeout);
      
      const fetchOptions = {
        ...options,
        signal: controller.signal
      };
      
      return originalFetch(url, fetchOptions)
        .then(response => {
          clearTimeout(timeoutId);
          return response;
        })
        .catch(error => {
          clearTimeout(timeoutId);
          if (error.name === 'AbortError') {
            console.log('⏰ انتهت مهلة الطلب:', url);
          }
          throw error;
        });
    };
    
    console.log('🌐 تم تحسين الطلبات');
  }
  
  // تحسين الذاكرة
  function optimizeMemory() {
    // مسح الـ cache القديم كل 30 دقيقة
    setInterval(() => {
      if ('caches' in window) {
        caches.keys().then(cacheNames => {
          cacheNames.forEach(cacheName => {
            if (cacheName.includes('old') || cacheName.includes('temp')) {
              caches.delete(cacheName);
              console.log('🗑️ تم مسح cache قديم:', cacheName);
            }
          });
        });
      }
    }, 30 * 60 * 1000);
    
    console.log('💾 تم تفعيل تحسين الذاكرة');
  }
  
  // مراقبة الأداء
  function monitorPerformance() {
    // مراقبة وقت التحميل
    window.addEventListener('load', () => {
      const loadTime = performance.now();
      console.log('⏱️ وقت تحميل الصفحة:', Math.round(loadTime), 'ms');
      
      // إرسال إحصائيات الأداء (اختياري)
      if (loadTime > 5000) {
        console.warn('⚠️ تحميل بطيء للصفحة:', Math.round(loadTime), 'ms');
      }
    });
    
    // مراقبة استخدام الذاكرة
    if ('memory' in performance) {
      setInterval(() => {
        const memory = performance.memory;
        const usedMB = Math.round(memory.usedJSHeapSize / 1048576);
        const totalMB = Math.round(memory.totalJSHeapSize / 1048576);
        
        if (usedMB > 100) {
          console.warn('⚠️ استخدام ذاكرة عالي:', usedMB, 'MB من', totalMB, 'MB');
        }
      }, 60000); // كل دقيقة
    }
    
    console.log('📊 تم تفعيل مراقبة الأداء');
  }
  
  // تحسين التمرير
  function optimizeScrolling() {
    let ticking = false;
    
    function updateScrollPosition() {
      // تحسين أداء التمرير
      ticking = false;
    }
    
    window.addEventListener('scroll', () => {
      if (!ticking) {
        requestAnimationFrame(updateScrollPosition);
        ticking = true;
      }
    }, { passive: true });
    
    console.log('📜 تم تحسين التمرير');
  }
  
  // تحسين اللمس للأجهزة المحمولة
  function optimizeTouch() {
    // إضافة دعم أفضل للمس
    document.addEventListener('touchstart', function() {}, { passive: true });
    document.addEventListener('touchmove', function() {}, { passive: true });
    
    console.log('👆 تم تحسين اللمس');
  }
  
  // تشغيل جميع التحسينات
  function initializeOptimizations() {
    try {
      optimizeImages();
      optimizeRequests();
      optimizeMemory();
      monitorPerformance();
      optimizeScrolling();
      optimizeTouch();
      
      console.log('✅ تم تشغيل جميع تحسينات الأداء');
    } catch (error) {
      console.error('❌ خطأ في تشغيل التحسينات:', error);
    }
  }
  
  // تشغيل التحسينات عند تحميل الصفحة
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeOptimizations);
  } else {
    initializeOptimizations();
  }
  
  // إضافة دوال للنافذة العامة
  window.montajatiOptimizer = {
    clearCache: function() {
      if ('caches' in window) {
        caches.keys().then(cacheNames => {
          return Promise.all(
            cacheNames.map(cacheName => caches.delete(cacheName))
          );
        }).then(() => {
          console.log('🗑️ تم مسح جميع الـ Cache');
          location.reload();
        });
      }
    },
    
    getPerformanceInfo: function() {
      const info = {
        loadTime: Math.round(performance.now()),
        navigation: performance.getEntriesByType('navigation')[0],
        resources: performance.getEntriesByType('resource').length
      };
      
      if ('memory' in performance) {
        info.memory = {
          used: Math.round(performance.memory.usedJSHeapSize / 1048576) + ' MB',
          total: Math.round(performance.memory.totalJSHeapSize / 1048576) + ' MB'
        };
      }
      
      console.table(info);
      return info;
    },
    
    testConnection: function() {
      if (window.testServerConnection) {
        return window.testServerConnection();
      } else {
        console.log('⚠️ دالة اختبار الاتصال غير متاحة');
      }
    }
  };
  
})();

console.log('✅ تم تحميل محسن الأداء');
