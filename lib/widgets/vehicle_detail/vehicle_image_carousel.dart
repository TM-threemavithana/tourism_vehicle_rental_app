import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VehicleImageCarousel extends StatefulWidget {
  final Map<String, dynamic> vehicleDetails;

  const VehicleImageCarousel({
    super.key,
    required this.vehicleDetails,
  });

  @override
  State<VehicleImageCarousel> createState() => _VehicleImageCarouselState();
}

class _VehicleImageCarouselState extends State<VehicleImageCarousel> {
  int _currentImageIndex = 0;
  List<String> _imageUrls = [];
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _extractImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _extractImages() {
    List<String> images = [];

    try {
      // Add primary image first if available
      if (widget.vehicleDetails['images']?['primaryImageUrl'] != null) {
        images.add(widget.vehicleDetails['images']['primaryImageUrl']);
      }

      // Add all other images if available
      if (widget.vehicleDetails['images']?['imageUrls'] is List) {
        for (var url in widget.vehicleDetails['images']['imageUrls']) {
          if (url != widget.vehicleDetails['images']?['primaryImageUrl']) {
            images.add(url);
          }
        }
      }
    } catch (e) {
      print('Error extracting images: $e');
    }

    setState(() {
      _imageUrls = images;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: _imageUrls.isNotEmpty
            ? Stack(
                children: [
                  // Image Carousel
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _imageUrls.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildCarouselItem(_imageUrls[index]);
                    },
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
              )
            : _buildPlaceholderImage(),
      ),
      actions: [
        // Favorite button
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to favorites')),
            );
          },
        ),
        // Share button
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share option selected')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCarouselItem(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.error, size: 50, color: Colors.grey),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.car_rental, size: 80, color: Colors.grey),
    );
  }
}
