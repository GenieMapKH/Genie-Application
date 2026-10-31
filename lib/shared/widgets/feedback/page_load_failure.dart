import 'package:flutter/material.dart';

import 'package:tilomnov/shared/widgets/feedback/load_failure_view.dart';

/// A [LoadFailureView] in place of a whole page's content, right under its
/// header: centred in what is left above the bottom inset (a floating
/// navigation bar, the home indicator), so every tab shows it in the same
/// place. Scrollable, so pull-to-refresh still works around it.
class PageLoadFailure extends StatelessWidget {
  final Object? error;
  final String message;
  final VoidCallback onRetry;

  const PageLoadFailure({
    super.key,
    required this.error,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom,
            ),
            child: Center(
              child: LoadFailureView(
                error: error,
                message: message,
                onRetry: onRetry,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
