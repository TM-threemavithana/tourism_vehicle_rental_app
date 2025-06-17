import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';

class NonOwnerVehicleForm extends StatefulWidget {
  const NonOwnerVehicleForm({super.key});

  @override
  State<NonOwnerVehicleForm> createState() => _NonOwnerVehicleFormState();
}

class _NonOwnerVehicleFormState extends State<NonOwnerVehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isLoading = false;

  String _vehicleType = 'Car';
  final List<String> _vehicleTypes = ['Bike', 'Three-Wheeler', 'Car'];
  String _relationshipToOwner = 'Family Member';
  final List<String> _relationshipOptions = [
    'Family Member',
    'Employee',
    'Business Partner',
    'Friend',
    'Other'
  ];

  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerContactController = TextEditingController();
  final TextEditingController _otherRelationshipController =
      TextEditingController();

  List<XFile> _selectedImages = [];
  List<XFile> _registrationDocImages = [];
  List<XFile> _authorizationDocImages = [];

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _registrationNumberController.dispose();
    _ownerNameController.dispose();
    _ownerContactController.dispose();
    _otherRelationshipController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages = pickedFiles;
      });
    }
  }

  Future<void> _pickRegistrationDocImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _registrationDocImages = pickedFiles;
      });
    }
  }

  Future<void> _pickAuthorizationDocImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _authorizationDocImages = pickedFiles;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please add at least one vehicle image')),
        );
        return;
      }

      if (_registrationDocImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please add registration document images')),
        );
        return;
      }

      if (_authorizationDocImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add authorization documents')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Upload vehicle images to Cloudinary
        List<String> imageUrls = [];
        for (var image in _selectedImages) {
          final response = await _cloudinaryService.uploadImage(
            File(image.path),
            FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
          );
          if (response != null) {
            imageUrls.add(response.secureUrl);
          }
        }

        // Upload registration documents
        List<String> registrationDocUrls = [];
        for (var image in _registrationDocImages) {
          final response = await _cloudinaryService.uploadImage(
            File(image.path),
            FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
          );
          if (response != null) {
            registrationDocUrls.add(response.secureUrl);
          }
        }

        // Upload authorization documents
        List<String> authorizationDocUrls = [];
        for (var image in _authorizationDocImages) {
          final response = await _cloudinaryService.uploadImage(
            File(image.path),
            FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
          );
          if (response != null) {
            authorizationDocUrls.add(response.secureUrl);
          }
        }

        // Save vehicle to database - implement this in a future update
        // For now, just show a success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle submitted for verification!')),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Non-Owned Vehicle'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Non-ownership status indicator
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "You've indicated you are not the registered owner. Please provide additional information and documentation.",
                              style: TextStyle(
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Owner Information Section
                    const Text(
                      'Registered Owner Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Owner Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter owner\'s name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _ownerContactController,
                      decoration: const InputDecoration(
                        labelText: 'Owner Contact Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter owner\'s contact number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Relationship to owner dropdown
                    const Text(
                      'Your Relationship to the Owner',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _relationshipToOwner,
                          items: _relationshipOptions.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _relationshipToOwner = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Other relationship field if "Other" is selected
                    if (_relationshipToOwner == 'Other')
                      Column(
                        children: [
                          TextFormField(
                            controller: _otherRelationshipController,
                            decoration: const InputDecoration(
                              labelText: 'Specify Relationship',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_relationshipToOwner == 'Other' &&
                                  (value == null || value.isEmpty)) {
                                return 'Please specify your relationship to the owner';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),

                    const Divider(height: 32),

                    // Vehicle Details Section
                    const Text(
                      'Vehicle Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Type Selection
                    const Text(
                      'Vehicle Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _vehicleType,
                          items: _vehicleTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(_getVehicleIcon(type)),
                                  const SizedBox(width: 12),
                                  Text(type),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _vehicleType = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Vehicle Details
                    TextFormField(
                      controller: _makeController,
                      decoration: const InputDecoration(
                        labelText: 'Make/Brand',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter vehicle make';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter vehicle model';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter vehicle year';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid year';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Registration number field
                    TextFormField(
                      controller: _registrationNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Registration Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter registration number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Rental Price (per day)',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter rental price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter vehicle location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter vehicle description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    const Divider(height: 32),

                    // Documents Section
                    const Text(
                      'Required Documents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Images Section
                    const Text(
                      'Vehicle Images',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: _selectedImages.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 40),
                                  SizedBox(height: 8),
                                  Text('Add Vehicle Images'),
                                ],
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Image.file(
                                          File(_selectedImages[index].path),
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedImages.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Registration Document Images
                    const Text(
                      'Vehicle Registration Documents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Upload clear images of the vehicle registration certificate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickRegistrationDocImages,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: _registrationDocImages.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_file, size: 40),
                                  SizedBox(height: 8),
                                  Text('Upload Registration Documents'),
                                ],
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _registrationDocImages.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Image.file(
                                          File(_registrationDocImages[index]
                                              .path),
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _registrationDocImages
                                                  .removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Authorization Document Images
                    const Text(
                      'Authorization Documents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Upload authorization letter from the vehicle owner and their ID proof',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickAuthorizationDocImages,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: _authorizationDocImages.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.file_present, size: 40),
                                  SizedBox(height: 8),
                                  Text('Upload Authorization Documents'),
                                ],
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _authorizationDocImages.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Image.file(
                                          File(_authorizationDocImages[index]
                                              .path),
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _authorizationDocImages
                                                  .removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'SUBMIT FOR VERIFICATION',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Note about verification
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vehicles listed by non-owners require additional verification which may take 1-2 business days.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  IconData _getVehicleIcon(String type) {
    switch (type) {
      case 'Bike':
        return Icons.directions_bike;
      case 'Three-Wheeler':
        return Icons.directions_car_filled;
      case 'Car':
        return Icons.directions_car;
      default:
        return Icons.directions_car;
    }
  }
}
