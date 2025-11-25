import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/competition.dart';
import '../providers/competitions_provider.dart';

class AdminCompetitionsPage extends StatefulWidget {
  const AdminCompetitionsPage({super.key});

  @override
  State<AdminCompetitionsPage> createState() => _AdminCompetitionsPageState();
}

class _AdminCompetitionsPageState extends State<AdminCompetitionsPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _prizeCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _completedCtrl = TextEditingController();

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
    _descCtrl.dispose();
    _productCtrl.dispose();
    _prizeCtrl.dispose();
    _targetCtrl.dispose();
    _completedCtrl.dispose();
    super.dispose();
  }

  void _openForm(BuildContext context, [Competition? existing]) {
    final isEdit = existing != null;
    _nameCtrl.text = existing?.name ?? '';
    _descCtrl.text = existing?.description ?? '';
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
                  _field(_descCtrl, 'التفاصيل', icon: Icons.notes, maxLines: 3),
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
                  _field(_productCtrl, 'اسم المنتج', icon: Icons.inventory_2),
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
                            description: _descCtrl.text.trim(),
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
                              description: _descCtrl.text.trim(),
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
