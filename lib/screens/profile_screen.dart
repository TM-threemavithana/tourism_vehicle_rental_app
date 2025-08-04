import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinary_service.dart';
import '../services/auth_service.dart';
import '../screens/auth/auth_wrapper.dart';
import '../widgets/side_menu.dart';
import '../utils/app_colors.dart';
import 'welcome_screen.dart';
import 'owner/owner_dashboard_screen.dart';
import '../widgets/not_logged_in_widget.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'renter/my_booking_requests_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User? user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isMenuOpen = false;
  String? userType;
  final TextEditingController _nameController = TextEditingController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final AuthService _authService = AuthService();

  // Add a controller for the AnimatedIcon
  late AnimationController _menuIconController;

  // Add current tab tracking
  final String _currentTab = 'Profile';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user?.displayName ?? '';
    _fetchUserType();

    // Initialize the animation controller
    _menuIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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
          });
        } else {
          setState(() {
            userType = 'renter';
          });
        }
      } catch (e) {
        setState(() {
          userType = 'renter';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _menuIconController.dispose();
    super.dispose();
  }

  // Add these methods to handle menu functionality
  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _menuIconController.forward();
      } else {
        _menuIconController.reverse();
      }
    });
  }

  void _closeMenu() {
    setState(() {
      _isMenuOpen = false;
      _menuIconController.reverse();
    });
  }

  void _updateCurrentTab(String tab) {
    _closeMenu();
    if (tab == _currentTab) return;

    // Navigate based on tab selection
    switch (tab) {
      case 'Search':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
        break;
      case 'Vehicle Bookings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bookings Screen - Coming Soon')),
        );
        break;
      case 'Your Vehicles':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your Vehicles Screen - Coming Soon')),
        );
        break;
    }
  }

  // Add sign out method
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Future<void> _updateUserName() async {
    if (widget.user == null) return;

    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == widget.user!.displayName) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update display name in Firebase Auth
      await widget.user!.updateDisplayName(newName);

      // Refresh the user to get updated info
      await FirebaseAuth.instance.currentUser?.reload();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Method to handle profile picture update
  Future<void> _updateProfilePicture() async {
    if (widget.user == null) return;

    // Show image source selection dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Update Profile Picture',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  title: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _getImageFromSource(true);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  title: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _getImageFromSource(false);
                  },
                ),
                if (widget.user?.photoURL != null)
                  _buildImageSourceOption(
                    icon: Icons.delete,
                    title: 'Remove',
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfilePicture();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper method to build image source options
  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isUploadingImage || _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Method to handle image selection and upload
  Future<void> _getImageFromSource(bool isCamera) async {
    try {
      File? imageFile;

      if (isCamera) {
        imageFile = await _cloudinaryService.takePhoto();
      } else {
        imageFile = await _cloudinaryService.pickImage();
      }

      if (imageFile != null) {
        _uploadImageToCloudinary(imageFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to upload the image to Cloudinary
  Future<void> _uploadImageToCloudinary(File imageFile) async {
    if (widget.user == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Upload to Cloudinary
      final response = await _cloudinaryService.uploadImage(
        imageFile,
        widget.user!.uid,
      );

      if (response != null) {
        // Update the user's profile with the new image URL
        await widget.user!.updatePhotoURL(response.secureUrl);
        await FirebaseAuth.instance.currentUser?.reload();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Update UI
          setState(() {});
        }
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  // Method to remove the profile picture with confirmation
  Future<void> _removeProfilePicture() async {
    if (widget.user == null || widget.user!.photoURL == null) return;

    // Show confirmation dialog
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Profile Picture'),
            content: const Text(
                'Are you sure you want to remove your profile picture?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Remove photo URL from Firebase Auth user profile
      await widget.user!.updatePhotoURL(null);
      await FirebaseAuth.instance.currentUser?.reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Add this method to refresh user data
  Future<void> _refreshUserData() async {
    if (widget.user != null) {
      await FirebaseAuth.instance.currentUser?.reload();
      setState(() {
        // This will trigger a rebuild with fresh user data
      });
    }
  }

  // Add this method to the _ProfileScreenState class
  Future<void> _switchUserType() async {
    // First get the current user type
    final currentUserType = await _authService.getUserType();

    // Toggle the user type
    final newUserType = currentUserType == 'renter' ? 'owner' : 'renter';

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.updateUserType(newUserType);

      // Navigate to the appropriate screen
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => newUserType == 'owner'
              ? const OwnerDashboardScreen()
              : const WelcomeScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error switching user type: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return Scaffold(
        body: const NotLoggedInWidget(),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: 2,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              );
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const MyBookingRequestsScreen()),
              );
            }
          },
        ),
      );
    }
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          userType == 'owner' ? 'Owner Profile' : 'My Profile',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _menuIconController,
          ),
          onPressed: _toggleMenu,
        ),
        actions: [
          // User type indicator badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: userType == 'owner'
                  ? Colors.orange.withOpacity(0.9)
                  : Colors.blue.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              userType == 'owner' ? 'OWNER' : 'RENTER',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Switch mode button (only show for renters)
          if (userType == 'renter')
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.swap_horiz, color: Colors.white),
              onPressed: _isLoading ? null : _switchUserType,
              tooltip: 'Switch to Owner Mode',
            ),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Yellow status bar overlay
          Container(
            height: MediaQuery.of(context).padding.top,
            color: const Color(0xFFFFC107),
          ),
          // Main content
          SingleChildScrollView(
            child: Column(
              children: [
                // Profile header with gradient background
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: userType == 'owner'
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.orange.shade400,
                              Colors.deepOrange.shade600,
                            ],
                          )
                        : AppColors.profileHeaderGradient,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 80, 20, 30),
                      child: Column(
                        children: [
                          // Profile picture with edit button
                          Stack(
                            children: [
                              // Profile picture
                              _isUploadingImage
                                  ? Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 70,
                                      backgroundColor:
                                          Colors.white.withOpacity(0.3),
                                      backgroundImage:
                                          widget.user?.photoURL != null
                                              ? CachedNetworkImageProvider(
                                                  widget.user!.photoURL!)
                                              : null,
                                      child: widget.user?.photoURL == null
                                          ? Text(
                                              _getInitials(),
                                              style: const TextStyle(
                                                fontSize: 42,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),

                              // Edit button
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 5,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.camera_alt,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    onPressed: _isUploadingImage || _isLoading
                                        ? null
                                        : _updateProfilePicture,
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // User name
                          Text(
                            widget.user?.displayName ?? 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          // User email
                          Text(
                            widget.user?.email ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content area
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information Section
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildInfoField(
                                label: 'Full Name',
                                value: _nameController.text,
                                icon: Icons.person_outline,
                                color: theme.colorScheme.primary,
                                isEditable: true,
                                onTap: () {
                                  _showEditNameDialog(context);
                                },
                              ),
                              const Divider(height: 24),
                              _buildInfoField(
                                label: 'Email',
                                value: widget.user?.email ?? 'No email',
                                icon: Icons.email_outlined,
                                color: theme.colorScheme.primary,
                                verified: widget.user?.emailVerified ?? false,
                              ),
                              const Divider(height: 24),
                              _buildInfoField(
                                label: 'Contact Info',
                                value: 'Add your phone number',
                                icon: Icons.phone_outlined,
                                color: theme.colorScheme.primary,
                                isEditable: true,
                                onTap: () {
                                  _showEditContactDialog(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Account & Security Section
                      const Text(
                        'Account & Security',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            _buildMenuOption(
                              icon: Icons.lock_outline,
                              title: 'Change Password',
                              subtitle: 'Update your security credentials',
                              iconColor: Colors.orange,
                              theme: theme,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Delete Account Option
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: _buildMenuOption(
                          icon: Icons.delete_outline,
                          title: 'Delete Account',
                          subtitle: 'Permanently remove your account and data',
                          iconColor: Colors.red,
                          theme: theme,
                          isDanger: true,
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Side Menu and Overlay
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

            // Side Menu
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.7,
              child: SideMenu(
                onClose: _closeMenu,
                onSignOut: _signOut,
                onTabChange: _updateCurrentTab,
                onProfileTap: () {
                  // First close the menu
                  _closeMenu();
                  // No need to navigate since we're already on the profile screen
                  // Or if you want to refresh: _refreshUserData();
                },
                width: 0.7,
                user: widget.user,
                currentTab: _currentTab,
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const MyBookingRequestsScreen()),
            );
          }
        },
      ),
    );
  }

  Future<void> _showEditNameDialog(BuildContext context) {
    final newNameController = TextEditingController(text: _nameController.text);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Full Name'),
        content: TextField(
          controller: newNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (newNameController.text.trim().isNotEmpty) {
                _nameController.text = newNameController.text.trim();
                _updateUserName();
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditContactDialog(BuildContext context) {
    final contactController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contact Info'),
        content: TextField(
          controller: contactController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter your phone number',
          ),
          keyboardType: TextInputType.phone,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (contactController.text.trim().isNotEmpty) {
                // TODO: Implement contact info update
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contact info updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  hintText: '********',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  hintText: '********',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  hintText: '********',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New passwords do not match'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isLoading = true;
                      });

                      try {
                        // Reauthenticate with current password
                        final credential = EmailAuthProvider.credential(
                          email: widget.user?.email ?? '',
                          password: currentPasswordController.text,
                        );
                        await widget.user
                            ?.reauthenticateWithCredential(credential);

                        // Change password
                        await widget.user
                            ?.updatePassword(newPasswordController.text);

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountConfirmation() {
    bool isLoading = false;
    final passwordController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please enter your password to confirm:',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: '********',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() {
                        isLoading = true;
                      });

                      try {
                        // Reauthenticate with password
                        final credential = EmailAuthProvider.credential(
                          email: widget.user?.email ?? '',
                          password: passwordController.text,
                        );
                        await widget.user
                            ?.reauthenticateWithCredential(credential);

                        // Delete the user account
                        await widget.user?.delete();

                        // Navigate back to login screen
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const AuthWrapper(),
                            ),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ))
                  : const Text('Delete My Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      endIndent: 16,
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isEditable = false,
    bool verified = false,
    bool showVerify = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isEditable ? onTap : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (verified)
            const Icon(
              Icons.verified,
              color: Colors.green,
              size: 20,
            )
          else if (showVerify)
            TextButton(
              onPressed: () {
                // Show verification dialog
              },
              child: const Text(
                'Verify',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (isEditable)
            const Icon(
              Icons.edit,
              color: Colors.grey,
              size: 20,
            ),
        ],
      ),
    );
  }

  // Updated _buildMenuOption function with proper handlers
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required ThemeData theme,
    bool showBadge = false,
    bool isDanger = false,
  }) {
    VoidCallback? onTap;

    // Assign proper actions based on the title
    switch (title) {
      case 'Change Password':
        onTap = () {
          _showChangePasswordDialog();
        };
        break;
      case 'Delete Account':
        onTap = () {
          _showDeleteAccountConfirmation();
        };
        break;
      default:
        onTap = () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title - Coming Soon')),
          );
        };
        break;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                if (showBadge)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDanger ? Colors.red : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials() {
    if (widget.user == null ||
        widget.user!.displayName == null ||
        widget.user!.displayName!.isEmpty) {
      return 'U';
    }

    final nameParts = widget.user!.displayName!.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return nameParts[0][0].toUpperCase();
  }
}
