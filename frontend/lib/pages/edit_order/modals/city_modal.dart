import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../providers/edit_order_provider.dart';
import '../../../models/city.dart';
import '../widgets/styled_modal_content.dart';

class CityModal extends StatefulWidget {
  const CityModal({super.key});

  @override
  State<CityModal> createState() => _CityModalState();
}

class _CityModalState extends State<CityModal> {
  late TextEditingController _searchController;
  List<City> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    final provider = Provider.of<EditOrderProvider>(context, listen: false);
    _filteredItems = provider.cities;
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
        _filteredItems = provider.cities;
      } else {
        _filteredItems = provider.cities.where((c) => c.name.contains(query)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EditOrderProvider>(context);

    // Auto-update if provider cities change (e.g. province selection change)
    // This logic in build ensures we don't show stale previous city list if province changed while modal open?
    // Modal usually closes on selection.
    // But if we want to be safe:
    if (_searchController.text.isEmpty && _filteredItems.length != provider.cities.length) {
      _filteredItems = provider.cities;
    }

    return StyledModalContent<City>(
      title: 'اختر المدينة',
      icon: FontAwesomeIcons.city,
      searchController: _searchController,
      onSearchChanged: _filter,
      items: _filteredItems,
      itemLabelBuilder: (item) => item.name,
      onSelected: (item) {
        provider.selectCity(item);
        Navigator.pop(context);
      },
      selectedItemName: provider.selectedCity,
    );
  }
}
