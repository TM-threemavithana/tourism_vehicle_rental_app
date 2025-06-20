import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VehicleImageCarousel extends StatefulWidget {
  final Map<String, dynamic> vehicleDetails;

  const VehicleImageCarousel({
    Key? key,
    required this.vehicleDetails,
  }) : super(key: key);

  @override
  State<VehicleImageCarousel> createState() => _VehicleImageCarouselState();
}

class _VehicleImageCarouselState extends State<VehicleImageCarousel> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _extractImages();
  }

  void _extractImages() {
    _imageUrls = [];
    
    try {
      // Check for images in different possible data structures
      
      // Case 1: images is a direct list of strings
      if (widget.vehicleDetails['images'] is List) {
        final List<dynamic> images = widget.vehicleDetails['images'] as List;
        _imageUrls = images.map((img) => img.toString()).toList();
      } 
      // Case 2: images is a map with nested structures
      else if (widget.vehicleDetails['images'] is Map) {
        final Map<String, dynamic> imagesMap = widget.vehicleDetails['images'] as Map<String, dynamic>;
        
        // Add primary image first if available
        if (imagesMap['primaryImageUrl'] != null) {
          _imageUrls.add(imagesMap['primaryImageUrl']);
        }
        
        // Add image URLs if available
        if (imagesMap['imageUrls'] is List) {
          final List<dynamic> imagesList = imagesMap['imageUrls'] as List;
          for (String url in imagesList) {
            // Avoid duplicates if primary image is also in imageUrls
            if (url != imagesMap['primaryImageUrl']) {
              _imageUrls.add(url);
            }
          }
        }
        
        // Add additional images if available
        if (imagesMap['additionalImages'] is List) {
          final List<dynamic> additionalImages = imagesMap['additionalImages'] as List;
          _imageUrls.addAll(additionalImages.map((img) => img.toString()));
        }
      }
      
      // If still no images, check for other possible formats
      if (_imageUrls.isEmpty && widget.vehicleDetails['imageUrls'] is List) {
        final List<dynamic> imagesList = widget.vehicleDetails['imageUrls'] as List;
        _imageUrls = imagesList.map((img) => img.toString()).toList();
      }
    } catch (e) {
      debugPrint('Error extracting images: $e');
    }
    
    // If no images found, use a placeholder
    if (_imageUrls.isEmpty) {
      _imageUrls.add('https://via.placeholder.com/400x250?text=No+Image+Available');
    }
    
    // Debug output
    debugPrint('Found ${_imageUrls.length} images: $_imageUrls');
  }
  
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        height: 300,
        child: Stack(
          children: [
            // PageView for swiping through images
            PageView.builder(
              controller: _pageController,
              itemCount: _imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: _imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, size: 50),
                  ),
                );
              },
            ),

            // Gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Image count indicator
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${_imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Image dots indicator
            if (_imageUrls.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _imageUrls.asMap().entries.map((entry) {
                    return Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(
                            _currentImageIndex == entry.key ? 0.9 : 0.4),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
