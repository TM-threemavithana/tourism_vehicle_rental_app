import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/side_menu.dart';
import 'owner/booking_requests_screen.dart';
import 'vehicle_detail_page.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isMenuOpen = false;
  String _currentTab = 'Notifications';
  String _userType = 'renter'; // Default, will be updated in initState

  @override
  void initState() {
    super.initState();
    _fetchUserType();
  }

  Future<void> _fetchUserType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _userType = doc.data()?['userType'] ?? 'renter';
          });
        }
      } catch (e) {
        debugPrint("Error fetching user type: $e");
      }
    }
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _closeMenu() {
    setState(() {
      _isMenuOpen = false;
    });
  }

  void _updateCurrentTab(String tabName) {
    _closeMenu();
    if (tabName == _currentTab) return;

    // Navigate based on tab selection
    switch (tabName) {
      case 'Search Vehicles':
      case 'Dashboard':
        Navigator.pushReplacementNamed(
            context, _userType == 'owner' ? '/owner-dashboard' : '/home');
        break;
      // Add other navigation options as needed
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_userType == 'owner') {
      await FirebaseFirestore.instance
          .collection('bookingRequests')
          .doc(notificationId)
          .update({'ownerNotified': true});
    } else {
      await FirebaseFirestore.instance
          .collection('bookingRequests')
          .doc(notificationId)
          .update({'notified': true});
    }
  }

  Future<void> _handleNotificationTap(DocumentSnapshot notification) async {
    // Mark notification as read
    await _markAsRead(notification.id);

    final data = notification.data() as Map<String, dynamic>;

    if (_userType == 'owner') {
      // For owners, navigate to booking request details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BookingRequestsScreen(),
        ),
      );
    } else {
      // For renters, navigate to vehicle details if approved
      if (data['status'] == 'approved') {
        final vehicleInfo = data['vehicleInfo'] as Map<String, dynamic>?;
        // Navigate to vehicle details or payment screen
        if (vehicleInfo != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailPage(vehicle: vehicleInfo),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle details not available'),
            ),
          );
        }
      }
    }
  }

  Widget _buildNotificationItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(createdAt);

    String title = '';
    String description = '';
    IconData icon = Icons.notifications;
    Color iconColor = Colors.blue;

    if (_userType == 'owner') {
      // Notifications for owners
      final renterName = data['userName'] ?? 'Someone';
      final vehicleInfo = data['vehicleInfo'] as Map<String, dynamic>? ?? {};
      final vehicleName =
          '${vehicleInfo['make'] ?? ''} ${vehicleInfo['model'] ?? ''}';

      title = 'New Booking Request';
      description = '$renterName wants to rent your $vehicleName';
      icon = Icons.calendar_today;
      iconColor = Colors.orange;
    } else {
      // Notifications for renters
      final status = data['status'] ?? 'pending';
      final vehicleInfo = data['vehicleInfo'] as Map<String, dynamic>? ?? {};
      final vehicleName =
          '${vehicleInfo['make'] ?? ''} ${vehicleInfo['model'] ?? ''}';

      if (status == 'approved') {
        title = 'Booking Approved';
        description = 'Your request to book $vehicleName has been approved!';
        icon = Icons.check_circle;
        iconColor = Colors.green;
      } else if (status == 'rejected') {
        title = 'Booking Declined';
        description = 'Your request to book $vehicleName was declined';
        icon = Icons.cancel;
        iconColor = Colors.red;
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(description),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _toggleMenu,
        ),
      ),
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: _userType == 'owner'
                      ? FirebaseFirestore.instance
                          .collection('bookingRequests')
                          .where('ownerId',
                              isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                          .orderBy('createdAt', descending: true)
                          .limit(50)
                          .snapshots()
                      : FirebaseFirestore.instance
                          .collection('bookingRequests')
                          .where('userId',
                              isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                          .orderBy('createdAt', descending: true)
                          .limit(50)
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
                              Icons.notifications_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    // For renters, filter to only show approved or rejected notifications
                    final filteredDocs = _userType != 'owner'
                        ? docs.where((doc) {
                            final docData = doc.data() as Map<String, dynamic>;
                            final status = docData['status'] ?? '';
                            return status == 'approved' || status == 'rejected';
                          }).toList()
                        : docs;

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Expanded(
                      child: ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          return _buildNotificationItem(doc);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Side menu and overlay
          if (_isMenuOpen) ...[
            // Semi-transparent overlay
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),

            // Side menu
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.7,
              child: SideMenu(
                onClose: _closeMenu,
                onSignOut: _signOut,
                onTabChange: _updateCurrentTab,
                width: 0.7,
                user: FirebaseAuth.instance.currentUser,
                currentTab: _currentTab,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
