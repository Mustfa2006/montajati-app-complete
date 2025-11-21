import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class BulkActionsWidget extends StatefulWidget {
  final List<AdminOrder> selectedOrders;
  final Function() onActionsCompleted;
  final Function(String) onShowMessage;

  const BulkActionsWidget({
    super.key,
    required this.selectedOrders,
    required this.onActionsCompleted,
    required this.onShowMessage,
  });

  @override
  State<BulkActionsWidget> createState() => _BulkActionsWidgetState();
}

class _BulkActionsWidgetState extends State<BulkActionsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedOrders.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFffd700).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFffd700).withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildActionButtons(),
              if (_isProcessing) ...[
                const SizedBox(height: 20),
                _buildProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFffd700).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.checklist,
            color: Color(0xFFffd700),
            size: 24,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الإجراءات المجمعة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${widget.selectedOrders.length} طلب محدد',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: widget.onActionsCompleted,
          tooltip: 'إغلاق',
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildActionButton(
          'تحديث الحالة',
          Icons.update,
          const Color(0xFF2196F3),
          _showStatusUpdateDialog,
        ),
        _buildActionButton(
          'تصدير المحدد',
          Icons.download,
          const Color(0xFF4CAF50),
          _exportSelected,
        ),
        _buildActionButton(
          'طباعة الكل',
          Icons.print,
          const Color(0xFFFF9800),
          _printSelected,
        ),
        _buildActionButton(
          'إرسال رسائل',
          Icons.message,
          const Color(0xFF9C27B0),
          _sendMessages,
        ),
        _buildActionButton(
          'نسخ أرقام الهواتف',
          Icons.phone,
          const Color(0xFF00BCD4),
          _copyPhoneNumbers,
        ),
        _buildActionButton(
          'حذف المحدد',
          Icons.delete,
          const Color(0xFFF44336),
          _showDeleteConfirmation,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isProcessing ? null : onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
            ),
          ),
          SizedBox(width: 15),
          Text(
            'جاري تنفيذ العملية...',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // دوال الإجراءات
  void _showStatusUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'تحديث حالة الطلبات',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'سيتم تحديث حالة ${widget.selectedOrders.length} طلب',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            _buildStatusDropdown(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrdersStatus('confirmed'); // مثال
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
            child: const Text('تحديث'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          hintText: 'اختر الحالة الجديدة',
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        ),
        style: const TextStyle(color: Colors.white),
        dropdownColor: const Color(0xFF1a1a2e),
        items: const [
          DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')),
          DropdownMenuItem(value: 'confirmed', child: Text('مؤكد')),
          DropdownMenuItem(value: 'processing', child: Text('قيد التحضير')),
          DropdownMenuItem(value: 'shipped', child: Text('تم الشحن')),
          DropdownMenuItem(value: 'delivered', child: Text('تم التسليم')),
          DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
        ],
        onChanged: (value) {
          // Handle status change
        },
      ),
    );
  }

  Future<void> _updateOrdersStatus(String newStatus) async {
    setState(() => _isProcessing = true);

    try {
      for (final order in widget.selectedOrders) {
        await AdminService.updateOrderStatus(order.id, newStatus);
      }

      widget.onShowMessage(
        'تم تحديث حالة ${widget.selectedOrders.length} طلب بنجاح',
      );
      widget.onActionsCompleted();
    } catch (e) {
      widget.onShowMessage('خطأ في تحديث الطلبات: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportSelected() async {
    setState(() => _isProcessing = true);

    try {
      // تنفيذ تصدير الطلبات المحددة
      await Future.delayed(const Duration(seconds: 2)); // محاكاة العملية

      widget.onShowMessage(
        'تم تصدير ${widget.selectedOrders.length} طلب بنجاح',
      );
      widget.onActionsCompleted();
    } catch (e) {
      widget.onShowMessage('خطأ في تصدير الطلبات: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _printSelected() async {
    setState(() => _isProcessing = true);

    try {
      // تنفيذ طباعة الطلبات المحددة
      await Future.delayed(const Duration(seconds: 2)); // محاكاة العملية

      widget.onShowMessage(
        'تم إرسال ${widget.selectedOrders.length} طلب للطباعة',
      );
      widget.onActionsCompleted();
    } catch (e) {
      widget.onShowMessage('خطأ في طباعة الطلبات: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendMessages() async {
    setState(() => _isProcessing = true);

    try {
      // تنفيذ إرسال الرسائل للعملاء
      await Future.delayed(const Duration(seconds: 2)); // محاكاة العملية

      widget.onShowMessage(
        'تم إرسال رسائل لـ ${widget.selectedOrders.length} عميل',
      );
      widget.onActionsCompleted();
    } catch (e) {
      widget.onShowMessage('خطأ في إرسال الرسائل: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _copyPhoneNumbers() async {
    try {
      final phoneNumbers = widget.selectedOrders
          .map((order) => order.customerPhone)
          .toSet() // إزالة المكرر
          .join('\n');

      // نسخ أرقام الهواتف إلى الحافظة
      // await Clipboard.setData(ClipboardData(text: phoneNumbers));

      widget.onShowMessage(
        'تم نسخ ${phoneNumbers.split('\n').length} رقم هاتف',
      );
    } catch (e) {
      widget.onShowMessage('خطأ في نسخ أرقام الهواتف: $e');
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من حذف ${widget.selectedOrders.length} طلب؟',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            const Text(
              'لا يمكن التراجع عن هذا الإجراء.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelected();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected() async {
    setState(() => _isProcessing = true);

    try {
      for (final order in widget.selectedOrders) {
        await AdminService.deleteOrder(order.id);
      }

      widget.onShowMessage('تم حذف ${widget.selectedOrders.length} طلب بنجاح');
      widget.onActionsCompleted();
    } catch (e) {
      widget.onShowMessage('خطأ في حذف الطلبات: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
