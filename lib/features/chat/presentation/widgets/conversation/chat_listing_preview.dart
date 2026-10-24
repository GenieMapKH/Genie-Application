import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/chat/models/chat_listing.dart';
import 'package:genie/shared/widgets/media/app_network_image.dart';

/// A listing's photo, title and price in a row: the card in a message, and
/// the one offered above the message bar.
class ChatListingPreview extends StatelessWidget {
  final ChatListing listing;

  /// Below the price, e.g. "View listing".
  final Widget? footer;

  const ChatListingPreview({super.key, required this.listing, this.footer});

  static const double _photo = 64;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final image = listing.imageUrl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox.square(
            dimension: _photo,
            child: image == null
                ? ColoredBox(
                    color: colors.surfaceMuted,
                    child: Icon(
                      Icons.home_work_outlined,
                      color: colors.iconSubtle,
                    ),
                  )
                : AppNetworkImage(url: image, width: _photo, height: _photo),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                listing.price,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              ?footer,
            ],
          ),
        ),
      ],
    );
  }
}
