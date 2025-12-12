import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'styled_text_field.dart';

class NotesField extends StatelessWidget {
  final TextEditingController controller;

  const NotesField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StyledTextField(
      controller: controller,
      label: 'ملاحظات (اختياري)',
      icon: FontAwesomeIcons.noteSticky,
      maxLines: 3,
      showIcon: false,
      isRequired: false,
    );
  }
}
