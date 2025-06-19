import 'package:flutter/material.dart';
import '../widgets/vehicle_detail/vehicle_image_carousel.dart';
import '../widgets/vehicle_detail/vehicle_info_header.dart';
import '../widgets/vehicle_detail/vehicle_specifications_section.dart';
import '../widgets/vehicle_detail/vehicle_features_section.dart';
import '../widgets/vehicle_detail/rental_info_section.dart';
import '../widgets/vehicle_detail/booking_form_section.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
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
                VehicleSpecificationsSection(vehicleDetails: _vehicleDetails),

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

                // Bottom padding
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
