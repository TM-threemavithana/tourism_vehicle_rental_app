import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// A responsive layout widget that adapts to different screen sizes
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.responsiveBuilder(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
}

/// A responsive container that provides consistent spacing and layout
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? ResponsiveHelper.getResponsiveMaxWidth(context),
      ),
      margin: ResponsiveHelper.getResponsiveHorizontalPadding(context),
      padding: padding ?? ResponsiveHelper.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ??
            BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context),
            ),
        boxShadow: boxShadow ?? ResponsiveHelper.getResponsiveShadow(context),
      ),
      child: child,
    );
  }
}

/// A responsive grid widget that adapts column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? childAspectRatio;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final EdgeInsets? padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.childAspectRatio,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getResponsiveGridColumns(context);

    return Padding(
      padding: padding ?? ResponsiveHelper.getResponsivePadding(context),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio ??
              ResponsiveHelper.getResponsiveAspectRatio(context),
          mainAxisSpacing:
              mainAxisSpacing ?? ResponsiveHelper.getResponsiveSpacing(context),
          crossAxisSpacing: crossAxisSpacing ??
              ResponsiveHelper.getResponsiveSpacing(context),
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

/// A responsive card widget with consistent styling
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? elevation;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation ?? ResponsiveHelper.getResponsiveElevation(context),
      color: backgroundColor,
      margin: margin ?? ResponsiveHelper.getResponsivePadding(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context),
        ),
      ),
      child: Padding(
        padding: padding ?? ResponsiveHelper.getResponsivePadding(context),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context),
        ),
        child: card,
      );
    }

    return card;
  }
}

/// A responsive text widget with automatic scaling
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool autoScale;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.autoScale = true,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle finalStyle = style ?? const TextStyle();

    if (autoScale && finalStyle.fontSize != null) {
      final scaledFontSize = finalStyle.fontSize! *
          ResponsiveHelper.getResponsiveTextScale(context);
      finalStyle = finalStyle.copyWith(fontSize: scaledFontSize);
    }

    return Text(
      text,
      style: finalStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// A responsive button that adapts its size and padding
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  final bool isLoading;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final ButtonStyle finalStyle = ElevatedButton.styleFrom(
      padding: ResponsiveHelper.getResponsiveButtonPadding(context),
      minimumSize: Size(
        ResponsiveHelper.getResponsiveContainerWidth(context, mobile: 0.8) *
            MediaQuery.of(context).size.width,
        ResponsiveHelper.getResponsiveButtonHeight(context),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context),
        ),
      ),
      textStyle: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveFontSize(context),
        fontWeight: FontWeight.bold,
      ),
    ).merge(style);

    Widget buttonChild = isLoading
        ? SizedBox(
            width: ResponsiveHelper.getResponsiveIconSize(context, mobile: 20),
            height: ResponsiveHelper.getResponsiveIconSize(context, mobile: 20),
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(text);

    if (icon != null && !isLoading) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: finalStyle,
        icon: icon!,
        label: Text(text),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: finalStyle,
      child: buttonChild,
    );
  }
}

/// A responsive scaffold with consistent app bar and layout
class ResponsiveScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final bool showAppBar;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;

  const ResponsiveScaffold({
    super.key,
    this.title,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.showAppBar = true,
    this.actions,
    this.leading,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: showAppBar
          ? AppBar(
              title: title != null
                  ? ResponsiveText(
                      title!,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
              leading: leading,
              actions: actions,
              elevation: ResponsiveHelper.getResponsiveElevation(context),
            )
          : null,
      body: SafeArea(
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
    );
  }
}
