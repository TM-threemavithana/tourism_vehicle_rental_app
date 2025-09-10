import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// Comprehensive iPad-responsive screen wrapper
class IPadResponsiveScreen extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool useMaxWidth;
  final bool preventOverflow;
  final Color? backgroundColor;

  const IPadResponsiveScreen({
    super.key,
    required this.child,
    this.padding,
    this.useMaxWidth = true,
    this.preventOverflow = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Apply responsive padding
    final screenPadding = padding ??
        ResponsiveHelper.getResponsivePaddingIPad(
          context,
          mobile: 16,
          tablet: 24,
          ipad: 32,
          ipadPro: 40,
          desktop: 48,
        );

    // Center content with max width on larger screens
    if (useMaxWidth) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.getResponsiveMaxWidth(context,
                mobile: double.infinity,
                tablet: 800,
                ipad: 900,
                ipadPro: 1000,
                desktop: 1200),
          ),
          child: content,
        ),
      );
    }

    // Apply padding
    content = Padding(
      padding: screenPadding,
      child: content,
    );

    // Wrap in overflow-safe container if needed
    if (preventOverflow) {
      content = SingleChildScrollView(
        child: content,
      );
    }

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: content,
      ),
    );
  }
}

/// iPad-responsive card that adapts to screen size
class IPadResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;

  const IPadResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ??
          ResponsiveHelper.getResponsiveElevation(context,
              mobile: 2, tablet: 4, ipad: 6, ipadPro: 8, desktop: 6),
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ??
            BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context,
                  mobile: 12, tablet: 16, ipad: 20, ipadPro: 24, desktop: 20),
            ),
      ),
      margin: margin ??
          ResponsiveHelper.getResponsivePaddingIPad(context,
              mobile: 8, tablet: 12, ipad: 16, ipadPro: 20, desktop: 16),
      child: Padding(
        padding: padding ??
            ResponsiveHelper.getResponsivePaddingIPad(context,
                mobile: 16, tablet: 20, ipad: 24, ipadPro: 28, desktop: 24),
        child: child,
      ),
    );
  }
}

/// iPad-responsive grid that adjusts columns based on screen size
class IPadResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? childAspectRatio;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const IPadResponsiveGrid({
    super.key,
    required this.children,
    this.childAspectRatio,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.padding,
    this.shrinkWrap = true,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getResponsiveGridColumns(context,
        mobile: 1, tablet: 2, ipad: 2, ipadPro: 3, desktop: 3);

    return Padding(
      padding: padding ??
          ResponsiveHelper.getResponsivePaddingIPad(context,
              mobile: 8, tablet: 12, ipad: 16, ipadPro: 20, desktop: 16),
      child: GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: physics ?? const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio ??
              ResponsiveHelper.getResponsiveAspectRatio(context,
                  mobile: 1.0,
                  tablet: 1.2,
                  ipad: 1.3,
                  ipadPro: 1.4,
                  desktop: 1.5),
          mainAxisSpacing: mainAxisSpacing ??
              ResponsiveHelper.getResponsiveSpacingIPad(context,
                  mobile: 8, tablet: 12, ipad: 16, ipadPro: 20, desktop: 16),
          crossAxisSpacing: crossAxisSpacing ??
              ResponsiveHelper.getResponsiveSpacingIPad(context,
                  mobile: 8, tablet: 12, ipad: 16, ipadPro: 20, desktop: 16),
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

/// iPad-responsive text that scales appropriately
class IPadResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool autoScale;

  const IPadResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.autoScale = true,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle effectiveStyle = style ?? Theme.of(context).textTheme.bodyMedium!;

    if (autoScale) {
      final baseFontSize = effectiveStyle.fontSize ?? 14.0;
      final responsiveFontSize = ResponsiveHelper.getResponsiveFontSizeIPad(
        context,
        mobile: baseFontSize,
        tablet: baseFontSize * 1.1,
        ipad: baseFontSize * 1.2,
        ipadPro: baseFontSize * 1.3,
        desktop: baseFontSize * 1.2,
      );

      effectiveStyle = effectiveStyle.copyWith(fontSize: responsiveFontSize);
    }

    return Text(
      text,
      style: effectiveStyle,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }
}

/// iPad-responsive button that adapts size and padding
class IPadResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool isLoading;
  final IconData? icon;

  const IPadResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = style ??
        ElevatedButton.styleFrom(
          padding: ResponsiveHelper.getResponsiveButtonPadding(context,
              mobile: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              tablet: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              ipad: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              ipadPro: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
              desktop:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 40)),
          minimumSize: Size.fromHeight(
              ResponsiveHelper.getResponsiveButtonHeight(context,
                  mobile: 48, tablet: 56, ipad: 64, ipadPro: 72, desktop: 64)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context,
                  mobile: 8, tablet: 12, ipad: 16, ipadPro: 20, desktop: 16),
            ),
          ),
        );

    if (isLoading) {
      return ElevatedButton(
        onPressed: null,
        style: buttonStyle,
        child: SizedBox(
          height: ResponsiveHelper.getResponsiveIconSize(context,
              mobile: 20, tablet: 24, ipad: 28, ipadPro: 32, desktop: 28),
          width: ResponsiveHelper.getResponsiveIconSize(context,
              mobile: 20, tablet: 24, ipad: 28, ipadPro: 32, desktop: 28),
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: buttonStyle,
        icon: Icon(
          icon,
          size: ResponsiveHelper.getResponsiveIconSize(context,
              mobile: 18, tablet: 20, ipad: 24, ipadPro: 28, desktop: 24),
        ),
        label: IPadResponsiveText(
          text,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                mobile: 14, tablet: 16, ipad: 18, ipadPro: 20, desktop: 18),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: IPadResponsiveText(
        text,
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
              mobile: 14, tablet: 16, ipad: 18, ipadPro: 20, desktop: 18),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
