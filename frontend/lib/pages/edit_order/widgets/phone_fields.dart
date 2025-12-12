import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'styled_text_field.dart';

class PhoneFields extends StatelessWidget {
  final TextEditingController primaryPhoneController;
  final TextEditingController secondaryPhoneController;

  const PhoneFields({super.key, required this.primaryPhoneController, required this.secondaryPhoneController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StyledTextField(
          controller: primaryPhoneController,
          label: 'رقم الهاتف الأساسي',
          icon: FontAwesomeIcons.phone,
          isRequired: true,
          keyboardType: TextInputType.phone,
          maxLength: 11,
        ),
        const SizedBox(height: 20),
        StyledTextField(
          controller: secondaryPhoneController,
          label: 'رقم الهاتف الثانوي (اختياري)',
          icon: FontAwesomeIcons.mobile,
          keyboardType: TextInputType.phone,
          maxLength: 11,
        ),
      ],
    );
  }
}
