import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class ExportOptionsWidget extends StatefulWidget {
  final List<AdminOrder> orders;
  final Function(String, Map<String, dynamic>) onExport;

  const ExportOptionsWidget({
    super.key,
    required this.orders,
    required this.onExport,
  });

  @override
  State<ExportOptionsWidget> createState() => _ExportOptionsWidgetState();
}

class _ExportOptionsWidgetState extends State<ExportOptionsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  String _selectedFormat = 'excel';
  String _selectedRange = 'all';
  bool _includeCustomerInfo = true;
  bool _includeOrderDetails = true;
  bool _includeFinancialInfo = true;
  bool _includeStatusHistory = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFffd700).withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFffd700).withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 25),
                _buildFormatSelection(),
                const SizedBox(height: 20),
                _buildRangeSelection(),
                const SizedBox(height: 20),
                _buildDataOptions(),
                const SizedBox(height: 25),
                _buildActionButtons(),
              ],
            ),
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
          child: const Icon(Icons.download, color: Color(0xFFffd700), size: 24),
        ),
        const SizedBox(width: 15),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تصدير الطلبات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'اختر تنسيق التصدير والبيانات المطلوبة',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
          tooltip: 'إغلاق',
        ),
      ],
    );
  }

  Widget _buildFormatSelection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تنسيق التصدير',
            style: TextStyle(
              color: Color(0xFFffd700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildFormatOption(
                'excel',
                'Excel',
                Icons.table_chart,
                const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 15),
              _buildFormatOption(
                'pdf',
                'PDF',
                Icons.picture_as_pdf,
                const Color(0xFFF44336),
              ),
              const SizedBox(width: 15),
              _buildFormatOption(
                'csv',
                'CSV',
                Icons.description,
                const Color(0xFF2196F3),
              ),
              const SizedBox(width: 15),
              _buildFormatOption(
                'json',
                'JSON',
                Icons.code,
                const Color(0xFFFF9800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedFormat == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFormat = value),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.white.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.white70, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSelection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نطاق البيانات',
            style: TextStyle(
              color: Color(0xFFffd700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildRangeOption(
                  'all',
                  'جميع الطلبات',
                  '${widget.orders.length} طلب',
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildRangeOption(
                  'filtered',
                  'الطلبات المفلترة',
                  'حسب الفلاتر الحالية',
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildRangeOption(
                  'custom',
                  'نطاق مخصص',
                  'اختيار التواريخ',
                ),
              ),
            ],
          ),
          if (_selectedRange == 'custom') ...[
            const SizedBox(height: 15),
            _buildDateRangePicker(),
          ],
        ],
      ),
    );
  }

  Widget _buildRangeOption(String value, String title, String subtitle) {
    final isSelected = _selectedRange == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedRange = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFffd700).withValues(alpha: 0.1)
              : const Color(0xFF16213e),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFffd700)
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? const Color(0xFFffd700) : Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFffd700)
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFffd700).withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFFffd700),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _startDate != null
                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : 'من تاريخ',
                      style: TextStyle(
                        color: _startDate != null
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text('-', style: TextStyle(color: Colors.white)),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFffd700).withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFFffd700),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _endDate != null
                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                          : 'إلى تاريخ',
                      style: TextStyle(
                        color: _endDate != null
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataOptions() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'البيانات المطلوب تصديرها',
            style: TextStyle(
              color: Color(0xFFffd700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildDataOption(
            'معلومات العملاء',
            'الأسماء، أرقام الهواتف، العناوين',
            _includeCustomerInfo,
            (value) => setState(() => _includeCustomerInfo = value),
          ),
          _buildDataOption(
            'تفاصيل الطلبات',
            'المنتجات، الكميات، الأسعار',
            _includeOrderDetails,
            (value) => setState(() => _includeOrderDetails = value),
          ),
          _buildDataOption(
            'المعلومات المالية',
            'المبالغ، الأرباح، طرق الدفع',
            _includeFinancialInfo,
            (value) => setState(() => _includeFinancialInfo = value),
          ),
          _buildDataOption(
            'تاريخ الحالات',
            'سجل تغييرات حالة الطلب',
            _includeStatusHistory,
            (value) => setState(() => _includeStatusHistory = value),
          ),
        ],
      ),
    );
  }

  Widget _buildDataOption(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
            fillColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFFffd700);
              }
              return Colors.transparent;
            }),
            checkColor: const Color(0xFF1a1a2e),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('إلغاء'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white70),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _exportData,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('تصدير'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: const Color(0xFF1a1a2e),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFffd700),
              onPrimary: Color(0xFF1a1a2e),
              surface: Color(0xFF16213e),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _exportData() {
    final options = {
      'format': _selectedFormat,
      'range': _selectedRange,
      'includeCustomerInfo': _includeCustomerInfo,
      'includeOrderDetails': _includeOrderDetails,
      'includeFinancialInfo': _includeFinancialInfo,
      'includeStatusHistory': _includeStatusHistory,
      'startDate': _startDate,
      'endDate': _endDate,
    };

    widget.onExport(_selectedFormat, options);
    Navigator.pop(context);
  }
}
