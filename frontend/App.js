// ===================================
// App.js الجاهز مع الإشعارات
// ===================================

import React, { useEffect, useState } from 'react';
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  View,
  Alert,
  TouchableOpacity,
} from 'react-native';

// استيراد خدمة الإشعارات
import NotificationService from './NotificationService';

const App = () => {
  const [notificationsEnabled, setNotificationsEnabled] = useState(false);
  const [userPhone, setUserPhone] = useState('07503597589'); // هاتف المستخدم

  // ===================================
  // تشغيل الإشعارات عند بدء التطبيق
  // ===================================
  useEffect(() => {
    initializeNotifications();
  }, []);

  const initializeNotifications = async () => {
    try {
      console.log('🚀 بدء تهيئة التطبيق...');
      
      // إعداد الإشعارات تلقائياً
      const success = await NotificationService.setupNotifications(userPhone);
      
      if (success) {
        setNotificationsEnabled(true);
        Alert.alert(
          '✅ تم تفعيل الإشعارات',
          'ستحصل على إشعارات عند تحديث طلباتك',
          [{ text: 'ممتاز' }]
        );
      } else {
        Alert.alert(
          '⚠️ تعذر تفعيل الإشعارات',
          'يرجى السماح بالإشعارات للحصول على التحديثات',
          [
            { text: 'إلغاء' },
            { text: 'إعادة المحاولة', onPress: initializeNotifications }
          ]
        );
      }
    } catch (error) {
      console.error('❌ خطأ في تهيئة التطبيق:', error);
    }
  };

  // ===================================
  // اختبار الإشعارات
  // ===================================
  const testNotification = async () => {
    try {
      const response = await fetch('https://your-api.com/api/fcm/test-notification', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          user_phone: userPhone,
          title: 'اختبار الإشعارات',
          message: 'هذا إشعار تجريبي للتأكد من عمل النظام'
        }),
      });

      const result = await response.json();
      
      if (result.success) {
        Alert.alert('✅ تم إرسال إشعار تجريبي');
      } else {
        Alert.alert('❌ فشل في إرسال الإشعار التجريبي');
      }
    } catch (error) {
      console.error('❌ خطأ في اختبار الإشعار:', error);
      Alert.alert('❌ خطأ في الاتصال بالخادم');
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#f8f9fa" />
      
      <ScrollView contentInsetAdjustmentBehavior="automatic" style={styles.scrollView}>
        
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>📱 تطبيق منتجاتي</Text>
          <Text style={styles.subtitle}>نظام الإشعارات الذكي</Text>
        </View>

        {/* حالة الإشعارات */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>🔔 حالة الإشعارات</Text>
          <View style={styles.statusContainer}>
            <View style={[styles.statusDot, { backgroundColor: notificationsEnabled ? '#28a745' : '#dc3545' }]} />
            <Text style={styles.statusText}>
              {notificationsEnabled ? 'مفعلة ✅' : 'غير مفعلة ❌'}
            </Text>
          </View>
          <Text style={styles.phoneText}>📱 الهاتف: {userPhone}</Text>
        </View>

        {/* معلومات النظام */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>ℹ️ كيف يعمل النظام</Text>
          <Text style={styles.infoText}>
            • عند تغيير حالة طلبك، ستحصل على إشعار فوري{'\n'}
            • الإشعارات تعمل حتى لو كان التطبيق مغلق{'\n'}
            • لا حاجة لأي إعدادات إضافية{'\n'}
            • النظام يعمل تلقائياً في الخلفية
          </Text>
        </View>

        {/* أزرار التحكم */}
        <View style={styles.buttonsContainer}>
          
          {/* زر إعادة تفعيل الإشعارات */}
          <TouchableOpacity 
            style={[styles.button, styles.primaryButton]} 
            onPress={initializeNotifications}
          >
            <Text style={styles.buttonText}>🔄 إعادة تفعيل الإشعارات</Text>
          </TouchableOpacity>

          {/* زر اختبار الإشعارات */}
          <TouchableOpacity 
            style={[styles.button, styles.secondaryButton]} 
            onPress={testNotification}
          >
            <Text style={[styles.buttonText, { color: '#007bff' }]}>🧪 اختبار الإشعارات</Text>
          </TouchableOpacity>

        </View>

        {/* معلومات إضافية */}
        <View style={styles.footer}>
          <Text style={styles.footerText}>
            💡 ملاحظة: تأكد من السماح بالإشعارات في إعدادات الهاتف للحصول على أفضل تجربة
          </Text>
        </View>

      </ScrollView>
    </SafeAreaView>
  );
};

// ===================================
// التصميم
// ===================================
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
  },
  scrollView: {
    flex: 1,
    padding: 16,
  },
  header: {
    alignItems: 'center',
    marginBottom: 24,
    paddingVertical: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#212529',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#6c757d',
  },
  card: {
    backgroundColor: '#ffffff',
    borderRadius: 12,
    padding: 20,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#212529',
    marginBottom: 12,
  },
  statusContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  statusDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    marginRight: 8,
  },
  statusText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#212529',
  },
  phoneText: {
    fontSize: 14,
    color: '#6c757d',
    marginTop: 4,
  },
  infoText: {
    fontSize: 14,
    color: '#495057',
    lineHeight: 20,
  },
  buttonsContainer: {
    marginVertical: 8,
  },
  button: {
    borderRadius: 8,
    paddingVertical: 14,
    paddingHorizontal: 20,
    marginBottom: 12,
    alignItems: 'center',
  },
  primaryButton: {
    backgroundColor: '#007bff',
  },
  secondaryButton: {
    backgroundColor: '#ffffff',
    borderWidth: 2,
    borderColor: '#007bff',
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#ffffff',
  },
  footer: {
    marginTop: 20,
    padding: 16,
    backgroundColor: '#e9ecef',
    borderRadius: 8,
  },
  footerText: {
    fontSize: 12,
    color: '#6c757d',
    textAlign: 'center',
    lineHeight: 16,
  },
});

export default App;
