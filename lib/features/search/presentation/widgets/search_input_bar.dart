import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/search/data/search_text.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Back arrow, the search field and its clear button, at the top of the
/// search page. A thin progress line under it shows a request in flight
/// without moving anything on screen.
class SearchInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onBack;

  const SearchInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
              ),
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.only(left: 14),
                  decoration: BoxDecoration(
                    color: colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/search.svg',
                        width: 22,
                        height: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _field(context)),
                      _ClearButton(
                        controller: controller,
                        onCleared: () {
                          controller.clear();
                          onChanged('');
                          focusNode.requestFocus();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Built only while loading: an indeterminate indicator repaints every
        // frame, even when faded out.
        SizedBox(
          height: 2,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? LinearProgressIndicator(
                    minHeight: 2,
                    color: colors.accent,
                    backgroundColor: Colors.transparent,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _field(BuildContext context) {
    final colors = context.colors;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      inputFormatters: [LengthLimitingTextInputFormatter(SearchText.maxLength)],
      cursorColor: colors.accent,
      style: GoogleFonts.inter(fontSize: 15, color: colors.textPrimary),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: context.l10n.searchFieldHint,
        hintMaxLines: 1,
        hintStyle: GoogleFonts.inter(fontSize: 15, color: colors.textHint),
      ),
    );
  }
}

/// Shown only while there is text; rebuilds alone as the text changes.
class _ClearButton extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onCleared;

  const _ClearButton({required this.controller, required this.onCleared});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.text.isEmpty) return const SizedBox(width: 12);
        return IconButton(
          onPressed: onCleared,
          tooltip: context.l10n.searchClear,
          icon: Icon(
            Icons.close_rounded,
            size: 20,
            color: context.colors.textMuted,
          ),
        );
      },
    );
  }
}
