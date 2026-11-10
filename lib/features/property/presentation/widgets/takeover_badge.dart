import 'package:flutter/material.dart';
import 'package:tilomnov/l10n/l10n.dart';

class TakeoverBadge extends StatelessWidget {
  const TakeoverBadge({super.key});
  static const color = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      context.l10n.listingTypeTakeover,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
