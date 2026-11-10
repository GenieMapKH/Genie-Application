import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';

/// A titled card of label–value rows: "Billing Summary", "Property
/// information". The last row may be [emphasizeLast] (a total).
class SummaryTable extends StatelessWidget {
  final String title;
  final List<(String label, String value)> rows;
  final bool emphasizeLast;

  const SummaryTable({
    super.key,
    required this.title,
    required this.rows,
    this.emphasizeLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              for (final (index, (label, value)) in rows.indexed) ...[
                if (index > 0) Divider(height: 1, color: colors.border),
                _SummaryRow(
                  label: label,
                  value: value,
                  emphasized: emphasizeLast && index == rows.length - 1,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.emphasized,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final weight = emphasized ? FontWeight.w700 : FontWeight.w500;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: weight,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: emphasized ? 16 : 14,
                fontWeight: weight,
                color: emphasized ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
