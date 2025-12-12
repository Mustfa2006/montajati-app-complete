import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../providers/theme_provider.dart';

class StyledModalContent<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final List<T> items;
  final Function(T) onSelected;
  final String Function(T) itemLabelBuilder;
  final String? selectedItemName;

  const StyledModalContent({
    super.key,
    required this.title,
    required this.icon,
    required this.searchController,
    required this.onSearchChanged,
    required this.items,
    required this.onSelected,
    required this.itemLabelBuilder,
    this.selectedItemName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header & Search
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFffd700).withValues(alpha: isDark ? 0.1 : 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: const Color(0xFFffd700), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Field
                TextField(
                  controller: searchController,
                  onChanged: (val) => onSearchChanged(val),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث...',
                    hintStyle: GoogleFonts.cairo(
                      fontSize: 14,
                      color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.6),
                    ),
                    prefixIcon: Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.7) : Colors.grey,
                      size: 16,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFFffd700).withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFFffd700).withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFffd700), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final label = itemLabelBuilder(item);
                final isSelected = label == selectedItemName;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFFffd700).withValues(alpha: 0.2),
                                    const Color(0xFFffd700).withValues(alpha: 0.1),
                                  ]
                                : [
                                    const Color(0xFFffd700).withValues(alpha: 0.15),
                                    const Color(0xFFffd700).withValues(alpha: 0.05),
                                  ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFffd700)
                          : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1)),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFffd700).withValues(alpha: 0.2)
                            : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected
                            ? FontAwesomeIcons.circleCheck
                            : (title.contains('المدينة') ? FontAwesomeIcons.city : FontAwesomeIcons.mapLocationDot),
                        color: isSelected ? const Color(0xFFffd700) : (isDark ? Colors.white54 : Colors.grey),
                        size: 16,
                      ),
                    ),
                    title: Text(
                      label,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? const Color(0xFFffd700) : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(FontAwesomeIcons.check, color: Color(0xFFffd700), size: 16)
                        : null,
                    onTap: () => onSelected(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
