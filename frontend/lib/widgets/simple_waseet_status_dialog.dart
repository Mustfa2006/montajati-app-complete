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
    super.key,
    required this.orderId,
    required this.currentStatus,
    required this.onStatusSelected,
  });

  @override
  State<SimpleWaseetStatusDialog> createState() => _SimpleWaseetStatusDialogState();
}

class _SimpleWaseetStatusDialogState extends State<SimpleWaseetStatusDialog> {
  int? selectedStatusId;
  String? selectedStatusText;

  // حالات شركة الوسيط الصحيحة بنفس النص والـ ID
  final List<Map<String, dynamic>> statuses = [
    {'id': 1, 'text': 'نشط', 'color': Colors.green, 'icon': Icons.check_circle},
    {'id': 4, 'text': 'تم التسليم للزبون', 'color': Colors.green, 'icon': Icons.check_circle},
    {'id': 24, 'text': 'تم تغيير محافظة الزبون', 'color': Colors.blue, 'icon': Icons.location_on},
    {'id': 42, 'text': 'تغيير المندوب', 'color': Colors.blue, 'icon': Icons.person_pin},
    {'id': 25, 'text': 'لا يرد', 'color': Colors.orange, 'icon': Icons.phone_disabled},
    {'id': 26, 'text': 'لا يرد بعد الاتفاق', 'color': Colors.deepOrange, 'icon': Icons.phone_disabled},
    {'id': 27, 'text': 'مغلق', 'color': Colors.grey, 'icon': Icons.phone_locked},
    {'id': 28, 'text': 'مغلق بعد الاتفاق', 'color': Colors.grey, 'icon': Icons.phone_locked},
    {'id': 3, 'text': 'قيد التوصيل الى الزبون (في عهدة المندوب)', 'color': Colors.blue, 'icon': Icons.local_shipping},
    {'id': 36, 'text': 'الرقم غير معرف', 'color': Colors.red, 'icon': Icons.phone_missed},
    {'id': 37, 'text': 'الرقم غير داخل في الخدمة', 'color': Colors.red, 'icon': Icons.phone_missed},
    {'id': 41, 'text': 'لا يمكن الاتصال بالرقم', 'color': Colors.orange, 'icon': Icons.phone_missed},
    {'id': 29, 'text': 'مؤجل', 'color': Colors.amber, 'icon': Icons.schedule},
    {'id': 30, 'text': 'مؤجل لحين اعادة الطلب لاحقا', 'color': Colors.amber, 'icon': Icons.schedule},
    {'id': 31, 'text': 'الغاء الطلب', 'color': Colors.red, 'icon': Icons.cancel},
    {'id': 32, 'text': 'رفض الطلب', 'color': Colors.red, 'icon': Icons.block},
    {'id': 33, 'text': 'مفصول عن الخدمة', 'color': Colors.red, 'icon': Icons.block},
    {'id': 34, 'text': 'طلب مكرر', 'color': Colors.orange, 'icon': Icons.repeat},
    {'id': 35, 'text': 'مستلم مسبقا', 'color': Colors.green, 'icon': Icons.check_circle_outline},
    {'id': 38, 'text': 'العنوان غير دقيق', 'color': Colors.brown, 'icon': Icons.location_off},
    {'id': 39, 'text': 'لم يطلب', 'color': Colors.red, 'icon': Icons.cancel},
    {'id': 40, 'text': 'حظر المندوب', 'color': Colors.red, 'icon': Icons.block},
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
                        'ID: ${status['id']}',
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
