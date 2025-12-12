import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../providers/edit_order_provider.dart';
import '../../../providers/theme_provider.dart';
import 'styled_selector_field.dart';
import 'styled_text_field.dart'; // We can't reuse StyledTextField easily if it's strictly a TextField wrapper.
// But we can implement a similar look or genericize StyledTextField?
// Actually, `_buildStyledSelectorField` was used before.
// I should extract `StyledSelectorField` as a shared widget too?
// The user didn't explicitly ask for `StyledSelectorField` but `LocationSection`.
// I'll implement the look inside `ScheduleField` or make a `StyledSelectorField` widget.
// Providing `StyledSelectorField` is better for consistency between Location and Schedule.
// I'll create `styled_selector_field.dart` first? Or inline it.
// I'll inline it inside `ScheduleField` and `LocationSection` uses it?
// No, duplicating is bad.
// I'll create `styled_selector_field.dart`.

class ScheduleField extends StatelessWidget {
  const ScheduleField({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditOrderProvider>(
      builder: (context, provider, child) {
        if (!provider.isScheduled) return const SizedBox.shrink();

        final date = provider.selectedScheduledDate;
        final value = date != null ? '${date.day}/${date.month}/${date.year}' : null;

        return StyledSelectorField(
          label: 'تاريخ الجدولة',
          value: value,
          icon: FontAwesomeIcons.calendarDay,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
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
              provider.selectDate(picked);
            }
          },
        );
      },
    );
  }
}
