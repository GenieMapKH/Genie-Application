import 'package:flutter/material.dart';

import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/feedback/empty_state_card.dart';

class EmptyPropertiesState extends StatelessWidget {
  const EmptyPropertiesState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      icon: Icons.home_outlined,
      title: context.l10n.propertyNoListingsYet,
    );
  }
}
