import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../providers/edit_order_provider.dart';
import 'styled_selector_field.dart';

class LocationSection extends StatelessWidget {
  final VoidCallback onTapProvince;
  final VoidCallback onTapCity;

  const LocationSection({super.key, required this.onTapProvince, required this.onTapCity});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EditOrderProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StyledSelectorField(
          label: 'المحافظة',
          value: provider.selectedProvince,
          icon: FontAwesomeIcons.mapLocationDot,
          onTap: onTapProvince,
        ),
        const SizedBox(height: 20),
        StyledSelectorField(
          label: 'المدينة',
          value: provider.selectedCity,
          icon: FontAwesomeIcons.city,
          onTap: provider.selectedProvince == null
              ? () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('الرجاء اختيار المحافظة أولاً')));
                }
              : onTapCity,
        ),
      ],
    );
  }
}
