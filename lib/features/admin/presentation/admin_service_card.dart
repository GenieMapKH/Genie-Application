import 'package:flutter/material.dart';
import 'package:tilomnov/core/theme/app_colors.dart';

class AdminServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback onRefresh;
  final bool refreshing;
  final bool refreshFailed;

  const AdminServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    required this.onRefresh,
    this.refreshing = false,
    this.refreshFailed = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: colors.highlight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Refresh $title',
                onPressed: refreshing ? null : onRefresh,
                style: IconButton.styleFrom(
                  backgroundColor: colors.primarySoft,
                  foregroundColor: colors.highlight,
                ),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 3,
            child: refreshing ? const LinearProgressIndicator() : null,
          ),
          const SizedBox(height: 12),
          if (refreshFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Refresh failed. Showing the last successful check.',
                style: TextStyle(color: colors.danger),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

IconData adminServiceIcon(String name) => switch (name.toLowerCase()) {
  'api-gateway' || 'api gateway' => Icons.hub_rounded,
  'authentication' || 'authentication database' => Icons.lock_rounded,
  'user' || 'users' || 'users database' => Icons.people_alt_rounded,
  'property' || 'listings' || 'listings database' => Icons.home_work_rounded,
  'chat' || 'chat database' => Icons.forum_rounded,
  'payment' ||
  'payments' ||
  'payments database' => Icons.account_balance_wallet_rounded,
  'notification' ||
  'notifications' ||
  'notifications database' => Icons.notifications_active_rounded,
  _ => Icons.shield_rounded,
};
