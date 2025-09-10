import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wayz/screens/owner/multi_step_owner_vehicle_form.dart';
import 'package:wayz/screens/owner/multi_step_non_owner_vehicle_form.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/app_colors.dart';

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
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: isDarkMode ? AppColors.neutralDark : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Add Your Vehicle',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                mobile: 18, tablet: 20, ipad: 22, ipadPro: 24, desktop: 26),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: ResponsiveHelper.getResponsiveIconSize(context,
                mobile: 20, tablet: 22, ipad: 24, ipadPro: 26, desktop: 28),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = ResponsiveHelper.isTablet(context);
              final isLargeTablet = ResponsiveHelper.isLargeTablet(context);
              final isIPad = ResponsiveHelper.isIPad(context);
              final isIPadPro = ResponsiveHelper.isIPadPro(context);

              // Use different layouts for different screen sizes
              if (isTablet || isLargeTablet || isIPad || isIPadPro) {
                return _buildTabletLayout(context, theme, isDarkMode);
              } else {
                return _buildMobileLayout(context, theme, isDarkMode);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, ThemeData theme, bool isDarkMode) {
    return Container(
      color: isDarkMode ? AppColors.neutralDark : Colors.grey[50],
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePaddingIPad(context,
              mobile: 16, tablet: 20, ipad: 24, ipadPro: 28, desktop: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacingIPad(context,
                      mobile: 16,
                      tablet: 20,
                      ipad: 24,
                      ipadPro: 28,
                      desktop: 32)),

              // Enhanced header with modern illustration
              _buildModernHeader(context, theme, isDarkMode),

              SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacingIPad(context,
                      mobile: 24,
                      tablet: 32,
                      ipad: 40,
                      ipadPro: 48,
                      desktop: 56)),

              // Enhanced title section
              _buildTitleSection(context, theme, isDarkMode),

              SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacingIPad(context,
                      mobile: 24,
                      tablet: 32,
                      ipad: 40,
                      ipadPro: 48,
                      desktop: 56)),

              // Enhanced option cards - Full width for mobile
              _buildEnhancedOptionCards(context, theme, isDarkMode,
                  isMobile: true),

              SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context,
                      mobile: 20, tablet: 28, desktop: 36)),

              // Selection summary
              if (_isRegisteredOwner != null)
                _buildSelectionSummary(context, theme, isDarkMode),

              SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context,
                      mobile: 24, tablet: 32, desktop: 40)),

              // Enhanced continue button
              _buildEnhancedContinueButton(context, theme, isDarkMode),

              SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context,
                      mobile: 24, tablet: 28, desktop: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(
      BuildContext context, ThemeData theme, bool isDarkMode) {
    return Container(
      color: isDarkMode ? AppColors.neutralDark : Colors.grey[50],
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.getResponsiveContainerWidth(context,
                mobile: 1.0,
                tablet: 0.8,
                ipad: 0.7,
                ipadPro: 0.6,
                desktop: 0.5),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: ResponsiveHelper.getResponsivePaddingIPad(context,
                  mobile: 24, tablet: 32, ipad: 40, ipadPro: 48, desktop: 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacingIPad(context,
                          mobile: 24,
                          tablet: 32,
                          ipad: 40,
                          ipadPro: 48,
                          desktop: 56)),

                  // Enhanced header with modern illustration
                  _buildModernHeader(context, theme, isDarkMode),

                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacingIPad(context,
                          mobile: 40,
                          tablet: 48,
                          ipad: 56,
                          ipadPro: 64,
                          desktop: 72)),

                  // Enhanced title section
                  _buildTitleSection(context, theme, isDarkMode),

                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacingIPad(context,
                          mobile: 40,
                          tablet: 48,
                          ipad: 56,
                          ipadPro: 64,
                          desktop: 72)),

                  // Enhanced option cards - Side by side for tablets
                  _buildEnhancedOptionCards(context, theme, isDarkMode,
                      isMobile: false),

                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context,
                          mobile: 32, tablet: 40, desktop: 48)),

                  // Selection summary
                  if (_isRegisteredOwner != null)
                    _buildSelectionSummary(context, theme, isDarkMode),

                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context,
                          mobile: 40, tablet: 48, desktop: 56)),

                  // Enhanced continue button
                  _buildEnhancedContinueButton(context, theme, isDarkMode),

                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context,
                          mobile: 24, tablet: 32, desktop: 40)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(
      BuildContext context, ThemeData theme, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context,
          mobile: 24, tablet: 32, ipad: 40, ipadPro: 48, desktop: 56),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black,
          ],
        ),
        borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context,
                mobile: 16, tablet: 20, ipad: 24, ipadPro: 28, desktop: 32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveContainerWidth(context,
                mobile: 0.2,
                tablet: 0.18,
                ipad: 0.16,
                ipadPro: 0.14,
                desktop: 0.12),
            height: ResponsiveHelper.getResponsiveContainerWidth(context,
                mobile: 0.2,
                tablet: 0.18,
                ipad: 0.16,
                ipadPro: 0.14,
                desktop: 0.12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFC107).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.directions_car_rounded,
              color: Colors.black,
              size: ResponsiveHelper.getResponsiveIconSize(context,
                  mobile: 28, tablet: 32, ipad: 36, ipadPro: 40, desktop: 44),
            ),
          ),
          SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(context,
                  mobile: 16, tablet: 20, ipad: 24, ipadPro: 28, desktop: 32)),
          Text(
            'Add Your Vehicle',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                  mobile: 20, tablet: 24, ipad: 28, ipadPro: 32, desktop: 36),
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(context,
                  mobile: 6, tablet: 8, ipad: 10, ipadPro: 12, desktop: 14)),
          Text(
            'Start earning with your vehicle today',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                  mobile: 14, tablet: 16, ipad: 18, ipadPro: 20, desktop: 22),
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(
      BuildContext context, ThemeData theme, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Vehicle Ownership',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                mobile: 24, tablet: 28, ipad: 32, ipadPro: 36, desktop: 40),
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white : Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(
            height: ResponsiveHelper.getResponsiveSpacingIPad(context,
                mobile: 8, tablet: 12, ipad: 16, ipadPro: 20, desktop: 24)),
        Text(
          'Are you the registered owner of this vehicle?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                mobile: 16, tablet: 18, ipad: 20, ipadPro: 22, desktop: 24),
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedOptionCards(
      BuildContext context, ThemeData theme, bool isDarkMode,
      {required bool isMobile}) {
    // Always show cards horizontally (side by side) for all screen sizes
    return Row(
      children: [
        Expanded(
          child: _buildCompactOptionCard(
            context: context,
            theme: theme,
            isDarkMode: isDarkMode,
            title: 'Yes, I am the owner',
            icon: Icons.verified_user_rounded,
            color: const Color(0xFF4CAF50),
            isSelected: _isRegisteredOwner == true,
            onTap: () {
              setState(() {
                _isRegisteredOwner = true;
              });
            },
          ),
        ),
        SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(context,
                mobile: 20, tablet: 0, desktop: 0),
            width: ResponsiveHelper.getResponsiveSpacing(context,
                mobile: 16, tablet: 16, desktop: 20)),
        Expanded(
          child: _buildCompactOptionCard(
            context: context,
            theme: theme,
            isDarkMode: isDarkMode,
            title: 'No, Not mine',
            icon: Icons.people_rounded,
            color: const Color(0xFFFF9800),
            isSelected: _isRegisteredOwner == false,
            onTap: () {
              setState(() {
                _isRegisteredOwner = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactOptionCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDarkMode,
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      height: ResponsiveHelper.getResponsiveSpacing(context,
          mobile: 160, tablet: 170, ipad: 180, ipadPro: 190, desktop: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? color.withOpacity(0.08)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context,
                mobile: 16, tablet: 18, ipad: 20, ipadPro: 22, desktop: 24)),
        border: Border.all(
          color: isSelected ? color : Colors.grey[300]!,
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: isSelected ? 8 : 4,
            spreadRadius: 0,
            offset: Offset(0, isSelected ? 3 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context,
                  mobile: 16, tablet: 18, ipad: 20, ipadPro: 22, desktop: 24)),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(context,
                mobile: 16, tablet: 18, ipad: 20, ipadPro: 22, desktop: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Compact icon container
                Container(
                  padding: ResponsiveHelper.getResponsivePadding(context,
                      mobile: 12,
                      tablet: 14,
                      ipad: 16,
                      ipadPro: 18,
                      desktop: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : color,
                    size: ResponsiveHelper.getResponsiveIconSize(context,
                        mobile: 24,
                        tablet: 26,
                        ipad: 28,
                        ipadPro: 30,
                        desktop: 32),
                  ),
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 12,
                        tablet: 14,
                        ipad: 16,
                        ipadPro: 18,
                        desktop: 20)),

                // Compact title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                        mobile: 13,
                        tablet: 14,
                        ipad: 15,
                        ipadPro: 16,
                        desktop: 17),
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : Colors.black87,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 10,
                        tablet: 12,
                        ipad: 14,
                        ipadPro: 16,
                        desktop: 18)),

                // Simple selection indicator
                Container(
                  width: ResponsiveHelper.getResponsiveIconSize(context,
                      mobile: 20,
                      tablet: 22,
                      ipad: 24,
                      ipadPro: 26,
                      desktop: 28),
                  height: ResponsiveHelper.getResponsiveIconSize(context,
                      mobile: 20,
                      tablet: 22,
                      ipad: 24,
                      ipadPro: 26,
                      desktop: 28),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? color : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: ResponsiveHelper.getResponsiveIconSize(context,
                              mobile: 12,
                              tablet: 14,
                              ipad: 16,
                              ipadPro: 18,
                              desktop: 20),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionSummary(
      BuildContext context, ThemeData theme, bool isDarkMode) {
    final color = _isRegisteredOwner == true
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF9800);
    final icon = _isRegisteredOwner == true
        ? Icons.verified_user_rounded
        : Icons.people_rounded;
    final message = _isRegisteredOwner == true
        ? "Great! You'll need to provide ownership details in the next step."
        : "Perfect! You'll need to provide authorization documents in the next step.";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: ResponsiveHelper.getResponsivePadding(context,
          mobile: 16, tablet: 20, ipad: 24, ipadPro: 28, desktop: 32),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context,
                mobile: 12, tablet: 14, ipad: 16, ipadPro: 18, desktop: 20)),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: ResponsiveHelper.getResponsivePadding(context,
                mobile: 10, tablet: 12, ipad: 14, ipadPro: 16, desktop: 18),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: ResponsiveHelper.getResponsiveIconSize(context,
                  mobile: 20, tablet: 22, ipad: 24, ipadPro: 26, desktop: 28),
            ),
          ),
          SizedBox(
              width: ResponsiveHelper.getResponsiveSpacing(context,
                  mobile: 12, tablet: 14, ipad: 16, ipadPro: 18, desktop: 20)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDarkMode ? Colors.white : color.withOpacity(0.9),
                fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                    mobile: 13, tablet: 14, ipad: 15, ipadPro: 16, desktop: 17),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedContinueButton(
      BuildContext context, ThemeData theme, bool isDarkMode) {
    return Container(
      width: double.infinity,
      height: ResponsiveHelper.getResponsiveSpacing(context,
          mobile: 48, tablet: 52, ipad: 56, ipadPro: 60, desktop: 64),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context,
                mobile: 24, tablet: 26, ipad: 28, ipadPro: 30, desktop: 32)),
        boxShadow: _isRegisteredOwner != null
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: _isRegisteredOwner == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _isRegisteredOwner!
                        ? const MultiStepOwnerVehicleForm()
                        : const MultiStepNonOwnerVehicleForm(),
                  ),
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: _isRegisteredOwner != null
              ? Colors.black
              : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
          foregroundColor: _isRegisteredOwner != null
              ? const Color(0xFFFFC107)
              : Colors.grey[500],
          disabledBackgroundColor:
              isDarkMode ? Colors.grey[700] : Colors.grey[300],
          disabledForegroundColor: Colors.grey[500],
          elevation: _isRegisteredOwner != null ? 4 : 1,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveBorderRadius(context,
                    mobile: 24,
                    tablet: 26,
                    ipad: 28,
                    ipadPro: 30,
                    desktop: 32)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRegisteredOwner != null) ...[
              Icon(
                Icons.arrow_forward_rounded,
                color: const Color.fromARGB(255, 255, 255, 255),
                size: ResponsiveHelper.getResponsiveIconSize(context,
                    mobile: 18, tablet: 20, ipad: 22, ipadPro: 24, desktop: 26),
              ),
              SizedBox(
                  width: ResponsiveHelper.getResponsiveSpacing(context,
                      mobile: 6,
                      tablet: 8,
                      ipad: 10,
                      ipadPro: 12,
                      desktop: 14)),
            ],
            Text(
              _isRegisteredOwner != null ? 'CONTINUE' : 'SELECT AN OPTION',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                    mobile: 14, tablet: 15, ipad: 16, ipadPro: 17, desktop: 18),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: _isRegisteredOwner != null
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
