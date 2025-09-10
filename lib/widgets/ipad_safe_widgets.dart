import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// iPad-optimized widgets to prevent overflow issues
class IPadSafeColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? spacing;

  const IPadSafeColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available space and adjust accordingly
        final availableHeight = constraints.maxHeight;
        final itemHeight = availableHeight / children.length;

        // Use Flex with proper constraints for iPads
        return Flex(
          direction: Axis.vertical,
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: children.asMap().entries.map((entry) {
            final child = entry.value;

            return Flexible(
              flex: 1,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      itemHeight > 0 ? itemHeight * 0.9 : double.infinity,
                ),
                child: child,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// iPad-optimized Row widget
class IPadSafeRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const IPadSafeRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: children.map((child) => Flexible(child: child)).toList(),
        );
      },
    );
  }
}

/// iPad-optimized navigation item
class IPadSafeNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;

  const IPadSafeNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: ResponsiveHelper.getIPadSafeConstraints(context,
              minHeight: 60, maxHeight: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: selected
                ? BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFC107),
                        Color(0xFFE8C547),
                        Color(0xFFD0E6A5),
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
                ? ResponsiveHelper.getIPadSafePadding(context,
                    mobile: 2, ipad: 6, ipadPro: 8)
                : EdgeInsets.zero,
            child: Padding(
              padding: ResponsiveHelper.getIPadSafePadding(context,
                  mobile: 4, ipad: 8, ipadPro: 10),
              child: IPadSafeColumn(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: ResponsiveHelper.getIPadSafeIconSize(context,
                        mobile: 18, ipad: 26, ipadPro: 30),
                    color: selected ? selectedColor : unselectedColor,
                  ),
                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacingIPad(context,
                          mobile: 2,
                          tablet: 3,
                          ipad: 4,
                          ipadPro: 5,
                          desktop: 4)),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getIPadSafeFontSize(context,
                          mobile: 10, ipad: 12, ipadPro: 13),
                      fontWeight: FontWeight.w600,
                      color: selected ? selectedColor : unselectedColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// Enhanced bottom navigation bar specifically for iPad
class IPadOptimizedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const IPadOptimizedBottomNavBar({
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
              ipad: 32,
              ipadPro: 36,
              desktop: 32)),
          topRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(
              context,
              mobile: 24,
              tablet: 28,
              ipad: 32,
              ipadPro: 36,
              desktop: 32)),
        ),
        boxShadow: ResponsiveHelper.getResponsiveShadow(context),
        border: Border(
          top: BorderSide(
              color: const Color(0xFFF3F6EA),
              width: ResponsiveHelper.getResponsiveStrokeWidth(context)),
        ),
      ),
      padding: ResponsiveHelper.getIPadSafePadding(context,
          mobile: 8, ipad: 16, ipadPro: 20),
      child: SafeArea(
        top: false,
        child: IPadSafeRow(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IPadSafeNavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              selected: currentIndex == 0,
              onTap: () => onTap(0),
              selectedColor: const Color(0xFF23281A),
              unselectedColor: const Color(0xFF9EB06A),
            ),
            IPadSafeNavItem(
              icon: Icons.directions_car,
              label: 'My Requests',
              selected: currentIndex == 1,
              onTap: () => onTap(1),
              selectedColor: const Color(0xFF23281A),
              unselectedColor: const Color(0xFF9EB06A),
            ),
            IPadSafeNavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              selected: currentIndex == 2,
              onTap: () => onTap(2),
              selectedColor: const Color(0xFF23281A),
              unselectedColor: const Color(0xFF9EB06A),
            ),
          ],
        ),
      ),
    );
  }
}
