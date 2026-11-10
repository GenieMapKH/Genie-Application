import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';
import 'package:tilomnov/shared/widgets/forms/app_text_field.dart';
import 'package:tilomnov/shared/widgets/media/user_avatar.dart';
import '../data/admin_record.dart';
import 'admin_moderation_provider.dart';
import 'admin_property_card.dart';
import 'admin_record_tile.dart';
import 'admin_account_actions.dart';
import 'admin_dashboard_provider.dart';

class AdminReportsPage extends ConsumerStatefulWidget {
  final String? type;
  final String? targetId;
  final Map<String, dynamic>? property;
  const AdminReportsPage({super.key, this.type, this.targetId, this.property});
  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  Timer? _debounce;
  String? _query;
  bool _busy = false;
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _resolve(String id) async {
    setState(() => _busy = true);
    try {
      await ref.read(adminModerationRepositoryProvider).resolveReport(id);
      ref.invalidate(adminReportsProvider);
      ref.invalidate(adminDashboardProvider);
    } catch (_) {
      if (mounted) {
        AppPopup.showError(
          context,
          'Could not resolve the report. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = (type: widget.type, id: widget.targetId, query: _query);
    final provider = adminReportsProvider(filter);
    final state = ref.watch(provider);
    return AppPageScaffold(
      title: widget.targetId == null
          ? 'Reported properties & accounts'
          : 'Report details',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppTextField(
              maxWidth: null,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              textInputAction: TextInputAction.search,
              label: widget.targetId == null
                  ? 'Search reports'
                  : 'Search reporters',
              hintText: 'Reporter, reason or details',
              prefixIcon: const Icon(Icons.search_rounded),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 350),
                  () => setState(
                    () => _query = value.trim().isEmpty ? null : value.trim(),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .refresh(provider.future)
                    .then((_) {}, onError: (Object _, StackTrace _) {});
              },
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Could not load reports.'),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(provider),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
                data: (page) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (widget.type == 'user' && widget.targetId != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: AdminAccountActions(
                          userId: widget.targetId!,
                          onChanged: () => Navigator.of(context).pop(),
                        ),
                      ),
                    if (widget.property != null)
                      AdminPropertyCard(property: widget.property!),
                    if (widget.targetId != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          '${page.reportCount ?? 0} reports from ${page.reporterCount ?? 0} people',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    if (page.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No reports found')),
                      ),
                    for (final record in page.items)
                      widget.targetId == null
                          ? _group(context, record)
                          : Column(
                              children: [
                                AdminRecordTile(
                                  record: AdminRecord({
                                    ...record.values,
                                    'account': record.values['reporter'],
                                  }),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : () => _resolve(record.id),
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                    ),
                                    label: const Text('Resolve report'),
                                  ),
                                ),
                              ],
                            ),
                    if (page.nextOffset != null)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () async {
                                setState(() => _busy = true);
                                try {
                                  await ref.read(provider.notifier).loadMore();
                                } catch (_) {
                                  if (context.mounted) {
                                    AppPopup.showError(
                                      context,
                                      'Could not load more reports. Please try again.',
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _busy = false);
                                }
                              },
                        child: Text(_busy ? 'Loading...' : 'Load more'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, AdminRecord record) {
    final values = record.values;
    final property = values['property'] as Map<String, dynamic>?;
    void open() => context.pushPage(
      AdminReportsPage(
        type: values['targetType'] as String,
        targetId: values['targetId'] as String,
        property: property,
      ),
    );
    if (property != null) {
      return AdminPropertyCard(
        property: property,
        reportCount: values['reportCount'] as int,
        onTap: open,
      );
    }
    final account = values['account'] as Map<String, dynamic>?;
    return Card(
      child: ListTile(
        onTap: open,
        leading: UserAvatar(
          name: (account?['name'] ?? account?['username'] ?? '').toString(),
          avatarUrl: account?['avatarUrl'] as String?,
        ),
        title: Text(
          (account?['name'] ?? account?['username'] ?? 'Unavailable target')
              .toString(),
        ),
        subtitle: Text('${values['reportCount']} reports'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
