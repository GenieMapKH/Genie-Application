import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/media/app_image_cache.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/features/chat/providers/chat_participant_providers.dart';
import 'package:tilomnov/features/chat/providers/chat_service_providers.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// The picture of a chat message: the local copy while it is being sent,
/// otherwise downloaded and decrypted on demand. Tap to view it full screen.
class ChatImageAttachment extends ConsumerWidget {
  static const _width = 220.0;
  static const _height = 220.0;

  final ChatMessage message;

  /// Replaces opening the picture, e.g. to retry a failed send.
  final VoidCallback? onTap;

  const ChatImageAttachment({super.key, required this.message, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = message.localImage;
    if (local != null) return _picture(context, local);

    final attachment = message.attachment!;
    // Opened recently: drawn now, with no loading frame in between.
    final opened = ref.read(chatAttachmentServiceProvider).cached(attachment);
    if (opened != null) return _picture(context, opened);

    return ref
        .watch(chatAttachmentBytesProvider(attachment))
        .when(
          data: (bytes) => _picture(context, bytes),
          loading: () => _placeholder(
            context,
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => GestureDetector(
            onTap: () =>
                ref.invalidate(chatAttachmentBytesProvider(attachment)),
            child: _placeholder(
              context,
              _notice(context, context.l10n.chatPhotoUnavailable),
            ),
          ),
        );
  }

  Widget _picture(BuildContext context, Uint8List bytes) {
    return GestureDetector(
      onTap:
          onTap ??
          () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) => _ChatImageViewer(bytes: bytes),
            ),
          ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _width,
            maxHeight: _height * 1.5,
          ),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            // Decoded at the size of the bubble, not the photo's own size:
            // quicker to show, and far less memory per picture.
            cacheWidth: AppImageCache.decodeWidth(
              _width,
              _height * 1.5,
              MediaQuery.devicePixelRatioOf(context),
            ),
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _placeholder(
              context,
              _notice(context, context.l10n.chatPictureCannotBeShown),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, Widget child) {
    return Container(
      width: _width,
      height: _height * 0.7,
      decoration: BoxDecoration(
        color: context.colors.divider,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  Widget _notice(BuildContext context, String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(fontSize: 13, color: context.colors.textMuted),
    );
  }
}

class _ChatImageViewer extends StatelessWidget {
  final Uint8List bytes;

  const _ChatImageViewer({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(maxScale: 5, child: Image.memory(bytes)),
      ),
    );
  }
}
