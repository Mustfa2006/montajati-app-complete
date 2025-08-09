// ===================================
// تحسينات خاصة للآيفون
// ===================================

(function() {
    'use strict';

    // فحص إذا كان الجهاز آيفون
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);

    if (isIOS) {
        console.log('🍎 تم اكتشاف جهاز iOS - تطبيق التحسينات...');
        
        // 1. منع التكبير عند النقر على input
        document.addEventListener('DOMContentLoaded', function() {
            const inputs = document.querySelectorAll('input, textarea, select');
            inputs.forEach(input => {
                input.addEventListener('focus', function() {
                    // منع التكبير التلقائي
                    const viewport = document.querySelector('meta[name=viewport]');
                    if (viewport) {
                        viewport.setAttribute('content', 
                            'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
                    }
                });
                
                input.addEventListener('blur', function() {
                    // إعادة السماح بالتكبير
                    const viewport = document.querySelector('meta[name=viewport]');
                    if (viewport) {
                        viewport.setAttribute('content', 
                            'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes');
                    }
                });
            });
        });

        // 2. إصلاح مشكلة الارتفاع في Safari
        function fixIOSHeight() {
            const vh = window.innerHeight * 0.01;
            document.documentElement.style.setProperty('--vh', `${vh}px`);
        }
        
        window.addEventListener('resize', fixIOSHeight);
        window.addEventListener('orientationchange', function() {
            setTimeout(fixIOSHeight, 500);
        });
        fixIOSHeight();

        // 3. تحسين اللمس والسحب
        document.addEventListener('touchstart', function() {}, { passive: true });
        document.addEventListener('touchmove', function() {}, { passive: true });

        // 4. منع السحب للتحديث في Safari
        document.body.addEventListener('touchstart', function(e) {
            if (e.touches.length === 1) {
                const touch = e.touches[0];
                if (touch.clientY <= 10) {
                    e.preventDefault();
                }
            }
        }, { passive: false });

        document.body.addEventListener('touchmove', function(e) {
            if (e.touches.length === 1) {
                const touch = e.touches[0];
                if (touch.clientY <= 10 && window.pageYOffset === 0) {
                    e.preventDefault();
                }
            }
        }, { passive: false });

        // 5. تحسين الأداء للآيفون
        if (isSafari) {
            // تحسين الرسوم المتحركة
            document.documentElement.style.setProperty('--animation-duration', '0.2s');
            
            // تحسين الخطوط
            document.documentElement.style.setProperty('font-smooth', 'antialiased');
            document.documentElement.style.setProperty('-webkit-font-smoothing', 'antialiased');
        }

        // 6. إضافة CSS خاص بالآيفون
        const iosStyles = document.createElement('style');
        iosStyles.textContent = `
            /* تحسينات خاصة بالآيفون */
            body {
                -webkit-overflow-scrolling: touch;
                -webkit-user-select: none;
                -webkit-touch-callout: none;
                -webkit-tap-highlight-color: transparent;
            }
            
            /* إصلاح الارتفاع */
            .full-height {
                height: 100vh;
                height: calc(var(--vh, 1vh) * 100);
            }
            
            /* تحسين الأزرار */
            button, .button {
                -webkit-appearance: none;
                border-radius: 8px;
                cursor: pointer;
            }
            
            /* تحسين الحقول */
            input, textarea, select {
                -webkit-appearance: none;
                border-radius: 8px;
                font-size: 16px; /* منع التكبير */
            }
            
            /* تحسين الانتقالات */
            * {
                -webkit-transform: translateZ(0);
                transform: translateZ(0);
            }
        `;
        document.head.appendChild(iosStyles);

        console.log('✅ تم تطبيق تحسينات iOS بنجاح');
    }

    // 7. رسالة ترحيب للآيفون
    if (isIOS && isSafari) {
        // فحص إذا كان التطبيق مُضاف للشاشة الرئيسية
        const isStandalone = window.navigator.standalone;
        
        if (!isStandalone) {
            // عرض رسالة لإضافة التطبيق للشاشة الرئيسية
            setTimeout(function() {
                if (!localStorage.getItem('ios-install-prompt-shown')) {
                    const showPrompt = confirm(
                        '📱 هل تريد إضافة منتجاتي للشاشة الرئيسية؟\n\n' +
                        '✅ سيعمل مثل التطبيق تماماً\n' +
                        '✅ وصول سريع\n' +
                        '✅ إشعارات\n\n' +
                        'اضغط "موافق" لمعرفة الطريقة'
                    );
                    
                    if (showPrompt) {
                        alert(
                            '📱 طريقة الإضافة:\n\n' +
                            '1. اضغط زر "مشاركة" 📤 في الأسفل\n' +
                            '2. اختر "إضافة إلى الشاشة الرئيسية"\n' +
                            '3. اضغط "إضافة"\n\n' +
                            '✅ ستجد أيقونة منتجاتي على الشاشة الرئيسية!'
                        );
                    }
                    
                    localStorage.setItem('ios-install-prompt-shown', 'true');
                }
            }, 3000); // بعد 3 ثوان من تحميل الصفحة
        } else {
            console.log('🏠 التطبيق يعمل من الشاشة الرئيسية');
        }
    }

    // 8. تحسين الإشعارات للآيفون
    if (isIOS && 'Notification' in window) {
        // فحص دعم الإشعارات في iOS
        if (Notification.permission === 'default') {
            setTimeout(function() {
                if (!localStorage.getItem('ios-notification-prompt-shown')) {
                    const enableNotifications = confirm(
                        '🔔 هل تريد تفعيل الإشعارات؟\n\n' +
                        '✅ ستصلك إشعارات عند تحديث طلباتك\n' +
                        '✅ إشعارات العروض والخصومات\n\n' +
                        'اضغط "موافق" للتفعيل'
                    );
                    
                    if (enableNotifications) {
                        Notification.requestPermission().then(function(permission) {
                            if (permission === 'granted') {
                                console.log('✅ تم تفعيل الإشعارات للآيفون');
                                
                                // إرسال إشعار ترحيبي
                                new Notification('🎉 مرحباً بك في منتجاتي!', {
                                    body: 'تم تفعيل الإشعارات بنجاح',
                                    icon: '/icons/Icon-192.png',
                                    badge: '/icons/Icon-192.png'
                                });
                            }
                        });
                    }
                    
                    localStorage.setItem('ios-notification-prompt-shown', 'true');
                }
            }, 5000); // بعد 5 ثوان
        }
    }

})();
