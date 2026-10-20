import 'package:flutter/material.dart';

import 'package:genie/core/theme/app_colors.dart';

/// The small spinner at the end of a list while its next page is on its way.
class LoadingMoreIndicator extends StatelessWidget {
  const LoadingMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: context.colors.accent,
          ),
        ),
      ),
    );
  }
}
