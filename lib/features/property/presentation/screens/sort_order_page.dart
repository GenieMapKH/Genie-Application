import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/shared/widgets/layout/app_header_bar.dart';
import 'package:tilomnov/features/property/presentation/view_models/saved_properties_provider.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/features/property/presentation/property_labels.dart';

/// Full screen / sub-page allowing users to select the sort order for saved properties.
/// Matches Screenshot 3.
class SortOrderPage extends ConsumerWidget {
  const SortOrderPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SortOrderPage());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOption = ref.watch(savedSortOptionProvider);

    return Scaffold(
      backgroundColor: context.colors.surfaceMuted,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: context.l10n.propertySortOrder,
              backgroundColor: context.colors.surfaceMuted,
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: SortOption.values.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: context.colors.divider),
                itemBuilder: (context, index) {
                  final option = SortOption.values[index];
                  final isSelected = option == currentOption;

                  return InkWell(
                    onTap: () {
                      ref.read(savedSortOptionProvider.notifier).state = option;
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              sortOptionLabel(context.l10n, option),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: context.colors.accent,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
