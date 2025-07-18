// نظام الإشعارات الرسمي - JavaScript
console.log('📢 تحميل نظام الإشعارات الرسمي...');

// طلب إذن الإشعارات
async function requestNotificationPermission() {
    console.log('📱 طلب إذن الإشعارات...');

    if (!("Notification" in window)) {
        console.log("❌ هذا المتصفح لا يدعم الإشعارات");
        return false;
    }

    if (Notification.permission === "granted") {
        console.log("✅ تم منح إذن الإشعارات مسبقاً");
        return true;
    }

    if (Notification.permission !== "denied") {
        const permission = await Notification.requestPermission();
        if (permission === "granted") {
            console.log("✅ تم منح إذن الإشعارات");
            return true;
        }
    }

    console.log("❌ تم رفض إذن الإشعارات");
    return false;
}

// إرسال إشعار المتصفح
function showBrowserNotification(title, body, icon = null) {
    console.log(`🔔 إرسال إشعار: ${title} - ${body}`);

    if (!("Notification" in window)) {
        console.log("❌ المتصفح لا يدعم الإشعارات");
        return false;
    }

    if (Notification.permission !== "granted") {
        console.log("❌ لا يوجد إذن للإشعارات");
        return false;
    }

    try {
        const notification = new Notification(title, {
            body: body,
            icon: icon || '/favicon.ico',
            badge: '/favicon.ico',
            tag: 'official-notification',
            requireInteraction: false,
            silent: false,
            timestamp: Date.now(),
            data: {
                type: 'official_notification',
                timestamp: new Date().toISOString()
            }
        });

        // إعدادات الإشعار
        notification.onclick = function (event) {
            console.log('🖱️ تم النقر على الإشعار');
            event.preventDefault();
            window.focus();
            notification.close();
        };

        notification.onshow = function () {
            console.log('✅ تم عرض الإشعار بنجاح');
        };

        notification.onerror = function (error) {
            console.log('❌ خطأ في عرض الإشعار:', error);
        };

        notification.onclose = function () {
            console.log('🔒 تم إغلاق الإشعار');
        };

        // إغلاق الإشعار تلقائياً بعد 8 ثوان
        setTimeout(() => {
            notification.close();
        }, 8000);

        return true;
    } catch (error) {
        console.log('❌ خطأ في إنشاء الإشعار:', error);
        return false;
    }
}

// إرسال إشعار رسمي
function sendOfficialNotification(title, body) {
    console.log('📢 إرسال إشعار رسمي:', title);

    return showBrowserNotification(title, body);
}

// إرسال إشعار السحب الرسمي
function sendWithdrawalNotification(status, amount) {
    console.log(`📢 إرسال إشعار رسمي لطلب السحب: ${status} - ${amount} د.ع`);

    let title, body;

    switch (status.toLowerCase()) {
        case 'completed':
        case 'transferred':
            title = 'تم تحويل طلب السحب';
            body = `تم تحويل مبلغ ${amount} د.ع إلى محفظتك بنجاح`;
            break;
        case 'rejected':
        case 'cancelled':
            title = 'تم إلغاء طلب السحب';
            body = `تم إلغاء طلب سحب بمبلغ ${amount} د.ع`;
            break;
        case 'pending':
            title = 'طلب سحب قيد المراجعة';
            body = `طلب سحب بمبلغ ${amount} د.ع قيد المراجعة`;
            break;
        default:
            title = 'تحديث طلب السحب';
            body = `تم تحديث حالة طلب السحب إلى ${status}`;
    }

    return showBrowserNotification(title, body);
}

// تهيئة الإشعارات عند تحميل الصفحة
document.addEventListener('DOMContentLoaded', async function () {
    console.log('🚀 تهيئة نظام الإشعارات الرسمي...');

    // طلب إذن الإشعارات
    const hasPermission = await requestNotificationPermission();

    if (hasPermission) {
        console.log('✅ نظام الإشعارات الرسمي جاهز');
    } else {
        console.log('❌ فشل في تهيئة نظام الإشعارات');
    }
});

// تصدير الدوال للاستخدام من Dart
window.showBrowserNotification = showBrowserNotification;
window.sendOfficialNotification = sendOfficialNotification;
window.sendWithdrawalNotification = sendWithdrawalNotification;
window.requestNotificationPermission = requestNotificationPermission;

console.log('✅ تم تحميل نظام الإشعارات الرسمي بنجاح');
