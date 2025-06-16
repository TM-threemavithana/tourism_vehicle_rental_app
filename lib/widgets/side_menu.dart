import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SideMenu extends StatelessWidget {
  final Function onClose;
  final Function onSignOut;
  final Function(String)? onTabChange;
  final Function? onProfileTap; // Add this callback for profile navigation
  final double width;
  final User? user;
  final String currentTab;

  const SideMenu({
    super.key,
    required this.onClose,
    required this.onSignOut,
    this.onTabChange,
    this.onProfileTap, // Add this parameter
    this.width = 0.8,
    required this.user,
    this.currentTab = 'Search',
  });

  @override
  Widget build(BuildContext context) {
    // Get initials for avatar
    String getInitials() {
      if (user == null ||
          user!.displayName == null ||
          user!.displayName!.isEmpty) {
        return 'U'; // Default if no name available
      }

      final nameParts = user!.displayName!.split(' ');
      if (nameParts.length > 1) {
        return '${nameParts[0][0]}${nameParts[1][0]}';
      }
      return nameParts[0][0];
    }

    // Get display name or email
    String getDisplayName() {
      if (user == null) {
        return 'Guest User';
      }
      return user!.displayName ?? 'User';
    }

    // Get email or empty string
    String getEmail() {
      if (user == null) {
        return '';
      }
      return user!.email ?? '';
    }

    return Container(
      width: MediaQuery.of(context).size.width * width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            Container(
              padding: const EdgeInsets.all(20.0),
              child: InkWell(
                onTap: () {
                  // Close the menu and navigate to profile
                  onClose();
                  if (onProfileTap != null) {
                    onProfileTap!();
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    // Profile Avatar - using initials or photoURL
                    user?.photoURL != null
                        ? Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: CachedNetworkImage(
                                imageUrl: user!.photoURL!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.0),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: Text(
                                      getInitials(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                getInitials(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(width: 12),
                    // User Info - Dynamic from user data
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

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(context, Icons.search, 'Search',
                      isActive: currentTab ==
                          'Search'), // Changed from 'Home' to 'Search'
                  _buildMenuItem(context, Icons.calendar_today_outlined,
                      'Vehicle Bookings',
                      isActive: currentTab == 'Vehicle Bookings'),
                  _buildMenuItem(
                      context, Icons.directions_car_outlined, 'Your Vehicles',
                      isActive: currentTab == 'Your Vehicles'),
                  _buildMenuItem(
                      context, Icons.notifications_outlined, 'Notifications',
                      isActive: currentTab == 'Notifications'),
                  _buildMenuItem(context, Icons.help_outline, 'FAQ',
                      isActive: currentTab == 'FAQ'),
                  _buildMenuItem(context, Icons.info_outline, 'About Us',
                      isActive: currentTab == 'About Us'),
                ],
              ),
            ),

            // Logout Section
            Container(
              margin: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () => onSignOut(),
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
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title,
      {bool isActive = false}) {
    return InkWell(
      onTap: () {
        onClose();
        // Call the tab change callback if provided
        if (onTabChange != null) {
          onTabChange!(title);
        }
        // Navigation logic would go here
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
