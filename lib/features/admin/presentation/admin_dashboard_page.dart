import 'admin_advertisements_page.dart';
import 'admin_records_page.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tilomnov/features/admin/presentation/admin_dashboard_provider.dart';
import 'admin_activity_overview.dart';
import 'admin_rotation_panel.dart';
import 'admin_operations_provider.dart';
import 'admin_sentry_panel.dart';
import 'admin_deployments_panel.dart';
import 'admin_payments_card.dart';
import 'package:tilomnov/features/admin/presentation/admin_system_health_panel.dart';

enum AdminSection { services, account, activity, financial }

class AdminDashboardPage extends ConsumerWidget {
  final AdminSection section;
  const AdminDashboardPage({super.key, this.section = AdminSection.activity});

  String get title => switch (section) {
    AdminSection.services => 'Services',
    AdminSection.account => 'Account',
    AdminSection.activity => 'Activity',
    AdminSection.financial => 'Financial',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = section == AdminSection.services
        ? null
        : ref.watch(adminDashboardProvider);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Refresh metrics',
            onPressed: () {
              if (section == AdminSection.services) {
                ref.invalidate(adminSystemHealthProvider);
                ref.invalidate(adminRotationProvider);
                ref.invalidate(adminRotationJobProvider);
                ref.invalidate(adminDeploymentsProvider);
                ref.invalidate(adminLogsProvider);
              } else {
                ref.invalidate(adminDashboardProvider);
              }
            },
            icon: const Icon(LucideIcons.refreshCw),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await Future.wait([
              if (section == AdminSection.services)
                ref.refresh(adminSystemHealthProvider.future)
              else
                ref.refresh(adminDashboardProvider.future),
              if (section == AdminSection.services)
                ref.refresh(adminRotationProvider.future),
              if (section == AdminSection.services)
                ref.refresh(adminRotationJobProvider.future),
              if (section == AdminSection.services)
                ref.refresh(adminDeploymentsProvider.future),
            ]);
            if (section == AdminSection.services) {
              ref.invalidate(adminLogsProvider);
            }
          } catch (_) {
            // Each provider displays its failure beside its own retry action.
          }
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            // Keep panels mounted so providers do not reload on scroll.
            child: SingleChildScrollView(
              key: PageStorageKey('admin-${section.name}'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                32 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (section != AdminSection.services) ...[
                    _OverviewHeader(title: title),
                    const SizedBox(height: 20),
                  ],
                  if (section == AdminSection.services)
                    const AdminSystemHealthPanel(),
                  if (section == AdminSection.services)
                    const AdminRotationPanel(),
                  if (section == AdminSection.services)
                    const AdminSentryPanel(),
                  if (section == AdminSection.services)
                    const AdminDeploymentsPanel(),
                  if (dashboard != null)
                    dashboard.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => _DashboardError(
                        onRetry: () => ref.invalidate(adminDashboardProvider),
                      ),
                      data: (data) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (section == AdminSection.activity) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => openAdminRecords(
                                    context,
                                    'all-listings',
                                    'Explore properties',
                                  ),
                                  icon: const Icon(LucideIcons.compass),
                                  label: const Text('Explore properties'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => context.pushPage(
                                    const AdminAdvertisementsPage(),
                                  ),
                                  icon: const Icon(LucideIcons.megaphone),
                                  label: const Text('Manage ads'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                          ],
                          if (section == AdminSection.account ||
                              section == AdminSection.activity)
                            AdminActivityOverview(
                              data: data,
                              accounts: section == AdminSection.account,
                            ),
                          if (section == AdminSection.financial) ...[
                            const _SectionTitle(
                              title: 'Income & membership',
                              subtitle:
                                  'Successful transactions recorded in the last 7 days',
                            ),
                            const SizedBox(height: 12),
                            AdminPaymentsCard(data: data),
                          ],
                          const SizedBox(height: 22),
                          Text(
                            'Metrics updated ${DateFormat.yMMMd().add_jm().format(data.generatedAt.toLocal())}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  final String title;
  const _OverviewHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF142B4A), Color(0xFF22577A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18203355),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tilomnov - $title',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  switch (title) {
                    'Services' =>
                      'Monitor the services powering your platform.',
                    'Account' => 'Manage your community and account access.',
                    'Financial' => 'Track income, payments and memberships.',
                    _ => 'Review listings, leads, reports and advertising.',
                  },
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.shieldUser, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _DashboardError extends StatelessWidget {
  final VoidCallback onRetry;
  const _DashboardError({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.cloudOff, size: 42),
          const SizedBox(height: 12),
          const Text('Dashboard data is unavailable'),
          const SizedBox(height: 6),
          Text(
            'Please check the connection and try again.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
