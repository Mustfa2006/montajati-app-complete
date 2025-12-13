import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/edit_order_provider.dart';
import '../../providers/theme_provider.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/location_repository.dart';
import '../../models/update_order_request.dart';
import 'edit_order/widgets/edit_order_header.dart';
import 'edit_order/widgets/loading_state.dart';
import 'edit_order/widgets/error_state.dart';
import 'edit_order/widgets/customer_name_field.dart';
import 'edit_order/widgets/phone_fields.dart';
import 'edit_order/widgets/location_section.dart';
import 'edit_order/widgets/notes_field.dart';
import 'edit_order/widgets/schedule_field.dart';
import 'edit_order/widgets/save_button.dart';
import 'edit_order/modals/province_modal.dart';
import 'edit_order/modals/city_modal.dart';
import '../widgets/app_background.dart';

class EditOrderPage extends StatelessWidget {
  final String orderId;
  final bool isScheduled;

  const EditOrderPage({super.key, required this.orderId, required this.isScheduled});

  @override
  Widget build(BuildContext context) {
    // Inject Dependencies directly here (Pragmatic approach)
    final orderRepo = OrderRepositoryImpl();
    final locationRepo = LocationRepositoryImpl();

    return ChangeNotifierProvider(
      create: (_) =>
          EditOrderProvider(orderRepository: orderRepo, locationRepository: locationRepo)..init(orderId, isScheduled),
      child: const _EditOrderView(),
    );
  }
}

class _EditOrderView extends StatefulWidget {
  const _EditOrderView();

  @override
  State<_EditOrderView> createState() => _EditOrderViewState();
}

class _EditOrderViewState extends State<_EditOrderView> {
  // Local UI State (Controllers)
  late TextEditingController _customerNameController;
  late TextEditingController _primaryPhoneController;
  late TextEditingController _secondaryPhoneController;
  late TextEditingController _notesController;

  bool _formPopulated = false;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController();
    _primaryPhoneController = TextEditingController();
    _secondaryPhoneController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _primaryPhoneController.dispose();
    _secondaryPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateForm(EditOrderProvider provider) {
    if (_formPopulated || provider.order == null) return;

    final order = provider.order!;
    _customerNameController.text = order.customer.name;
    _primaryPhoneController.text = order.customer.phone;
    _secondaryPhoneController.text = order.customer.alternatePhone ?? '';
    _notesController.text = order.notes ?? '';

    _formPopulated = true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditOrderProvider>(
      builder: (context, provider, child) {
        // One-time population when data ready
        if (provider.order != null && !_formPopulated) {
          // Delay to avoid build conflicts safely
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _populateForm(provider);
          });
        }

        return AppBackground(child: SafeArea(child: _buildBody(context, provider)));
      },
    );
  }

  Widget _buildBody(BuildContext context, EditOrderProvider provider) {
    if (provider.isLoadingOrder) {
      return const LoadingState();
    }

    if (provider.failure != null) {
      return const ErrorState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const EditOrderHeader(),
          const SizedBox(height: 20),

          CustomerNameField(controller: _customerNameController),
          const SizedBox(height: 20),

          PhoneFields(
            primaryPhoneController: _primaryPhoneController,
            secondaryPhoneController: _secondaryPhoneController,
          ),
          const SizedBox(height: 20),

          LocationSection(onTapProvince: () => _showProvinceModal(context), onTapCity: () => _showCityModal(context)),
          const SizedBox(height: 20),

          NotesField(controller: _notesController),

          if (provider.isScheduled) ...[const SizedBox(height: 20), const ScheduleField()],

          const SizedBox(height: 30),
          SaveButton(onPressed: () => _onSave(context, provider)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _onSave(BuildContext context, EditOrderProvider provider) async {
    // 1. Local Validation
    if (_customerNameController.text.trim().isEmpty || _primaryPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى ملء الحقول المطلوبة'), backgroundColor: Colors.red));
      return;
    }

    if (provider.selectedProvince == null || provider.selectedCity == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار الموقع'), backgroundColor: Colors.red));
      return;
    }

    // 2. Prepare DTO
    final request = UpdateOrderRequest(
      orderId: provider.order!.id,
      customerName: _customerNameController.text.trim(),
      primaryPhone: _primaryPhoneController.text.trim(),
      secondaryPhone: _secondaryPhoneController.text.trim().isEmpty ? null : _secondaryPhoneController.text.trim(),
      province: provider.selectedProvince!,
      city: provider.selectedCity!,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isScheduled: provider.isScheduled,
      scheduledDate: provider.selectedScheduledDate,
    );

    // 3. Call Provider
    final success = await provider.saveOrder(request);

    // 4. Handle Result
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ التغييرات بنجاح'), backgroundColor: Colors.green));
        GoRouter.of(context).go('/orders');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(provider.failure?.message ?? 'فشل الحفظ'), backgroundColor: Colors.red));
      }
    }
  }

  void _showProvinceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: Provider.of<EditOrderProvider>(context, listen: false),
        child: const ProvinceModal(),
      ),
    );
  }

  void _showCityModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: Provider.of<EditOrderProvider>(context, listen: false),
        child: const CityModal(),
      ),
    );
  }
}
