import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdvancedSearchWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersChanged;
  final Map<String, dynamic> initialFilters;

  const AdvancedSearchWidget({super.key, required this.onFiltersChanged, this.initialFilters = const {}});

  @override
  State<AdvancedSearchWidget> createState() => _AdvancedSearchWidgetState();
}

class _AdvancedSearchWidgetState extends State<AdvancedSearchWidget> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // فلاتر البحث
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedDateRange = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedUser = 'all';
  double _minAmount = 0;
  double _maxAmount = 1000000;
  String _selectedCity = 'all';
  String _selectedPaymentMethod = 'all';
  bool _showAdvancedFilters = false;

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeFilters();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
  }

  void _initializeFilters() {
    _searchQuery = widget.initialFilters['searchQuery'] ?? '';
    _selectedStatus = widget.initialFilters['selectedStatus'] ?? 'all';
    _selectedDateRange = widget.initialFilters['selectedDateRange'] ?? 'all';
    _startDate = widget.initialFilters['startDate'];
    _endDate = widget.initialFilters['endDate'];
    _selectedUser = widget.initialFilters['selectedUser'] ?? 'all';
    _minAmount = widget.initialFilters['minAmount'] ?? 0;
    _maxAmount = widget.initialFilters['maxAmount'] ?? 1000000;
    _selectedCity = widget.initialFilters['selectedCity'] ?? 'all';
    _selectedPaymentMethod = widget.initialFilters['selectedPaymentMethod'] ?? 'all';

    _searchController.text = _searchQuery;
    _minAmountController.text = _minAmount > 0 ? _minAmount.toString() : '';
    _maxAmountController.text = _maxAmount < 1000000 ? _maxAmount.toString() : '';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filters = {
      'searchQuery': _searchQuery,
      'selectedStatus': _selectedStatus,
      'selectedDateRange': _selectedDateRange,
      'startDate': _startDate,
      'endDate': _endDate,
      'selectedUser': _selectedUser,
      'minAmount': _minAmount,
      'maxAmount': _maxAmount,
      'selectedCity': _selectedCity,
      'selectedPaymentMethod': _selectedPaymentMethod,
    };

    widget.onFiltersChanged(filters);
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedStatus = 'all';
      _selectedDateRange = 'all';
      _startDate = null;
      _endDate = null;
      _selectedUser = 'all';
      _minAmount = 0;
      _maxAmount = 1000000;
      _selectedCity = 'all';
      _selectedPaymentMethod = 'all';
    });

    _searchController.clear();
    _minAmountController.clear();
    _maxAmountController.clear();

    _applyFilters();
  }

  void _toggleAdvancedFilters() {
    setState(() {
      _showAdvancedFilters = !_showAdvancedFilters;
    });

    if (_showAdvancedFilters) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 15),
          _buildBasicFilters(),
          if (_showAdvancedFilters) ...[const SizedBox(height: 15), _buildAdvancedFilters()],
          const SizedBox(height: 15),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.search, color: Color(0xFFffd700), size: 24),
        const SizedBox(width: 10),
        const Text(
          'البحث والفلترة المتقدمة',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(_showAdvancedFilters ? Icons.expand_less : Icons.expand_more, color: const Color(0xFFffd700)),
          onPressed: _toggleAdvancedFilters,
          tooltip: _showAdvancedFilters ? 'إخفاء الفلاتر المتقدمة' : 'إظهار الفلاتر المتقدمة',
        ),
      ],
    );
  }

  Widget _buildBasicFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 2, child: _buildSearchField()),
            const SizedBox(width: 15),
            Expanded(child: _buildStatusFilter()),
            const SizedBox(width: 15),
            Expanded(child: _buildDateRangeFilter()),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'البحث (رقم الطلب، اسم العميل، الهاتف...)',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFffd700), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFFffd700), size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _applyFilters();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildStatusFilter() {
    final statuses = [
      {'value': 'all', 'label': 'جميع الحالات'},
      {'value': 'pending', 'label': 'قيد الانتظار'},
      {'value': 'confirmed', 'label': 'مؤكد'},
      {'value': 'processing', 'label': 'قيد التحضير'},
      {'value': 'shipped', 'label': 'تم الشحن'},
      {'value': 'delivered', 'label': 'تم التسليم'},
      {'value': 'cancelled', 'label': 'ملغي'},
    ];

    return _buildDropdown(
      value: _selectedStatus,
      items: statuses,
      hint: 'حالة الطلب',
      onChanged: (value) {
        setState(() => _selectedStatus = value!);
        _applyFilters();
      },
    );
  }

  Widget _buildDateRangeFilter() {
    final dateRanges = [
      {'value': 'all', 'label': 'جميع التواريخ'},
      {'value': 'today', 'label': 'اليوم'},
      {'value': 'yesterday', 'label': 'أمس'},
      {'value': 'week', 'label': 'هذا الأسبوع'},
      {'value': 'month', 'label': 'هذا الشهر'},
      {'value': 'custom', 'label': 'تاريخ مخصص'},
    ];

    return _buildDropdown(
      value: _selectedDateRange,
      items: dateRanges,
      hint: 'فترة زمنية',
      onChanged: (value) {
        setState(() => _selectedDateRange = value!);
        if (value == 'custom') {
          _showDatePicker();
        } else {
          _applyFilters();
        }
      },
    );
  }

  Widget _buildAdvancedFilters() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'فلاتر متقدمة',
                style: TextStyle(color: Color(0xFFffd700), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildUserFilter()),
                  const SizedBox(width: 15),
                  Expanded(child: _buildCityFilter()),
                  const SizedBox(width: 15),
                  Expanded(child: _buildPaymentMethodFilter()),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildAmountRangeFilter()),
                  const SizedBox(width: 15),
                  Expanded(child: _buildCustomDateRange()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserFilter() {
    final users = [
      {'value': 'all', 'label': 'جميع المستخدمين'},
      {'value': 'admin', 'label': 'المدير'},
      {'value': 'employee1', 'label': 'موظف 1'},
      {'value': 'employee2', 'label': 'موظف 2'},
    ];

    return _buildDropdown(
      value: _selectedUser,
      items: users,
      hint: 'المستخدم',
      onChanged: (value) {
        setState(() => _selectedUser = value!);
        _applyFilters();
      },
    );
  }

  Widget _buildCityFilter() {
    final cities = [
      {'value': 'all', 'label': 'جميع المدن'},
      {'value': 'baghdad', 'label': 'بغداد'},
      {'value': 'basra', 'label': 'البصرة'},
      {'value': 'erbil', 'label': 'أربيل'},
      {'value': 'najaf', 'label': 'النجف'},
      {'value': 'karbala', 'label': 'كربلاء'},
    ];

    return _buildDropdown(
      value: _selectedCity,
      items: cities,
      hint: 'المدينة',
      onChanged: (value) {
        setState(() => _selectedCity = value!);
        _applyFilters();
      },
    );
  }

  Widget _buildPaymentMethodFilter() {
    final paymentMethods = [
      {'value': 'all', 'label': 'جميع طرق الدفع'},
      {'value': 'cash', 'label': 'نقداً'},
      {'value': 'card', 'label': 'بطاقة'},
      {'value': 'transfer', 'label': 'تحويل'},
      {'value': 'wallet', 'label': 'محفظة إلكترونية'},
    ];

    return _buildDropdown(
      value: _selectedPaymentMethod,
      items: paymentMethods,
      hint: 'طريقة الدفع',
      onChanged: (value) {
        setState(() => _selectedPaymentMethod = value!);
        _applyFilters();
      },
    );
  }

  Widget _buildAmountRangeFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نطاق المبلغ (د.ع)',
            style: TextStyle(color: Color(0xFFffd700), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minAmountController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'من',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: const Color(0xFFffd700).withValues(alpha: 0.3)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _minAmount = double.tryParse(value) ?? 0;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('-', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxAmountController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'إلى',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: const Color(0xFFffd700).withValues(alpha: 0.3)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _maxAmount = double.tryParse(value) ?? 1000000;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDateRange() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تاريخ مخصص',
            style: TextStyle(color: Color(0xFFffd700), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'من تاريخ',
                      style: TextStyle(
                        color: _startDate != null ? Colors.white : Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('-', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'إلى تاريخ',
                      style: TextStyle(
                        color: _endDate != null ? Colors.white : Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _applyFilters,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('تطبيق الفلاتر'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: const Color(0xFF1a1a2e),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('مسح الفلاتر'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFffd700),
              side: const BorderSide(color: Color(0xFFffd700)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<Map<String, String>> items,
    required String hint,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 12),
        dropdownColor: const Color(0xFF1a1a2e),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFffd700)),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item['value'],
            child: Text(item['label']!, style: const TextStyle(color: Colors.white, fontSize: 12)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
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
      _applyFilters();
    }
  }

  Future<void> _showDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
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
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFilters();
    }
  }
}
