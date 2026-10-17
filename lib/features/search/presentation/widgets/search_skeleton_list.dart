import 'package:flutter/material.dart';

import 'package:genie/core/theme/app_colors.dart';

/// Grey placeholder rows shown while the first answer loads, shaped like the
/// rows that will replace them, so the layout does not jump.
class SearchSkeletonList extends StatelessWidget {
  final int rows;
  final double gutter;

  const SearchSkeletonList({super.key, this.rows = 4, this.gutter = 16});

  @override
  Widget build(BuildContext context) {
    final fill = context.colors.divider;

    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (_) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(90, 14),
                    const SizedBox(height: 8),
                    bar(double.infinity, 12),
                    const SizedBox(height: 6),
                    bar(140, 10),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
