import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../models/vehicle_form_models.dart';
import '../../../widgets/form_widgets.dart';

class VehicleImagesSection extends StatefulWidget {
  final VehicleImages vehicleImages;
  final Function(VehicleImages) onImagesChanged;

  const VehicleImagesSection({
    super.key,
    required this.vehicleImages,
    required this.onImagesChanged,
  });

  @override
  _VehicleImagesSectionState createState() => _VehicleImagesSectionState();
}

class _VehicleImagesSectionState extends State<VehicleImagesSection> {
  final ImagePicker _picker = ImagePicker();

  // Reduced to 6 required images (removed vehicle reg)
  final List<File?> _requiredImages = List.filled(6, null);
  final List<File?> _optionalImages = List.filled(4, null);

  // Updated labels (changed "Interior" to "Additional", removed "Vehicle Reg")
  final List<String> _requiredLabels = [
    'Main Image',
    'Front View',
    'Rear View',
    'Side View',
    'Dashboard',
    'Additional', // Changed from "Interior"
  ];

  // Sample image assets for each required image type
  final List<String> _sampleImages = [
    'assets/images/main_sample.jpg',
    'assets/images/front_sample.jpg',
    'assets/images/rear_sample.jpg',
    'assets/images/side_sample.jpg',
    'assets/images/dashboard_sample.jpg',
    'assets/images/additional_sample.jpg', // Changed from interior_sample
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingImages();
  }

  void _loadExistingImages() {
    // If there are already saved images, load them into our local state
    if (widget.vehicleImages.imageUrls.isNotEmpty) {
      for (int i = 0; i < widget.vehicleImages.imageUrls.length; i++) {
        final path = widget.vehicleImages.imageUrls[i];
        if (i < 6) {
          _requiredImages[i] = File(path);
        } else if (i < 10) {
          _optionalImages[i - 6] = File(path);
        }
      }
    }
  }

  Future<File?> _compressImage(File file) async {
    final targetPath = file.path
        .replaceFirst('.jpg', '_compressed.jpg')
        .replaceFirst('.png', '_compressed.jpg');
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 80, // Good balance between quality and size
      minWidth: 1280,
      minHeight: 1280,
      format: CompressFormat.jpeg,
    );
    return result as File? ?? file;
  }

  Future<void> _pickImage(int index, bool isRequired) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: null, // Let flutter_image_compress handle quality
      );

      if (pickedFile != null) {
        File originalFile = File(pickedFile.path);
        File? compressedFile = await _compressImage(originalFile);
        setState(() {
          if (isRequired) {
            _requiredImages[index] = compressedFile ?? originalFile;
          } else {
            _optionalImages[index] = compressedFile ?? originalFile;
          }
          _updateVehicleImages();
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  void _updateVehicleImages() {
    List<String> allImagePaths = [];
    String? primaryImagePath;

    // Add required images
    for (int i = 0; i < _requiredImages.length; i++) {
      if (_requiredImages[i] != null) {
        allImagePaths.add(_requiredImages[i]!.path);
        // Set the first image as primary if none selected
        if (i == 0) {
          primaryImagePath = _requiredImages[i]!.path;
        }
      }
    }

    // Add optional images
    for (int i = 0; i < _optionalImages.length; i++) {
      if (_optionalImages[i] != null) {
        allImagePaths.add(_optionalImages[i]!.path);
      }
    }

    // Update the vehicle images model
    final updatedImages = VehicleImages(
      imageUrls: allImagePaths,
      primaryImageUrl: primaryImagePath,
    );

    widget.onImagesChanged(updatedImages);
  }

  // View sample image method
  void _viewSampleImage(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  _sampleImages[index],
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      '${_requiredLabels[index]} Example',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate available width based on screen size
    double screenWidth = MediaQuery.of(context).size.width;
    // Use 3 columns instead of 4 to make images larger
    int crossAxisCount = 3;
    double horizontalPadding = 16.0; // Padding on both sides
    double spacing = 8.0;
    double availableWidth = screenWidth -
        (horizontalPadding * 2) -
        (spacing * (crossAxisCount - 1));
    double itemWidth = availableWidth / crossAxisCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormWidgets.buildSectionHeader('Vehicle Images'),
        const SizedBox(height: 16),

        // Image Upload Instructions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'For best results:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 8),
              Text('• Take photos in good lighting',
                  style: TextStyle(fontSize: 12, color: Colors.blue)),
              Text('• Include exterior front, back and side views',
                  style: TextStyle(fontSize: 12, color: Colors.blue)),
              Text('• Make sure the vehicle is clean',
                  style: TextStyle(fontSize: 12, color: Colors.blue)),
              Text('• Upload clear and recent images',
                  style: TextStyle(fontSize: 12, color: Colors.blue)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Required Images Section
        Row(
          children: [
            const Text(
              'Required Images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(tap on sample to see example)',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Required Images Grid - changed to 3 columns
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 0.75, // Make items taller than they are wide
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _requiredImages.length,
          itemBuilder: (context, index) {
            return _buildImageSlot(
              index: index,
              label: _requiredLabels[index],
              isRequired: true,
              imageFile: _requiredImages[index],
              samplePath: _sampleImages[index],
            );
          },
        ),

        const SizedBox(height: 24),

        // Optional Images Section
        const Text(
          'Optional Images',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 12),

        // Optional Images Grid - also 3 columns
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 0.75, // Make items taller than they are wide
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _optionalImages.length,
          itemBuilder: (context, index) {
            return _buildImageSlot(
              index: index,
              label: 'Add Image',
              isRequired: false,
              imageFile: _optionalImages[index],
              samplePath: null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildImageSlot({
    required int index,
    required String label,
    required bool isRequired,
    File? imageFile,
    String? samplePath,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1.0, // Square image container
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: imageFile == null
                    ? samplePath != null
                        ? GestureDetector(
                            onTap: () => _viewSampleImage(index),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    samplePath,
                                    fit: BoxFit.cover,
                                    opacity: const AlwaysStoppedAnimation(0.7),
                                  ),
                                ),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.search,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.camera_alt,
                                size: 40, color: Colors.grey),
                          )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(imageFile, fit: BoxFit.cover),
                          ),
                          // Delete button overlay
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isRequired) {
                                    _requiredImages[index] = null;
                                  } else {
                                    _optionalImages[index] = null;
                                  }
                                  _updateVehicleImages();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 3,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            imageFile == null ? 'No image' : 'Image selected',
            style: TextStyle(
              fontSize: 10,
              color: imageFile == null && isRequired ? Colors.red : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: ElevatedButton(
              onPressed: () => _pickImage(index, isRequired),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontSize: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(imageFile == null ? 'Add Image' : 'Change Image'),
            ),
          ),
        ],
      ),
    );
  }
}
