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
    
    // Check for images in different formats
    if (widget.vehicleDetails['images'] is List) {
      final List<dynamic> images = widget.vehicleDetails['images'] as List;
      _imageUrls = images.map((img) => img.toString()).toList();
    } else if (widget.vehicleDetails['images'] is Map) {
      final Map<String, dynamic> imagesMap = widget.vehicleDetails['images'] as Map<String, dynamic>;
      
      // Try to get primaryImageUrl
      if (imagesMap['primaryImageUrl'] != null) {
        _imageUrls.add(imagesMap['primaryImageUrl']);
      }
      
      // Additional images
      if (imagesMap['additionalImages'] is List) {
        final List<dynamic> additionalImages = imagesMap['additionalImages'] as List;
        _imageUrls.addAll(additionalImages.map((img) => img.toString()));
      }
    }
    
    // If no images found, use a placeholder
    if (_imageUrls.isEmpty) {
      _imageUrls.add('https://via.placeholder.com/400x250?text=No+Image+Available');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
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

            // Image indicators
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
