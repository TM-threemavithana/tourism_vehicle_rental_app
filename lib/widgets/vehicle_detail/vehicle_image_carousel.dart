import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/favorites_service.dart';

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
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;
  bool _loading = true;
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _extractImages();
    _checkFavoriteStatus();
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

  Future<void> _checkFavoriteStatus() async {
    try {
      bool isFav = await _favoritesService.isFavorite(widget.vehicleDetails['id']);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final bool newStatus = await _favoritesService.toggleFavorite(widget.vehicleDetails);
      if (mounted) {
        setState(() {
          _isFavorite = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite 
              ? 'Added to favorites' 
              : 'Removed from favorites'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareVehicle() async {
    try {
      // Create a shareable text with vehicle details
      final String vehicleName = '${widget.vehicleDetails['make'] ?? ''} ${widget.vehicleDetails['model'] ?? ''}';
      final String vehicleType = widget.vehicleDetails['type'] ?? 'Vehicle';
      final String year = widget.vehicleDetails['year'] != null ? '(${widget.vehicleDetails['year']})' : '';
      final String transmission = widget.vehicleDetails['transmission'] ?? '';
      final String fuelType = widget.vehicleDetails['fuelType'] ?? '';
      
      // Get price information
      String priceText = 'Contact for pricing';
      if (widget.vehicleDetails['pricing']?['daily']?['vehicleOnly']?['price'] != null) {
        final price = widget.vehicleDetails['pricing']['daily']['vehicleOnly']['price'];
        priceText = 'LKR ${price.toString()}/day';
      }
      
      // Get location
      final String location = '${widget.vehicleDetails['collectionPoint']?['city'] ?? ''} ${widget.vehicleDetails['collectionPoint']?['district'] ?? ''}';
      
      // Construct share text
      String shareText = 'Check out this $vehicleType: $vehicleName $year\n\n'
          '• $transmission, $fuelType\n'
          '• Price: $priceText\n'
          '• Location: $location\n\n'
          'Find this and more vehicles on Tourism Vehicle Rental App!';
      
      // Include image if available
      final String? imageUrl = _imageUrls.isNotEmpty ? _imageUrls[0] : null;
      
      // Share using share_plus package
      await Share.share(shareText, subject: 'Check out this $vehicleName!');
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
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
              
            // Favorite button
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: _loading 
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                      ),
                onPressed: _toggleFavorite,
              ),
            ),
            
            // Share button
            Positioned(
              top: 8,
              right: 56,
              child: IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _shareVehicle,
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
