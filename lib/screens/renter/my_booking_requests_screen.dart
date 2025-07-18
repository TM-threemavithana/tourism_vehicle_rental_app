import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../widgets/not_logged_in_widget.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../welcome_screen.dart';
import '../profile_screen.dart';

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
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                      'No booking requests yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Your booking requests will appear here',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
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
                              padding: const EdgeInsets.all(16),
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                final doc = snapshot.data!.docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                return _buildRequestCard(
                                    context, data, isDarkMode);
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
                  child: Image.network(
                    vehicleInfo['primaryImage'] ??
                        'https://via.placeholder.com/60?text=No+Image',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
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
                if (status == 'approved') ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Proceeding to payment...')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Proceed to Payment'),
                    ),
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
