import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/property/data/models/property_insights.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/property_insights_provider.dart';
import 'package:genie/features/property/presentation/widgets/insights/insights_day_chart.dart';
import 'package:genie/features/property/presentation/widgets/insights/insights_totals.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/widgets/layout/app_page_scaffold.dart';

/// How one of the owner's listings is doing: everyone who opened, saved,
/// called or chatted, and the last two weeks day by day.
class PropertyInsightsPage extends ConsumerStatefulWidget {
  final PropertyModel property;

  const PropertyInsightsPage({super.key, required this.property});

  @override
  ConsumerState<PropertyInsightsPage> createState() =>
      _PropertyInsightsPageState();
}

class _PropertyInsightsPageState extends ConsumerState<PropertyInsightsPage> {
  var _measure = InsightMeasure.views;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = propertyInsightsProvider(widget.property.id);
    final insights = ref.watch(provider);

    return AppPageScaffold(
      title: l10n.insightsTitle,
      child: RefreshIndicator(
        color: context.colors.accent,
        onRefresh: () => ref.refresh(provider.future),
        child: insights.when(
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _Message(
            text: l10n.insightsLoadFailed,
            onRetry: () => ref.invalidate(provider),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              Text(
                widget.property.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              InsightsTotals(insights: data),
              const SizedBox(height: 24),
              _Trend(
                insights: data,
                measure: _measure,
                onMeasure: (measure) => setState(() => _measure = measure),
              ),
              if (data.isEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.insightsEmptyHint,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: context.colors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The last 14 days of one measure, with this week against the one before.
class _Trend extends StatelessWidget {
  final PropertyInsights insights;
  final InsightMeasure measure;
  final ValueChanged<InsightMeasure> onMeasure;

  const _Trend({
    required this.insights,
    required this.measure,
    required this.onMeasure,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final week = insights.weekOf(measure);
    String describe(int count) => switch (measure) {
      InsightMeasure.views => l10n.insightsViewers(count),
      InsightMeasure.saves => l10n.insightsSaves(count),
      InsightMeasure.leads => l10n.insightsLeads(count),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.insightsLast14Days,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<InsightMeasure>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: InsightMeasure.views,
                label: Text(l10n.insightsMeasureViews),
              ),
              ButtonSegment(
                value: InsightMeasure.saves,
                label: Text(l10n.insightsMeasureSaves),
              ),
              ButtonSegment(
                value: InsightMeasure.leads,
                label: Text(l10n.insightsMeasureLeads),
              ),
            ],
            selected: {measure},
            onSelectionChanged: (picked) => onMeasure(picked.first),
          ),
          const SizedBox(height: 16),
          InsightsDayChart(
            days: insights.days,
            measure: measure,
            describe: describe,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.insightsThisWeek(describe(week.thisWeek), week.lastWeek),
            style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;

  const _Message({required this.text, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    // Scrollable, so pulling down tries again too.
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: context.colors.textMuted),
        ),
        TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
      ],
    );
  }
}
