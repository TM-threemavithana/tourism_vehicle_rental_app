import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../services/onesignal_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BookingRequestsScreen extends StatelessWidget {
  const BookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Booking Requests',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 18, tablet: 20, desktop: 22),
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Please log in to view booking requests',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Booking Requests',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 18, tablet: 20, desktop: 22),
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookingRequests')
            .where('ownerId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: ResponsiveHelper.getResponsiveSpacing(context, mobile: 3, tablet: 4, desktop: 5),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 80, tablet: 100, desktop: 120),
                    color: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade400,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                  Text(
                    'No booking requests yet',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 18, tablet: 20, desktop: 22),
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                  Text(
                    'When users request to book your vehicles, they\'ll appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                      color: isDarkMode
                          ? Colors.grey.shade500
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: ResponsiveHelper.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _buildRequestCard(context, doc.id, data, isDarkMode);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, String docId,
      Map<String, dynamic> data, bool isDarkMode) {
    final currencyFormat = NumberFormat("#,##0.00", "en_US");
    final status = data['status'] as String;
    final vehicleInfo = data['vehicleInfo'] as Map<String, dynamic>;
    final userName = data['userName'] as String;
    final pricing = data['pricing'] as Map<String, dynamic>;
    final withDriver = data['withDriver'] as bool;
    final unitLabel = pricing['unitLabel'] as String;
    final unitCount = pricing['unitCount'] as int;
    final rentalCost = pricing['rentalCost'] as double;

    final pickupDateTime = DateTime.parse(data['pickupDateTime']);
    final returnDateTime = DateTime.parse(data['returnDateTime']);

    final isPending = status == 'pending';

    // Determine card styling based on status
    Color statusColor;
    Color cardBorderColor;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        cardBorderColor = Colors.green.shade200;
        break;
      case 'rejected':
        statusColor = Colors.red;
        cardBorderColor = Colors.red.shade200;
        break;
      case 'pending':
        statusColor = Colors.orange;
        cardBorderColor = Colors.orange.shade200;
        break;
      default:
        statusColor = Colors.grey;
        cardBorderColor = Colors.grey.shade300;
    }

    return Card(
      elevation: ResponsiveHelper.isTablet(context) ? 4 : 2,
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 14, desktop: 16)),
        side: BorderSide(color: cardBorderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with vehicle info and status
          Container(
            padding: ResponsiveHelper.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 14, desktop: 16)),
                topRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 14, desktop: 16)),
              ),
            ),
            child: Row(
              children: [
                // Vehicle image
                ClipRRect(
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 8, tablet: 10, desktop: 12)),
                  child: CachedNetworkImage(
                    imageUrl: vehicleInfo['primaryImage'] ??
                        'https://via.placeholder.com/60?text=No+Image',
                    width: ResponsiveHelper.getResponsiveImageSize(context, mobile: 60, tablet: 70, desktop: 80),
                    height: ResponsiveHelper.getResponsiveImageSize(context, mobile: 60, tablet: 70, desktop: 80),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: ResponsiveHelper.getResponsiveImageSize(context, mobile: 60, tablet: 70, desktop: 80),
                      height: ResponsiveHelper.getResponsiveImageSize(context, mobile: 60, tablet: 70, desktop: 80),
                      color: Colors.grey.shade300,
                      child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: ResponsiveHelper.getResponsiveSpacing(context, mobile: 2, tablet: 3, desktop: 4),
                          )),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: ResponsiveHelper.getResponsiveImageSize(context, mobile: 60, tablet: 70, desktop: 80),
                      height: ResponsiveHelper.getResponsiveImageSize(context, mobile: 60, tablet: 70, desktop: 80),
                      color: Colors.grey.shade300,
                      child: Icon(
                        Icons.directions_car, 
                        color: Colors.grey,
                        size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 14, desktop: 16)),

                // Vehicle details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicleInfo['make']} ${vehicleInfo['model']} (${vehicleInfo['year']})',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vehicleInfo['vehicleNo'],
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 15, desktop: 16),
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status chip
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveSpacing(context, mobile: 10, tablet: 12, desktop: 14),
                    vertical: ResponsiveHelper.getResponsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8),
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 14, desktop: 16)),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Request details
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Requester info
                Row(
                  children: [
                    Icon(
                      Icons.person, 
                      size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 18, tablet: 20, desktop: 22),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 10, desktop: 12)),
                    Text(
                      'Request from $userName',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 15, tablet: 16, desktop: 17),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),

                // Trip details
                Text(
                  'Trip Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 15, tablet: 16, desktop: 17),
                    color: isDarkMode
                        ? Colors.grey.shade300
                        : Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 10, desktop: 12)),

                // Rental period
                _buildDetailRow(
                  context,
                  icon: Icons.date_range,
                  label: 'Duration',
                  value: '$unitCount ${unitLabel.toLowerCase()}(s)',
                ),
                _buildDetailRow(
                  context,
                  icon: Icons.access_time,
                  label: 'Pickup',
                  value: DateFormat('MMM dd, yyyy \'at\' h:mm a')
                      .format(pickupDateTime),
                ),
                _buildDetailRow(
                  context,
                  icon: Icons.access_time,
                  label: 'Return',
                  value: DateFormat('MMM dd, yyyy \'at\' h:mm a')
                      .format(returnDateTime),
                ),
                _buildDetailRow(
                  context,
                  icon: Icons.person_outline,
                  label: 'Driver',
                  value: withDriver ? 'With Driver' : 'Self Drive',
                ),
                _buildDetailRow(
                  context,
                  icon: Icons.payments_outlined,
                  label: 'Rental Cost',
                  value: 'Rs. ${currencyFormat.format(rentalCost)}',
                  isHighlighted: true,
                ),

                // Request date
                if (data['createdAt'] != null)
                  Padding(
                    padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                    child: Text(
                      'Requested on ${DateFormat('MMM dd, yyyy \'at\' h:mm a').format((data['createdAt'] as Timestamp).toDate())}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                        fontStyle: FontStyle.italic,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),

                // Response options for pending requests
                if (isPending) ...[
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 24, tablet: 28, desktop: 32)),
                  Divider(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _respondToRequest(context, docId, 'rejected'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 8, tablet: 10, desktop: 12)),
                              side: BorderSide(color: Colors.red.shade300),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 14, desktop: 16),
                            ),
                          ),
                          child: Text(
                            'Decline',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 14, desktop: 16)),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _respondToRequest(context, docId, 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 8, tablet: 10, desktop: 12)),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 14, desktop: 16),
                            ),
                          ),
                          child: Text(
                            'Accept',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 10, desktop: 12)),
      child: Row(
        children: [
          Icon(
            icon,
            size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 16, tablet: 18, desktop: 20),
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 10, desktop: 12)),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 15, desktop: 16),
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 10, desktop: 12)),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 15, desktop: 16),
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                color: isHighlighted
                    ? (isDarkMode ? Colors.tealAccent : Colors.teal.shade700)
                    : (isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update the response method to include OneSignal notifications

  Future<void> _respondToRequest(
      BuildContext context, String docId, String status) async {
    try {
      debugPrint("Responding to request $docId with status: $status");

      // Get the request document to access user information
      final requestDoc = await FirebaseFirestore.instance
          .collection('bookingRequests')
          .doc(docId)
          .get();

      if (!requestDoc.exists) {
        debugPrint("Request document not found!");
        return;
      }

      final data = requestDoc.data() as Map<String, dynamic>;
      final renterId = data['userId'];
      final vehicleInfo = data['vehicleInfo'] as Map<String, dynamic>;

      debugPrint("Renter ID: $renterId");
      debugPrint("Vehicle: ${vehicleInfo['make']} ${vehicleInfo['model']}");

      // Update the request status
      await FirebaseFirestore.instance
          .collection('bookingRequests')
          .doc(docId)
          .update({
        'status': status,
        'respondedAt': FieldValue.serverTimestamp(),
        'notified':
            false, // Reset notified flag to trigger notification to renter
      });

      debugPrint("Request status updated to $status");

      // Get the renter's OneSignal player ID
      final renterDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(renterId)
          .get();

      if (!renterDoc.exists) {
        debugPrint("Renter document not found!");
        return;
      }

      final renterData = renterDoc.data();
      final renterOneSignalId = renterData?['oneSignalPlayerId'];

      debugPrint("Renter OneSignal ID: $renterOneSignalId");

      if (renterOneSignalId != null) {
        // Send push notification to renter using OneSignal
        final oneSignalService = OneSignalService();
        final vehicleName = '${vehicleInfo['make']} ${vehicleInfo['model']}';
        debugPrint("Sending notification to renter...");

        await oneSignalService.sendNotificationToUser(
          playerId: renterOneSignalId,
          title: status == 'approved' ? 'Booking Approved' : 'Booking Declined',
          content: status == 'approved'
              ? 'Your booking request for $vehicleName has been approved! You can now proceed to payment.'
              : 'Your request for $vehicleName was declined by the owner.',
          notificationType: 'booking_response',
          data: {'requestId': docId},
        );
      } else {
        debugPrint("⚠️ Renter doesn't have a OneSignal ID registered!");
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'approved'
              ? 'You have accepted the booking request'
              : 'You have declined the booking request'),
          backgroundColor:
              status == 'approved' ? Colors.green : Colors.red.shade400,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint("❌ Error responding to request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
