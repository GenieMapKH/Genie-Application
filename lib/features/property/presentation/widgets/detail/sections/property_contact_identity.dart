import 'package:flutter/material.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/phone_number.dart';

/// Verification describes the exact contact, not the seller or the listing.
class PropertyContactIdentity extends StatelessWidget {
  final PropertyModel property;

  const PropertyContactIdentity({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final email = property.ownerEmail;
    final phones = <String>{
      ?property.ownerPhone,
      ?property.details.contactPhone,
      ...property.details.additionalContactPhones,
    };
    final normalized = phones
        .map((phone) => normalizePhoneNumber(phone) ?? phone.trim())
        .where((phone) => phone.isNotEmpty)
        .toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (email != null && email.isNotEmpty)
          _ContactStatus(value: email, verified: property.ownerEmailVerified),
        for (final phone in normalized)
          _ContactStatus(
            value: phone,
            verified:
                property.ownerPhoneVerified &&
                phone == normalizePhoneNumber(property.ownerPhone ?? ''),
          ),
      ],
    );
  }
}

class _ContactStatus extends StatelessWidget {
  final String value;
  final bool verified;

  const _ContactStatus({required this.value, required this.verified});

  @override
  Widget build(BuildContext context) {
    final status = verified
        ? context.l10n.contactVerified
        : context.l10n.contactNotVerified;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(value),
          Row(
            children: [
              Icon(
                verified ? Icons.verified_outlined : Icons.info_outline,
                size: 16,
                semanticLabel: status,
              ),
              const SizedBox(width: 6),
              Flexible(child: Text(status)),
            ],
          ),
        ],
      ),
    );
  }
}
