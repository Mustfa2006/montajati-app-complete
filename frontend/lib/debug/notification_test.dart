// ===================================
// اختبار مباشر لنظام الإشعارات
// Direct Notification Test
// ===================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/official_notification_service.dart';

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  bool _isLoading = false;
  String _status = 'جاهز للاختبار';
  List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    debugPrint('🧪 $message');
  }

  Future<void> _initializeNotificationSystem() async {
    setState(() {
      _isLoading = true;
      _status = 'جاري تهيئة النظام...';
      _logs.clear();
    });

    try {
      _addLog('بدء تهيئة نظام الإشعارات...');
      
      await OfficialNotificationService.initialize();
      _addLog('تم تهيئة النظام بنجاح');
      
      final isInitialized = OfficialNotificationService.isInitialized;
      _addLog('حالة النظام: ${isInitialized ? "مهيأ" : "غير مهيأ"}');
      
      final fcmToken = OfficialNotificationService.fcmToken;
      if (fcmToken != null) {
        _addLog('FCM Token: ${fcmToken.substring(0, 20)}...');
      } else {
        _addLog('لا يوجد FCM Token');
      }
      
      setState(() {
        _status = isInitialized ? 'النظام مهيأ ويعمل' : 'فشل في تهيئة النظام';
      });
      
    } catch (e) {
      _addLog('خطأ في التهيئة: $e');
      setState(() {
        _status = 'خطأ في التهيئة';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFCMToken() async {
    setState(() {
      _isLoading = true;
      _status = 'جاري حفظ FCM Token...';
    });

    try {
      _addLog('بدء حفظ FCM Token...');
      
      final success = await OfficialNotificationService.saveUserFCMToken('07503597589');
      
      if (success) {
        _addLog('تم حفظ FCM Token بنجاح');
        setState(() {
          _status = 'تم حفظ FCM Token';
        });
      } else {
        _addLog('فشل في حفظ FCM Token');
        setState(() {
          _status = 'فشل في حفظ FCM Token';
        });
      }
      
    } catch (e) {
      _addLog('خطأ في حفظ FCM Token: $e');
      setState(() {
        _status = 'خطأ في حفظ FCM Token';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testNotification() async {
    setState(() {
      _isLoading = true;
      _status = 'جاري اختبار الإشعار...';
    });

    try {
      _addLog('بدء اختبار الإشعار...');
      
      final success = await OfficialNotificationService.testNotificationForCurrentUser();
      
      if (success) {
        _addLog('تم إرسال الإشعار بنجاح!');
        setState(() {
          _status = 'تم إرسال الإشعار بنجاح';
        });
      } else {
        _addLog('فشل في إرسال الإشعار');
        setState(() {
          _status = 'فشل في إرسال الإشعار';
        });
      }
      
    } catch (e) {
      _addLog('خطأ في اختبار الإشعار: $e');
      setState(() {
        _status = 'خطأ في اختبار الإشعار';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFCMToken() async {
    setState(() {
      _isLoading = true;
      _status = 'جاري تحديث FCM Token...';
    });

    try {
      _addLog('بدء تحديث FCM Token...');
      
      await OfficialNotificationService.refreshFCMToken();
      _addLog('تم تحديث FCM Token بنجاح');
      
      final newToken = OfficialNotificationService.fcmToken;
      if (newToken != null) {
        _addLog('FCM Token الجديد: ${newToken.substring(0, 20)}...');
      }
      
      setState(() {
        _status = 'تم تحديث FCM Token';
      });
      
    } catch (e) {
      _addLog('خطأ في تحديث FCM Token: $e');
      setState(() {
        _status = 'خطأ في تحديث FCM Token';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      _status = 'جاهز للاختبار';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار نظام الإشعارات'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // حالة النظام
            Card(
              color: _status.contains('نجاح') || _status.contains('يعمل') 
                  ? Colors.green.withOpacity(0.1)
                  : _status.contains('خطأ') || _status.contains('فشل')
                      ? Colors.red.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'حالة النظام',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // أزرار الاختبار
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _initializeNotificationSystem,
                  icon: const Icon(Icons.settings),
                  label: const Text('تهيئة النظام'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _refreshFCMToken,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث Token'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveFCMToken,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ Token'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testNotification,
                  icon: const Icon(Icons.send),
                  label: const Text('اختبار إشعار'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _clearLogs,
                  icon: const Icon(Icons.clear),
                  label: const Text('مسح السجل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // سجل الأحداث
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.list_alt, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'سجل الأحداث (${_logs.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _logs.isEmpty
                          ? const Center(
                              child: Text(
                                'لا توجد أحداث بعد\nاضغط على أي زر للبدء',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: log.contains('خطأ') || log.contains('فشل')
                                        ? Colors.red
                                        : log.contains('نجاح') || log.contains('تم')
                                            ? Colors.green
                                            : Colors.blue,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    log,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: log.contains('خطأ') || log.contains('فشل')
                                          ? Colors.red
                                          : log.contains('نجاح') || log.contains('تم')
                                              ? Colors.green
                                              : Colors.black87,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
