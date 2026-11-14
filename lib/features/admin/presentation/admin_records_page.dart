import 'admin_property_card.dart';
import 'admin_reports_page.dart';
import 'package:tilomnov/features/property/presentation/property_list_layout.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/admin/presentation/admin_records_provider.dart';
import 'package:tilomnov/features/admin/presentation/admin_record_tile.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/page_load_failure.dart';
import 'package:tilomnov/shared/widgets/forms/app_text_field.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';

void openAdminRecords(
  BuildContext context,
  String section,
  String title, {
  String? tier,
  String? purpose,
}) {
  if (section == 'reports') {
    context.pushPage(const AdminReportsPage());
    return;
  }
  context.pushPage(
    AdminRecordsPage(
      section: section,
      title: title,
      tier: tier,
      purpose: purpose,
    ),
  );
}

class AdminRecordsPage extends ConsumerStatefulWidget {
  final String section;
  final String title;
  final String? tier;
  final String? purpose;
  final bool showBackButton;
  const AdminRecordsPage({
    super.key,
    required this.section,
    required this.title,
    this.tier,
    this.purpose,
    this.showBackButton = true,
  });

  @override
  ConsumerState<AdminRecordsPage> createState() => _AdminRecordsPageState();
}

class _AdminRecordsPageState extends ConsumerState<AdminRecordsPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  String? _query;

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final query = value.trim();
      setState(() => _query = query.isEmpty ? null : query);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final section = widget.section;
    final colors = Theme.of(context).colorScheme;
    final filter = (
      section: section,
      tier: widget.tier,
      query: _query,
      purpose: widget.purpose,
    );
    final provider = adminRecordsProvider(filter);
    final records = ref.watch(provider);
    return AppPageScaffold(
      showBackButton: widget.showBackButton,
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: AppTextField(
              maxWidth: null,
              controller: _search,
              onChanged: _onSearch,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              textInputAction: TextInputAction.search,
              label: 'Search $title',
              hintText: section.endsWith('users')
                  ? 'Name, username, email, phone or ID'
                  : section == 'leads'
                  ? 'Listing title, listing ID or user ID'
                  : section == 'subscriptions'
                  ? 'Tier, transaction ID or user ID'
                  : section.endsWith('payments')
                  ? 'Payment ID, user ID, listing ID or purpose'
                  : section == 'reports'
                  ? 'Reason, details, account or ID'
                  : 'Title, description, phone or ID',
              prefixIcon: const Icon(LucideIcons.search),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _search,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(LucideIcons.x),
                        onPressed: () {
                          _search.clear();
                          _debounce?.cancel();
                          setState(() => _query = null);
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .refresh(provider.future)
                  .then((_) {}, onError: (Object _, StackTrace _) {}),
              child: records.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => PageLoadFailure(
                  error: error,
                  message: 'Could not load $title',
                  onRetry: () => ref.invalidate(provider),
                ),
                data: (page) => LayoutBuilder(
                  builder: (context, constraints) {
                    final listingColumns = section.endsWith('listings')
                        ? PropertyListLayout.columnCount(
                            constraints.maxWidth - 32,
                            PropertyListLayout.savedCardMaxWidth,
                          )
                        : 1;
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          (page.items.length / listingColumns).ceil() + 2,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _query == null
                                        ? 'Browse $title'
                                        : 'Search results',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  '${page.items.length}${page.hasMore ? '+' : ''} records',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          );
                        }
                        if (index <=
                            (page.items.length / listingColumns).ceil()) {
                          return section.endsWith('listings')
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (
                                      var column = 0;
                                      column < listingColumns;
                                      column++
                                    ) ...[
                                      if (column > 0) const SizedBox(width: 16),
                                      Expanded(
                                        child:
                                            (index - 1) * listingColumns +
                                                    column <
                                                page.items.length
                                            ? AdminPropertyCard(
                                                property: page
                                                    .items[(index - 1) *
                                                            listingColumns +
                                                        column]
                                                    .values,
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ],
                                )
                              : AdminRecordTile(record: page.items[index - 1]);
                        }
                        if (page.items.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 48,
                              horizontal: 24,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.searchX,
                                  size: 44,
                                  color: colors.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                const Text('No records found'),
                                const SizedBox(height: 8),
                                Text(
                                  _query == null
                                      ? 'Records will appear here when available.'
                                      : 'Try a different name, keyword or ID.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          );
                        }
                        if (!page.hasMore) return const SizedBox(height: 24);
                        return Center(
                          child: page.loadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                )
                              : OutlinedButton(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(provider.notifier)
                                          .loadMore();
                                    } catch (_) {
                                      if (context.mounted) {
                                        AppPopup.showError(
                                          context,
                                          'Could not load more records. Please try again.',
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Load more'),
                                ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
