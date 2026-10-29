import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/core/media/app_image_cache.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/widgets/share/property_share_card.dart';
import 'package:tilomnov/features/property/utils/property_share_link.dart';
import 'package:tilomnov/features/property/utils/property_share_message.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';

/// Shows a listing as the picture it is shared as ([PropertyShareCard]) and
/// sends it on: to any app on the phone (Telegram, Messenger, TikTok...)
/// with [propertyShareMessage] alongside, to the photo gallery, or as a
/// copied link.
class PropertyShareSheet extends StatefulWidget {
  final PropertyModel property;

  /// Saves the picture to the gallery as soon as it is ready: the share
  /// section's Download button.
  final bool saveOnOpen;

  const PropertyShareSheet({
    super.key,
    required this.property,
    this.saveOnOpen = false,
  });

  /// Opens the sheet; for a listing that is not public, whose link would
  /// open "not found", says why it cannot be shared instead.
  static Future<void> show(
    BuildContext context,
    PropertyModel property, {
    bool saveImage = false,
  }) async {
    if (!property.isPublic) {
      AppPopup.showInfo(context, notShareableReason(context.l10n, property));
      return;
    }
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) =>
          PropertyShareSheet(property: property, saveOnOpen: saveImage),
    );
  }

  /// Why a listing that is not public cannot be shared yet, or any more.
  static String notShareableReason(
    AppLocalizations l10n,
    PropertyModel property,
  ) => switch (property.status) {
    'Draft' => l10n.propertyShareNotPublicDraft,
    'Pending' => l10n.propertyShareNotPublicPending,
    _ => l10n.propertyShareNotPublicEnded,
  };

  @override
  State<PropertyShareSheet> createState() => _PropertyShareSheetState();
}

class _PropertyShareSheetState extends State<PropertyShareSheet> {
  final _cardKey = GlobalKey();
  final _shareButtonKey = GlobalKey();

  /// The lead photo at full size: the picture is three times the card's
  /// width, more than a thumbnail has.
  ImageProvider? _photo;

  /// The photo has loaded (or failed to), so a picture taken now is final.
  bool _ready = false;
  bool _preparing = false;
  bool _busy = false;

  PropertyModel get _property => widget.property;

  @override
  void initState() {
    super.initState();
    final url = _property.imageUrls.firstOrNull;
    if (url != null && url.startsWith('http')) {
      _photo = CachedNetworkImageProvider(
        url,
        cacheManager: AppImageCache.files,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_preparing) {
      _preparing = true;
      _prepare();
    }
  }

  Future<void> _prepare() async {
    final photo = _photo;
    if (photo != null) {
      await precacheImage(
        photo,
        context,
        onError: (error, stackTrace) {
          AppLogger.error('Share picture photo failed to load', error);
          // The card draws its placeholder instead.
          _photo = null;
        },
      );
    }
    if (!mounted) return;
    setState(() => _ready = true);
    if (widget.saveOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _run(_save);
      });
    }
  }

  /// The card as a PNG, or null when it could not be drawn.
  Future<Uint8List?> _capture() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Runs one action at a time, with the buttons off meanwhile.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final l10n = context.l10n;
    // iPads anchor the share popover to the button.
    final box =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final message = propertyShareMessage(l10n, _property);
    try {
      final picture = await _capture();
      // Messenger, Facebook and Instagram drop the text that comes with a
      // picture; on the clipboard it is one paste away there.
      await Clipboard.setData(ClipboardData(text: message));
      if (mounted) AppPopup.showInfo(context, l10n.propertyShareCaptionCopied);
      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: _property.title,
          files: picture == null
              ? null
              : [XFile.fromData(picture, mimeType: 'image/png')],
          fileNameOverrides: picture == null
              ? null
              : ['tilomnov-${_property.id}.png'],
          sharePositionOrigin: origin,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Sharing a listing failed', e, stackTrace);
      if (mounted) AppPopup.showError(context, l10n.propertyShareFailed);
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    try {
      final picture = await _capture();
      if (picture == null) {
        throw StateError('The share picture could not be drawn');
      }
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
        if (mounted) {
          AppPopup.showError(context, l10n.propertySharePhotosDenied);
        }
        return;
      }
      await Gal.putImageBytes(picture, name: 'tilomnov-${_property.id}');
      if (mounted) AppPopup.showSuccess(context, l10n.propertyShareImageSaved);
    } catch (e, stackTrace) {
      AppLogger.error('Saving the share picture failed', e, stackTrace);
      if (mounted) {
        AppPopup.showError(context, l10n.propertyShareImageSaveFailed);
      }
    }
  }

  Future<void> _copyLink() async {
    final l10n = context.l10n;
    await Clipboard.setData(
      ClipboardData(text: propertyShareLink(_property.id).toString()),
    );
    if (mounted) AppPopup.showSuccess(context, l10n.propertyShareLinkCopied);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final enabled = _ready && !_busy;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.propertyShareSheetTitle,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.55,
              ),
              child: FittedBox(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: PropertyShareCard(
                      property: _property,
                      photo: _ready ? _photo : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              key: _shareButtonKey,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: enabled ? () => _run(_share) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(Icons.ios_share, size: 18, color: colors.onPrimary),
                label: Text(
                  l10n.propertyShare,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _OutlinedAction(
                    icon: Icons.link_rounded,
                    label: l10n.propertyShareCopyLink,
                    onPressed: _busy ? null : () => _run(_copyLink),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OutlinedAction(
                    icon: Icons.download_rounded,
                    label: l10n.propertyShareSaveImage,
                    onPressed: enabled ? () => _run(_save) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _OutlinedAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, size: 18, color: colors.textPrimary),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
