import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';
import 'package:tilomnov/shared/widgets/layout/legal_text.dart';

/// "Privacy & cookies": what the app collects, why, who else sees it, what
/// it keeps on the phone, and the user's choices. For reading only.
class PrivacyCookiesPage extends StatelessWidget {
  const PrivacyCookiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AppPageScaffold(
      title: l10n.accountPrivacy,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            l10n.privacyLastUpdated,
            style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted),
          ),
          const SizedBox(height: 16),
          LegalParagraph(l10n.privacyIntro),
          ..._section(
            l10n.privacyCollectTitle,
            bullets: [
              l10n.privacyCollectAccount,
              l10n.privacyCollectListings,
              l10n.privacyCollectLocation,
              l10n.privacyCollectActivity,
              l10n.privacyCollectDevice,
            ],
          ),
          ..._section(
            l10n.privacyUseTitle,
            bullets: [
              l10n.privacyUseRun,
              l10n.privacyUseProtect,
              l10n.privacyUseFix,
              l10n.privacyUseNoSale,
            ],
          ),
          ..._section(l10n.privacyChatTitle, intro: l10n.privacyChatBody),
          ..._section(
            l10n.privacyPaymentsTitle,
            intro: l10n.privacyPaymentsBody,
          ),
          ..._section(
            l10n.privacySharingTitle,
            intro: l10n.privacySharingIntro,
            bullets: [
              l10n.privacySharingUsers,
              l10n.privacySharingProviders,
              l10n.privacySharingLaw,
            ],
          ),
          ..._section(
            l10n.privacyCookiesTitle,
            intro: l10n.privacyCookiesIntro,
            bullets: [
              l10n.privacyCookiesSignIn,
              l10n.privacyCookiesSettings,
              l10n.privacyCookiesOffline,
            ],
            outro: l10n.privacyCookiesClear,
          ),
          ..._section(
            l10n.privacyChoicesTitle,
            bullets: [
              l10n.privacyChoicesEdit,
              l10n.privacyChoicesLocation,
              l10n.privacyChoicesNotifications,
              l10n.privacyChoicesDelete,
            ],
          ),
          ..._section(l10n.privacyContactTitle, intro: l10n.privacyContactBody),
        ],
      ),
    );
  }

  /// One section: heading, then an optional paragraph, points and closing
  /// paragraph.
  static List<Widget> _section(
    String title, {
    String? intro,
    List<String> bullets = const [],
    String? outro,
  }) {
    return [
      const SizedBox(height: 22),
      LegalSectionHeader(title),
      if (intro != null) LegalParagraph(intro),
      if (intro != null && bullets.isNotEmpty) const SizedBox(height: 8),
      for (final bullet in bullets) LegalBullet(bullet),
      if (outro != null) ...[const SizedBox(height: 6), LegalParagraph(outro)],
    ];
  }
}
