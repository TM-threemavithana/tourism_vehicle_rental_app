import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/cloudinary_service.dart';
import '../../models/vehicle_form_models.dart';
import 'sections/vehicle_details_section.dart';
import 'sections/collection_point_section.dart';
import 'sections/rental_conditions_section.dart';
import 'sections/driver_details_section.dart';
import 'sections/pricing_section.dart';
import 'sections/extras_section.dart';
import 'sections/insurance_section.dart';
import 'sections/vehicle_images_section.dart';
import '../../widgets/form_widgets.dart';

class OwnerVehicleForm extends StatefulWidget {
  const OwnerVehicleForm({super.key});

  @override
  State<OwnerVehicleForm> createState() => _OwnerVehicleFormState();
}

class _OwnerVehicleFormState extends State<OwnerVehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Form data state
  late VehicleBasicDetails _vehicleDetails;
  late CollectionPoint _collectionPoint;
  late RentalConditions _rentalConditions;
  late DriverDetails _driverDetails;
  late VehiclePricing _pricing;
  late VehicleExtras _vehicleExtras;
  late VehicleInsurance _vehicleInsurance; // Add to your state variables
  late VehicleImages _vehicleImages;
  List<XFile> _registrationDocImages = [];
  bool _agreementChecked =
      false; // Add this to your state variables in _OwnerVehicleFormState

  @override
  void initState() {
    super.initState();
    // Initialize with empty data
    _vehicleDetails = VehicleBasicDetails();
    _collectionPoint = CollectionPoint();
    _rentalConditions = RentalConditions();
    _driverDetails = DriverDetails();
    _pricing = VehiclePricing();
    _vehicleExtras = VehicleExtras();
    _vehicleInsurance = VehicleInsurance();
    _vehicleImages = VehicleImages(); // Add this line
  }

  Future<void> _pickRegistrationDocImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _registrationDocImages = pickedFiles;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if agreement is checked
    if (!_agreementChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please agree to the vehicle owners agreement')),
      );
      return;
    }

    // Check if at least one rental period is selected
    if (!_pricing.rentalPeriods.values.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one rental time period')),
      );
      return;
    }

    // Check for registration documents
    if (_registrationDocImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add registration document images')),
      );
      return;
    }

    // Check if at least one image is selected
    if (_vehicleImages.imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one vehicle image')),
      );
      return;
    }

    // Check if all required images are uploaded
    bool allRequiredImagesUploaded = true;
    for (int i = 0; i < 7; i++) {
      if (!_vehicleImages.imageUrls.asMap().containsKey(i) ||
          _vehicleImages.imageUrls[i].isEmpty) {
        allRequiredImagesUploaded = false;
        break;
      }
    }

    if (!allRequiredImagesUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload all required vehicle images')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload all images to your storage service (Cloudinary or Firebase Storage)
      // This part depends on your implementation, but typically:
      List<String> uploadedImageUrls = [];
      String primaryImageUrl = '';

      for (String localPath in _vehicleImages.imageUrls) {
        // Upload image and get URL
        // For example:
        final response = await _cloudinaryService.uploadImage(
          File(localPath),
          FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        );

        if (response != null) {
          uploadedImageUrls.add(response.secureUrl);

          // Set primary image URL
          if (localPath == _vehicleImages.primaryImageUrl) {
            primaryImageUrl = response.secureUrl;
          }
        }
      }

      // If primary image not set but we have images, use the first one
      if (primaryImageUrl.isEmpty && uploadedImageUrls.isNotEmpty) {
        primaryImageUrl = uploadedImageUrls[0];
      }

      // First create the pricing map with the correct types
      Map<String, dynamic> pricingMap = {
        'vehicleValue': _pricing.vehicleValue,
        'rentalPeriods': _pricing.rentalPeriods,
      };

      // Add pricing details for each period
      if (_pricing.rentalPeriods['Hourly'] == true && _pricing.hourly != null) {
        pricingMap['hourly'] = _pricing.hourly!.toMap();
      }

      if (_pricing.rentalPeriods['Daily'] == true && _pricing.daily != null) {
        pricingMap['daily'] = _pricing.daily!.toMap();
      }

      if (_pricing.rentalPeriods['Weekly'] == true && _pricing.weekly != null) {
        pricingMap['weekly'] = _pricing.weekly!.toMap();
      }

      if (_pricing.rentalPeriods['Monthly'] == true &&
          _pricing.monthly != null) {
        pricingMap['monthly'] = _pricing.monthly!.toMap();
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

      // Convert all form data to a map that can be saved to Firebase
      final vehicleData = {
        // Basic vehicle details
        'type': _vehicleDetails.vehicleType,
        'make': _vehicleDetails.make,
        'model': _vehicleDetails.model,
        'category': _vehicleDetails.category,
        'grade': _vehicleDetails.grade,
        'year': _vehicleDetails.year,
        'vehicleNo': _vehicleDetails.vehicleNo,
        'chassisNo': _vehicleDetails.chassisNo,
        'engineNo': _vehicleDetails.engineNo,
        'engineCapacity': _vehicleDetails.engineCapacity,
        'transmission': _vehicleDetails.transmission,
        'fuelType': _vehicleDetails.fuelType,
        'color': _vehicleDetails.color,
        'seatingCapacity': _vehicleDetails.seatingCapacity,
        'doors': _vehicleDetails.doors,

        // Collection point
        'collectionPoint': {
          'district': _collectionPoint.district,
          'city': _collectionPoint.city,
          'address': _collectionPoint.address,
        },

        // Rental conditions
        'rentalConditions': {
          'minRentalPeriod': {
            'value': _rentalConditions.minRentalPeriod.value,
            'unit': _rentalConditions.minRentalPeriod.unit,
          },
          'maxRentalPeriod': {
            'value': _rentalConditions.maxRentalPeriod.value,
            'unit': _rentalConditions.maxRentalPeriod.unit,
          },
          'advanceRentalPeriod': {
            'value': _rentalConditions.advanceRentalPeriod.value,
            'unit': _rentalConditions.advanceRentalPeriod.unit,
          },
          'rentMode': _rentalConditions.rentMode,
        },

        // Pricing - use the structured pricing map we created above
        'pricing': pricingMap,

        // Add the extras section
        'extras': _vehicleExtras.toMap(),

        // Add the insurance section
        'insurance': _vehicleInsurance.toMap(),

        // Images section
        'images': {
          'imageUrls': uploadedImageUrls,
          'primaryImageUrl': primaryImageUrl,
        },

        // Documents section
        'documents': {
          'registrationDocs': registrationDocUrls,
        },

        // Status and ownership
        'status': 'available',
        'isOwned': true,
        'ownerId': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Add driver details if applicable
      if (_rentalConditions.rentMode == 'With Driver' ||
          _rentalConditions.rentMode == 'With or Without Driver') {
        vehicleData['driverDetails'] = {
          'name': _driverDetails.name,
          'licenseNo': _driverDetails.licenseNo,
        };
      }

      // Save vehicle data to Firebase/Firestore
      try {
        // Get the current user ID
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not logged in');
        }

        // Create a reference to the vehicles collection
        final vehiclesRef = FirebaseFirestore.instance.collection('vehicles');

        // Add the vehicle document
        await vehiclesRef.add(vehicleData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle added successfully!')),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving vehicle: $e')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _shouldShowDriverDetails() {
    return _rentalConditions.rentMode == 'With Driver' ||
        _rentalConditions.rentMode == 'With or Without Driver';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Your Vehicle'),
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
                    // Vehicle Details Section
                    VehicleDetailsSection(
                      vehicleDetails: _vehicleDetails,
                      onVehicleDetailsChanged: (updatedDetails) {
                        setState(() {
                          _vehicleDetails = updatedDetails;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Collection Point Section
                    CollectionPointSection(
                      collectionPoint: _collectionPoint,
                      onCollectionPointChanged: (updatedPoint) {
                        setState(() {
                          _collectionPoint = updatedPoint;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Rental Conditions Section
                    RentalConditionsSection(
                      rentalConditions: _rentalConditions,
                      onRentalConditionsChanged: (updatedConditions) {
                        setState(() {
                          _rentalConditions = updatedConditions;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Driver Details Section (conditional)
                    if (_shouldShowDriverDetails()) ...[
                      DriverDetailsSection(
                        driverDetails: _driverDetails,
                        onDriverDetailsChanged: (updatedDetails) {
                          setState(() {
                            _driverDetails = updatedDetails;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Pricing Section - rental period selection is now only here
                    PricingSection(
                      pricing: _pricing,
                      onPricingChanged: (updatedPricing) {
                        setState(() {
                          _pricing = updatedPricing;
                        });
                      },
                      rentMode: _rentalConditions.rentMode,
                    ),
                    const SizedBox(height: 24),

                    // Extras Section - Add this new section
                    ExtrasSection(
                      extras: _vehicleExtras,
                      onExtrasChanged: (updatedExtras) {
                        setState(() {
                          _vehicleExtras = updatedExtras;
                        });
                      },
                      vehicleDetails: _vehicleDetails,
                    ),
                    const SizedBox(height: 24),

                    // Insurance Section - Add this new section
                    InsuranceSection(
                      insurance: _vehicleInsurance,
                      onInsuranceChanged: (updatedInsurance) {
                        setState(() {
                          _vehicleInsurance = updatedInsurance;
                        });
                      },
                      rentMode: _rentalConditions.rentMode,
                    ),
                    const SizedBox(height: 24),

                    // Vehicle Images Section - Add this new section
                    VehicleImagesSection(
                      vehicleImages: _vehicleImages,
                      onImagesChanged: (updatedImages) {
                        setState(() {
                          _vehicleImages = updatedImages;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Registration Documents Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormWidgets.buildSectionHeader(
                            'Vehicle Registration Documents'),
                        const SizedBox(height: 8),
                        const Text(
                          'Upload clear images of the vehicle registration certificate',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Agreement Checkbox
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _agreementChecked,
                                onChanged: (value) {
                                  setState(() {
                                    _agreementChecked = value ?? false;
                                  });
                                },
                                activeColor: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'I have read and agree to the vehicle owners agreement.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () {
                                        // Show the full agreement
                                        _showAgreement(context);
                                      },
                                      child: Text(
                                        'View Agreement',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_agreementChecked)
                            ? null
                            : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'SUBMIT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  // Add this method to show the agreement dialog
  void _showAgreement(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vehicle Owner Agreement',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: const [
                      Text(
                        'This Vehicle Owner Agreement (the "Agreement") is made and entered into between you ("Owner") and our Tourism Vehicle Rental Platform ("Platform").',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '1. Vehicle Information',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'You confirm that all information provided about your vehicle is accurate and complete. Any misrepresentation may result in termination of this agreement.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '2. Vehicle Condition',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'You agree to maintain your vehicle in safe and roadworthy condition at all times. This includes regular servicing, addressing any mechanical issues promptly, and ensuring the vehicle meets all legal requirements.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '3. Insurance Requirements',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'You are responsible for maintaining appropriate insurance coverage for your vehicle that specifically allows for rental use.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '4. Liability',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'The Platform acts only as an intermediary and is not liable for any damages, losses, or injuries related to the rental of your vehicle.',
                      ),
                      // Add more terms as needed
                    ],
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
