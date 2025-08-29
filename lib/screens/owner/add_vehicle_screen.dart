import 'package:flutter/material.dart';
import 'package:wayz/screens/owner/owner_vehicle_form.dart';
import 'package:wayz/screens/owner/non_owner_vehicle_form.dart';
import '../../utils/responsive_helper.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen>
    with SingleTickerProviderStateMixin {
  bool? _isRegisteredOwner;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Your Vehicle',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 18, tablet: 20, desktop: 22),
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              theme.colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(context, mobile: 16, tablet: 24, desktop: 32),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with illustration
                    Center(
                      child: Container(
                        width: ResponsiveHelper.getResponsiveContainerWidth(context, mobile: 0.35, tablet: 0.3, desktop: 0.25),
                        height: ResponsiveHelper.getResponsiveContainerWidth(context, mobile: 0.35, tablet: 0.3, desktop: 0.25),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          boxShadow: ResponsiveHelper.getResponsiveShadow(context, mobile: 20, tablet: 25, desktop: 30),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          color: theme.colorScheme.primary,
                          size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 24, tablet: 32, desktop: 40),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 24, tablet: 32, desktop: 40)),

                    // Title
                    Text(
                      'Vehicle Ownership',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 24, tablet: 28, desktop: 32),
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),

                    // Description
                    Text(
                      'Are you the registered owner of this vehicle?',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 6, tablet: 8, desktop: 10)),
                    Text(
                      'This information is needed for verification purposes.',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 15, desktop: 16),
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 24, tablet: 36, desktop: 48)),

                    // Options
                    Row(
                      children: [
                        // Yes option
                        Expanded(
                          child: _buildOptionCard(
                            title: 'Yes',
                            description: 'I am the registered owner',
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                            isSelected: _isRegisteredOwner == true,
                            onTap: () {
                              setState(() {
                                _isRegisteredOwner = true;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                        // No option
                        Expanded(
                          child: _buildOptionCard(
                            title: 'No',
                            description: 'Someone else owns it',
                            icon: Icons.info_outline,
                            color: Colors.orange,
                            isSelected: _isRegisteredOwner == false,
                            onTap: () {
                              setState(() {
                                _isRegisteredOwner = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 24, tablet: 40, desktop: 48)),

                    // Selection summary
                    if (_isRegisteredOwner != null)
                      Container(
                        padding: ResponsiveHelper.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20),
                        decoration: BoxDecoration(
                          color: _isRegisteredOwner == true
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 10, tablet: 12, desktop: 16)),
                          border: Border.all(
                            color: _isRegisteredOwner == true
                                ? Colors.green.shade300
                                : Colors.orange.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isRegisteredOwner == true
                                  ? Icons.check_circle
                                  : Icons.info_outline,
                              color: _isRegisteredOwner == true
                                  ? Colors.green
                                  : Colors.orange,
                              size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 20, tablet: 24, desktop: 28),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                            Expanded(
                              child: Text(
                                _isRegisteredOwner == true
                                    ? "You'll need to provide ownership details in the next step."
                                    : "You'll need to provide authorization documents in the next step.",
                                style: TextStyle(
                                  color: _isRegisteredOwner == true
                                      ? Colors.green.shade800
                                      : Colors.orange.shade800,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 24, desktop: 32)),

                    // Continue button
                    Padding(
                      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                      child: SizedBox(
                        width: double.infinity,
                        height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 48, tablet: 55, desktop: 60),
                        child: ElevatedButton(
                          onPressed: _isRegisteredOwner == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => _isRegisteredOwner!
                                          ? const OwnerVehicleForm()
                                          : const NonOwnerVehicleForm(),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 14, desktop: 16)),
                            ),
                          ),
                          child: Text(
                            'CONTINUE',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 16, desktop: 20)),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: ResponsiveHelper.getResponsiveSpacing(context, mobile: 6, tablet: 8, desktop: 10),
                  spreadRadius: 0,
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: ResponsiveHelper.getResponsiveSpacing(context, mobile: 3, tablet: 4, desktop: 5),
                  spreadRadius: 0,
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 16, desktop: 20)),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: ResponsiveHelper.getResponsivePadding(context, mobile: 8, tablet: 10, desktop: 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : Colors.black87,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                    color: isSelected
                        ? color.withOpacity(0.8)
                        : Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 10, desktop: 12)),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Container(
                    width: ResponsiveHelper.getResponsiveIconSize(context, mobile: 16, tablet: 20, desktop: 24),
                    height: ResponsiveHelper.getResponsiveIconSize(context, mobile: 16, tablet: 20, desktop: 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 10, tablet: 12, desktop: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
