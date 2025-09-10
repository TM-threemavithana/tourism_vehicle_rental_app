import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// A comprehensive responsive scaffold that prevents overflow and adapts to all devices
class ResponsiveScaffoldNew extends StatelessWidget {
  final Widget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final EdgeInsets? padding;
  final bool safeArea;

  const ResponsiveScaffoldNew({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.padding,
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget = body;

    // Add responsive padding if specified
    if (padding != null) {
      bodyWidget = Padding(padding: padding!, child: bodyWidget);
    } else {
      // Apply default responsive padding
      bodyWidget = Padding(
        padding: ResponsiveHelper.getResponsiveSafePadding(context),
        child: bodyWidget,
      );
    }

    // Wrap in SafeArea if requested
    if (safeArea) {
      bodyWidget = SafeArea(child: bodyWidget);
    }

    // Wrap in SingleChildScrollView to prevent overflow
    bodyWidget = SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              (appBar != null ? AppBar().preferredSize.height : 0) -
              (bottomNavigationBar != null ? 80 : 0) -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom,
        ),
        child: IntrinsicHeight(child: bodyWidget),
      ),
    );

    return Scaffold(
      appBar: appBar as PreferredSizeWidget?,
      body: bodyWidget,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}

/// A responsive column that prevents overflow
class ResponsiveColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool preventOverflow;
  final EdgeInsets? padding;

  const ResponsiveColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.preventOverflow = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> processedChildren = children;

    if (preventOverflow) {
      processedChildren =
          children.map((child) => Flexible(child: child)).toList();
    }

    Widget columnWidget = Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: processedChildren,
    );

    if (padding != null) {
      columnWidget = Padding(padding: padding!, child: columnWidget);
    }

    return columnWidget;
  }
}

/// A responsive row that prevents overflow
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool preventOverflow;
  final EdgeInsets? padding;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.preventOverflow = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> processedChildren = children;

    if (preventOverflow) {
      processedChildren =
          children.map((child) => Flexible(child: child)).toList();
    }

    Widget rowWidget = Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: processedChildren,
    );

    if (padding != null) {
      rowWidget = Padding(padding: padding!, child: rowWidget);
    }

    return rowWidget;
  }
}

/// A responsive text widget that prevents overflow
class ResponsiveTextNew extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign textAlign;
  final bool autoSize;

  const ResponsiveTextNew(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign = TextAlign.start,
    this.autoSize = true,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle effectiveStyle = style ?? Theme.of(context).textTheme.bodyMedium!;

    if (autoSize) {
      // Apply responsive font size if not explicitly set
      effectiveStyle = effectiveStyle.copyWith(
        fontSize: ResponsiveHelper.getResponsiveSafeFontSize(
          context,
          mobile: effectiveStyle.fontSize ?? 14,
          tablet: (effectiveStyle.fontSize ?? 14) * 1.1,
          desktop: (effectiveStyle.fontSize ?? 14) * 1.2,
        ),
      );
    }

    return Text(
      text,
      style: effectiveStyle,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

/// A responsive container that adapts to screen size
class ResponsiveContainerNew extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final BoxDecoration? decoration;
  final bool adaptiveWidth;
  final bool adaptiveHeight;

  const ResponsiveContainerNew({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.decoration,
    this.adaptiveWidth = true,
    this.adaptiveHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    double? effectiveWidth = width;
    double? effectiveHeight = height;

    if (adaptiveWidth && width != null) {
      effectiveWidth = ResponsiveHelper.getResponsiveSafeSize(
        context,
        width!,
        maxMobile: MediaQuery.of(context).size.width * 0.9,
        maxTablet: MediaQuery.of(context).size.width * 0.8,
        maxDesktop: MediaQuery.of(context).size.width * 0.7,
      );
    }

    if (adaptiveHeight && height != null) {
      effectiveHeight = ResponsiveHelper.getResponsiveSafeSize(
        context,
        height!,
        maxMobile: MediaQuery.of(context).size.height * 0.8,
        maxTablet: MediaQuery.of(context).size.height * 0.7,
        maxDesktop: MediaQuery.of(context).size.height * 0.6,
      );
    }

    return Container(
      width: effectiveWidth,
      height: effectiveHeight,
      padding: padding ?? ResponsiveHelper.getResponsiveSafePadding(context),
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }
}

/// A responsive card that adapts to screen size
class ResponsiveCardNew extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  final Color? color;
  final ShapeBorder? shape;

  const ResponsiveCardNew({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.color,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? ResponsiveHelper.getResponsiveElevation(context),
      color: color,
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context),
            ),
          ),
      margin: margin ?? ResponsiveHelper.getResponsiveSafePadding(context),
      child: Padding(
        padding: padding ?? ResponsiveHelper.getResponsiveSafePadding(context),
        child: child,
      ),
    );
  }
}

/// A responsive list tile that prevents overflow
class ResponsiveListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? contentPadding;
  final bool dense;

  const ResponsiveListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      dense: dense,
      contentPadding:
          contentPadding ?? ResponsiveHelper.getResponsiveSafePadding(context),
      // Ensure text doesn't overflow
      titleTextStyle: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveSafeFontSize(context),
        overflow: TextOverflow.ellipsis,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveSafeFontSize(
          context,
          mobile: 12,
          tablet: 13,
          desktop: 14,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
