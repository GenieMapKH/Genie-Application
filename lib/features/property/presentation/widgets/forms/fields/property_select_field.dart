import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilomnov/core/theme/app_colors.dart';

/// A pick-one field for the property form. Its list slides open just under
/// the field, exactly as wide, so the current value stays readable while
/// choosing (a plain dropdown opens on top of it). It opens above instead
/// when there is not enough room below.
class PropertySelectField extends StatefulWidget {
  final String? value;
  final List<String> items;
  final String Function(String item) labelOf;
  final ValueChanged<String?> onChanged;

  /// How the closed field looks; its hint shows while nothing is picked.
  final InputDecoration decoration;

  const PropertySelectField({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    required this.decoration,
  });

  @override
  State<PropertySelectField> createState() => _PropertySelectFieldState();
}

class _PropertySelectFieldState extends State<PropertySelectField>
    with SingleTickerProviderStateMixin {
  static const _itemHeight = 44.0;
  static const _maxMenuHeight = 264.0;
  static const _gap = 4.0;

  final _link = LayerLink();
  final _portal = OverlayPortalController();
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    reverseDuration: const Duration(milliseconds: 120),
  );
  late final _reveal = CurvedAnimation(
    parent: _animation,
    curve: Curves.easeOutCubic,
  );

  double _width = 0;
  bool _opensUp = false;
  bool _isOpen = false;

  double get _menuHeight =>
      math.min(widget.items.length * _itemHeight + 8, _maxMenuHeight);

  @override
  void dispose() {
    _reveal.dispose();
    _animation.dispose();
    super.dispose();
  }

  void _toggle() => _isOpen ? _close() : _open();

  void _open() {
    FocusScope.of(context).unfocus();
    final box = context.findRenderObject()! as RenderBox;
    final top = box.localToGlobal(Offset.zero).dy;
    final media = MediaQuery.of(context);
    final spaceBelow =
        media.size.height -
        math.max(media.viewPadding.bottom, media.viewInsets.bottom) -
        (top + box.size.height);
    final spaceAbove = top - media.viewPadding.top;
    setState(() {
      _isOpen = true;
      _width = box.size.width;
      _opensUp = spaceBelow < _menuHeight + _gap && spaceAbove > spaceBelow;
    });
    _portal.show();
    _animation.forward();
  }

  Future<void> _close() async {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    await _animation.reverse();
    // Reopened while closing: the reverse was cut short, so stay shown.
    if (mounted && !_isOpen) _portal.hide();
  }

  void _pick(String item) {
    widget.onChanged(item);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.items.contains(widget.value) ? widget.value : null;

    return TapRegion(
      groupId: this,
      onTapOutside: (_) => _close(),
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (_) => _buildMenu(value),
          child: _buildField(value),
        ),
      ),
    );
  }

  Widget _buildField(String? value) {
    final colors = context.colors;
    return Semantics(
      button: true,
      expanded: _isOpen,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: InputDecorator(
          decoration: widget.decoration.copyWith(
            suffixIcon: AnimatedRotation(
              turns: _isOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(Icons.keyboard_arrow_down, color: colors.textHint),
            ),
          ),
          isFocused: _isOpen,
          isEmpty: value == null,
          child: Text(
            value == null ? '' : widget.labelOf(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(String? value) {
    final colors = context.colors;
    return Positioned(
      width: _width,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: _opensUp ? Alignment.topLeft : Alignment.bottomLeft,
        followerAnchor: _opensUp ? Alignment.bottomLeft : Alignment.topLeft,
        offset: Offset(0, _opensUp ? -_gap : _gap),
        child: TapRegion(
          groupId: this,
          child: FadeTransition(
            opacity: _reveal,
            child: SizeTransition(
              sizeFactor: _reveal,
              alignment: _opensUp
                  ? Alignment.bottomCenter
                  : Alignment.topCenter,
              child: Material(
                color: colors.surface,
                elevation: 6,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: colors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: _menuHeight),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    children: [
                      for (final item in widget.items)
                        _buildItem(item, item == value),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(String item, bool isSelected) {
    final colors = context.colors;
    return InkWell(
      onTap: () => _pick(item),
      child: Container(
        height: _itemHeight,
        color: isSelected ? colors.primarySoft : null,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.labelOf(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: isSelected ? colors.accent : colors.textPrimary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, size: 18, color: colors.accent),
          ],
        ),
      ),
    );
  }
}
