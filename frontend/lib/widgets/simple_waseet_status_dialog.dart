// ===================================
// حوار بسيط لاختيار حالات الوسيط
// Simple Waseet Status Dialog
// ===================================

import 'package:flutter/material.dart';

class SimpleWaseetStatusDialog extends StatefulWidget {
  final String orderId;
  final String currentStatus;
  final Function(int statusId, String statusText) onStatusSelected;

  const SimpleWaseetStatusDialog({
    Key? key,
    required this.orderId,
    required this.currentStatus,
    required this.onStatusSelected,
  }) : super(key: key);

  @override
  State<SimpleWaseetStatusDialog> createState() => _SimpleWaseetStatusDialogState();
}

class _SimpleWaseetStatusDialogState extends State<SimpleWaseetStatusDialog> {
  int? selectedStatusId;
  String? selectedStatusText;

  // الحالات الأساسية المهمة
  final List<Map<String, dynamic>> statuses = [
    {
      'id': 4,
      'text': 'تم التسليم للزبون',
      'color': Colors.green,
      'icon': Icons.check_circle,
      'category': 'delivered'
    },
    {
      'id': 3,
      'text': 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      'color': Colors.blue,
      'icon': Icons.local_shipping,
      'category': 'in_delivery'
    },
    {
      'id': 25,
      'text': 'لا يرد',
      'color': Colors.orange,
      'icon': Icons.phone_disabled,
      'category': 'contact_issue'
    },
    {
      'id': 31,
      'text': 'الغاء الطلب',
      'color': Colors.red,
      'icon': Icons.cancel,
      'category': 'cancelled'
    },
    {
      'id': 32,
      'text': 'رفض الطلب',
      'color': Colors.red,
      'icon': Icons.block,
      'category': 'cancelled'
    },
    {
      'id': 29,
      'text': 'مؤجل',
      'color': Colors.amber,
      'icon': Icons.schedule,
      'category': 'postponed'
    },
    {
      'id': 38,
      'text': 'العنوان غير دقيق',
      'color': Colors.brown,
      'icon': Icons.location_off,
      'category': 'address_issue'
    },
    {
      'id': 41,
      'text': 'لا يمكن الاتصال بالرقم',
      'color': Colors.orange,
      'icon': Icons.phone_missed,
      'category': 'contact_issue'
    },
    {
      'id': 26,
      'text': 'لا يرد بعد الاتفاق',
      'color': Colors.deepOrange,
      'icon': Icons.phone_disabled,
      'category': 'contact_issue'
    },
    {
      'id': 27,
      'text': 'مغلق',
      'color': Colors.grey,
      'icon': Icons.phone_locked,
      'category': 'contact_issue'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit, color: Colors.blue[700]),
          const SizedBox(width: 8),
          const Text('تحديث حالة الطلب'),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الطلب: ${widget.orderId}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'اختر الحالة الجديدة:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: statuses.length,
                itemBuilder: (context, index) {
                  final status = statuses[index];
                  final isSelected = selectedStatusId == status['id'];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: isSelected ? 4 : 1,
                    color: isSelected 
                      ? status['color'].withOpacity(0.1)
                      : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: status['color'],
                        child: Icon(
                          status['icon'],
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        status['text'],
                        style: TextStyle(
                          fontWeight: isSelected 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                          color: isSelected 
                            ? status['color']
                            : null,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${status['id']} • ${getCategoryName(status['category'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: isSelected 
                        ? Icon(Icons.check_circle, color: status['color'])
                        : null,
                      onTap: () {
                        setState(() {
                          selectedStatusId = status['id'];
                          selectedStatusText = status['text'];
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: selectedStatusId != null
            ? () {
                widget.onStatusSelected(selectedStatusId!, selectedStatusText!);
                Navigator.pop(context);
              }
            : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          child: const Text('تحديث'),
        ),
      ],
    );
  }

  String getCategoryName(String category) {
    const categoryNames = {
      'delivered': 'تم التوصيل',
      'in_delivery': 'قيد التوصيل',
      'contact_issue': 'مشاكل التواصل',
      'cancelled': 'ملغي',
      'postponed': 'مؤجل',
      'address_issue': 'مشاكل العنوان',
    };
    return categoryNames[category] ?? category;
  }
}

// دالة مساعدة لعرض الحوار
Future<void> showSimpleWaseetStatusDialog(
  BuildContext context, {
  required String orderId,
  required String currentStatus,
  required Function(int statusId, String statusText) onStatusSelected,
}) async {
  await showDialog(
    context: context,
    builder: (context) => SimpleWaseetStatusDialog(
      orderId: orderId,
      currentStatus: currentStatus,
      onStatusSelected: onStatusSelected,
    ),
  );
}
