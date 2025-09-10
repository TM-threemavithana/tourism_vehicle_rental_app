import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// A debug widget that displays current breakpoint information
class ResponsiveDebugInfo extends StatelessWidget {
  final bool showOverlay;
  final Widget child;

  const ResponsiveDebugInfo({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showOverlay) return child;

    return Stack(
      children: [
        child,
        Positioned(
          top: 40,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDebugInfo(
                    'Device:', ResponsiveHelper.getDeviceType(context)),
                _buildDebugInfo(
                    'Width:', '${MediaQuery.of(context).size.width.toInt()}px'),
                _buildDebugInfo('Height:',
                    '${MediaQuery.of(context).size.height.toInt()}px'),
                _buildDebugInfo(
                    'Orientation:', MediaQuery.of(context).orientation.name),
                _buildDebugInfo('Scale:',
                    MediaQuery.of(context).textScaleFactor.toStringAsFixed(1)),
                _buildDebugInfo('Density:',
                    MediaQuery.of(context).devicePixelRatio.toStringAsFixed(1)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebugInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

/// A widget that shows responsive breakpoint indicators
class ResponsiveBreakpointIndicator extends StatelessWidget {
  const ResponsiveBreakpointIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: _getBreakpointColor(context),
      child: Text(
        'Current: ${ResponsiveHelper.getDeviceType(context)} (${MediaQuery.of(context).size.width.toInt()}px)',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getBreakpointColor(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) return Colors.red;
    if (ResponsiveHelper.isTablet(context)) return Colors.orange;
    if (ResponsiveHelper.isLargeTablet(context)) return Colors.yellow.shade700;
    if (ResponsiveHelper.isIPad(context)) return Colors.green;
    if (ResponsiveHelper.isIPadPro(context)) return Colors.blue;
    if (ResponsiveHelper.isDesktop(context)) return Colors.purple;
    if (ResponsiveHelper.isLargeDesktop(context)) return Colors.indigo;
    return Colors.grey;
  }
}

/// A responsive app wrapper that can show debug information
class ResponsiveApp extends StatefulWidget {
  final Widget app;
  final bool showDebugInfo;

  const ResponsiveApp({
    super.key,
    required this.app,
    this.showDebugInfo = false,
  });

  @override
  State<ResponsiveApp> createState() => _ResponsiveAppState();
}

class _ResponsiveAppState extends State<ResponsiveApp> {
  bool _showDebug = false;

  @override
  void initState() {
    super.initState();
    _showDebug = widget.showDebugInfo;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        setState(() {
          _showDebug = !_showDebug;
        });
      },
      child: ResponsiveDebugInfo(
        showOverlay: _showDebug,
        child: widget.app,
      ),
    );
  }
}

/// Responsive spacing widget for consistent spacing
class ResponsiveSpacing extends StatelessWidget {
  final double factor;
  final bool horizontal;

  const ResponsiveSpacing({
    super.key,
    this.factor = 1.0,
    this.horizontal = false,
  });

  const ResponsiveSpacing.horizontal({
    super.key,
    this.factor = 1.0,
  })  : horizontal = true;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveHelper.getResponsiveSpacing(context) * factor;

    if (horizontal) {
      return SizedBox(width: spacing);
    }
    return SizedBox(height: spacing);
  }
}

/// Responsive divider that adapts thickness and margins
class ResponsiveDivider extends StatelessWidget {
  final Color? color;
  final double? thickness;
  final EdgeInsets? margin;

  const ResponsiveDivider({
    super.key,
    this.color,
    this.thickness,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? ResponsiveHelper.getResponsiveVerticalPadding(context),
      child: Divider(
        color: color,
        thickness:
            thickness ?? ResponsiveHelper.getResponsiveStrokeWidth(context),
      ),
    );
  }
}
