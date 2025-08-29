import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static bool isLargeTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900 &&
      MediaQuery.of(context).size.width < 1200;

  // Responsive sizing
  static double getResponsiveFontSize(
    BuildContext context, {
    double mobile = 14,
    double tablet = 16,
    double desktop = 18,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getResponsiveIconSize(
    BuildContext context, {
    double mobile = 24,
    double tablet = 28,
    double desktop = 32,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive padding
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    if (isMobile(context)) return EdgeInsets.all(mobile);
    if (isTablet(context)) return EdgeInsets.all(tablet);
    return EdgeInsets.all(desktop);
  }

  static EdgeInsets getResponsiveHorizontalPadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 32,
    double desktop = 48,
  }) {
    if (isMobile(context)) return EdgeInsets.symmetric(horizontal: mobile);
    if (isTablet(context)) return EdgeInsets.symmetric(horizontal: tablet);
    return EdgeInsets.symmetric(horizontal: desktop);
  }

  // Responsive spacing
  static double getResponsiveSpacing(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive container sizing
  static double getResponsiveContainerWidth(
    BuildContext context, {
    double mobile = 0.9,
    double tablet = 0.8,
    double desktop = 0.7,
  }) {
    return MediaQuery.of(context).size.width *
        (isMobile(context)
            ? mobile
            : isTablet(context)
                ? tablet
                : desktop);
  }

  // Responsive card sizing
  static double getResponsiveCardHeight(
    BuildContext context, {
    double mobile = 200,
    double tablet = 250,
    double desktop = 300,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive image sizing
  static double getResponsiveImageSize(
    BuildContext context, {
    double mobile = 100,
    double tablet = 140,
    double desktop = 180,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive profile picture sizing
  static double getResponsiveProfileSize(
    BuildContext context, {
    double mobile = 70,
    double tablet = 100,
    double desktop = 120,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive button sizing
  static EdgeInsets getResponsiveButtonPadding(
    BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    mobile ??= const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    tablet ??= const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    desktop ??= const EdgeInsets.symmetric(horizontal: 32, vertical: 16);

    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive grid columns
  static int getResponsiveGridColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive aspect ratio
  static double getResponsiveAspectRatio(
    BuildContext context, {
    double mobile = 2.5,
    double tablet = 3.0,
    double desktop = 3.5,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive border radius
  static double getResponsiveBorderRadius(
    BuildContext context, {
    double mobile = 15,
    double tablet = 20,
    double desktop = 25,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive shadow
  static List<BoxShadow> getResponsiveShadow(
    BuildContext context, {
    double mobile = 4,
    double tablet = 6,
    double desktop = 8,
  }) {
    final blurRadius = isMobile(context)
        ? mobile
        : isTablet(context)
            ? tablet
            : desktop;

    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: blurRadius,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
