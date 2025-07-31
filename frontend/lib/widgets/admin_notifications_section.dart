import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminNotificationsSection extends StatefulWidget {
  const AdminNotificationsSection({super.key});

  @override
  State<AdminNotificationsSection> createState() => _AdminNotificationsSectionState();
}

class _AdminNotificationsSectionState extends State<AdminNotificationsSection> {
  List<AdminNotification> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // محاكاة تحميل الإشعارات
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      notifications = [
        AdminNotification(
          id: '1',
          type: NotificationType.newOrder,
          title: 'طلب جديد',
          message: 'طلب جديد من أحمد محمد',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: false,
          actionData: {'orderId': 'ORD123'},
        ),
        AdminNotification(
          id: '2',
          type: NotificationType.withdrawalRequest,
          title: 'طلب سحب جديد',
          message: 'طلب سحب جديد بمبلغ 75000 د.ع',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          isRead: false,
          actionData: {'withdrawalId': 'WD456'},
        ),
        AdminNotification(
          id: '3',
          type: NotificationType.newUser,
          title: 'مستخدم جديد',
          message: 'مستخدم جديد: فاطمة علي',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          isRead: true,
          actionData: {'userId': 'USR789'},
        ),
        AdminNotification(
          id: '4',
          type: NotificationType.orderStatusUpdate,
          title: 'تحديث حالة الطلب',
          message: 'تم تحديث حالة الطلب #ORD124 إلى "تم التوصيل"',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: true,
          actionData: {'orderId': 'ORD124'},
        ),
        AdminNotification(
          id: '5',
          type: NotificationType.newOrder,
          title: 'طلب جديد',
          message: 'طلب جديد من محمد حسن',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          isRead: true,
          actionData: {'orderId': 'ORD125'},
        ),
      ];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم مع عداد الإشعارات غير المقروءة
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFffc107),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.bell,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              const Text(
                'الإشعارات',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (!isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFdc3545),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${notifications.where((n) => !n.isRead).length} جديد',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // أزرار الفلتر
          _buildFilterButtons(),
          const SizedBox(height: 20),

          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFffd700)),
            )
          else
            // قائمة الإشعارات
            _buildNotificationsList(),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Row(
      children: [
        _buildFilterButton('الكل', true),
        const SizedBox(width: 10),
        _buildFilterButton('غير مقروء', false),
        const SizedBox(width: 10),
        _buildFilterButton('الطلبات', false),
        const SizedBox(width: 10),
        _buildFilterButton('السحب', false),
      ],
    );
  }

  Widget _buildFilterButton(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFffd700) : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFFffd700) : Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF1a1a2e) : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return Column(
      children: notifications.map((notification) => _buildNotificationItem(notification)).toList(),
    );
  }

  Widget _buildNotificationItem(AdminNotification notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.withValues(alpha: 0.2)
              : _getNotificationColor(notification.type).withValues(alpha: 0.3),
          width: notification.isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // أيقونة الإشعار
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getNotificationColor(notification.type),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),

          // محتوى الإشعار
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                          color: const Color(0xFF1a1a2e),
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFdc3545),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6c757d),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6c757d),
                      ),
                    ),
                    const Spacer(),
                    if (notification.actionData != null)
                      GestureDetector(
                        onTap: () => _handleNotificationAction(notification),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification.type),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'عرض',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return const Color(0xFF007bff);
      case NotificationType.withdrawalRequest:
        return const Color(0xFFffc107);
      case NotificationType.newUser:
        return const Color(0xFF28a745);
      case NotificationType.orderStatusUpdate:
        return const Color(0xFF17a2b8);
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return FontAwesomeIcons.bagShopping;
      case NotificationType.withdrawalRequest:
        return FontAwesomeIcons.moneyBillWave;
      case NotificationType.newUser:
        return FontAwesomeIcons.userPlus;
      case NotificationType.orderStatusUpdate:
        return FontAwesomeIcons.arrowsRotate;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  void _handleNotificationAction(AdminNotification notification) {
    // معالجة النقر على الإشعار
    switch (notification.type) {
      case NotificationType.newOrder:
        // الانتقال إلى تفاصيل الطلب
        break;
      case NotificationType.withdrawalRequest:
        // الانتقال إلى طلب السحب
        break;
      case NotificationType.newUser:
        // الانتقال إلى ملف المستخدم
        break;
      case NotificationType.orderStatusUpdate:
        // الانتقال إلى تفاصيل الطلب
        break;
    }

    // تحديد الإشعار كمقروء
    setState(() {
      notification.isRead = true;
    });
  }
}

// نماذج البيانات
enum NotificationType {
  newOrder,
  withdrawalRequest,
  newUser,
  orderStatusUpdate,
}

class AdminNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final Map<String, dynamic>? actionData;

  AdminNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.actionData,
  });
}
