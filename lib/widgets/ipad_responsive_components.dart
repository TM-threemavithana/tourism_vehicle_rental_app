import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// iPad-optimized app bar that adapts to different screen sizes
class IPadResponsiveAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool centerTitle;
  final TextStyle? titleTextStyle;

  const IPadResponsiveAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
    this.titleTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null
          ? Text(
              title!,
              style: titleTextStyle ??
                  TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(
                        context,
                        mobile: 18,
                        tablet: 20,
                        ipad: 22,
                        ipadPro: 24,
                        desktop: 22),
                    fontWeight: FontWeight.w600,
                    color: foregroundColor,
                  ),
            )
          : null,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      toolbarHeight: ResponsiveHelper.getResponsiveContainerHeight(context,
          mobile: 56, tablet: 64, ipad: 72, ipadPro: 80, desktop: 72),
      titleSpacing: ResponsiveHelper.getResponsiveSpacingIPad(context,
          mobile: 16, tablet: 20, ipad: 24, ipadPro: 28, desktop: 24),
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(56); // Default height, will be responsive in build
}

/// iPad-optimized scaffold that prevents overflow and provides proper spacing
class IPadResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final EdgeInsets? padding;

  const IPadResponsiveScaffold({
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
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      drawer: drawer,
      endDrawer: endDrawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget bodyWidget = body;

          // Apply responsive padding
          if (padding != null) {
            bodyWidget = Padding(padding: padding!, child: bodyWidget);
          }

          // For iPads, ensure content doesn't overflow and is properly centered
          if (ResponsiveHelper.isIPad(context) ||
              ResponsiveHelper.isIPadPro(context)) {
            bodyWidget = SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveHelper.getResponsiveMaxWidth(context,
                        ipad: constraints.maxWidth * 0.9,
                        ipadPro: constraints.maxWidth * 0.85),
                    maxHeight: constraints.maxHeight,
                  ),
                  child: bodyWidget,
                ),
              ),
            );
          }

          return bodyWidget;
        },
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// iPad-optimized form field that adapts to screen size
class IPadResponsiveFormField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool enabled;

  const IPadResponsiveFormField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePaddingIPad(context,
          mobile: 8, tablet: 12, ipad: 16, ipadPro: 20, desktop: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        enabled: enabled,
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
              mobile: 14, tablet: 16, ipad: 18, ipadPro: 20, desktop: 18),
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          contentPadding: ResponsiveHelper.getResponsivePaddingIPad(context,
              mobile: 16, tablet: 20, ipad: 24, ipadPro: 28, desktop: 24),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context,
                  mobile: 8, tablet: 12, ipad: 16, ipadPro: 20, desktop: 16),
            ),
          ),
          labelStyle: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                mobile: 12, tablet: 14, ipad: 16, ipadPro: 18, desktop: 16),
          ),
          hintStyle: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                mobile: 12, tablet: 14, ipad: 16, ipadPro: 18, desktop: 16),
          ),
        ),
      ),
    );
  }
}

/// iPad-optimized list view that handles spacing properly
class IPadResponsiveListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsets? padding;
  final Axis scrollDirection;

  const IPadResponsiveListView({
    super.key,
    required this.children,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.scrollDirection = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: physics,
      shrinkWrap: shrinkWrap,
      scrollDirection: scrollDirection,
      padding: padding ??
          ResponsiveHelper.getResponsivePaddingIPad(context,
              mobile: 16, tablet: 24, ipad: 32, ipadPro: 40, desktop: 32),
      children: children.map((child) {
        // Add spacing between items
        return Padding(
          padding: EdgeInsets.only(
            bottom: ResponsiveHelper.getResponsiveSpacingIPad(context,
                mobile: 8, tablet: 12, ipad: 16, ipadPro: 20, desktop: 16),
          ),
          child: child,
        );
      }).toList(),
    );
  }
}
