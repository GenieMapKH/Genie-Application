import 'package:flutter/material.dart';
import '../data/admin_record.dart';
import '../../subscription/domain/plan_tier.dart';
import '../../subscription/presentation/plan_tier_style.dart';
import 'package:tilomnov/shared/widgets/media/user_avatar.dart';

class AdminRecordIcon extends StatelessWidget {
  final AdminRecord record;
  const AdminRecordIcon({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final values = record.values;
    if (values.containsKey('username')) {
      return UserAvatar(
        name: (values['name'] ?? values['username'] ?? '').toString(),
        avatarUrl: values['avatarUrl'] as String?,
        radius: 24,
      );
    }
    final tier = PlanTier.fromApi(values['subscriptionTier'] ?? values['tier']);
    final subscription =
        values['purpose'] == 'SUBSCRIPTION' || values['tier'] != null;
    final icon = subscription
        ? (tier.isPaid
              ? PlanTierStyle.of(tier).icon
              : Icons.workspace_premium_outlined)
        : values['purpose'] == 'LISTING_PUBLISH'
        ? Icons.post_add_rounded
        : values.containsKey('amount')
        ? Icons.receipt_long_outlined
        : values.containsKey('reason')
        ? Icons.flag_outlined
        : Icons.home_work_outlined;
    final colors = Theme.of(context).colorScheme;
    final color = subscription ? tier.accentOn(context) : colors.primary;
    return Tooltip(
      message: record.title,
      child: CircleAvatar(
        radius: 24,
        backgroundColor: color.withValues(alpha: .12),
        child: Icon(icon, color: color),
      ),
    );
  }
}
