import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/vehicle_detail/vehicle_image_carousel.dart';
import '../widgets/vehicle_detail/vehicle_info_header.dart';
import '../widgets/vehicle_detail/vehicle_specifications_section.dart';
import '../widgets/vehicle_detail/vehicle_features_section.dart';
import '../widgets/vehicle_detail/rental_info_section.dart';
// import '../widgets/vehicle_detail/booking_form_section.dart'; // Commented out booking form
import '../widgets/vehicle_detail/full_screen_image_viewer.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_helper.dart';

class VehicleDetailPage extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailPage({
    super.key,
    required this.vehicle,
  });

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  late Map<String, dynamic> _vehicleDetails;

  @override
  void initState() {
    super.initState();
    _vehicleDetails = widget.vehicle;
    _debugPrintVehicleImages(); // Add this for debugging
  }

  // Debug method to check image structure
  void _debugPrintVehicleImages() {
    debugPrint('Vehicle data: ${widget.vehicle['id']}');
    debugPrint('Image data: ${widget.vehicle['images']}');
  }

  // Extract images from vehicle data
  List<String> _extractImages() {
    List<String> imageUrls = [];

    try {
      // Check for images in different possible data structures

      // Case 1: images is a direct list of strings
      if (widget.vehicle['images'] is List) {
        final List<dynamic> images = widget.vehicle['images'] as List;
        imageUrls = images.map((img) => img.toString()).toList();
      }
      // Case 2: images is a map with nested structures
      else if (widget.vehicle['images'] is Map) {
        final Map<String, dynamic> imagesMap =
            widget.vehicle['images'] as Map<String, dynamic>;

        // Add primary image first if available
        if (imagesMap['primaryImageUrl'] != null) {
          imageUrls.add(imagesMap['primaryImageUrl']);
        }

        // Add image URLs if available
        if (imagesMap['imageUrls'] is List) {
          final List<dynamic> imagesList = imagesMap['imageUrls'] as List;
          for (String url in imagesList) {
            // Avoid duplicates if primary image is also in imageUrls
            if (url != imagesMap['primaryImageUrl']) {
              imageUrls.add(url);
            }
          }
        }

        // Add additional images if available
        if (imagesMap['additionalImages'] is List) {
          final List<dynamic> additionalImages =
              imagesMap['additionalImages'] as List;
          imageUrls.addAll(additionalImages.map((img) => img.toString()));
        }
      }

      // If still no images, check for other possible formats
      if (imageUrls.isEmpty && widget.vehicle['imageUrls'] is List) {
        final List<dynamic> imagesList = widget.vehicle['imageUrls'] as List;
        imageUrls = imagesList.map((img) => img.toString()).toList();
      }
    } catch (e) {
      debugPrint('Error extracting images: $e');
    }

    // If no images found, use a placeholder
    if (imageUrls.isEmpty) {
      imageUrls
          .add('https://via.placeholder.com/400x250?text=No+Image+Available');
    }

    return imageUrls;
  }

  // Open full screen image viewer
  void _openFullScreenImageViewer(int initialIndex) {
    final imageUrls = _extractImages();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title:
            "${widget.vehicle['make'] ?? ''} ${widget.vehicle['model'] ?? ''}",
        vehicleDetails: widget.vehicle,
        showBackButton: true,
        showShareButton: true,
        showFavoriteButton: true,
        backgroundColor: const Color(0xFFFFC107),
        iconColor: Colors.black,
      ),
      body: Stack(
        children: [
          // Yellow status bar overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top,
              color: const Color(0xFFFFC107),
            ),
          ),
          CustomScrollView(
            slivers: [
              // Image Carousel in App Bar
              VehicleImageCarousel(vehicleDetails: _vehicleDetails),

              // Main content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle information header with logo and name
                    VehicleInfoHeader(vehicleDetails: _vehicleDetails),

                    // Divider
                    const Divider(height: 1),

                    // Vehicle specifications section
                    VehicleSpecificationsSection(
                        vehicleDetails: _vehicleDetails),

                    // Divider
                    const Divider(height: 1),

                    // Vehicle features section
                    VehicleFeaturesSection(vehicleDetails: _vehicleDetails),

                    // Divider
                    const Divider(height: 1),

                    // Rental information section
                    RentalInfoSection(vehicleDetails: _vehicleDetails),

                    // Divider
                    const Divider(height: 1),

                    // Booking form section - COMMENTED OUT
                    // BookingFormSection(vehicleDetails: _vehicleDetails),

                    // Divider
                    const Divider(height: 1),

                    // Contact buttons section
                    _buildContactButtonsSection(),

                    // Bottom padding
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 24, tablet: 32, desktop: 40)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButtonsSection() {
    final String? whatsappNumber =
        _vehicleDetails['driverDetails']?['whatsappNumber'];
    final String? contactNumber =
        (whatsappNumber != null && whatsappNumber.isNotEmpty)
            ? whatsappNumber
            : _vehicleDetails['contactNumber'];

    if (contactNumber == null || contactNumber.isEmpty) {
      return const SizedBox
          .shrink(); // Don't show contact section if no contact info
    }

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Vehicle Owner',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 20, tablet: 22, desktop: 24),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  'Call',
                  Icons.phone,
                  AppColors.success,
                  () => _makePhoneCall(contactNumber),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
              Expanded(
                child: _buildContactButton(
                  'WhatsApp',
                  FontAwesomeIcons.whatsapp,
                  AppColors.primary,
                  () => _openWhatsApp(contactNumber),
                  isFaIcon: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(
      String text, dynamic icon, Color color, VoidCallback onPressed,
      {bool isFaIcon = false}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isFaIcon
          ? FaIcon(icon as IconData, color: Colors.white, size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 18, tablet: 20, desktop: 22))
          : Icon(icon as IconData, color: Colors.white, size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 18, tablet: 20, desktop: 22)),
      label: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 20, tablet: 24, desktop: 28)),
        ),
        elevation: 2,
        padding: ResponsiveHelper.getResponsiveButtonPadding(context),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  // Helper to clean phone number for WhatsApp
  String _cleanPhoneNumber(String number) {
    // Remove all non-digit characters except leading +
    String cleaned = number.replaceAll(RegExp(r'[^0-9+]'), '');
    // Remove leading zeros after country code
    if (cleaned.startsWith('00')) {
      cleaned = cleaned.replaceFirst('00', '');
    }
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot make a call from this device.')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final cleanedNumber = _cleanPhoneNumber(phoneNumber);
    final whatsappUrl = Uri.parse('https://wa.me/$cleanedNumber');

    // Try to launch WhatsApp
    if (await canLaunchUrl(whatsappUrl)) {
      final launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback: try to open in browser
        final browserLaunched = await launchUrl(
          whatsappUrl,
          mode: LaunchMode.platformDefault,
        );
        if (!browserLaunched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Could not open WhatsApp or browser. Please make sure WhatsApp is installed and the number is valid.'),
            ),
          );
        }
      }
    } else {
      // Fallback: try to open in browser
      final browserLaunched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.platformDefault,
      );
      if (!browserLaunched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not open WhatsApp or browser. Please make sure WhatsApp is installed and the number is valid.'),
          ),
        );
      }
    }
  }
}
