import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/cloudinary_service.dart';
import '../../models/vehicle_form_models.dart';
import '../../utils/responsive_helper.dart';
import 'sections/vehicle_details_section.dart';
import 'sections/collection_point_section.dart';
import 'sections/rental_conditions_section.dart';
import 'sections/driver_details_section.dart';
import 'sections/pricing_section.dart';
import 'sections/extras_section.dart';
import 'sections/insurance_section.dart';
import 'sections/vehicle_images_section.dart';

class OwnerVehicleForm extends StatefulWidget {
  const OwnerVehicleForm({super.key});

  @override
  State<OwnerVehicleForm> createState() => _OwnerVehicleFormState();
}

class _OwnerVehicleFormState extends State<OwnerVehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final CloudinaryService _cloudinaryService = CloudinaryService();
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
        'engineCapacity': _vehicleDetails.engineCapacity,
        'transmission': _vehicleDetails.transmission,
        'fuelType': _vehicleDetails.fuelType,
        'seatingCapacity': _vehicleDetails.seatingCapacity,

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
        'extras': {
          'features': _vehicleExtras.toMap(),
        },

        // Add the insurance section
        'insurance': _vehicleInsurance.toMap(),

        // Images section
        'images': {
          'imageUrls': uploadedImageUrls,
          'primaryImageUrl': primaryImageUrl,
        },

        // Status and ownership
        'status': 'available',
        'isOwned': true,
        'ownerId': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Add driver details if applicable
      vehicleData['driverDetails'] = {
        'name': _driverDetails.name,
        'licenseNo': _driverDetails.licenseNo,
        'whatsappNumber': _driverDetails.whatsappNumber,
      };

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Register Your Vehicle',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                mobile: 18, tablet: 20, ipad: 22, ipadPro: 24, desktop: 26),
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: ResponsiveHelper.getResponsiveSpacingIPad(context,
                    mobile: 3, tablet: 4, ipad: 5, ipadPro: 6, desktop: 7),
              ),
            )
          : SingleChildScrollView(
              padding: ResponsiveHelper.getResponsivePaddingIPad(context,
                  mobile: 16, tablet: 20, ipad: 24, ipadPro: 32, desktop: 40),
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
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacingIPad(
                            context,
                            mobile: 24,
                            tablet: 28,
                            ipad: 32,
                            ipadPro: 40,
                            desktop: 48)),

                    // Collection Point Section
                    CollectionPointSection(
                      collectionPoint: _collectionPoint,
                      onCollectionPointChanged: (updatedPoint) {
                        setState(() {
                          _collectionPoint = updatedPoint;
                        });
                      },
                    ),
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 24, tablet: 28, desktop: 32)),

                    // Rental Conditions Section
                    RentalConditionsSection(
                      rentalConditions: _rentalConditions,
                      onRentalConditionsChanged: (updatedConditions) {
                        setState(() {
                          _rentalConditions = updatedConditions;
                        });
                      },
                    ),
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 24, tablet: 28, desktop: 32)),

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
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 24, tablet: 28, desktop: 32)),

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
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 24, tablet: 28, desktop: 32)),

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
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 24, tablet: 28, desktop: 32)),

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
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 24, tablet: 28, desktop: 32)),

                    // Vehicle Images Section - Add this new section
                    VehicleImagesSection(
                      vehicleImages: _vehicleImages,
                      onImagesChanged: (updatedImages) {
                        setState(() {
                          _vehicleImages = updatedImages;
                        });
                      },
                    ),
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 24, tablet: 28, desktop: 32)),

                    // Agreement Checkbox
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context,
                                mobile: 8, tablet: 10, desktop: 12)),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      padding: ResponsiveHelper.getResponsivePadding(context,
                          mobile: 16, tablet: 20, desktop: 24),
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
                              SizedBox(
                                  width: ResponsiveHelper.getResponsiveSpacing(
                                      context,
                                      mobile: 8,
                                      tablet: 10,
                                      desktop: 12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'I have read and agree to the vehicle owners agreement.',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSize(context,
                                                mobile: 16,
                                                tablet: 18,
                                                desktop: 20),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(
                                        height: ResponsiveHelper
                                            .getResponsiveSpacing(context,
                                                mobile: 4,
                                                tablet: 6,
                                                desktop: 8)),
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
                                          fontSize: ResponsiveHelper
                                              .getResponsiveFontSize(context,
                                                  mobile: 14,
                                                  tablet: 16,
                                                  desktop: 18),
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
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 24, tablet: 28, desktop: 32)),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveHelper.getResponsiveSpacing(context,
                          mobile: 50, tablet: 55, desktop: 60),
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_agreementChecked)
                            ? null
                            : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getResponsiveBorderRadius(
                                    context,
                                    mobile: 8,
                                    tablet: 10,
                                    desktop: 12)),
                          ),
                        ),
                        child: Text(
                          'SUBMIT',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 18,
                                desktop: 20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 16, tablet: 20, desktop: 24)),
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
            borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveBorderRadius(context,
                    mobile: 16, tablet: 18, desktop: 20)),
          ),
          child: Container(
            padding: ResponsiveHelper.getResponsivePadding(context,
                mobile: 16, tablet: 20, desktop: 24),
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.getResponsiveSpacing(context,
                  mobile: 500, tablet: 600, desktop: 700),
              maxHeight: ResponsiveHelper.getResponsiveSpacing(context,
                  mobile: 500, tablet: 600, desktop: 700),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Vehicle Owner Agreement',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 20,
                            tablet: 22,
                            desktop: 24),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: ResponsiveHelper.getResponsiveIconSize(context,
                            mobile: 20, tablet: 24, desktop: 28),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Divider(
                    height: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 16, tablet: 20, desktop: 24)),
                Expanded(
                  child: ListView(
                    children: [
                      Text(
                        'This Vehicle Owner Agreement (the "Agreement") is made and entered into between you ("Owner") and our Tourism Vehicle Rental Platform ("Platform").',
                        style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 17,
                                desktop: 18)),
                      ),
                      SizedBox(
                          height: ResponsiveHelper.getResponsiveSpacing(context,
                              mobile: 16, tablet: 20, desktop: 24)),
                      Text(
                        '1. Vehicle Information',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 17,
                                desktop: 18)),
                      ),
                      Text(
                        'You confirm that all information provided about your vehicle is accurate and complete. Any misrepresentation may result in termination of this agreement.',
                        style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 15,
                                desktop: 16)),
                      ),
                      SizedBox(
                          height: ResponsiveHelper.getResponsiveSpacing(context,
                              mobile: 16, tablet: 20, desktop: 24)),
                      Text(
                        '2. Vehicle Condition',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 17,
                                desktop: 18)),
                      ),
                      Text(
                        'You agree to maintain your vehicle in safe and roadworthy condition at all times. This includes regular servicing, addressing any mechanical issues promptly, and ensuring the vehicle meets all legal requirements.',
                        style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 15,
                                desktop: 16)),
                      ),
                      SizedBox(
                          height: ResponsiveHelper.getResponsiveSpacing(context,
                              mobile: 16, tablet: 20, desktop: 24)),
                      Text(
                        '3. Insurance Requirements',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 17,
                                desktop: 18)),
                      ),
                      Text(
                        'You are responsible for maintaining appropriate insurance coverage for your vehicle that specifically allows for rental use.',
                        style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 15,
                                desktop: 16)),
                      ),
                      SizedBox(
                          height: ResponsiveHelper.getResponsiveSpacing(context,
                              mobile: 16, tablet: 20, desktop: 24)),
                      Text(
                        '4. Liability',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 17,
                                desktop: 18)),
                      ),
                      Text(
                        'The Platform acts only as an intermediary and is not liable for any damages, losses, or injuries related to the rental of your vehicle.',
                        style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 15,
                                desktop: 16)),
                      ),
                      // Add more terms as needed
                    ],
                  ),
                ),
                Divider(
                    height: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 16, tablet: 20, desktop: 24)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 16,
                              desktop: 18),
                        ),
                      ),
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
