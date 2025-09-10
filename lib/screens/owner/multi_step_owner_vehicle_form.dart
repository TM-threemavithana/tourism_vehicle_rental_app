import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/cloudinary_service.dart';
import '../../models/vehicle_form_models.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/step_indicator.dart';
import 'sections/vehicle_details_section.dart';
import 'sections/collection_point_section.dart';
import 'sections/rental_conditions_section.dart';
import 'sections/driver_details_section.dart';
import 'sections/pricing_section.dart';
import 'sections/extras_section.dart';
import 'sections/insurance_section.dart';
import 'sections/vehicle_images_section.dart';

class MultiStepOwnerVehicleForm extends StatefulWidget {
  const MultiStepOwnerVehicleForm({super.key});

  @override
  State<MultiStepOwnerVehicleForm> createState() =>
      _MultiStepOwnerVehicleFormState();
}

class _MultiStepOwnerVehicleFormState extends State<MultiStepOwnerVehicleForm> {
  final PageController _pageController = PageController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isLoading = false;
  int _currentStep = 0;
  bool _agreementChecked = false;

  // Form keys for each step
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(), // Step 1: Vehicle Details
    GlobalKey<FormState>(), // Step 2: Collection Point
    GlobalKey<FormState>(), // Step 3: Rental Conditions & Driver
    GlobalKey<FormState>(), // Step 4: Pricing & Extras
    GlobalKey<FormState>(), // Step 5: Insurance & Images
  ];

  // Form data state
  late VehicleBasicDetails _vehicleDetails;
  late CollectionPoint _collectionPoint;
  late RentalConditions _rentalConditions;
  late DriverDetails _driverDetails;
  late VehiclePricing _pricing;
  late VehicleExtras _vehicleExtras;
  late VehicleInsurance _vehicleInsurance;
  late VehicleImages _vehicleImages;

  final List<String> _stepTitles = [
    'Vehicle Details',
    'Collection Point',
    'Rental & Driver',
    'Pricing & Extras',
    'Insurance & Images',
  ];

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
  
    switch (_currentStep) {
      case 0:
        // Validate vehicle details
      
        return _vehicleDetails.vehicleType != null &&
            _vehicleDetails.make != null &&
            _vehicleDetails.model != null &&
            _vehicleDetails.category != null &&
            _vehicleDetails.year != null &&
            _vehicleDetails.vehicleNo.isNotEmpty &&
            _vehicleDetails.engineCapacity.isNotEmpty &&
            _vehicleDetails.transmission != null &&
            _vehicleDetails.fuelType != null &&
            _vehicleDetails.seatingCapacity.isNotEmpty;
      case 1:
        // Validate collection point
        return _collectionPoint.district != null &&
            _collectionPoint.city.isNotEmpty;
      case 2:
        // Validate rental conditions and driver details
        return _rentalConditions.rentMode != null &&
            (_rentalConditions.rentMode == 'Self Drive' ||
                (_driverDetails.name.isNotEmpty &&
                    _driverDetails.licenseNo.isNotEmpty &&
                    (_driverDetails.whatsappNumber?.isNotEmpty ?? false)));
      case 3:
        // Validate pricing
        return _pricing.rentalPeriods.values.contains(true);
      case 4:
        // Validate images
        return _vehicleImages.imageUrls.length >= 6;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _stepTitles.length - 1) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submitForm();
      }
    } else {
      _showValidationError();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showValidationError() {
    String message = '';
    switch (_currentStep) {
      case 0:
        message = 'Please fill in all required vehicle details';
        break;
      case 1:
        message = 'Please select district and city';
        break;
      case 2:
        message = 'Please complete rental conditions and driver details';
        break;
      case 3:
        message = 'Please select at least one rental period';
        break;
      case 4:
        message = 'Please upload at least 6 vehicle images';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitForm() async {
    // Check if agreement is checked
    if (!_agreementChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please agree to the vehicle owners agreement')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload images to Cloudinary first
      List<String> uploadedImageUrls = [];
      String primaryImageUrl = '';

      for (int i = 0; i < _vehicleImages.imageUrls.length; i++) {
        final imageUrl = _vehicleImages.imageUrls[i];
        if (imageUrl.isNotEmpty) {
          if (imageUrl.startsWith('http')) {
            // Already uploaded
            uploadedImageUrls.add(imageUrl);
            if (i == 0) primaryImageUrl = imageUrl;
          } else if (imageUrl.startsWith('/')) {
            // Local file path - need to upload
            final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
            final uploadResult =
                await _cloudinaryService.uploadImage(File(imageUrl), userId);
            if (uploadResult != null) {
              uploadedImageUrls.add(uploadResult.secureUrl);
              if (i == 0) primaryImageUrl = uploadResult.secureUrl;
            }
          }
        }
      }

      // Prepare vehicle data - match the original structure
      final vehicleData = {
        // Basic vehicle details - flatten them to match original structure
        'type': _vehicleDetails.vehicleType,
        'make': _vehicleDetails.make,
        'model': _vehicleDetails.model,
        'category': _vehicleDetails.category,
        'grade': _vehicleDetails.grade,
        'year': _vehicleDetails.year,
        'vehicleNo': _vehicleDetails.vehicleNo,
        'engineCapacity': _vehicleDetails.engineCapacity,
        'transmission': _vehicleDetails.transmission,
        'fuelType': _vehicleDetails.fuelType,
        'seatingCapacity': _vehicleDetails.seatingCapacity,

        // Collection point
        'collectionPoint': _collectionPoint.toMap(),

        // Rental conditions
        'rentalConditions': _rentalConditions.toMap(),

        // Driver details
        'driverDetails': _driverDetails.toMap(),

        // Pricing
        'pricing': _pricing.toMap(),

        // Extras - match original structure
        'extras': {
          'features': _vehicleExtras.features,
        },

        // Insurance
        'insurance': _vehicleInsurance.toMap(),

        // Images
        'images': {
          'imageUrls': uploadedImageUrls,
          'primaryImageUrl': primaryImageUrl,
        },
        'status': 'available',
        'isOwned': true,
        'ownerId': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Save to Firestore
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final vehiclesRef = FirebaseFirestore.instance.collection('vehicles');
      await vehiclesRef.add(vehicleData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle added successfully!')),
        );
        Navigator.pop(context, true);
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

  void _showAgreement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vehicle Owner Agreement'),
        content: const SingleChildScrollView(
          child: Text(
            'Vehicle Owner Agreement\n\n'
            '1. Vehicle Condition: The owner guarantees that the vehicle is in good working condition and roadworthy.\n\n'
            '2. Documentation: All vehicle documents (registration, insurance, etc.) must be valid and up to date.\n\n'
            '3. Liability: The owner is responsible for ensuring the vehicle meets all legal requirements.\n\n'
            '4. Rental Terms: The owner agrees to honor the rental terms and conditions set forth in the platform.\n\n'
            '5. Platform Commission: The owner agrees to pay the platform commission as per the agreed terms.\n\n'
            'By checking the agreement box, you confirm that you have read, understood, and agree to all terms and conditions.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Register Vehicle - ${_stepTitles[_currentStep]}',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                mobile: 16, tablet: 18, ipad: 20, ipadPro: 22, desktop: 24),
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: StepIndicator(
              currentStep: _currentStep,
              stepTitles: _stepTitles,
            ),
          ),

          // Form content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Step 1: Vehicle Details
                      _buildStepContent(
                        Form(
                          key: _formKeys[0],
                          child: VehicleDetailsSection(
                            vehicleDetails: _vehicleDetails,
                            onVehicleDetailsChanged: (updatedDetails) {
                              setState(() {
                                _vehicleDetails = updatedDetails;
                              });
                            },
                          ),
                        ),
                      ),

                      // Step 2: Collection Point
                      _buildStepContent(
                        Form(
                          key: _formKeys[1],
                          child: CollectionPointSection(
                            collectionPoint: _collectionPoint,
                            onCollectionPointChanged: (updatedPoint) {
                              setState(() {
                                _collectionPoint = updatedPoint;
                              });
                            },
                          ),
                        ),
                      ),

                      // Step 3: Rental Conditions & Driver Details
                      _buildStepContent(
                        Form(
                          key: _formKeys[2],
                          child: Column(
                            children: [
                              RentalConditionsSection(
                                rentalConditions: _rentalConditions,
                                onRentalConditionsChanged: (updatedConditions) {
                                  setState(() {
                                    _rentalConditions = updatedConditions;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),
                              DriverDetailsSection(
                                driverDetails: _driverDetails,
                                onDriverDetailsChanged: (updatedDetails) {
                                  setState(() {
                                    _driverDetails = updatedDetails;
                                  });
                                },
                                rentMode: _rentalConditions.rentMode,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Step 4: Pricing & Extras
                      _buildStepContent(
                        Form(
                          key: _formKeys[3],
                          child: Column(
                            children: [
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
                              ExtrasSection(
                                extras: _vehicleExtras,
                                onExtrasChanged: (updatedExtras) {
                                  setState(() {
                                    _vehicleExtras = updatedExtras;
                                  });
                                },
                                vehicleDetails: _vehicleDetails,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Step 5: Insurance & Images
                      _buildStepContent(
                        Form(
                          key: _formKeys[4],
                          child: Column(
                            children: [
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
                              VehicleImagesSection(
                                vehicleImages: _vehicleImages,
                                onImagesChanged: (updatedImages) {
                                  setState(() {
                                    _vehicleImages = updatedImages;
                                  });
                                },
                              ),
                              if (_currentStep == _stepTitles.length - 1) ...[
                                const SizedBox(height: 24),
                                // Agreement checkbox
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              onTap: () =>
                                                  _showAgreement(context),
                                              child: Text(
                                                'View Agreement',
                                                style: TextStyle(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_currentStep == _stepTitles.length - 1 &&
                            !_agreementChecked)
                        ? null
                        : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _currentStep == _stepTitles.length - 1
                          ? 'Submit'
                          : 'Next',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}
