import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';
import 'ipad_optimized_bottom_nav.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use iPad-optimized version for iPads to prevent overflow
    if (ResponsiveHelper.isIPad(context) ||
        ResponsiveHelper.isIPadPro(context) ||
        ResponsiveHelper.isIPadPro11(context) ||
        ResponsiveHelper.isIPadPro12_9(context)) {
      return IPadOptimizedBottomNavBar(
        currentIndex: currentIndex,
        onTap: onTap,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDF7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(
              context,
              mobile: 24,
              tablet: 28,
              desktop: 32)),
          topRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(
              context,
              mobile: 24,
              tablet: 28,
              desktop: 32)),
        ),
        boxShadow: ResponsiveHelper.getResponsiveShadow(context),
        border: Border(
          top: BorderSide(
              color: const Color(0xFFF3F6EA),
              width: ResponsiveHelper.getResponsiveStrokeWidth(context)),
        ),
      ),
      padding: ResponsiveHelper.getResponsivePaddingIPad(context,
          mobile: 8, tablet: 12, ipad: 16, ipadPro: 20, desktop: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context: context,
            icon: Icons.home_outlined,
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.directions_car,
            label: 'My Requests',
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.person_outline,
            label: 'Profile',
            selected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final Color selectedColor = const Color(0xFF23281A);
    final Color unselectedColor = const Color(0xFF9EB06A);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: ResponsiveHelper.getResponsiveButtonHeight(context,
                mobile: 56, tablet: 64, ipad: 72, ipadPro: 80, desktop: 70),
            maxHeight: ResponsiveHelper.getResponsiveButtonHeight(context,
                mobile: 80, tablet: 88, ipad: 96, ipadPro: 104, desktop: 90),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: ResponsiveHelper.getResponsivePadding(context,
                mobile: 2, tablet: 4, desktop: 6),
            decoration: selected
                ? BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE6F0C2),
                        const Color(0xFFD0E6A5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context,
                            mobile: 16,
                            tablet: 20,
                            ipad: 24,
                            ipadPro: 28,
                            desktop: 24)),
                    boxShadow: ResponsiveHelper.getResponsiveShadow(context,
                        mobile: 4, tablet: 6, ipad: 8, ipadPro: 10, desktop: 8),
                  )
                : null,
            margin: selected
                ? ResponsiveHelper.getResponsivePaddingIPad(context,
                    mobile: 2, tablet: 4, ipad: 6, ipadPro: 8, desktop: 6)
                : EdgeInsets.zero,
            child: Padding(
              padding: selected
                  ? ResponsiveHelper.getResponsivePaddingIPad(context,
                      mobile: 6, tablet: 8, ipad: 10, ipadPro: 12, desktop: 8)
                  : ResponsiveHelper.getResponsivePaddingIPad(context,
                      mobile: 4, tablet: 6, ipad: 8, ipadPro: 10, desktop: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 2,
                    child: Icon(
                      icon,
                      size: ResponsiveHelper.getResponsiveIconSize(context,
                          mobile: 18,
                          tablet: 22,
                          ipad: 26,
                          ipadPro: 30,
                          desktop: 26),
                      color: selected ? selectedColor : unselectedColor,
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacingIPad(context,
                          mobile: 2,
                          tablet: 3,
                          ipad: 4,
                          ipadPro: 5,
                          desktop: 4)),
                  Flexible(
                    flex: 1,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(
                            context,
                            mobile: 10,
                            tablet: 11,
                            ipad: 12,
                            ipadPro: 13,
                            desktop: 12),
                        fontWeight: FontWeight.w600,
                        color: selected ? selectedColor : unselectedColor,
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
