import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'styled_text_field.dart';

class CustomerNameField extends StatelessWidget {
  final TextEditingController controller;

  const CustomerNameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StyledTextField(controller: controller, label: 'اسم العميل', icon: FontAwesomeIcons.user, isRequired: true);
  }
}
