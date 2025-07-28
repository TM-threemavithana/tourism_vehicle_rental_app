import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/vehicle_detail/vehicle_image_carousel.dart';
import '../widgets/vehicle_detail/vehicle_info_header.dart';
import '../widgets/vehicle_detail/vehicle_specifications_section.dart';
import '../widgets/vehicle_detail/vehicle_features_section.dart';
import '../widgets/vehicle_detail/rental_info_section.dart';
import '../widgets/vehicle_detail/booking_form_section.dart';
import '../utils/app_colors.dart';

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

                    // Booking form section
                    BookingFormSection(vehicleDetails: _vehicleDetails),

                    // Divider
                    const Divider(height: 1),

                    // Contact buttons section
                    _buildContactButtonsSection(),

                    // Bottom padding
                    const SizedBox(height: 24),
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Vehicle Owner',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
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
              const SizedBox(width: 12),
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
          ? FaIcon(icon as IconData, color: Colors.white, size: 18)
          : Icon(icon as IconData, color: Colors.white, size: 18),
      label: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
