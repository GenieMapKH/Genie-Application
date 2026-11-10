import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import '../data/admin_service_health.dart';
import 'admin_dashboard_provider.dart';
import 'admin_service_card.dart';

class AdminSystemHealthPanel extends ConsumerWidget {
  const AdminSystemHealthPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(adminSystemHealthProvider);
    return AdminServiceCard(
      icon: Icons.dns_rounded,
      title: 'Backend services',
      onRefresh: () => ref.invalidate(adminSystemHealthProvider),
      refreshing: health.isLoading && health.hasValue,
      refreshFailed: health.hasError && health.hasValue,
      child: health.when(
        skipLoadingOnReload: true,
        skipError: true,
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const Text('Service status unavailable'),
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  data.services.isNotEmpty &&
                          data.services.every(
                            (service) => service.status == 'up',
                          )
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color:
                      data.services.isNotEmpty &&
                          data.services.every(
                            (service) => service.status == 'up',
                          )
                      ? context.colors.success
                      : context.colors.highlight,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${data.services.where((service) => service.status == 'up').length} of ${data.services.length} responding',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 850
                    ? 3
                    : constraints.maxWidth >= 550
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final service in data.services)
                      SizedBox(
                        width: width,
                        child: _ServiceCard(service: service),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'HTTP check ? ${DateFormat.yMMMd().add_jm().format(data.checkedAt.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final AdminServiceHealth service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (service.status) {
      'up' => context.colors.success,
      'down' => colors.error,
      _ => colors.onSurfaceVariant,
    };
    final icon = adminServiceIcon(service.name);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Icon(
                switch (service.status) {
                  'up' => Icons.check_circle_outline,
                  'down' => Icons.error_outline,
                  _ => Icons.help_outline,
                },
                color: color,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            service.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(switch (service.status) {
            'up' => 'Responding',
            'down' =>
              service.httpStatus == null
                  ? 'Unreachable or timed out'
                  : 'Unhealthy response (HTTP ${service.httpStatus})',
            _ => 'Service address not configured',
          }, style: TextStyle(color: color)),
          const SizedBox(height: 12),
          Text(
            service.latencyMs == null
                ? 'Latency unavailable'
                : '${service.latencyMs} ms',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
