import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/admin_service.dart';
import '../services/fcm_service.dart';
import '../debug/fcm_debug_helper.dart';

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _result = '';
  Map<String, dynamic>? _tokenStats;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 اختبار الإشعارات'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // معلومات FCM
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📱 معلومات FCM',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _getFCMInfo(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final info = snapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('✅ مُهيأ: ${info['isInitialized'] ? 'نعم' : 'لا'}'),
                              Text('🔑 لديه Token: ${info['hasToken'] ? 'نعم' : 'لا'}'),
                              if (info['token'] != null)
                                Text('📋 Token: ${info['token'].toString().substring(0, 20)}...'),
                            ],
                          );
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // اختبار الإشعارات
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔔 اختبار الإشعارات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        hintText: '05xxxxxxxx',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _testNotification,
                            icon: const Icon(Icons.send),
                            label: const Text('إرسال إشعار تجريبي'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _testOrderNotification,
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text('إشعار طلب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // إحصائيات FCM Tokens
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '📊 إحصائيات FCM Tokens',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: _loadTokenStats,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'تحديث',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_tokenStats != null) ...[
                      Text('📈 إجمالي الرموز: ${_tokenStats!['total']['tokens'] ?? 0}'),
                      Text('✅ الرموز النشطة: ${_tokenStats!['total']['activeTokens'] ?? 0}'),
                      Text('👥 المستخدمين الفريدين: ${_tokenStats!['total']['uniqueUsers'] ?? 0}'),
                      Text('💚 نسبة النشاط: ${_tokenStats!['health']['activePercentage'] ?? 0}%'),
                    ] else ...[
                      const Text('اضغط تحديث لعرض الإحصائيات'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // أزرار إضافية
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _registerCurrentUserToken,
                    icon: const Icon(Icons.app_registration),
                    label: const Text('تسجيل Token الحالي'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _cleanupTokens,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('تنظيف الرموز'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // زر التشخيص الشامل
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _runFCMDiagnosis,
                icon: const Icon(Icons.bug_report),
                label: const Text('🔍 تشخيص شامل لـ FCM'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // النتائج
            if (_result.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 النتيجة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_result),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testNotification() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _result = '❌ يرجى إدخال رقم الهاتف';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = '⏳ جاري الإرسال...';
    });

    try {
      final success = await AdminService.testNotification(_phoneController.text.trim());
      setState(() {
        _result = success 
          ? '✅ تم إرسال الإشعار التجريبي بنجاح!'
          : '❌ فشل في إرسال الإشعار التجريبي';
      });
    } catch (e) {
      setState(() {
        _result = '❌ خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testOrderNotification() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _result = '❌ يرجى إدخال رقم الهاتف';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = '⏳ جاري الإرسال...';
    });

    try {
      await AdminService.sendGeneralNotification(
        customerPhone: _phoneController.text.trim(),
        title: '📦 تحديث حالة طلبك',
        message: 'تم تحديث حالة طلبك إلى: جاري التوصيل - هذا إشعار تجريبي',
        additionalData: {
          'type': 'order_status_test',
          'orderId': 'TEST-${DateTime.now().millisecondsSinceEpoch}',
          'newStatus': 'out_for_delivery',
        },
      );
      
      setState(() {
        _result = '✅ تم إرسال إشعار تحديث الطلب التجريبي!';
      });
    } catch (e) {
      setState(() {
        _result = '❌ خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getFCMInfo() async {
    try {
      return FCMService().getServiceInfo();
    } catch (e) {
      return {
        'isInitialized': false,
        'hasToken': false,
        'error': e.toString(),
      };
    }
  }

  Future<void> _loadTokenStats() async {
    setState(() {
      _isLoading = true;
      _result = '⏳ جاري تحميل الإحصائيات...';
    });

    try {
      final response = await http.get(
        Uri.parse('${AdminService.baseUrl}/api/fcm/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _tokenStats = data['data'];
            _result = '✅ تم تحميل الإحصائيات بنجاح';
          });
        } else {
          setState(() {
            _result = '❌ فشل في تحميل الإحصائيات: ${data['message']}';
          });
        }
      } else {
        setState(() {
          _result = '❌ خطأ في الخادم: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _result = '❌ خطأ في الاتصال: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registerCurrentUserToken() async {
    setState(() {
      _isLoading = true;
      _result = '⏳ جاري تسجيل FCM Token...';
    });

    try {
      final success = await FCMService.registerCurrentUserToken();
      setState(() {
        _result = success
          ? '✅ تم تسجيل FCM Token بنجاح!'
          : '❌ فشل في تسجيل FCM Token';
      });

      // تحديث الإحصائيات
      if (success) {
        await _loadTokenStats();
      }
    } catch (e) {
      setState(() {
        _result = '❌ خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanupTokens() async {
    setState(() {
      _isLoading = true;
      _result = '⏳ جاري تنظيف الرموز القديمة...';
    });

    try {
      final response = await http.post(
        Uri.parse('${AdminService.baseUrl}/api/fcm/cleanup'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = data['success']
            ? '✅ تم تنظيف الرموز القديمة بنجاح!'
            : '❌ فشل في تنظيف الرموز: ${data['message']}';
        });

        // تحديث الإحصائيات
        await _loadTokenStats();
      } else {
        setState(() {
          _result = '❌ خطأ في الخادم: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _result = '❌ خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runFCMDiagnosis() async {
    setState(() {
      _isLoading = true;
      _result = '🔍 جاري تشغيل التشخيص الشامل لـ FCM...';
    });

    try {
      // تشغيل التشخيص الشامل
      await FCMDebugHelper.quickDiagnosis();

      setState(() {
        _result = '✅ تم تشغيل التشخيص الشامل! تحقق من console للتفاصيل.';
      });

      // تحديث الإحصائيات
      await _loadTokenStats();

    } catch (e) {
      setState(() {
        _result = '❌ خطأ في التشخيص: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
