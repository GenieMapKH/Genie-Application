import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/admin_income.dart';
import 'admin_records_page.dart';

class AdminIncomeChart extends StatelessWidget {
  final AdminIncome? income;
  const AdminIncomeChart({super.key, required this.income});
  static const subscriptionColor = Color(0xFF8B5CF6);
  static const listingColor = Color(0xFF0891B2);

  @override
  Widget build(BuildContext context) {
    final data = income;
    if (data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Income breakdown is unavailable. Refresh to try again.'),
      );
    }
    final colors = Theme.of(context).colorScheme;
    final money = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final peak = data.days.fold(
      0.0,
      (max, day) => day.totalUsd > max ? day.totalUsd : max,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _IncomeSource(
              label: 'Tier subscriptions',
              purpose: 'SUBSCRIPTION',
              amount: money.format(data.subscriptionUsd),
              color: subscriptionColor,
              icon: Icons.workspace_premium_outlined,
            ),
            _IncomeSource(
              label: 'One-time property posts',
              purpose: 'LISTING_PUBLISH',
              amount: money.format(data.listingUsd),
              color: listingColor,
              icon: Icons.post_add_rounded,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Daily income',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text('USD', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Cambodia time (UTC+7)',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        if (peak == 0)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('No income recorded in the last 7 days.'),
          ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Peak ${money.format(peak)}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final day in data.days)
                Expanded(
                  child: Tooltip(
                    triggerMode: TooltipTriggerMode.tap,
                    message:
                        '${DateFormat.yMMMd().format(day.date)}\nTier subscriptions: ${money.format(day.subscriptionUsd)}\nOne-time property posts: ${money.format(day.listingUsd)}\nTotal: ${money.format(day.totalUsd)}',
                    child: Semantics(
                      label:
                          '${DateFormat.yMMMd().format(day.date)}, tier subscriptions ${money.format(day.subscriptionUsd)}, one-time property posts ${money.format(day.listingUsd)}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (day.totalUsd > 0)
                              Flexible(
                                child: FractionallySizedBox(
                                  heightFactor: day.totalUsd / peak,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5),
                                    ),
                                    child: Column(
                                      children: [
                                        if (day.subscriptionUsd > 0)
                                          Expanded(
                                            flex: (day.subscriptionUsd * 100)
                                                .round(),
                                            child: const ColoredBox(
                                              color: subscriptionColor,
                                              child: SizedBox.expand(),
                                            ),
                                          ),
                                        if (day.listingUsd > 0)
                                          Expanded(
                                            flex: (day.listingUsd * 100)
                                                .round(),
                                            child: const ColoredBox(
                                              color: listingColor,
                                              child: SizedBox.expand(),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 2,
                                color: colors.outlineVariant,
                              ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('d').format(day.date),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (data.days.isNotEmpty)
          Text(
            '${DateFormat.MMMd().format(data.days.first.date)} - ${DateFormat.MMMd().format(data.days.last.date)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _IncomeSource extends StatelessWidget {
  final String label;
  final String purpose;
  final String amount;
  final Color color;
  final IconData icon;
  const _IncomeSource({
    required this.label,
    required this.purpose,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: color.withValues(alpha: .1),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => openAdminRecords(
        context,
        'successful-payments',
        label,
        purpose: purpose,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  Text(
                    amount,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
