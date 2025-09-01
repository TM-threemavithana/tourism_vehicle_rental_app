import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// iPad-optimized bottom navigation bar that prevents overflow
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
        border: Border(
          top: BorderSide(
            color: const Color(0xFF9EB06A).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      // Reduced padding for iPad to prevent overflow
      padding: EdgeInsets.only(
        left: ResponsiveHelper.isIPadPro12_9(context) ? 16 : 12,
        right: ResponsiveHelper.isIPadPro12_9(context) ? 16 : 12,
        top: 8,
        bottom: ResponsiveHelper.isIPadPro12_9(context) ? 12 : 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildOptimizedNavItem(
            context: context,
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _buildOptimizedNavItem(
            context: context,
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment,
            label: 'My Requests',
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _buildOptimizedNavItem(
            context: context,
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
            selected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final Color selectedColor = const Color(0xFF23281A);
    final Color unselectedColor = const Color(0xFF9EB06A);

    // iPad-specific sizing to prevent overflow
    final bool isLargeIPad = ResponsiveHelper.isIPadPro12_9(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          // Fixed height that works across all iPad sizes
          height: isLargeIPad ? 70 : 60,
          padding: EdgeInsets.symmetric(
            horizontal: isLargeIPad ? 8 : 6,
            vertical: isLargeIPad ? 8 : 6,
          ),
          decoration: selected
              ? BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE6F0C2),
                      Color(0xFFD0E6A5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isLargeIPad ? 20 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: isLargeIPad ? 8 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          margin: EdgeInsets.symmetric(
            horizontal: isLargeIPad ? 4 : 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: isLargeIPad ? 24 : 20,
                color: selected ? selectedColor : unselectedColor,
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isLargeIPad ? 11 : 10,
                    fontWeight: FontWeight.w600,
                    color: selected ? selectedColor : unselectedColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
