import 'package:flutter/material.dart';

import 'package:genie/core/theme/app_colors.dart';

/// Small heading above a [SettingsSection].
class SettingsSectionTitle extends StatelessWidget {
  final String title;

  const SettingsSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.colors.textMuted,
        ),
      ),
    );
  }
}

/// Rounded card holding a group of [SettingsRow]s, with a hairline between them.
class SettingsSection extends StatelessWidget {
  final List<Widget> children;

  const SettingsSection({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      // Clips the ink of the first and last row to the rounded corners.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (final (index, child) in children.indexed) ...[
              if (index > 0)
                Divider(height: 1, indent: 52, color: colors.divider),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// One settings row: icon, title, an optional current value, and a chevron
/// when tapping it leads somewhere.
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;

  /// The current setting, shown on the right (e.g. "English").
  final String? value;

  /// Null for a row that only shows information.
  final VoidCallback? onTap;

  /// Paints the row in the danger colour: it removes or resets something.
  final bool isDestructive;

  /// Paints the row in the accent colour and drops the chevron: it acts at
  /// once instead of opening a screen.
  final bool isAction;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.isDestructive = false,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final emphasis = isDestructive
        ? colors.danger
        : (isAction ? colors.accent : null);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: emphasis ?? colors.textMuted),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: emphasis ?? colors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            // The value gives way to the title: it shrinks and ends in "…".
            Expanded(
              child: Text(
                value ?? '',
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: colors.textMuted),
              ),
            ),
            if (onTap != null && !isAction) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: colors.iconSubtle),
            ],
          ],
        ),
      ),
    );
  }
}

/// A settings row with an on/off switch, and a line saying what it does.
class SettingsSwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;

  /// Null disables the switch, e.g. while a change is being saved.
  final ValueChanged<bool>? onChanged;

  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = this.subtitle;
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: colors.textMuted),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: colors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              Switch.adaptive(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
