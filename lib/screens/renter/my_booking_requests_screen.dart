import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../widgets/not_logged_in_widget.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../welcome_screen.dart';
import '../profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyBookingRequestsScreen extends StatelessWidget {
  const MyBookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Yellow status bar overlay (always at the very top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: statusBarHeight,
              color: const Color(0xFFFFC107),
            ),
          ),
          // Main content with SafeArea
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom AppBar look
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Text(
                    'My Booking Requests',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: currentUser == null
                      ? const NotLoggedInWidget()
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('bookingRequests')
                              .where('userId', isEqualTo: currentUser.uid)
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, bookingSnapshot) {
                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('inquiries')
                                  .where('userId', isEqualTo: currentUser.uid)
                                  .snapshots(),
                              builder: (context, inquirySnapshot) {
                                if (bookingSnapshot.connectionState ==
                                        ConnectionState.waiting ||
                                    inquirySnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                if (bookingSnapshot.hasError ||
                                    inquirySnapshot.hasError) {
                                  return Center(
                                    child: Text(
                                        'Error: ${bookingSnapshot.error ?? inquirySnapshot.error}'),
                                  );
                                }

                                // Combine and sort all requests
                                List<Map<String, dynamic>> allRequests = [];

                                // Add booking requests
                                if (bookingSnapshot.hasData) {
                                  for (var doc in bookingSnapshot.data!.docs) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    allRequests.add({
                                      ...data,
                                      'id': doc.id,
                                      'type': 'booking',
                                      'timestamp': data['createdAt'],
                                    });
                                  }
                                }

                                // Add inquiries
                                if (inquirySnapshot.hasData) {
                                  for (var doc in inquirySnapshot.data!.docs) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    allRequests.add({
                                      ...data,
                                      'id': doc.id,
                                      'type': 'inquiry',
                                      'timestamp': data['createdAt'],
                                    });
                                  }
                                }

                                // Sort by timestamp (most recent first)
                                allRequests.sort((a, b) {
                                  final aTimestamp =
                                      a['timestamp'] as Timestamp?;
                                  final bTimestamp =
                                      b['timestamp'] as Timestamp?;
                                  if (aTimestamp == null && bTimestamp == null)
                                    return 0;
                                  if (aTimestamp == null) return 1;
                                  if (bTimestamp == null) return -1;
                                  return bTimestamp.compareTo(aTimestamp);
                                });

                                if (allRequests.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.car_rental,
                                          size: 80,
                                          color: isDarkMode
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No requests yet',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Your booking requests and inquiries will appear here',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: allRequests.length,
                                  itemBuilder: (context, index) {
                                    final request = allRequests[index];
                                    return _buildRequestCard(
                                        context, request, isDarkMode);
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
                // Add bottom padding for nav bar
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(user: FirebaseAuth.instance.currentUser)),
            );
          }
        },
      ),
    );
  }

  Widget _buildRequestCard(
      BuildContext context, Map<String, dynamic> data, bool isDarkMode) {
    final requestType = data['type'] as String;

    if (requestType == 'booking') {
      return _buildBookingRequestCard(context, data, isDarkMode);
    } else {
      return _buildInquiryCard(context, data, isDarkMode);
    }
  }

  Widget _buildBookingRequestCard(
      BuildContext context, Map<String, dynamic> data, bool isDarkMode) {
    final currencyFormat = NumberFormat("#,##0.00", "en_US");
    final status = data['status'] as String;
    final vehicleInfo = data['vehicleInfo'] as Map<String, dynamic>;
    final pricing = data['pricing'] as Map<String, dynamic>;
    final withDriver = data['withDriver'] as bool;
    final pickupDateTime = DateTime.parse(data['pickupDateTime']);
    final returnDateTime = DateTime.parse(data['returnDateTime']);
    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red.shade400;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        break;
    }
    final cardBorderColor = status == 'pending'
        ? Colors.orange
        : status == 'approved'
            ? Colors.green
            : Colors.red.shade300;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardBorderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: vehicleInfo['primaryImage'] ??
                        'https://via.placeholder.com/60?text=No+Image',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade300,
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade300,
                      child:
                          const Icon(Icons.directions_car, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicleInfo['make']} ${vehicleInfo['model']} (${vehicleInfo['year']})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vehicleInfo['vehicleNo'],
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDarkMode
                        ? Colors.grey.shade300
                        : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  icon: Icons.date_range,
                  label: 'Duration',
                  value:
                      '${pricing['unitCount']} ${pricing['unitLabel'].toLowerCase()}(s)',
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
                  value: 'Rs. ${currencyFormat.format(pricing['rentalCost'])}',
                  isHighlighted: true,
                ),
                if (data['createdAt'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Requested on ${DateFormat('MMM dd, yyyy \'at\' h:mm a').format((data['createdAt'] as Timestamp).toDate())}',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryCard(
      BuildContext context, Map<String, dynamic> data, bool isDarkMode) {
    final vehicleType = data['vehicleType'] as String? ?? 'Vehicle';
    final dateTime = data['dateTime'] is Timestamp
        ? (data['dateTime'] as Timestamp).toDate()
        : data['dateTime'] as DateTime?;
    final location = data['location'] as String? ?? '';
    final details = data['details'] as String? ?? '';
    final contactNumber = data['contactNumber'] as String? ?? '';
    final email = data['email'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Inquiry',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Looking for: $vehicleType',
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: const Text(
                    'INQUIRY',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inquiry Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDarkMode
                        ? Colors.grey.shade300
                        : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                if (dateTime != null)
                  _buildDetailRow(
                    context,
                    icon: Icons.access_time,
                    label: 'Preferred Date/Time',
                    value: DateFormat('MMM dd, yyyy \'at\' h:mm a')
                        .format(dateTime),
                  ),
                if (location.isNotEmpty)
                  _buildDetailRow(
                    context,
                    icon: Icons.location_on,
                    label: 'Location',
                    value: location,
                  ),
                if (details.isNotEmpty)
                  _buildDetailRow(
                    context,
                    icon: Icons.description,
                    label: 'Details',
                    value: details,
                  ),
                if (contactNumber.isNotEmpty)
                  _buildDetailRow(
                    context,
                    icon: Icons.phone,
                    label: 'Contact',
                    value: contactNumber,
                  ),
                if (email.isNotEmpty)
                  _buildDetailRow(
                    context,
                    icon: Icons.email,
                    label: 'Email',
                    value: email,
                  ),
                if (data['createdAt'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Submitted on ${DateFormat('MMM dd, yyyy \'at\' h:mm a').format((data['createdAt'] as Timestamp).toDate())}',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
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
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
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
}
