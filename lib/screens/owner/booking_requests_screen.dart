import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';

class BookingRequestsScreen extends StatelessWidget {
  const BookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Requests')),
        body:
            const Center(child: Text('Please log in to view booking requests')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Requests'),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
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
                    'When users request to book your vehicles, they\'ll appear here.',
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
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(16),
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
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardBorderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with vehicle info and status
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
                // Vehicle image
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

                // Vehicle details
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

                // Status chip
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

          // Request details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Requester info
                Row(
                  children: [
                    const Icon(Icons.person, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Request from $userName',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Trip details
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

                // Response options for pending requests
                if (isPending) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
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
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.red.shade300),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _respondToRequest(context, docId, 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Accept'),
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

  Future<void> _respondToRequest(
      BuildContext context, String docId, String status) async {
    try {
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
    } catch (error) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
