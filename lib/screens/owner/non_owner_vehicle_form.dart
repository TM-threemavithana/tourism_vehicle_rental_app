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
import '../../utils/responsive_helper.dart';

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
        title: Text(
          'Register Non-Owned Vehicle',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                mobile: 18, tablet: 20, desktop: 22),
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: ResponsiveHelper.getResponsiveSpacing(context,
                    mobile: 3, tablet: 4, desktop: 5),
              ),
            )
          : SingleChildScrollView(
              padding: ResponsiveHelper.getResponsivePadding(context,
                  mobile: 12, tablet: 16, desktop: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Non-ownership status indicator
                    Container(
                      width: double.infinity,
                      padding: ResponsiveHelper.getResponsivePadding(context,
                          mobile: 12, tablet: 16, desktop: 20),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context,
                                mobile: 6, tablet: 8, desktop: 10)),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: ResponsiveHelper.getResponsiveIconSize(
                                context,
                                mobile: 20,
                                tablet: 24,
                                desktop: 28),
                          ),
                          SizedBox(
                              width: ResponsiveHelper.getResponsiveSpacing(
                                  context,
                                  mobile: 8,
                                  tablet: 12,
                                  desktop: 16)),
                          Expanded(
                            child: Text(
                              "You've indicated you are not the registered owner. Please provide additional information and documentation.",
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSize(
                                        context,
                                        mobile: 14,
                                        tablet: 16,
                                        desktop: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 16, tablet: 20, desktop: 24)),

                    // Owner Details Section - new section for registered owner details
                    OwnerDetailsSection(
                      ownerDetails: _ownerDetails,
                      onOwnerDetailsChanged: (updatedDetails) {
                        setState(() {
                          _ownerDetails = updatedDetails;
                        });
                      },
                    ),
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 20, tablet: 24, desktop: 28)),

                    // Vehicle Details Section (this comes next after removing the relationship section)
                    VehicleDetailsSection(
                      vehicleDetails: _vehicleDetails,
                      onVehicleDetailsChanged: (updatedDetails) {
                        setState(() {
                          _vehicleDetails = updatedDetails;
                        });
                      },
                    ),
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 20, tablet: 24, desktop: 28)),

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
                            mobile: 20, tablet: 24, desktop: 28)),

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
                            mobile: 20, tablet: 24, desktop: 28)),

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
                            mobile: 20, tablet: 24, desktop: 28)),

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
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 20, tablet: 24, desktop: 28)),

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
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 20, tablet: 24, desktop: 28)),

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
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 20, tablet: 24, desktop: 28)),

                    // Vehicle Images Section
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
                            mobile: 20, tablet: 24, desktop: 28)),

                    // Registration Documents Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormWidgets.buildSectionHeader(
                            'Vehicle Registration Documents'),
                        SizedBox(
                            height: ResponsiveHelper.getResponsiveSpacing(
                                context,
                                mobile: 6,
                                tablet: 8,
                                desktop: 10)),
                        Text(
                          'Upload clear images of the vehicle registration certificate',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 13,
                                tablet: 14,
                                desktop: 15),
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(
                            height: ResponsiveHelper.getResponsiveSpacing(
                                context,
                                mobile: 12,
                                tablet: 16,
                                desktop: 20)),
                        GestureDetector(
                          onTap: _pickRegistrationDocImages,
                          child: Container(
                            height: ResponsiveHelper.getResponsiveSpacing(
                                context,
                                mobile: 100,
                                tablet: 120,
                                desktop: 140),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveBorderRadius(
                                      context,
                                      mobile: 6,
                                      tablet: 8,
                                      desktop: 10)),
                            ),
                            alignment: Alignment.center,
                            child: _registrationDocImages.isEmpty
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.upload_file,
                                        size: ResponsiveHelper
                                            .getResponsiveIconSize(context,
                                                mobile: 32,
                                                tablet: 40,
                                                desktop: 48),
                                      ),
                                      SizedBox(
                                          height: ResponsiveHelper
                                              .getResponsiveSpacing(context,
                                                  mobile: 6,
                                                  tablet: 8,
                                                  desktop: 10)),
                                      Text(
                                        'Upload Registration Documents',
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper
                                              .getResponsiveFontSize(context,
                                                  mobile: 14,
                                                  tablet: 16,
                                                  desktop: 18),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _registrationDocImages.length,
                                    itemBuilder: (context, index) {
                                      return Stack(
                                        children: [
                                          Padding(
                                            padding: ResponsiveHelper
                                                .getResponsivePadding(context,
                                                    mobile: 3,
                                                    tablet: 4,
                                                    desktop: 5),
                                            child: Image.file(
                                              File(_registrationDocImages[index]
                                                  .path),
                                              height: ResponsiveHelper
                                                  .getResponsiveSpacing(context,
                                                      mobile: 80,
                                                      tablet: 100,
                                                      desktop: 120),
                                              width: ResponsiveHelper
                                                  .getResponsiveSpacing(context,
                                                      mobile: 80,
                                                      tablet: 100,
                                                      desktop: 120),
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
                                                child: Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: ResponsiveHelper
                                                      .getResponsiveIconSize(
                                                          context,
                                                          mobile: 14,
                                                          tablet: 18,
                                                          desktop: 22),
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
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 20, tablet: 24, desktop: 28)),

                    // Agreement Checkbox
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context,
                                mobile: 6, tablet: 8, desktop: 10)),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      padding: ResponsiveHelper.getResponsivePadding(context,
                          mobile: 12, tablet: 16, desktop: 20),
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
                                      mobile: 6,
                                      tablet: 8,
                                      desktop: 10)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'I have read and agree to the vehicle owners agreement.',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSize(context,
                                                mobile: 14,
                                                tablet: 16,
                                                desktop: 18),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(
                                        height: ResponsiveHelper
                                            .getResponsiveSpacing(context,
                                                mobile: 3,
                                                tablet: 4,
                                                desktop: 5)),
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
                                                  mobile: 13,
                                                  tablet: 14,
                                                  desktop: 15),
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
                            mobile: 20, tablet: 24, desktop: 28)),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveHelper.getResponsiveSpacing(context,
                          mobile: 45, tablet: 50, desktop: 55),
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
                                    mobile: 6,
                                    tablet: 8,
                                    desktop: 10)),
                          ),
                        ),
                        child: Text(
                          'SUBMIT FOR VERIFICATION',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 16,
                                desktop: 18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 16, tablet: 20, desktop: 24)),

                    // Note about verification
                    Container(
                      padding: ResponsiveHelper.getResponsivePadding(context,
                          mobile: 10, tablet: 12, desktop: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context,
                                mobile: 6, tablet: 8, desktop: 10)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey,
                            size: ResponsiveHelper.getResponsiveIconSize(
                                context,
                                mobile: 18,
                                tablet: 20,
                                desktop: 22),
                          ),
                          SizedBox(
                              width: ResponsiveHelper.getResponsiveSpacing(
                                  context,
                                  mobile: 6,
                                  tablet: 8,
                                  desktop: 10)),
                          Expanded(
                            child: Text(
                              'Vehicles listed by non-owners require additional verification which may take 1-2 business days.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSize(
                                        context,
                                        mobile: 11,
                                        tablet: 12,
                                        desktop: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 20, tablet: 24, desktop: 28)),
                  ],
                ),
              ),
            ),
    );
  }
}
