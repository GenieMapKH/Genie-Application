import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/shared/utils/app_popup.dart';

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
      AppPopup.showError(
        context,
        'Please scroll to the bottom of the terms to agree.',
      );
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
      backgroundColor: Colors.white,
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
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1E293B),
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
                      'Terms of Service for Genie Property',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Last updated: 14 February 2026',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildParagraph(
                      'Welcome to Genie Property. By accessing or using the Genie application and services, you agree to comply with and be bound by the following Terms of Service.',
                    ),
                    const SizedBox(height: 12),
                    _buildParagraph(
                      'If you do not agree with these terms, please do not use the application.',
                    ),
                    const SizedBox(height: 20),

                    // Section 1
                    _buildSectionHeader('1. About Genie'),
                    _buildParagraph(
                      'Genie is a map-based property platform that allows users to:',
                    ),
                    const SizedBox(height: 8),
                    _buildBulletPoint(
                      'View property listings with accurate map locations and boundaries',
                    ),
                    _buildBulletPoint(
                      'Add, manage, and share property information',
                    ),
                    _buildBulletPoint(
                      'Connect buyers, sellers, agents, and developers',
                    ),
                    _buildBulletPoint(
                      'Use coordinate tools such as UTM input and map measurement',
                    ),
                    const SizedBox(height: 12),
                    _buildParagraph(
                      'Genie acts only as a platform and does not own, sell, or broker any property.',
                    ),
                    const SizedBox(height: 20),

                    // Section 2
                    _buildSectionHeader('2. User Accounts'),
                    _buildParagraph(
                      'To use certain features, users must register using a valid phone number or email address.\nYou agree that:',
                    ),
                    const SizedBox(height: 8),
                    _buildBulletPoint(
                      'The information you provide is accurate',
                    ),
                    _buildBulletPoint(
                      'You are responsible for maintaining the confidentiality of your account',
                    ),
                    _buildBulletPoint(
                      'You will not impersonate another person',
                    ),
                    const SizedBox(height: 12),
                    _buildParagraph(
                      'Genie reserves the right to suspend accounts that provide false information.',
                    ),
                    const SizedBox(height: 20),

                    // Section 3
                    _buildSectionHeader('3. Property Listings'),
                    _buildParagraph(
                      'Users who post properties (owners, agents, developers) agree that:',
                    ),
                    const SizedBox(height: 8),
                    _buildBulletPoint(
                      'All information, boundaries, prices, and details are truthful',
                    ),
                    _buildBulletPoint(
                      'You have the legal right to share and advertise the property',
                    ),
                    _buildBulletPoint(
                      'The map boundary or UTM coordinates you provide are accurate to the best of your knowledge',
                    ),
                    const SizedBox(height: 12),
                    _buildParagraph(
                      'Genie is not responsible for incorrect property data submitted by users.',
                    ),
                    const SizedBox(height: 20),

                    // Section 4
                    _buildSectionHeader('4. Map and Coordinate Accuracy'),
                    _buildParagraph(
                      'Genie provides tools for map visualization, UTM conversion, and distance measurement.',
                    ),
                    const SizedBox(height: 8),
                    _buildBulletPoint(
                      'Map boundaries are for visual guidance only and do not replace official cadastral surveys or land titles.',
                    ),
                    _buildBulletPoint(
                      'Users should verify all land borders and titles with relevant authorities before financial transactions.',
                    ),
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
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: const Color(0xFFE5E7EB), width: 1.0),
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
                        activeColor: const Color(0xFF4F5BD5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        side: BorderSide(
                          color: _hasScrolledToBottom
                              ? const Color(0xFF4F5BD5)
                              : const Color(0xFF9CA3AF),
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
                              ? 'Agree terms of services'
                              : 'Scroll to bottom to agree terms of services',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _hasScrolledToBottom
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF64748B),
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
          color: const Color(0xFF1E293B),
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
        color: const Color(0xFF475569),
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
          const Padding(
            padding: EdgeInsets.only(top: 7.0, right: 8.0),
            child: Icon(Icons.circle, size: 4.5, color: Color(0xFF475569)),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
