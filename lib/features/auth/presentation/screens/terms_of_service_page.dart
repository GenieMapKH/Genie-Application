import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

/// Terms of Service screen for Genie Property.
/// Enforces scrolling to the very bottom before the user can agree.
class TermsOfServicePage extends StatefulWidget {
  final ValueChanged<bool>? onAgreeChanged;
  final bool initialAgreed;

  const TermsOfServicePage({
    super.key,
    this.onAgreeChanged,
    this.initialAgreed = false,
  });

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
  final ScrollController _scrollController = ScrollController();
  late bool _hasScrolledToBottom;
  late bool _isAgreed;

  @override
  void initState() {
    super.initState();
    _hasScrolledToBottom = widget.initialAgreed;
    _isAgreed = widget.initialAgreed;
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollability();
    });
  }

  void _checkScrollability() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent <= 0) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    if (!_hasScrolledToBottom && currentScroll >= (maxScroll - 24.0)) {
      setState(() {
        _hasScrolledToBottom = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleAgree(bool value) {
    if (!_hasScrolledToBottom) {
      AppPopup.showError(context, context.l10n.termsScrollToAgree);
      return;
    }

    setState(() {
      _isAgreed = value;
    });

    if (widget.onAgreeChanged != null) {
      widget.onAgreeChanged!(value);
    }

    if (value) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
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
                controller: _scrollController,
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
              child: Opacity(
                opacity: _hasScrolledToBottom ? 1.0 : 0.45,
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isAgreed,
                        activeColor: context.colors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        side: BorderSide(
                          color: _hasScrolledToBottom
                              ? context.colors.primary
                              : context.colors.textHint,
                          width: 1.5,
                        ),
                        onChanged: _hasScrolledToBottom
                            ? (val) => _handleAgree(val ?? false)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _handleAgree(!_isAgreed),
                        child: Text(
                          _hasScrolledToBottom
                              ? context.l10n.termsAgree
                              : context.l10n.termsScrollHint,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _hasScrolledToBottom
                                ? context.colors.textPrimary
                                : context.colors.textMuted,
                          ),
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
