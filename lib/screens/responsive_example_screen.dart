import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';
import '../utils/responsive_helper.dart';

/// Example screen demonstrating the responsive design system
class ResponsiveExampleScreen extends StatelessWidget {
  const ResponsiveExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Responsive Example',
      backgroundColor: const Color(0xFFF7FBEF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Device info card
            ResponsiveContainer(
              backgroundColor: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    'Device Information',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                          mobile: 18, tablet: 22, desktop: 26),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context)),
                  _buildInfoRow(
                      'Device Type', ResponsiveHelper.getDeviceType(context)),
                  _buildInfoRow('Screen Width',
                      '${MediaQuery.of(context).size.width.toInt()}px'),
                  _buildInfoRow('Screen Height',
                      '${MediaQuery.of(context).size.height.toInt()}px'),
                  _buildInfoRow('Is Mobile',
                      ResponsiveHelper.isMobile(context).toString()),
                  _buildInfoRow('Is Tablet',
                      ResponsiveHelper.isTablet(context).toString()),
                  _buildInfoRow('Is Desktop',
                      ResponsiveHelper.isDesktop(context).toString()),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

            // Responsive grid example
            ResponsiveContainer(
              backgroundColor: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    'Responsive Grid',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                          mobile: 18, tablet: 22, desktop: 26),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context)),
                  ResponsiveGrid(
                    children: List.generate(
                      6,
                      (index) => ResponsiveCard(
                        backgroundColor: Colors.blue.shade50,
                        child: Center(
                          child: ResponsiveText(
                            'Item ${index + 1}',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

            // Responsive layout example
            ResponsiveContainer(
              backgroundColor: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    'Responsive Layout',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                          mobile: 18, tablet: 22, desktop: 26),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context)),
                  ResponsiveLayout(
                    mobile: _buildMobileLayout(),
                    tablet: _buildTabletLayout(),
                    desktop: _buildDesktopLayout(),
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

            // Responsive buttons example
            ResponsiveContainer(
              backgroundColor: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    'Responsive Buttons',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                          mobile: 18, tablet: 22, desktop: 26),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context)),
                  ResponsiveButton(
                    text: 'Primary Button',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Button pressed!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context,
                          mobile: 12)),
                  ResponsiveButton(
                    text: 'Loading Button',
                    isLoading: true,
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('Mobile Layout',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.red.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('Single Column'),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('Tablet Layout',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('Two Columns'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('Desktop Layout',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('Column 2'),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('Column 3'),
            ),
          ),
        ),
      ],
    );
  }
}
