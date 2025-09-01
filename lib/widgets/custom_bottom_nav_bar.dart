import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

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
      padding: ResponsiveHelper.getResponsivePadding(context,
          mobile: 8, tablet: 12, desktop: 16),
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
                mobile: 50, tablet: 60, desktop: 70),
            maxHeight: ResponsiveHelper.getResponsiveButtonHeight(context,
                mobile: 70, tablet: 80, desktop: 90),
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
                            mobile: 16, tablet: 20, desktop: 24)),
                    boxShadow: ResponsiveHelper.getResponsiveShadow(context,
                        mobile: 4, tablet: 6, desktop: 8),
                  )
                : null,
            margin: selected
                ? ResponsiveHelper.getResponsivePadding(context,
                    mobile: 2, tablet: 4, desktop: 6)
                : EdgeInsets.zero,
            child: Padding(
              padding: selected
                  ? ResponsiveHelper.getResponsivePadding(context,
                      mobile: 4, tablet: 6, desktop: 8)
                  : ResponsiveHelper.getResponsivePadding(context,
                      mobile: 2, tablet: 3, desktop: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Icon(
                      icon,
                      size: ResponsiveHelper.getResponsiveIconSize(context,
                          mobile: 20, tablet: 24, desktop: 28),
                      color: selected ? selectedColor : unselectedColor,
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context,
                          mobile: 1, tablet: 2, desktop: 3)),
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 11,
                            tablet: 12,
                            desktop: 13),
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
