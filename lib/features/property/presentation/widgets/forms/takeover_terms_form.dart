import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tilomnov/features/property/data/models/takeover_terms.dart';
import 'package:tilomnov/features/property/presentation/takeover_labels.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_form_inputs.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/core/theme/app_colors.dart';

class TakeoverTermsForm extends StatefulWidget {
  final TakeoverTerms? initialTerms;
  final ValueChanged<TakeoverTerms> onChanged;
  final bool showErrors;
  const TakeoverTermsForm({
    super.key,
    this.initialTerms,
    required this.onChanged,
    this.showErrors = false,
  });

  @override
  State<TakeoverTermsForm> createState() => _TakeoverTermsFormState();
}

class _TakeoverTermsFormState extends State<TakeoverTermsForm> {
  final _fields = <String, TextEditingController>{};
  final _extra = <(TextEditingController, TextEditingController)>[];
  late final Map<String, dynamic> _choices;
  static const _textFields = [
    'providerName',
    'projectName',
    'sellerAmount',
    'remainingBalance',
    'balanceAsOf',
    'paymentAmount',
    'remainingMonths',
    'nextPaymentDate',
    'annualInterestRate',
    'transferFee',
    'arrearsAmount',
    'notes',
  ];

  @override
  void initState() {
    super.initState();
    _choices = (widget.initialTerms ?? const TakeoverTerms()).toJson();
    for (final field in _textFields) {
      _fields[field] = TextEditingController(
        text: _choices[field]?.toString() ?? '',
      )..addListener(_changed);
    }
    for (final payment
        in widget.initialTerms?.additionalPayments ??
            const <TakeoverPayment>[]) {
      _extra.add((
        TextEditingController(text: payment.amount?.toString() ?? '')
          ..addListener(_changed),
        TextEditingController(text: payment.dueDate ?? '')
          ..addListener(_changed),
      ));
    }
  }

  TakeoverTerms _read() => TakeoverTerms.fromJson({
    ..._choices,
    for (final field in _textFields)
      field: _fields[field]!.text.isEmpty ? null : _fields[field]!.text,
    if (_choices['interestType'] == 'None' ||
        _choices['interestType'] == 'Unknown')
      'annualInterestRate': null,
    if ((double.tryParse(_fields['arrearsAmount']!.text) ?? 0) == 0)
      'arrearsPayer': null,
    'additionalPayments': _choices['hasAdditionalPayments'] != true
        ? <Map<String, dynamic>>[]
        : [
            for (final row in _extra)
              {'amount': row.$1.text, 'dueDate': row.$2.text},
          ],
  });

  void _changed() {
    setState(() {});
    widget.onChanged(_read());
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    for (final row in _extra) {
      row.$1.dispose();
      row.$2.dispose();
    }
    super.dispose();
  }

  Widget _choice(String field, List<String> values) {
    final error = widget.showErrors && _read().errors.contains(field);
    final stored = _choices[field];
    final value = field == 'hasAdditionalPayments'
        ? (stored == null
              ? null
              : stored == true
              ? 'Yes'
              : 'No')
        : stored as String?;
    return PropertyDropdown(
      label: takeoverFieldLabel(context.l10n, field),
      required: true,
      value: value,
      items: values,
      hasError: error,
      onChanged: (value) {
        _choices[field] = field == 'hasAdditionalPayments'
            ? value == 'Yes'
            : value;
        _changed();
      },
    );
  }

  Widget _field(
    String field, {
    bool required = true,
    bool money = false,
    bool date = false,
    TextEditingController? controller,
  }) {
    final text = controller ?? _fields[field]!;
    final error =
        widget.showErrors &&
        _read().errors.contains(
          controller == null ? field : 'additionalPayments',
        );
    return PropertyTextField(
      label: takeoverFieldLabel(context.l10n, field),
      required: required,
      controller: text,
      hasError: error,
      maxLines: field == 'notes' ? 3 : 1,
      hintText: date
          ? context.l10n.takeoverDateHint
          : error
          ? context.l10n.takeoverFieldError
          : '',
      maxLength: money || date || field == 'remainingMonths'
          ? null
          : field == 'notes'
          ? 1000
          : 200,
      keyboardType: money
          ? const TextInputType.numberWithOptions(decimal: true)
          : field == 'remainingMonths'
          ? TextInputType.number
          : null,
      inputFormatters: money
          ? [
              TextInputFormatter.withFunction(
                (old, value) =>
                    RegExp(r'^(?:\d+(?:\.\d{0,2})?)?$').hasMatch(value.text)
                    ? value
                    : old,
              ),
            ]
          : field == 'remainingMonths'
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      readOnly: date,
      onTap: date
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(text.text) ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2200),
              );
              if (picked != null && mounted) {
                text.text = picked.toIso8601String().split('T').first;
              }
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final terms = _read();
    final errors = terms.errors;
    final children = <Widget>[
      Text(l10n.takeoverIntro),
      _choice('providerType', takeoverProviders),
      _field('providerName'),
      if (_choices['providerType'] == 'Developer') _field('projectName'),
      _field('sellerAmount', money: true),
      _field('remainingBalance', money: true),
      Text(l10n.takeoverBalanceHelp),
      _field('balanceAsOf', date: true),
      _field('paymentAmount', money: true),
      _choice('paymentFrequency', takeoverFrequencies),
      _field('remainingMonths'),
      _field('nextPaymentDate', date: true),
      _choice('interestType', takeoverInterestTypes),
      if (['Fixed', 'Variable'].contains(_choices['interestType']))
        _field('annualInterestRate', money: true),
      _choice('transferStatus', takeoverTransferStatuses),
      if (_choices['transferStatus'] == 'Not allowed')
        Text(
          l10n.takeoverNotAllowed,
          style: TextStyle(color: context.colors.danger),
        ),
      _field('transferFee', required: false, money: true),
      _choice('transferFeePayer', takeoverCostPayers),
      _field('arrearsAmount', money: true),
      Text(l10n.takeoverArrearsHelp),
      if ((terms.arrearsAmount ?? 0) > 0)
        _choice('arrearsPayer', takeoverCostPayers),
      _choice('hasAdditionalPayments', const ['Yes', 'No']),
      if (_choices['hasAdditionalPayments'] == true) ...[
        Text(l10n.takeoverAdditionalHelp),
        for (var i = 0; i < _extra.length; i++)
          Column(
            key: ObjectKey(_extra[i].$1),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field('additionalAmount', money: true, controller: _extra[i].$1),
              const SizedBox(height: 12),
              _field('additionalDate', date: true, controller: _extra[i].$2),
              TextButton.icon(
                onPressed: () {
                  final removed = _extra.removeAt(i);
                  removed.$1.dispose();
                  removed.$2.dispose();
                  _changed();
                },
                icon: const Icon(Icons.remove_circle_outline),
                label: Text(l10n.takeoverRemovePayment),
              ),
            ],
          ),
        if (_extra.length < 24)
          TextButton.icon(
            onPressed: () {
              _extra.add((
                TextEditingController()..addListener(_changed),
                TextEditingController()..addListener(_changed),
              ));
              _changed();
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.takeoverAddPayment),
          ),
        if (widget.showErrors && errors.contains('additionalPayments'))
          Text(
            l10n.takeoverFieldError,
            style: TextStyle(color: context.colors.danger),
          ),
      ],
      _field('notes', required: (terms.arrearsAmount ?? 0) > 0),
      Text(
        '${l10n.takeoverCombinedPrice}: ${terms.combinedPrice == null ? '—' : PropertyFormat.takeoverMoney(terms.combinedPrice!)}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      Text(l10n.takeoverCombinedHelp),
      Text(l10n.takeoverBuyerNotice),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final child in children)
          Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
      ],
    );
  }
}
