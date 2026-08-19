import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:genie/shared/widgets/tactile_button.dart';
import 'package:genie/features/home/presentation/widgets/utm_locate_bottom_sheet.dart';

class MapFloatingMenu extends StatefulWidget {
  final VoidCallback onDrawPressed;
  final void Function(List<LatLng>) onCoordinatesScanned;

  const MapFloatingMenu({
    super.key,
    required this.onDrawPressed,
    required this.onCoordinatesScanned,
  });

  @override
  State<MapFloatingMenu> createState() => _MapFloatingMenuState();
}

class _MapFloatingMenuState extends State<MapFloatingMenu> with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Widget _buildAnimatedMenuItem({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Padding(
          padding: const EdgeInsets.only(left: 10.0, bottom: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TactileButton(
                onPressed: onTap,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      iconPath,
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF374151),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      bottom: 110, // Offset for extendBody bottom navigation bar
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {}, // Prevent taps from bleeding to map
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedMenuItem(
              iconPath: 'assets/icons/utm.svg',
              label: 'Coordinates',
              onTap: () async {
                // Close the floating menu first
                _toggleMenu();
                final result = await showModalBottomSheet<List<LatLng>>(
                  context: context,
                  isScrollControlled: true,
                  useRootNavigator: false,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const UtmLocateBottomSheet(),
                );
                
                if (result != null && result.isNotEmpty && mounted) {
                  widget.onCoordinatesScanned(result);
                }
              },
            ),
            _buildAnimatedMenuItem(
              iconPath: 'assets/icons/draw.svg',
              label: 'Draw',
              onTap: () {
                _toggleMenu();
                widget.onDrawPressed();
              },
            ),
            TactileButton(
              onPressed: _toggleMenu,
              child: AnimatedRotation(
                turns: _isMenuOpen ? 0.125 : 0, // 45 degree rotation
                duration: const Duration(milliseconds: 250),
                child: SvgPicture.asset(
                  'assets/icons/plus.svg',
                  width: 76,
                  height: 76,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
