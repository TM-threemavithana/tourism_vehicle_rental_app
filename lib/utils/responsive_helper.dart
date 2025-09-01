import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Enhanced breakpoints for better responsive design
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;

  static bool isLargeTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1600;

  // Enhanced device detection methods
  static bool isIPad(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    // iPad detection based on logical pixels and aspect ratio
    final minDimension = size.shortestSide;
    final maxDimension = size.longestSide;
    final aspectRatio = maxDimension / minDimension;

    return minDimension >= 768 &&
        aspectRatio >= 1.3 &&
        aspectRatio <= 1.6 &&
        devicePixelRatio >= 1.5;
  }

  static bool isIPadPro(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    // iPad Pro detection - larger screen with high DPI
    final minDimension = size.shortestSide;
    return minDimension >= 1024 && devicePixelRatio >= 2.0;
  }

  static bool isIPadAir(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final minDimension = size.shortestSide;
    final maxDimension = size.longestSide;

    return minDimension >= 820 && minDimension < 1024 && maxDimension >= 1180;
  }

  // Get current device type as string for debugging
  static String getDeviceType(BuildContext context) {
    if (isIPadPro(context)) return 'iPad Pro';
    if (isIPadAir(context)) return 'iPad Air';
    if (isIPad(context)) return 'iPad';
    if (isLargeDesktop(context)) return 'Large Desktop';
    if (isDesktop(context)) return 'Desktop';
    if (isLargeTablet(context)) return 'Large Tablet';
    if (isTablet(context)) return 'Tablet';
    return 'Mobile';
  }

  // Enhanced responsive sizing with consistent parameters
  static double getResponsiveFontSize(
    BuildContext context, {
    double mobile = 14,
    double tablet = 16,
    double largeTablet = 17,
    double ipad = 18,
    double ipadPro = 20,
    double desktop = 18,
    double largeDesktop = 20,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    if (isLargeTablet(context)) return largeTablet;
    if (isIPad(context)) return ipad;
    if (isIPadPro(context)) return ipadPro;
    if (isLargeDesktop(context)) return largeDesktop;
    return desktop;
  }

  static double getResponsiveIconSize(
    BuildContext context, {
    double mobile = 24,
    double tablet = 28,
    double largeTablet = 30,
    double ipad = 32,
    double ipadPro = 36,
    double desktop = 32,
    double largeDesktop = 40,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    if (isLargeTablet(context)) return largeTablet;
    if (isIPad(context)) return ipad;
    if (isIPadPro(context)) return ipadPro;
    if (isLargeDesktop(context)) return largeDesktop;
    return desktop;
  }

  // Enhanced responsive padding with consistent parameters
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double largeTablet = 28,
    double ipad = 32,
    double ipadPro = 40,
    double desktop = 32,
    double largeDesktop = 48,
  }) {
    final value = _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
    return EdgeInsets.all(value);
  }

  static EdgeInsets getResponsiveHorizontalPadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 32,
    double largeTablet = 40,
    double ipad = 48,
    double ipadPro = 64,
    double desktop = 64,
    double largeDesktop = 80,
  }) {
    final value = _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
    return EdgeInsets.symmetric(horizontal: value);
  }

  static EdgeInsets getResponsiveVerticalPadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double largeTablet = 28,
    double ipad = 32,
    double ipadPro = 40,
    double desktop = 32,
    double largeDesktop = 48,
  }) {
    final value = _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
    return EdgeInsets.symmetric(vertical: value);
  }

  // Helper method to get responsive values consistently
  static double _getResponsiveValue(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double largeTablet,
    required double ipad,
    required double ipadPro,
    required double desktop,
    required double largeDesktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    if (isLargeTablet(context)) return largeTablet;
    if (isIPad(context)) return ipad;
    if (isIPadPro(context)) return ipadPro;
    if (isLargeDesktop(context)) return largeDesktop;
    return desktop;
  }

  // Enhanced responsive spacing
  static double getResponsiveSpacing(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double largeTablet = 28,
    double ipad = 32,
    double ipadPro = 40,
    double desktop = 32,
    double largeDesktop = 48,
  }) {
    return _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  // Enhanced responsive container sizing
  static double getResponsiveContainerWidth(
    BuildContext context, {
    double mobile = 0.9,
    double tablet = 0.8,
    double largeTablet = 0.75,
    double ipad = 0.7,
    double ipadPro = 0.65,
    double desktop = 0.6,
    double largeDesktop = 0.5,
  }) {
    final multiplier = _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
    return MediaQuery.of(context).size.width * multiplier;
  }

  static double getResponsiveContainerHeight(
    BuildContext context, {
    double mobile = 0.8,
    double tablet = 0.7,
    double largeTablet = 0.65,
    double ipad = 0.6,
    double ipadPro = 0.55,
    double desktop = 0.5,
    double largeDesktop = 0.45,
  }) {
    final multiplier = _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
    return MediaQuery.of(context).size.height * multiplier;
  }

  // Enhanced responsive sizing methods
  static double getResponsiveCardHeight(
    BuildContext context, {
    double mobile = 200,
    double tablet = 250,
    double largeTablet = 275,
    double ipad = 300,
    double ipadPro = 350,
    double desktop = 300,
    double largeDesktop = 400,
  }) {
    return _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  static double getResponsiveImageSize(
    BuildContext context, {
    double mobile = 100,
    double tablet = 140,
    double largeTablet = 150,
    double ipad = 160,
    double ipadPro = 180,
    double desktop = 160,
    double largeDesktop = 200,
  }) {
    return _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  static double getResponsiveProfileSize(
    BuildContext context, {
    double mobile = 70,
    double tablet = 100,
    double largeTablet = 110,
    double ipad = 120,
    double ipadPro = 140,
    double desktop = 120,
    double largeDesktop = 160,
  }) {
    return _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  // Enhanced responsive button sizing
  static EdgeInsets getResponsiveButtonPadding(
    BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? largeTablet,
    EdgeInsets? ipad,
    EdgeInsets? ipadPro,
    EdgeInsets? desktop,
    EdgeInsets? largeDesktop,
  }) {
    mobile ??= const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    tablet ??= const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    largeTablet ??= const EdgeInsets.symmetric(horizontal: 26, vertical: 13);
    ipad ??= const EdgeInsets.symmetric(horizontal: 28, vertical: 14);
    ipadPro ??= const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    desktop ??= const EdgeInsets.symmetric(horizontal: 28, vertical: 14);
    largeDesktop ??= const EdgeInsets.symmetric(horizontal: 36, vertical: 18);

    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    if (isLargeTablet(context)) return largeTablet;
    if (isIPad(context)) return ipad;
    if (isIPadPro(context)) return ipadPro;
    if (isLargeDesktop(context)) return largeDesktop;
    return desktop;
  }

  static double getResponsiveButtonHeight(
    BuildContext context, {
    double mobile = 48,
    double tablet = 52,
    double largeTablet = 54,
    double ipad = 56,
    double ipadPro = 60,
    double desktop = 52,
    double largeDesktop = 64,
  }) {
    return _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  // Enhanced responsive grid and layout
  static int getResponsiveGridColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int largeTablet = 2,
    int ipad = 3,
    int ipadPro = 3,
    int desktop = 3,
    int largeDesktop = 4,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    if (isLargeTablet(context)) return largeTablet;
    if (isIPad(context)) return ipad;
    if (isIPadPro(context)) return ipadPro;
    if (isLargeDesktop(context)) return largeDesktop;
    return desktop;
  }

  static double getResponsiveAspectRatio(
    BuildContext context, {
    double mobile = 2.5,
    double tablet = 3.0,
    double largeTablet = 3.2,
    double ipad = 3.5,
    double ipadPro = 4.0,
    double desktop = 3.5,
    double largeDesktop = 4.5,
  }) {
    return _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  static double getResponsiveBorderRadius(
    BuildContext context, {
    double mobile = 15,
    double tablet = 20,
    double largeTablet = 22,
    double ipad = 25,
    double ipadPro = 30,
    double desktop = 25,
    double largeDesktop = 35,
  }) {
    return _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  // Enhanced responsive shadow
  static List<BoxShadow> getResponsiveShadow(
    BuildContext context, {
    double mobile = 4,
    double tablet = 6,
    double largeTablet = 7,
    double ipad = 8,
    double ipadPro = 10,
    double desktop = 8,
    double largeDesktop = 12,
  }) {
    final blurRadius = _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: blurRadius,
        offset: Offset(0, blurRadius * 0.25),
        spreadRadius: blurRadius * 0.1,
      ),
    ];
  }

  // New responsive methods for better UI control
  static double getResponsiveElevation(
    BuildContext context, {
    double mobile = 2,
    double tablet = 4,
    double largeTablet = 5,
    double ipad = 6,
    double ipadPro = 8,
    double desktop = 6,
    double largeDesktop = 10,
  }) {
    return _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  static double getResponsiveStrokeWidth(
    BuildContext context, {
    double mobile = 1,
    double tablet = 1.5,
    double largeTablet = 1.5,
    double ipad = 2,
    double ipadPro = 2.5,
    double desktop = 2,
    double largeDesktop = 3,
  }) {
    return _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  // iPad-specific responsive methods (maintained for backward compatibility)
  static double getResponsiveFontSizeIPad(
    BuildContext context, {
    double mobile = 14,
    double tablet = 16,
    double largeTablet = 17,
    double ipad = 18,
    double ipadPro = 20,
    double desktop = 18,
    double largeDesktop = 22,
  }) {
    return getResponsiveFontSize(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  static EdgeInsets getResponsivePaddingIPad(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double largeTablet = 28,
    double ipad = 32,
    double ipadPro = 40,
    double desktop = 32,
    double largeDesktop = 48,
  }) {
    return getResponsivePadding(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  static double getResponsiveSpacingIPad(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double largeTablet = 28,
    double ipad = 32,
    double ipadPro = 40,
    double desktop = 32,
    double largeDesktop = 48,
  }) {
    return getResponsiveSpacing(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  // Enhanced safe area handling
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.padding;
    final baseMultiplier = isMobile(context)
        ? 1.0
        : isTablet(context)
            ? 1.2
            : isLargeTablet(context)
                ? 1.3
                : isIPad(context)
                    ? 1.5
                    : isIPadPro(context)
                        ? 2.0
                        : 1.8;

    return EdgeInsets.only(
      top: padding.top + (10 * baseMultiplier),
      bottom: padding.bottom + (10 * baseMultiplier),
      left: padding.left + (20 * baseMultiplier),
      right: padding.right + (20 * baseMultiplier),
    );
  }

  // Enhanced card and image sizing for iPad
  static double getResponsiveCardHeightIPad(
    BuildContext context, {
    double mobile = 200,
    double tablet = 250,
    double largeTablet = 275,
    double ipad = 300,
    double ipadPro = 350,
    double desktop = 320,
    double largeDesktop = 400,
  }) {
    return getResponsiveCardHeight(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  static double getResponsiveImageSizeIPad(
    BuildContext context, {
    double mobile = 100,
    double tablet = 140,
    double largeTablet = 160,
    double ipad = 180,
    double ipadPro = 220,
    double desktop = 200,
    double largeDesktop = 260,
  }) {
    return getResponsiveImageSize(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  // Additional utility methods for comprehensive responsiveness
  static double getResponsiveMaxWidth(
    BuildContext context, {
    double mobile = double.infinity,
    double tablet = 600,
    double largeTablet = 800,
    double ipad = 1000,
    double ipadPro = 1200,
    double desktop = 1000,
    double largeDesktop = 1400,
  }) {
    return _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  static bool shouldUseTabletLayout(BuildContext context) {
    return isTablet(context) ||
        isLargeTablet(context) ||
        isIPad(context) ||
        isIPadPro(context) ||
        isDesktop(context);
  }

  static bool shouldUseMobileLayout(BuildContext context) {
    return isMobile(context);
  }

  static bool shouldUseDesktopLayout(BuildContext context) {
    return isDesktop(context) || isLargeDesktop(context);
  }

  // Enhanced layout builders for better responsive design
  static Widget responsiveBuilder(
    BuildContext context, {
    required Widget mobile,
    Widget? tablet,
    Widget? largeTablet,
    Widget? ipad,
    Widget? ipadPro,
    Widget? desktop,
    Widget? largeDesktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? mobile;
    if (isLargeTablet(context)) return largeTablet ?? tablet ?? mobile;
    if (isIPad(context)) return ipad ?? largeTablet ?? tablet ?? mobile;
    if (isIPadPro(context)) {
      return ipadPro ?? ipad ?? largeTablet ?? tablet ?? mobile;
    }
    if (isDesktop(context)) {
      return desktop ?? ipadPro ?? ipad ?? largeTablet ?? tablet ?? mobile;
    }
    if (isLargeDesktop(context)) {
      return largeDesktop ??
          desktop ??
          ipadPro ??
          ipad ??
          largeTablet ??
          tablet ??
          mobile;
    }
    return mobile;
  }

  // Responsive text scaling
  static double getResponsiveTextScale(BuildContext context) {
    if (isMobile(context)) return 1.0;
    if (isTablet(context)) return 1.1;
    if (isLargeTablet(context)) return 1.15;
    if (isIPad(context)) return 1.2;
    if (isIPadPro(context)) return 1.3;
    if (isDesktop(context)) return 1.2;
    if (isLargeDesktop(context)) return 1.4;
    return 1.0;
  }

  // Safe responsive sizing that accounts for device limitations
  static double getResponsiveSafeSize(
    BuildContext context,
    double size, {
    double? maxMobile,
    double? maxTablet,
    double? maxDesktop,
  }) {
    final deviceSize = size;

    if (isMobile(context) && maxMobile != null) {
      return deviceSize > maxMobile ? maxMobile : deviceSize;
    }
    if ((isTablet(context) || isLargeTablet(context) || isIPad(context)) &&
        maxTablet != null) {
      return deviceSize > maxTablet ? maxTablet : deviceSize;
    }
    if ((isDesktop(context) || isLargeDesktop(context)) && maxDesktop != null) {
      return deviceSize > maxDesktop ? maxDesktop : deviceSize;
    }

    return deviceSize;
  }

  // Overflow prevention utilities
  static EdgeInsets getResponsiveSafePadding(
    BuildContext context, {
    double mobile = 8,
    double tablet = 12,
    double largeTablet = 14,
    double ipad = 16,
    double ipadPro = 20,
    double desktop = 16,
    double largeDesktop = 24,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final value = _getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );

    // Ensure padding doesn't exceed 10% of screen dimensions
    final maxPadding = (screenWidth * 0.1).clamp(8.0, value);
    final safePadding = value > maxPadding ? maxPadding : value;

    return EdgeInsets.all(safePadding);
  }

  static double getResponsiveSafeIconSize(
    BuildContext context, {
    double mobile = 20,
    double tablet = 24,
    double largeTablet = 26,
    double ipad = 28,
    double ipadPro = 32,
    double desktop = 28,
    double largeDesktop = 36,
  }) {
    final iconSize = getResponsiveIconSize(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );

    // Ensure icon size doesn't exceed reasonable bounds
    return iconSize.clamp(16.0, 48.0);
  }

  static double getResponsiveSafeFontSize(
    BuildContext context, {
    double mobile = 12,
    double tablet = 14,
    double largeTablet = 15,
    double ipad = 16,
    double ipadPro = 18,
    double desktop = 16,
    double largeDesktop = 20,
  }) {
    final fontSize = getResponsiveFontSize(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      ipad: ipad,
      ipadPro: ipadPro,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );

    // Ensure font size is within readable bounds
    return fontSize.clamp(10.0, 32.0);
  }

  // Flexible layout utilities
  static Widget buildFlexibleLayout({
    required BuildContext context,
    required List<Widget> children,
    bool horizontal = false,
    MainAxisAlignment? mainAxisAlignment,
    CrossAxisAlignment? crossAxisAlignment,
    bool preventOverflow = true,
  }) {
    if (preventOverflow) {
      return Flexible(
        child: horizontal
            ? Row(
                mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
                crossAxisAlignment:
                    crossAxisAlignment ?? CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children:
                    children.map((child) => Flexible(child: child)).toList(),
              )
            : Column(
                mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
                crossAxisAlignment:
                    crossAxisAlignment ?? CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children:
                    children.map((child) => Flexible(child: child)).toList(),
              ),
      );
    } else {
      return horizontal
          ? Row(
              mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
              crossAxisAlignment:
                  crossAxisAlignment ?? CrossAxisAlignment.center,
              children: children,
            )
          : Column(
              mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
              crossAxisAlignment:
                  crossAxisAlignment ?? CrossAxisAlignment.center,
              children: children,
            );
    }
  }

  // Screen dimension utilities
  static bool hasEnoughVerticalSpace(
      BuildContext context, double requiredHeight) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaHeight = MediaQuery.of(context).padding.top +
        MediaQuery.of(context).padding.bottom;
    final availableHeight = screenHeight - safeAreaHeight;
    return availableHeight >= requiredHeight;
  }

  static bool hasEnoughHorizontalSpace(
      BuildContext context, double requiredWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaWidth = MediaQuery.of(context).padding.left +
        MediaQuery.of(context).padding.right;
    final availableWidth = screenWidth - safeAreaWidth;
    return availableWidth >= requiredWidth;
  }

  // Dynamic spacing based on available screen space
  static double getDynamicSpacing(
    BuildContext context, {
    double minSpacing = 4,
    double maxSpacing = 24,
    double screenSizeRatio = 0.02,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dynamicSpacing = screenHeight * screenSizeRatio;
    return dynamicSpacing.clamp(minSpacing, maxSpacing);
  }
}
