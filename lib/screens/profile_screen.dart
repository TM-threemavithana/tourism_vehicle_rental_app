import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/cloudinary_service.dart'; // Import the new service
import '../screens/auth/auth_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  final User? user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isUploadingImage = false;
  final TextEditingController _nameController = TextEditingController();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Hardcoded stats until Firestore is set up
  final Map<String, String> _userStats = {
    'vehiclesRented': '0',
    'totalReviews': '0',
    'vehiclesListed': '0',
    'activeRentals': '0',
  };

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

  // New method to handle profile picture update
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
            const Text(
              'Update Profile Picture',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
              ],
            ),
            const SizedBox(height: 20),
            if (widget.user?.photoURL != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _removeProfilePicture();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Remove Current Photo'),
              ),
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
      onTap: _isUploadingImage || _isLoading
          ? null
          : onTap, // Disable when either loading state is true
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
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

  // Method to remove the profile picture
  Future<void> _removeProfilePicture() async {
    if (widget.user == null || widget.user!.photoURL == null) return;

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

        // Update UI
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing profile picture: $e'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section with Gradient Background
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // Profile Picture with Edit Button
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _isUploadingImage
                            ? Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.2),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: theme.colorScheme.secondary,
                                    strokeWidth: 3,
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                radius: 70,
                                backgroundColor: theme.colorScheme.secondary,
                                backgroundImage: widget.user?.photoURL != null
                                    ? CachedNetworkImageProvider(
                                        widget.user!.photoURL!)
                                    : null,
                                child: widget.user?.photoURL == null
                                    ? Text(
                                        _getInitials(),
                                        style: const TextStyle(
                                          fontSize: 50,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: InkWell(
                          onTap: _isUploadingImage || _isLoading
                              ? null
                              : _updateProfilePicture, // Disable when either loading state is true
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: _isUploadingImage
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // User Name - from Firebase Auth
                  Text(
                    widget.user?.displayName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Email with Verification - from Firebase Auth
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.user?.emailVerified ?? false
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.user?.email ?? 'No email',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Curved bottom edge
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info Cards Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Personal Info Card
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Account & Security',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Security Options
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        _buildMenuOption(
                          icon: Icons.credit_card_outlined,
                          title: 'Payment Methods',
                          subtitle: 'Add or remove payment options',
                          iconColor: Colors.indigo,
                          theme: theme,
                        ),
                        _buildDivider(),
                        _buildMenuOption(
                          icon: Icons.account_balance_outlined,
                          title: 'Bank Account',
                          subtitle: 'Set up for deposits and withdrawals',
                          iconColor: Colors.blue,
                          theme: theme,
                        ),
                        _buildDivider(),
                        _buildMenuOption(
                          icon: Icons.verified_user_outlined,
                          title: 'License Verification',
                          subtitle:
                              'Upload your driving license for verification',
                          iconColor: Colors.green,
                          theme: theme,
                          showBadge: true,
                        ),
                        _buildDivider(),
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

                  // Statistics Section - Data from Firestore
                  const Text(
                    'Activity Statistics',
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
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                    _userStats['vehiclesRented'] ?? '0',
                                    'Vehicles\nRented',
                                    Colors.deepPurple,
                                    Icons.directions_car_outlined),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                    _userStats['totalReviews'] ?? '0',
                                    'Total\nReviews',
                                    Colors.amber,
                                    Icons.star_outline),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                    _userStats['vehiclesListed'] ?? '0',
                                    'Vehicles\nListed',
                                    Colors.teal,
                                    Icons.add_circle_outline),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                    _userStats['activeRentals'] ?? '0',
                                    'Active\nRentals',
                                    Colors.red,
                                    Icons.local_activity_outlined),
                              ),
                            ],
                          ),
                        ],
                      ),
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
      case 'Payment Methods':
        onTap = () {
          // Navigate to payment methods screen or show dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment Methods - Coming Soon')),
          );
        };
        break;
      case 'Bank Account':
        onTap = () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Bank Account Settings - Coming Soon')),
          );
        };
        break;
      case 'License Verification':
        onTap = () {
          // Show license upload dialog or navigate to verification screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('License Verification - Coming Soon')),
          );
        };
        break;
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

  Widget _buildStatItem(
      String number, String label, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          number,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
