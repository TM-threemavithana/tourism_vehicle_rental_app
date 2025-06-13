import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final Function onClose;
  final Function onSignOut;
  final double width;

  const SideMenu({
    Key? key,
    required this.onClose,
    required this.onSignOut,
    this.width = 0.7, // 70% of screen width
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.white, // Changed from black to white
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.black, // Changed to black
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.black, // Changed to black
                    ),
                    onPressed: () => onClose(),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.black12), // Changed to light black
            _buildMenuItem(context, Icons.home, 'Home'),
            _buildMenuItem(context, Icons.search, 'Search Vehicles'),
            _buildMenuItem(context, Icons.history, 'Booking History'),
            _buildMenuItem(context, Icons.favorite, 'Favorites'),
            _buildMenuItem(context, Icons.person, 'My Profile'),
            _buildMenuItem(context, Icons.settings, 'Settings'),
            const Spacer(),
            const Divider(color: Colors.black12), // Changed to light black
            InkWell(
              onTap: () => onSignOut(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors
                          .red, // Changed to red for better visibility on white
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.red, // Changed to red
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title) {
    return InkWell(
      onTap: () {
        onClose();
        // Navigate to the corresponding screen
        // For now, just print the menu item
        print('Selected menu item: $title');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.black87, // Changed to dark gray
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87, // Changed to dark gray
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
