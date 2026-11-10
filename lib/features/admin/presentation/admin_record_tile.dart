import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tilomnov/features/admin/data/admin_record.dart';
import 'admin_record_icon.dart';
import 'admin_account_actions.dart';

class AdminRecordTile extends StatelessWidget {
  final AdminRecord record;
  const AdminRecordTile({super.key, required this.record});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      key: PageStorageKey(record.id),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: const Border(),
      collapsedShape: const Border(),
      leading: AdminRecordIcon(record: record),
      title: Text(
        record.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record.subtitle.isNotEmpty)
              Text(
                record.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (record.values.containsKey('username'))
              _AccountBadges(values: record.values),
          ],
        ),
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        if (record.values.containsKey('username') &&
            record.values['role'] == 'user')
          Align(
            alignment: Alignment.centerRight,
            child: AdminAccountActions(userId: record.id),
          ),
        for (final field in _fields(record.values))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 12),
                  child: Icon(
                    field.$3,
                    size: 19,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.$1,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 3),
                      // Keep text scroll offsets separate from the tile's saved expansion state.
                      SelectableText(field.$2, key: PageStorageKey(field.$1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  static Iterable<(String, String, IconData)> _fields(
    Map<String, dynamic> values, [
    String prefix = '',
  ]) sync* {
    for (final entry in values.entries) {
      if (entry.value == null || entry.key == 'avatarUrl') continue;
      final key = entry.key.replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (m) => '${m[1]} ${m[2]}',
      );
      final label = '$prefix${key[0].toUpperCase()}${key.substring(1)}';
      if (entry.value is Map<String, dynamic>) {
        yield* _fields(entry.value as Map<String, dynamic>, '$label · ');
      } else {
        final value = entry.value;
        final date =
            value is String && RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(value)
            ? DateTime.tryParse(value)
            : null;
        yield (
          label,
          date != null
              ? DateFormat.yMMMd().add_jm().format(date.toLocal())
              : value is bool
              ? (value ? 'Yes' : 'No')
              : value.toString(),
          _fieldIcon(entry.key),
        );
      }
    }
  }

  static IconData _fieldIcon(String key) => switch (key) {
    'email' => Icons.mail_outline_rounded,
    'phone' || 'contactPhone' => Icons.phone_outlined,
    'emailVerified' || 'phoneVerified' => Icons.verified_user_outlined,
    'username' => Icons.alternate_email_rounded,
    'name' || 'firstName' || 'lastName' => Icons.person_outline_rounded,
    'role' => Icons.badge_outlined,
    'createdAt' || 'publishedAt' => Icons.calendar_today_outlined,
    'lastSeenAt' || 'updatedAt' => Icons.history_rounded,
    'deactivatedAt' || 'cancelledAt' => Icons.person_off_outlined,
    'tier' || 'subscriptionTier' => Icons.workspace_premium_outlined,
    'amount' || 'price' || 'currency' => Icons.payments_outlined,
    'status' => Icons.info_outline_rounded,
    'reason' || 'details' => Icons.flag_outlined,
    'id' ||
    'userId' ||
    'propertyId' ||
    'transactionId' => Icons.fingerprint_rounded,
    _ => Icons.notes_rounded,
  };
}

class _AccountBadges extends StatelessWidget {
  final Map<String, dynamic> values;
  const _AccountBadges({required this.values});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final badges = [
      if (values['bannedAt'] != null)
        (Icons.block_rounded, 'Banned')
      else if (values.containsKey('deactivatedAt'))
        values['deactivatedAt'] == null
            ? (Icons.check_circle_outline_rounded, 'Active account')
            : (Icons.person_off_outlined, 'Deactivated'),
      if (values['emailVerified'] == true)
        (Icons.mark_email_read_outlined, 'Email verified'),
      if (values['phoneVerified'] == true)
        (Icons.verified_user_outlined, 'Phone verified'),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (icon, label) in badges)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: colors.onSecondaryContainer),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
