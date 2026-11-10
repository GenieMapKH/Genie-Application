import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/admin_dashboard_repository.dart';
import 'admin_records_page.dart';
import 'admin_income_chart.dart';
import '../../subscription/domain/plan_tier.dart';
import '../../subscription/presentation/plan_tier_style.dart';

class AdminPaymentsCard extends StatelessWidget {
  final AdminDashboardData data;
  const AdminPaymentsCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: EdgeInsets.zero,
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => openAdminRecords(
              context,
              'successful-payments',
              'Income - last 7 days',
            ),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF142B4A), Color(0xFF22577A)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Income - last 7 days',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      Icon(
                        Icons.arrow_outward_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      NumberFormat.currency(
                        symbol: r'$',
                        decimalDigits: 2,
                      ).format(data.volumeUsd7d),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Successful payments in USD',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AdminIncomeChart(income: data.income),
          const SizedBox(height: 16),
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              _PaymentValue(
                label: 'Successful payments',
                section: 'successful-payments',
                value: NumberFormat.decimalPattern().format(
                  data.successfulPayments7d,
                ),
              ),
              _PaymentValue(
                label: 'Pending payments',
                section: 'pending-payments',
                value: NumberFormat.decimalPattern().format(
                  data.pendingPayments,
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          Text(
            'Membership tiers',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final tier in PlanTier.values.where((tier) => tier.isPaid))
                  SizedBox(
                    width: constraints.maxWidth < 480
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 24) / 3,
                    child: Material(
                      color: tier.accentOn(context).withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => openAdminRecords(
                          context,
                          'subscriptions',
                          '${tier.name} subscriptions',
                          tier: tier.name,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    PlanTierStyle.of(tier).icon,
                                    color: tier.accentOn(context),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${tier.name[0].toUpperCase()}${tier.name.substring(1)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                NumberFormat.decimalPattern().format(
                                  data.subscriptionsByTier[tier.name] ?? 0,
                                ),
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Active subscriptions',
                                style: Theme.of(context).textTheme.bodySmall,
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
        ],
      ),
    ),
  );
}

class _PaymentValue extends StatelessWidget {
  final String section;
  final String label;
  final String value;
  const _PaymentValue({
    required this.label,
    required this.value,
    required this.section,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 145,
    child: InkWell(
      onTap: () => openAdminRecords(context, section, label),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
