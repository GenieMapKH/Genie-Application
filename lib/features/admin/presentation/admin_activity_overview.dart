import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';
import '../data/admin_dashboard_repository.dart';
import 'admin_metric_card.dart';

class AdminActivityOverview extends StatelessWidget {
  final AdminDashboardData data;
  final bool accounts;
  const AdminActivityOverview({
    super.key,
    required this.data,
    required this.accounts,
  });

  static String _number(int value) =>
      NumberFormat.decimalPattern().format(value);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 920
          ? 4
          : constraints.maxWidth >= 560
          ? 3
          : 2;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (accounts) ...[
            Text(
              'Accounts',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Your community at a glance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AdminMetricCard(
                  width: width,
                  label: 'Active users',
                  section: 'active-users',
                  value: _number(data.activeUsers),
                  hint: 'Accounts not deactivated',
                  icon: LucideIcons.usersRound,
                  color: const Color(0xFF2563EB),
                ),
                AdminMetricCard(
                  width: width,
                  label: 'All users',
                  section: 'all-users',
                  value: _number(data.totalUsers),
                  hint: '${_number(data.activeUsers)} active',
                  icon: LucideIcons.usersRound,
                  color: const Color(0xFF0F766E),
                ),
                AdminMetricCard(
                  width: width,
                  label: 'New users',
                  section: 'new-users',
                  value: _number(data.newUsers7d),
                  hint: 'Last 7 days',
                  icon: LucideIcons.userRoundPlus,
                  color: const Color(0xFF2563EB),
                ),
                AdminMetricCard(
                  width: width,
                  label: 'Subscriptions',
                  section: 'subscriptions',
                  value: _number(data.activeSubscriptions),
                  hint: 'Currently active',
                  icon: LucideIcons.award,
                  color: const Color(0xFF9333EA),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Activities',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Listings, leads and reports',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AdminMetricCard(
                  width: width,
                  label: 'Active listings',
                  section: 'active-listings',
                  value: _number(data.activeListings),
                  hint: '${_number(data.newListings7d)} new this week',
                  icon: LucideIcons.building2,
                  color: const Color(0xFF059669),
                ),
                AdminMetricCard(
                  width: width,
                  label: 'All listings',
                  section: 'all-listings',
                  value: _number(data.totalListings),
                  hint: 'Including drafts',
                  icon: LucideIcons.package,
                  color: const Color(0xFFB45309),
                ),
                AdminMetricCard(
                  width: width,
                  label: 'New listings',
                  section: 'new-listings',
                  value: _number(data.newListings7d),
                  hint: 'Last 7 days',
                  icon: LucideIcons.housePlus,
                  color: const Color(0xFF059669),
                ),
                AdminMetricCard(
                  width: width,
                  label: 'Listing leads',
                  section: 'leads',
                  value: _number(data.leads7d),
                  hint: 'Last 7 days',
                  icon: LucideIcons.trendingUp,
                  color: const Color(0xFF7C3AED),
                ),
                AdminMetricCard(
                  width: width,
                  label: 'Open reports',
                  section: 'reports',
                  value: _number(data.openReports),
                  hint: 'Needs review',
                  icon: LucideIcons.flag,
                  color: const Color(0xFFDC2626),
                ),
              ],
            ),
          ],
        ],
      );
    },
  );
}
