import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'admin_records_page.dart';

class AdminMetricCard extends StatelessWidget {
  final String section;
  final double width;
  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final Color color;
  const AdminMetricCard({
    super.key,
    required this.section,
    required this.width,
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.w600,
    );
    final hintStyle = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final textScaler = MediaQuery.textScalerOf(context);
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openAdminRecords(context, section, label),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, size: 19, color: color),
                    ),
                    const SizedBox(width: 8),
                    const Spacer(),
                    Icon(LucideIcons.arrowUpRight, size: 17, color: color),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height:
                      textScaler.scale(labelStyle.fontSize!) *
                      (labelStyle.height ?? 1.4) *
                      2,
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height:
                      textScaler.scale(hintStyle.fontSize!) *
                      (hintStyle.height ?? 1.4) *
                      2,
                  child: Text(
                    hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: hintStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
