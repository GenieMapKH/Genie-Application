import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'admin_operations_provider.dart';
import 'admin_service_card.dart';

class AdminSentryPanel extends ConsumerStatefulWidget {
  const AdminSentryPanel({super.key});
  @override
  ConsumerState<AdminSentryPanel> createState() => _AdminSentryPanelState();
}

class _AdminSentryPanelState extends ConsumerState<AdminSentryPanel> {
  Timer? _timer;
  bool _live = true;
  String _dataset = 'errors';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_live &&
          mounted &&
          TickerMode.valuesOf(context).enabled &&
          !(Scrollable.maybeOf(context)?.position.isScrollingNotifier.value ??
              false) &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          (ModalRoute.of(context)?.isCurrent ?? true)) {
        ref.read(adminLogsProvider(_dataset).notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminLogsProvider(_dataset);
    final feed = ref.watch(provider);
    final colors = context.colors;
    return AdminServiceCard(
      icon: LucideIcons.heartPulse,
      title: 'Sentry',
      refreshing: feed.isLoading && feed.hasValue,
      refreshFailed: feed.hasError && feed.hasValue,
      onRefresh: () {
        if (feed.hasValue) {
          ref.read(provider.notifier).refresh();
        } else {
          ref.invalidate(provider);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'errors',
                    label: Text('Errors'),
                    icon: Icon(LucideIcons.bug),
                  ),
                  ButtonSegment(
                    value: 'logs',
                    label: Text('Logs'),
                    icon: Icon(LucideIcons.terminal),
                  ),
                ],
                selected: {_dataset},
                onSelectionChanged: (values) =>
                    setState(() => _dataset = values.single),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _live = !_live),
                icon: Icon(_live ? LucideIcons.pause : LucideIcons.play),
                label: Text(_live ? 'Pause live' : 'Resume live'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          feed.when(
            skipLoadingOnReload: true,
            skipError: true,
            loading: () => const SizedBox(
              height: 320,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const SizedBox(
              height: 320,
              child: Center(
                child: Text('Feed unavailable. Tap refresh to retry.'),
              ),
            ),
            data: (page) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  page.status == 'ok'
                      ? 'Connected${page.environment == null ? '' : ' ? ${page.environment}'}'
                      : 'Not connected',
                  style: TextStyle(
                    color: page.status == 'ok'
                        ? colors.success
                        : colors.textMuted,
                  ),
                ),
                if (page.refreshFailed)
                  Text(
                    'Refresh failed. Showing saved events.',
                    style: TextStyle(color: colors.danger),
                  ),
                const SizedBox(height: 8),
                Container(
                  height: 320,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: page.entries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.inbox,
                                size: 32,
                                color: colors.iconSubtle,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                page.status != 'ok'
                                    ? 'Feed not connected'
                                    : _dataset == 'errors'
                                    ? 'No errors in the last 24 hours'
                                    : 'No logs received in the last 24 hours',
                              ),
                            ],
                          ),
                        )
                      : NotificationListener<UserScrollNotification>(
                          onNotification: (notification) {
                            if (_live &&
                                notification.direction !=
                                    ScrollDirection.idle) {
                              setState(() => _live = false);
                            }
                            return false;
                          },
                          child: Scrollbar(
                            child: ListView.separated(
                              key: PageStorageKey('sentry-$_dataset'),
                              primary: false,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: page.entries.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final entry = page.entries[index];
                                final isError = const [
                                  'error',
                                  'fatal',
                                  'critical',
                                ].contains(entry.level.toLowerCase());
                                final color = isError
                                    ? colors.danger
                                    : colors.highlight;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        isError
                                            ? LucideIcons.circleAlert
                                            : LucideIcons.fileText,
                                        color: color,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              '${entry.project} ? ${entry.level} ? ${DateFormat.Hms().format(entry.timestamp.toLocal())}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: colors.textSecondary,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            SelectableText(
                                              entry.message,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
                SizedBox(
                  height: 3,
                  child: page.busy ? const LinearProgressIndicator() : null,
                ),
                if (page.nextCursor != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: page.busy
                          ? null
                          : () {
                              setState(() => _live = false);
                              ref.read(provider.notifier).refresh(older: true);
                            },
                      icon: const Icon(LucideIcons.chevronDown),
                      label: const Text('Load older events'),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Checked ${DateFormat.yMMMd().add_jms().format(page.checkedAt.toLocal())}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
