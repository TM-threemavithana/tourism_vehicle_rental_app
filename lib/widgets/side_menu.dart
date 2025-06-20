import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SideMenu extends StatefulWidget {
  final Function onClose;
  final Function onSignOut;
  final Function(String)? onTabChange;
  final Function? onProfileTap;
  final double width;
  final User? user;
  final String currentTab;

  const SideMenu({
    super.key,
    required this.onClose,
    required this.onSignOut,
    this.onTabChange,
    this.onProfileTap,
    this.width = 0.8,
    required this.user,
    this.currentTab = 'Search',
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  String? userType;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserType();
  }

  Future<void> _fetchUserType() async {
    if (widget.user?.uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user!.uid)
            .get();

        if (doc.exists) {
          setState(() {
            userType = doc.data()?['userType'] ?? 'renter';
            isLoading = false;
          });
        } else {
          setState(() {
            userType = 'renter';
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          userType = 'renter';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        userType = 'renter';
        isLoading = false;
      });
    }
  }

  String getInitials() {
    if (widget.user == null ||
        widget.user!.displayName == null ||
        widget.user!.displayName!.isEmpty) {
      return 'U';
    }
    List<String> names = widget.user!.displayName!.split(' ');
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    } else {
      return '${names[0].substring(0, 1)}${names[1].substring(0, 1)}'
          .toUpperCase();
    }
  }

  String getDisplayName() {
    return widget.user?.displayName ?? 'User';
  }

  String getEmail() {
    return widget.user?.email ?? 'No email';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: MediaQuery.of(context).size.width * widget.width,
        color: Colors.white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: MediaQuery.of(context).size.width * widget.width,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add top spacing
          const SizedBox(height: 20),

          // User Profile Section
          Container(
            padding: const EdgeInsets.all(20.0),
            child: InkWell(
              onTap: () {
                widget.onClose();
                if (widget.onProfileTap != null) {
                  widget.onProfileTap!();
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  // Profile Avatar
                  widget.user?.photoURL != null
                      ? Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: CachedNetworkImage(
                              imageUrl: widget.user!.photoURL!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.grey[600],
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              getInitials(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(width: 12),
                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getDisplayName(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          getEmail(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // User type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: userType == 'owner'
                                ? Colors.orange.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            userType == 'owner' ? 'Vehicle Owner' : 'Renter',
                            style: TextStyle(
                              color: userType == 'owner'
                                  ? Colors.orange
                                  : Colors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'View Profile',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 10,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          // Add space between divider and menu items
          const SizedBox(height: 16),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8), // Adjust padding here
              children: _buildMenuItems(),
            ),
          ),

          // Logout Section
          Container(
            margin: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () => widget.onSignOut(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.grey,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    if (userType == 'owner') {
      return [
        _buildMenuItem(context, Icons.dashboard_outlined, 'Dashboard',
            isActive: widget.currentTab == 'Dashboard'),
        _buildMenuItem(context, Icons.directions_car_outlined, 'My Vehicles',
            isActive: widget.currentTab == 'My Vehicles'),
        _buildMenuItem(context, Icons.calendar_today_outlined, 'Bookings',
            isActive: widget.currentTab == 'Bookings'),
        _buildMenuItem(context, Icons.analytics_outlined, 'Analytics',
            isActive: widget.currentTab == 'Analytics'),
        _buildMenuItem(
            context, Icons.account_balance_wallet_outlined, 'Earnings',
            isActive: widget.currentTab == 'Earnings'),
        _buildMenuItem(context, Icons.notifications_outlined, 'Notifications',
            isActive: widget.currentTab == 'Notifications'),
        _buildMenuItem(context, Icons.settings_outlined, 'Settings',
            isActive: widget.currentTab == 'Settings'),
        _buildMenuItem(context, Icons.help_outline, 'Help & Support',
            isActive: widget.currentTab == 'Help & Support'),
      ];
    } else {
      return [
        _buildMenuItem(context, Icons.search, 'Search Vehicles',
            isActive: widget.currentTab == 'Search'),
        _buildMenuItem(context, Icons.history_outlined, 'My Rentals',
            isActive: widget.currentTab == 'My Rentals'),
        _buildMenuItem(context, Icons.favorite_outline, 'Favorites',
            isActive: widget.currentTab == 'Favorites'),
        _buildMenuItem(context, Icons.notifications_outlined, 'Notifications',
            isActive: widget.currentTab == 'Notifications'),
        _buildMenuItem(context, Icons.payment_outlined, 'Payment Methods',
            isActive: widget.currentTab == 'Payment Methods'),
        _buildMenuItem(context, Icons.help_outline, 'Help & Support',
            isActive: widget.currentTab == 'Help & Support'),
        _buildMenuItem(context, Icons.info_outline, 'About',
            isActive: widget.currentTab == 'About'),
        _buildMenuItem(context, Icons.book_online, 'My Booking Requests',
            isActive: widget.currentTab == 'My Booking Requests'),
      ];
    }
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title,
      {bool isActive = false}) {
    return InkWell(
      onTap: () {
        widget.onClose();
        if (widget.onTabChange != null) {
          widget.onTabChange!(title);
        }

        // Add navigation for specific menu items
        switch (title) {
          case 'Favorites':
            Navigator.pushReplacementNamed(context, '/favorites');
            break;
          case 'Search Vehicles':
            Navigator.pushReplacementNamed(context, '/home');
            break;
          // Add other cases as needed
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          border: isActive
              ? Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 4,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[800],
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
