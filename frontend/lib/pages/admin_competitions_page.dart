import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/competition.dart';
import '../providers/competitions_provider.dart';
import '../models/product.dart';
import '../config/api_config.dart';

class AdminCompetitionsPage extends StatefulWidget {
  const AdminCompetitionsPage({super.key});

  @override
  State<AdminCompetitionsPage> createState() => _AdminCompetitionsPageState();
}

class _AdminCompetitionsPageState extends State<AdminCompetitionsPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _prizeCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _completedCtrl = TextEditingController();

  DateTime? _startAt;
  DateTime? _endAt;

  @override
  void initState() {
    super.initState();
    // تحميل قائمة المسابقات (وضع إداري)
    final provider = context.read<CompetitionsProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.loadAdmin();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _productCtrl.dispose();
    _prizeCtrl.dispose();
    _targetCtrl.dispose();
    _completedCtrl.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _fmtDate(DateTime? d) => d == null ? '' : '${d.year}-${_two(d.month)}-${_two(d.day)}';

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _startAt ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'اختر تاريخ البداية',
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _startAt = DateTime(picked.year, picked.month, picked.day);
        _startCtrl.text = _fmtDate(_startAt);
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final initial = _endAt ?? _startAt ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'اختر تاريخ النهاية',
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        // اضبط النهاية لنهاية اليوم حتى تكون "إلى" شاملة لليوم المختار
        _endAt = DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999);
        _endCtrl.text = _fmtDate(_endAt);
      });
    }
  }

  void _openForm(BuildContext context, [Competition? existing]) {
    final isEdit = existing != null;
    _nameCtrl.text = existing?.name ?? '';
    _startAt = existing?.startsAt;
    _endAt = existing?.endsAt;
    _startCtrl.text = _fmtDate(_startAt);
    _endCtrl.text = _fmtDate(_endAt);
    _productCtrl.text = existing?.product ?? '';
    _prizeCtrl.text = existing?.prize ?? '';
    _targetCtrl.text = existing?.target.toString() ?? '';
    _completedCtrl.text = existing?.completed.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, left: 16, right: 16, top: 16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'تعديل مسابقة' : 'إضافة مسابقة',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _nameCtrl,
                    'عنوان المسابقة',
                    icon: Icons.title,
                    validator: (v) => v!.trim().isEmpty ? 'أدخل العنوان' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startCtrl,
                          readOnly: true,
                          onTap: _pickStartDate,
                          validator: (v) => v!.trim().isEmpty ? 'اختر تاريخ البداية' : null,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            labelText: 'تاريخ البداية',
                            prefixIcon: Icon(Icons.event),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _endCtrl,
                          readOnly: true,
                          onTap: _pickEndDate,
                          validator: (v) => v!.trim().isEmpty ? 'اختر تاريخ النهاية' : null,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            labelText: 'تاريخ النهاية',
                            prefixIcon: Icon(Icons.event),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _field(_prizeCtrl, 'الجائزة (مثال: 100,000 د.ع)', icon: Icons.card_giftcard),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _field(_targetCtrl, 'هدف الطلبات', icon: Icons.flag, keyboardType: TextInputType.number),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _field(
                          _completedCtrl,
                          'المنجز',
                          icon: Icons.check_circle,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _productCtrl,
                    readOnly: true,
                    onTap: _openProductPickerAndSet,
                    validator: (v) => v!.trim().isEmpty ? 'اختر المنتج' : null,
                    decoration: const InputDecoration(
                      labelText: 'اختيار المنتج',
                      prefixIcon: Icon(Icons.inventory_2),
                      suffixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: Text(isEdit ? 'حفظ التعديلات' : 'إضافة'),
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final target = int.tryParse(_targetCtrl.text.trim()) ?? 0;
                        final completed = int.tryParse(_completedCtrl.text.trim()) ?? 0;
                        final provider = context.read<CompetitionsProvider>();
                        if (isEdit) {
                          final updated = Competition(
                            id: existing.id,
                            name: _nameCtrl.text.trim(),
                            startsAt: _startAt,
                            endsAt: _endAt,
                            product: _productCtrl.text.trim(),
                            completed: completed,
                            target: target,
                            prize: _prizeCtrl.text.trim(),
                          );
                          await provider.updateCompetition(updated);
                        } else {
                          await provider.addCompetition(
                            Competition.create(
                              name: _nameCtrl.text.trim(),
                              startsAt: _startAt,
                              endsAt: _endAt,
                              product: _productCtrl.text.trim(),
                              completed: completed,
                              target: target,
                              prize: _prizeCtrl.text.trim(),
                            ),
                          );
                        }
                        if (mounted) Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _openProductPickerAndSet() async {
    final selected = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => const _ProductPickerSheet(),
    );
    if (!mounted) return;
    if (selected != null) {
      setState(() {
        _productCtrl.text = selected.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFffd700)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('إدارة المسابقات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('إضافة مسابقة'),
                onPressed: () => _openForm(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Consumer<CompetitionsProvider>(
              builder: (context, provider, _) {
                final items = provider.competitions;
                if (!provider.isLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (items.isEmpty) {
                  return const Center(child: Text('لا توجد مسابقات بعد'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = items[index];
                    return ListTile(
                      leading: const Icon(Icons.emoji_events, color: Color(0xFFffd700)),
                      title: Text(c.name, textAlign: TextAlign.right),
                      subtitle: Text(
                        'الجائزة: ${c.prize} • الهدف: ${c.target} طلب • المنجز: ${c.completed} • المنتج: ${c.product}',
                        textAlign: TextAlign.right,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => _openForm(context, c),
                            tooltip: 'تعديل',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'حذف',
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('تأكيد الحذف'),
                                  content: Text('هل تريد حذف المسابقة "${c.name}"؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),

                                      child: const Text('إلغاء'),
                                    ),
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('حذف')),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                final provider = context.read<CompetitionsProvider>();
                                await provider.deleteCompetition(c.id);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet({super.key});
  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();
  final int _limit = 20;
  final List<Product> _items = [];
  List<Product> _filtered = [];
  bool _loading = true;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 && !_loading && _hasMore) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(ApiConfig.productsUrl).replace(queryParameters: {'page': '$_page', 'limit': '$_limit'});
      final res = await http.get(uri, headers: ApiConfig.defaultHeaders).timeout(ApiConfig.defaultTimeout);
      final body = json.decode(res.body);
      final List raw = (body['data']?['products'] as List?) ?? [];
      final bool more = (body['data']?['pagination']?['hasMore'] == true) || raw.length >= _limit;
      final newItems = raw.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).cast<Product>().toList();
      _items.addAll(newItems);
      _page++;
      _hasMore = more;
      _applyFilter();
    } catch (_) {
      // تجاهل الأخطاء هنا
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    _filtered = q.isEmpty ? List<Product>.from(_items) : _items.where((p) => p.name.toLowerCase().contains(q)).toList();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: 'ابحث عن منتج',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: _loading && _items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      controller: _scroll,
                      itemCount: _filtered.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        if (i < _filtered.length) {
                          final p = _filtered[i];
                          String? img;
                          if (p.images.isNotEmpty) img = p.images.first;
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: (img != null && img.isNotEmpty)
                                  ? Image.network(img, width: 48, height: 48, fit: BoxFit.cover)
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.inventory_2),
                                    ),
                            ),
                            title: Text(p.name, textAlign: TextAlign.right),
                            onTap: () => Navigator.of(context).pop<Product>(p),
                          );
                        }
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
