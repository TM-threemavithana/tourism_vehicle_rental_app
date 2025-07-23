import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';
import '../../models/vehicle_form_models.dart';
import '../../widgets/form_widgets.dart'; // Add this import
import 'sections/vehicle_details_section.dart';
import 'sections/collection_point_section.dart';
import 'sections/rental_conditions_section.dart';
import 'sections/driver_details_section.dart';
import 'sections/pricing_section.dart';
import 'sections/extras_section.dart';
import 'sections/insurance_section.dart';
import 'sections/vehicle_images_section.dart';
import 'sections/owner_details_section.dart';

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
  bool _agreementChecked = false;

  // Form data state - similar to OwnerVehicleForm
  late VehicleBasicDetails _vehicleDetails;
  late CollectionPoint _collectionPoint;
  late RentalConditions _rentalConditions;
  late DriverDetails _driverDetails;
  late VehiclePricing _pricing;
  late VehicleExtras _vehicleExtras;
  late VehicleInsurance _vehicleInsurance;
  late VehicleImages _vehicleImages;

  // Adding owner details
  late OwnerDetails _ownerDetails;

  // Registration documents
  List<XFile> _registrationDocImages = [];

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
    _vehicleImages = VehicleImages();
    _ownerDetails = OwnerDetails();
  }

  Future<void> _pickRegistrationDocImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _registrationDocImages = pickedFiles;
      });
    }
  }

  bool _shouldShowDriverDetails() {
    return _rentalConditions.rentMode == 'With Driver' ||
        _rentalConditions.rentMode == 'With or Without Driver';
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

    // Check if at least one image is selected
    if (_vehicleImages.imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one vehicle image')),
      );
      return;
    }

    // Check if all required images are uploaded
    bool allRequiredImagesUploaded = true;
    for (int i = 0; i < 6; i++) {
      // We have 6 required images in our implementation
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

    // Check for registration documents
    if (_registrationDocImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add registration document images')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload all vehicle images in parallel
      final imageUploadFutures = _vehicleImages.imageUrls.map((localPath) {
        return _cloudinaryService.uploadImage(
          File(localPath),
          FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        );
      }).toList();
      final imageUploadResponses = await Future.wait(imageUploadFutures);
      List<String> uploadedImageUrls = [];
      String primaryImageUrl = '';
      for (int i = 0; i < imageUploadResponses.length; i++) {
        final response = imageUploadResponses[i];
        if (response != null) {
          uploadedImageUrls.add(response.secureUrl);
          if (_vehicleImages.imageUrls[i] == _vehicleImages.primaryImageUrl) {
            primaryImageUrl = response.secureUrl;
          }
        }
      }
      if (primaryImageUrl.isEmpty && uploadedImageUrls.isNotEmpty) {
        primaryImageUrl = uploadedImageUrls[0];
      }

      // Upload registration documents in parallel
      final regDocUploadFutures = _registrationDocImages.map((image) {
        return _cloudinaryService.uploadImage(
          File(image.path),
          FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        );
      }).toList();
      final regDocUploadResponses = await Future.wait(regDocUploadFutures);
      List<String> registrationDocUrls = [];
      for (final response in regDocUploadResponses) {
        if (response != null) {
          registrationDocUrls.add(response.secureUrl);
        }
      }

      // Create pricing map
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

      // Build the complete vehicle data object
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

        // Current owner details
        'ownerDetails': _ownerDetails.toMap(),

        // Pricing
        'pricing': pricingMap,

        // Extras
        'extras': _vehicleExtras.toMap(),

        // Insurance
        'insurance': _vehicleInsurance.toMap(),

        // Images
        'images': {
          'imageUrls': uploadedImageUrls,
          'primaryImageUrl': primaryImageUrl,
        },

        // Documents
        'documents': {
          'registrationDocs': registrationDocUrls,
        },

        // Status and ownership
        'status':
            'pending_verification', // Pending verification for non-owner listings
        'isOwned': false,
        'ownerId': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Add driver details if applicable
      vehicleData['driverDetails'] = {
        'name': _driverDetails.name,
        'licenseNo': _driverDetails.licenseNo,
        'whatsappNumber': _driverDetails.whatsappNumber,
      };

      // TODO: Save vehicle data to Firebase/Firestore
      // For now, just show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle submitted for verification!')),
        );
        Navigator.pop(context);
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

  // Method to show agreement dialog
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
                        'This Vehicle Owner Agreement (the "Agreement") is made and entered into between you ("User"), the vehicle owner ("Owner"), and our Tourism Vehicle Rental Platform ("Platform").',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '1. Vehicle Information',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'You confirm that all information provided about the vehicle is accurate and complete. Any misrepresentation may result in termination of this agreement.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '2. Owner Authorization',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'You confirm that you have proper authorization from the owner to list this vehicle for rental purposes. The platform reserves the right to verify this authorization with the owner directly.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '3. Vehicle Condition',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'You agree to ensure the vehicle is maintained in safe and roadworthy condition at all times. This includes regular servicing, addressing any mechanical issues promptly, and ensuring the vehicle meets all legal requirements.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '4. Insurance Requirements',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'You are responsible for ensuring appropriate insurance coverage for the vehicle that specifically allows for rental use.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '5. Liability',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'The Platform acts only as an intermediary and is not liable for any damages, losses, or injuries related to the rental of your vehicle.',
                      ),
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

                    // Owner Details Section - new section for registered owner details
                    OwnerDetailsSection(
                      ownerDetails: _ownerDetails,
                      onOwnerDetailsChanged: (updatedDetails) {
                        setState(() {
                          _ownerDetails = updatedDetails;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Vehicle Details Section (this comes next after removing the relationship section)
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

                    // Driver Details Section (always shown)
                    DriverDetailsSection(
                      driverDetails: _driverDetails,
                      onDriverDetailsChanged: (updatedDetails) {
                        setState(() {
                          _driverDetails = updatedDetails;
                        });
                      },
                      rentMode: _rentalConditions.rentMode,
                    ),
                    const SizedBox(height: 24),

                    // Pricing Section
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

                    // Extras Section
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

                    // Insurance Section
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

                    // Vehicle Images Section
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
