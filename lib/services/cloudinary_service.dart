import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Replace these with your actual Cloudinary credentials - using the ones from your file
  static const String cloudName = 'dsxi4tejw';
  static const String uploadPreset = 'user_profiles';

  final cloudinary = CloudinaryPublic(cloudName, uploadPreset);
  final ImagePicker _picker = ImagePicker();

  // Pick an image from gallery
  Future<File?> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // Slightly compress for faster upload
      maxWidth: 800, // Resize for efficient storage and download
    );

    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  // Pick an image from camera
  Future<File?> takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 800,
    );

    if (photo != null) {
      return File(photo.path);
    }
    return null;
  }

  // Upload image to Cloudinary
  Future<CloudinaryResponse?> uploadImage(File imageFile, String userId) async {
    try {
      // For version 0.21.0, we can't use the transformation parameter directly
      // Instead, we'll use the uploadPreset to set transformations in Cloudinary dashboard
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'user_profiles',
          resourceType: CloudinaryResourceType.Image,
          tags: ['profile', userId],
          // Remove the transformation parameter as it's not supported in this version
        ),
      );

      return response;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }
}
