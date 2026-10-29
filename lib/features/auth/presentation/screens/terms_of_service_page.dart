import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Terms of Service screen for Tilomnov, for reading. Ticking the box on
/// the sign-up form is enough to agree; the box here does the same, without
/// having to scroll through first. Pops with whether the user agrees.
class TermsOfServicePage extends StatefulWidget {
  final bool initialAgreed;

  const TermsOfServicePage({super.key, this.initialAgreed = false});

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
  late bool _isAgreed = widget.initialAgreed;

  void _handleAgree(bool value) {
    setState(() => _isAgreed = value);
    if (value) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with back button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.colors.textPrimary,
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(_isAgreed),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.termsTitle,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.termsLastUpdated,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: context.colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildParagraph(context.l10n.termsWelcome),
                    const SizedBox(height: 12),
                    _buildParagraph(context.l10n.termsDisagree),
                    const SizedBox(height: 20),

                    // Section 1
                    _buildSectionHeader(context.l10n.termsAboutTitle),
                    _buildParagraph(context.l10n.termsAboutIntro),
                    const SizedBox(height: 8),
                    _buildBulletPoint(context.l10n.termsAboutView),
                    _buildBulletPoint(context.l10n.termsAboutManage),
                    _buildBulletPoint(context.l10n.termsAboutConnect),
                    _buildBulletPoint(context.l10n.termsAboutTools),
                    const SizedBox(height: 12),
                    _buildParagraph(context.l10n.termsAboutPlatformOnly),
                    const SizedBox(height: 20),

                    // Section 2
                    _buildSectionHeader(context.l10n.termsAccountsTitle),
                    _buildParagraph(context.l10n.termsAccountsIntro),
                    const SizedBox(height: 8),
                    _buildBulletPoint(context.l10n.termsAccountsAccurate),
                    _buildBulletPoint(context.l10n.termsAccountsConfidential),
                    _buildBulletPoint(
                      context.l10n.termsAccountsNoImpersonation,
                    ),
                    const SizedBox(height: 12),
                    _buildParagraph(context.l10n.termsAccountsSuspend),
                    const SizedBox(height: 20),

                    // Section 3
                    _buildSectionHeader(context.l10n.termsListingsTitle),
                    _buildParagraph(context.l10n.termsListingsIntro),
                    const SizedBox(height: 8),
                    _buildBulletPoint(context.l10n.termsListingsTruthful),
                    _buildBulletPoint(context.l10n.termsListingsRight),
                    _buildBulletPoint(context.l10n.termsListingsCoordinates),
                    const SizedBox(height: 12),
                    _buildParagraph(context.l10n.termsListingsNotResponsible),
                    const SizedBox(height: 20),

                    // Section 4
                    _buildSectionHeader(context.l10n.termsMapTitle),
                    _buildParagraph(context.l10n.termsMapIntro),
                    const SizedBox(height: 8),
                    _buildBulletPoint(context.l10n.termsMapGuidanceOnly),
                    _buildBulletPoint(context.l10n.termsMapVerify),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Agree Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 14.0,
              ),
              decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border(
                  top: BorderSide(color: context.colors.border, width: 1.0),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: InkWell(
                key: const Key('terms_agree_row'),
                onTap: () => _handleAgree(!_isAgreed),
                child: Row(
                  children: [
                    Transform.scale(
                      scale: 1.3,
                      child: Checkbox(
                        value: _isAgreed,
                        activeColor: context.colors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        side: BorderSide(
                          color: context.colors.primary,
                          width: 1.5,
                        ),
                        onChanged: (val) => _handleAgree(val ?? false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.termsAgree,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: context.colors.textSecondary,
        height: 1.5,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 7.0, right: 8.0),
            child: Icon(
              Icons.circle,
              size: 4.5,
              color: context.colors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: context.colors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
