import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/onesignal_service.dart';

class BookingConfirmationSection extends StatefulWidget {
  final Map<String, dynamic> vehicleDetails;
  final DateTime pickupDate;
  final TimeOfDay pickupTime;
  final DateTime returnDate;
  final TimeOfDay returnTime;
  final bool withDriver;
  final bool hasApplied;

  const BookingConfirmationSection({
    super.key,
    required this.vehicleDetails,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
    required this.withDriver,
    required this.hasApplied,
  });

  @override
  State<BookingConfirmationSection> createState() =>
      _BookingConfirmationSectionState();
}

class _BookingConfirmationSectionState
    extends State<BookingConfirmationSection> {
  bool _isRequesting = false;
  bool _requestSent = false;
  String _requestStatus = ""; // "pending", "approved", "rejected"
  String? _requestId;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  Future<void> _checkExistingRequest() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Check for existing requests for this vehicle by this user
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('bookingRequests')
          .where('userId', isEqualTo: currentUser.uid)
          .where('vehicleId', isEqualTo: widget.vehicleDetails['id'])
          .where('status', whereIn: ['pending', 'approved', 'rejected'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (requestsSnapshot.docs.isNotEmpty) {
        final latestRequest = requestsSnapshot.docs.first;
        final data = latestRequest.data();

        setState(() {
          _requestSent = true;
          _requestId = latestRequest.id;
          _requestStatus = data['status'];
        });
      }
    } catch (e) {
      print('Error checking existing request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat("#,##0.00", "en_US");

    // Calculate rental details
    final rentalDetails = _calculateRentalDetails();

    // Helper to check login and redirect
    Future<void> handleRequestBooking() async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        // Not logged in, navigate to login
        Navigator.pushNamed(context, '/auth');
        return;
      }
      _sendBookingRequest();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: _getBorderColor(theme),
          width: widget.hasApplied ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _getHeaderIcon(),
                color: _getHeaderIconColor(theme),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _getHeaderTitle(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              if (!widget.hasApplied && !_requestSent) Spacer(),
              if (!widget.hasApplied && !_requestSent)
                Text(
                  '(estimated)',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
            ],
          ),

          // Request status message
          if (_requestStatus.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusBackgroundColor(),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(),
                    size: 18,
                    color: _getStatusColor(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getStatusMessage(),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 24),

          // Cost breakdown section
          Text(
            'Trip Cost',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),

          // Rate x duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Rs ${currencyFormat.format(rentalDetails['unitRate'])}/Day x ${rentalDetails['unitCount']} ${rentalDetails['unitLabel'].toLowerCase()}(s)',
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.grey.shade300
                        : Colors.grey.shade800,
                  ),
                ),
              ),
              Text(
                'Rs. ${currencyFormat.format(rentalDetails['tripCost'])}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Handling fee
          Text(
            'Handling Fee',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Will be charged at booking confirmation',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              Text(
                'Rs. ${currencyFormat.format(1000.00)}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Total rental cost
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rental Cost',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rental Cost for Trip',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Rs. ${currencyFormat.format(rentalDetails['rentalCost'])}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          // Trip duration info
          if (widget.hasApplied || _requestSent) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Trip Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              label: 'Duration',
              value:
                  '${rentalDetails['unitCount']} ${rentalDetails['unitLabel']}',
            ),
            _buildInfoRow(
              context,
              label: 'Pickup',
              value: _formatDateTime(widget.pickupDate, widget.pickupTime),
            ),
            _buildInfoRow(
              context,
              label: 'Return',
              value: _formatDateTime(widget.returnDate, widget.returnTime),
            ),
            _buildInfoRow(
              context,
              label: 'Driver',
              value: widget.withDriver ? 'Included' : 'Self Drive',
            ),
          ],

          const SizedBox(height: 24),

          // Request button (if not already sent)
          if (!_requestSent && !_isRequesting)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.hasApplied ? handleRequestBooking : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  disabledBackgroundColor:
                      isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  disabledForegroundColor:
                      isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                ),
                child: Text(
                    widget.hasApplied ? 'Request Booking' : 'Apply to Confirm'),
              ),
            ),

          // Loading indicator while sending request
          if (_isRequesting)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Sending request to vehicle owner...',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

          // Show status based on request response
          if (_requestSent && !_isRequesting)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusBackgroundColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getStatusMessage(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_requestStatus == "approved")
                    TextButton(
                      onPressed: () {
                        // Navigate to payment screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Proceeding to payment...')),
                        );
                      },
                      child: const Text('Pay Now'),
                    ),
                ],
              ),
            ),

          // Hint for user if not applied
          if (!widget.hasApplied && !_requestSent)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: Text(
                  'Click Apply to update booking details',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDarkMode
                        ? Colors.grey.shade500
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required String label, required String value}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$formattedDate at $hour:$minute';
  }

  Map<String, dynamic> _calculateRentalDetails() {
    // Calculate the number of days between pickup and return
    final difference = widget.returnDate.difference(widget.pickupDate).inDays;

    // Default values
    double unitRate = 0.0;
    int unitCount = 0;
    String unitLabel = "Day";
    String unitType = "daily";

    // Determine the best rate to use (hourly, daily, weekly, monthly)
    if (difference < 1) {
      // Less than a day - use hourly rate if available
      unitLabel = "Hour";
      unitType = "hourly";

      // Calculate hours, accounting for time of day
      final pickupDateTime = DateTime(
          widget.pickupDate.year,
          widget.pickupDate.month,
          widget.pickupDate.day,
          widget.pickupTime.hour,
          widget.pickupTime.minute);

      final returnDateTime = DateTime(
          widget.returnDate.year,
          widget.returnDate.month,
          widget.returnDate.day,
          widget.returnTime.hour,
          widget.returnTime.minute);

      unitCount = returnDateTime.difference(pickupDateTime).inHours;
      if (unitCount < 1) unitCount = 1;
    } else if (difference < 7) {
      // Less than a week - use daily rate
      unitLabel = "Day";
      unitType = "daily";
      unitCount = difference;
      if (unitCount < 1) unitCount = 1;
    } else if (difference < 30) {
      // Less than a month - use weekly rate if available
      unitLabel = "Week";
      unitType = "weekly";
      unitCount = (difference / 7).ceil();
    } else {
      // More than a month - use monthly rate if available
      unitLabel = "Month";
      unitType = "monthly";
      unitCount = (difference / 30).ceil();
    }

    // Get the appropriate rate based on the unit type and driver option
    final driverOption = widget.withDriver ? 'withDriver' : 'vehicleOnly';

    // Check if the selected rate type is available
    if (widget.vehicleDetails['pricing']?[unitType]?[driverOption] != null) {
      final price =
          widget.vehicleDetails['pricing'][unitType][driverOption]['price'];

      // Handle both String and num types for price
      if (price is num) {
        unitRate = price.toDouble();
      } else if (price is String) {
        unitRate = double.tryParse(price) ?? 0.0;
      }
    } else {
      // Fallback to daily rate if the selected rate isn't available
      final price =
          widget.vehicleDetails['pricing']?['daily']?[driverOption]?['price'];

      if (price is num) {
        unitRate = price.toDouble();
        unitLabel = "Day";
        unitCount = difference;
        if (unitCount < 1) unitCount = 1;
      } else if (price is String) {
        unitRate = double.tryParse(price) ?? 0.0;
        unitLabel = "Day";
        unitCount = difference;
        if (unitCount < 1) unitCount = 1;
      }
    }

    // Calculate costs
    final tripCost = unitRate * unitCount;
    const handlingFee = 1000.0;
    final rentalCost = tripCost + handlingFee;

    return {
      'unitRate': unitRate,
      'unitCount': unitCount,
      'unitLabel': unitLabel,
      'tripCost': tripCost,
      'handlingFee': handlingFee,
      'rentalCost': rentalCost,
    };
  }

  Future<void> _sendBookingRequest() async {
    // Set state to show loading
    setState(() {
      _isRequesting = true;
    });

    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Calculate rental details for the request
      final rentalDetails = _calculateRentalDetails();

      // Convert TimeOfDay to a storable format
      final pickupDateTime = DateTime(
        widget.pickupDate.year,
        widget.pickupDate.month,
        widget.pickupDate.day,
        widget.pickupTime.hour,
        widget.pickupTime.minute,
      );

      final returnDateTime = DateTime(
        widget.returnDate.year,
        widget.returnDate.month,
        widget.returnDate.day,
        widget.returnTime.hour,
        widget.returnTime.minute,
      );

      // Create booking request document
      final bookingRequest = {
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Guest',
        'userEmail': currentUser.email,
        'userPhone': currentUser.phoneNumber,
        'userPhotoUrl': currentUser.photoURL,
        'vehicleId': widget.vehicleDetails['id'],
        'vehicleInfo': {
          'make': widget.vehicleDetails['make'],
          'model': widget.vehicleDetails['model'],
          'year': widget.vehicleDetails['year'],
          'vehicleNo': widget.vehicleDetails['vehicleNo'],
          'primaryImage': widget.vehicleDetails['images']?['primaryImageUrl'],
        },
        'ownerId': widget.vehicleDetails['ownerId'],
        'pickupDateTime': pickupDateTime.toIso8601String(),
        'returnDateTime': returnDateTime.toIso8601String(),
        'withDriver': widget.withDriver,
        'pricing': {
          'unitRate': rentalDetails['unitRate'],
          'unitCount': rentalDetails['unitCount'],
          'unitLabel': rentalDetails['unitLabel'],
          'tripCost': rentalDetails['tripCost'],
          'handlingFee': rentalDetails['handlingFee'],
          'rentalCost': rentalDetails['rentalCost'],
        },
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'notified': false,
        'ownerNotified': false,
      };

      // Add to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('bookingRequests')
          .add(bookingRequest);

      // Find owner's OneSignal player ID
      final ownerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.vehicleDetails['ownerId'])
          .get();

      final ownerOneSignalId = ownerDoc.data()?['oneSignalPlayerId'];

      if (ownerOneSignalId != null) {
        final oneSignalService = OneSignalService();

        // Send notification to owner about new booking request
        await oneSignalService.sendNotificationToUser(
          playerId: ownerOneSignalId,
          title: "New Booking Request",
          content:
              "${currentUser.displayName} wants to rent your ${widget.vehicleDetails['make']} ${widget.vehicleDetails['model']}",
          notificationType: 'booking_request',
          data: {'requestId': _requestId},
        );
      }

      // Update state to show request sent
      setState(() {
        _isRequesting = false;
        _requestSent = true;
        _requestStatus = "pending";
        _requestId = docRef.id;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Booking request sent to the owner! You\'ll be notified when they respond.'),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (error) {
      // Handle error
      setState(() {
        _isRequesting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending request: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Send push notification to vehicle owner
  Future<void> _sendOwnerNotification(
      String ownerOneSignalId, String userName, String vehicleName) async {
    try {
      // Get the OneSignalService instance
      final oneSignalService = OneSignalService();

      // Send the notification
      await oneSignalService.sendNotificationToUser(
        playerId: ownerOneSignalId,
        title: "New Booking Request",
        content: "$userName wants to rent your $vehicleName",
        notificationType: 'booking_request',
        data: {'requestId': _requestId},
      );
    } catch (e) {
      print('Error sending OneSignal notification: $e');
    }
  }

  // Helper methods for UI elements
  Color _getBorderColor(ThemeData theme) {
    if (_requestStatus == "approved") {
      return Colors.green;
    } else if (_requestStatus == "rejected") {
      return Colors.red.shade300;
    } else if (_requestStatus == "pending") {
      return Colors.orange;
    } else {
      return widget.hasApplied
          ? theme.colorScheme.primary.withOpacity(0.5)
          : (theme.brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200);
    }
  }

  IconData _getHeaderIcon() {
    if (_requestStatus == "approved") {
      return Icons.check_circle;
    } else if (_requestStatus == "rejected") {
      return Icons.cancel;
    } else if (_requestStatus == "pending") {
      return Icons.schedule;
    } else {
      return widget.hasApplied ? Icons.check_circle : Icons.info_outline;
    }
  }

  Color _getHeaderIconColor(ThemeData theme) {
    if (_requestStatus == "approved") {
      return Colors.green;
    } else if (_requestStatus == "rejected") {
      return Colors.red;
    } else if (_requestStatus == "pending") {
      return Colors.orange;
    } else {
      return widget.hasApplied
          ? theme.colorScheme.primary
          : (theme.brightness == Brightness.dark
              ? Colors.grey.shade400
              : Colors.grey.shade600);
    }
  }

  String _getHeaderTitle() {
    if (_requestStatus == "approved") {
      return "Booking Approved";
    } else if (_requestStatus == "rejected") {
      return "Booking Declined";
    } else if (_requestStatus == "pending") {
      return "Request Pending";
    } else {
      return "Booking Confirmation";
    }
  }

  IconData _getStatusIcon() {
    switch (_requestStatus) {
      case "approved":
        return Icons.check_circle;
      case "rejected":
        return Icons.cancel;
      case "pending":
        return Icons.schedule;
      default:
        return Icons.info_outline;
    }
  }

  Color _getStatusColor() {
    switch (_requestStatus) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "pending":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBackgroundColor() {
    switch (_requestStatus) {
      case "approved":
        return Colors.green.withOpacity(0.1);
      case "rejected":
        return Colors.red.withOpacity(0.1);
      case "pending":
        return Colors.orange.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  String _getStatusMessage() {
    switch (_requestStatus) {
      case "approved":
        return "Your booking has been approved by the owner. You can now proceed to payment.";
      case "rejected":
        return "The owner couldn't accept your request at this time. Please try a different vehicle or time period.";
      case "pending":
        return "Your request has been sent to the owner. You'll be notified when they respond.";
      default:
        return "";
    }
  }
}
