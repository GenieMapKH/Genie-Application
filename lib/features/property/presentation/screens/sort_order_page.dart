import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/property/presentation/view_models/saved_properties_provider.dart';

/// Full screen / sub-page allowing users to select the sort order for saved properties.
/// Matches Screenshot 3.
class SortOrderPage extends ConsumerWidget {
  const SortOrderPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const SortOrderPage(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOption = ref.watch(savedSortOptionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Sort Order',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: SortOption.values.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
          itemBuilder: (context, index) {
            final option = SortOption.values[index];
            final isSelected = option == currentOption;

            return InkWell(
              onTap: () {
                ref.read(savedSortOptionProvider.notifier).state = option;
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.label,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        color: Color(0xFF5B5FEF),
                        size: 22,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
