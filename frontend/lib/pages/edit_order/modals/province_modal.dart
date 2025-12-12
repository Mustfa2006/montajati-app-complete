import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../providers/edit_order_provider.dart';
import '../../../models/province.dart';
import '../widgets/styled_modal_content.dart';

class ProvinceModal extends StatefulWidget {
  const ProvinceModal({super.key});

  @override
  State<ProvinceModal> createState() => _ProvinceModalState();
}

class _ProvinceModalState extends State<ProvinceModal> {
  late TextEditingController _searchController;
  List<Province> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Initial list
    final provider = Provider.of<EditOrderProvider>(context, listen: false);
    _filteredItems = provider.provinces;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final provider = Provider.of<EditOrderProvider>(context, listen: false);
    setState(() {
      if (query.isEmpty) {
        _filteredItems = provider.provinces;
      } else {
        _filteredItems = provider.provinces.where((p) => p.name.contains(query)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EditOrderProvider>(context);

    return StyledModalContent<Province>(
      title: 'اختر المحافظة',
      icon: FontAwesomeIcons.locationDot,
      searchController: _searchController,
      onSearchChanged: _filter,
      // If provider updates provinces (e.g. reload), we should probably respect that?
      // For now, using local filtered list initiated from provider.
      // If provider.provinces changes, this might be stale unless we update in build or didChangeDependencies.
      // Let's use filtered list but ensure it works.
      // Ideally we shouldn't cache provider list in state if it's dynamic.
      // But for edit page, it's loaded once.
      // Better: Use `provider.provinces` in build to re-filter?
      items: _filteredItems,
      itemLabelBuilder: (item) => item.name,
      onSelected: (item) {
        provider.selectProvince(item);
        Navigator.pop(context);
      },
      selectedItemName: provider.selectedProvince,
    );
  }
}
