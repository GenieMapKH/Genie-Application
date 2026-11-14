import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_form_inputs.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/phone_number.dart';

class PropertyContactFields extends StatelessWidget {
  final TextEditingController primary;
  final List<TextEditingController> additional;
  final bool showErrors;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final bool accountPhoneVerified;
  final bool verifying;
  final VoidCallback? onVerify;

  const PropertyContactFields({
    super.key,
    required this.primary,
    required this.additional,
    required this.showErrors,
    required this.onAdd,
    required this.onRemove,
    this.accountPhoneVerified = false,
    this.verifying = false,
    this.onVerify,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: PropertyTextField(
              label: context.l10n.propertyContactInformation,
              required: true,
              controller: primary,
              keyboardType: TextInputType.phone,
              hintText: context.l10n.propertyPhoneNumber0,
              hasError:
                  showErrors && normalizePhoneNumber(primary.text) == null,
            ),
          ),
          if (additional.length < 4)
            IconButton(
              onPressed: onAdd,
              tooltip: context.l10n.propertyAddPhone,
              icon: const Icon(LucideIcons.circlePlus),
            ),
        ],
      ),
      if (onVerify != null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('property_verify_phone'),
            onPressed: accountPhoneVerified || verifying ? null : onVerify,
            icon: Icon(
              accountPhoneVerified
                  ? LucideIcons.badgeCheck
                  : LucideIcons.messageSquare,
            ),
            label: Text(
              accountPhoneVerified
                  ? context.l10n.propertyAccountPhoneVerified
                  : context.l10n.propertyVerifyPhone,
            ),
          ),
        ),
      for (var i = 0; i < additional.length; i++) ...[
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: PropertyTextField(
                label: context.l10n.propertyAdditionalPhone,
                controller: additional[i],
                keyboardType: TextInputType.phone,
                hintText: context.l10n.propertyPhoneNumber0,
                hasError:
                    showErrors &&
                    normalizePhoneNumber(additional[i].text) == null,
              ),
            ),
            IconButton(
              onPressed: () => onRemove(i),
              tooltip: context.l10n.propertyRemovePhone,
              icon: const Icon(LucideIcons.circleMinus),
            ),
          ],
        ),
      ],
    ],
  );
}
