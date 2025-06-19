import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CarLogoHelper {
  static Widget getCarLogo(String? make) {
    // For Toyota, use a local asset image
    if (make == 'Toyota') {
      return Image.asset(
        'assets/car logo/Toyota.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to default icon if asset loading fails
          return const Icon(Icons.directions_car, size: 24, color: Colors.grey);
        },
      );
    }

    // For other makes, continue using online sources
    final logoMap = {
      'Honda': 'https://www.car-logos.org/wp-content/uploads/2011/09/honda.png',
      'Nissan':
          'https://www.car-logos.org/wp-content/uploads/2011/09/nissan.png',
      'Suzuki':
          'https://www.car-logos.org/wp-content/uploads/2011/09/suzuki.png',
      'Mitsubishi':
          'https://www.car-logos.org/wp-content/uploads/2011/09/mitsubishi.png',
      'Mazda': 'https://www.car-logos.org/wp-content/uploads/2011/09/mazda.png',
      'Subaru':
          'https://www.car-logos.org/wp-content/uploads/2011/09/subaru.png',
      'BMW': 'https://www.car-logos.org/wp-content/uploads/2011/09/bmw.png',
      'Mercedes-Benz':
          'https://www.car-logos.org/wp-content/uploads/2011/09/mercedes.png',
      'Audi': 'https://www.car-logos.org/wp-content/uploads/2011/09/audi.png',
      'Volkswagen':
          'https://www.car-logos.org/wp-content/uploads/2011/09/volkswagen.png',
      'Ford': 'https://www.car-logos.org/wp-content/uploads/2011/09/ford.png',
      'Hyundai':
          'https://www.car-logos.org/wp-content/uploads/2011/09/hyundai.png',
      'Kia': 'https://www.car-logos.org/wp-content/uploads/2011/09/kia.png',
      'Lexus': 'https://www.car-logos.org/wp-content/uploads/2011/09/lexus.png',
      'Bajaj':
          'https://seeklogo.com/images/B/Bajaj-logo-0B669C9905-seeklogo.com.png',
      'Hero':
          'https://seeklogo.com/images/H/hero-motocorp-logo-86B709D919-seeklogo.com.png',
      'TVS':
          'https://seeklogo.com/images/T/TVS-logo-66AF311B17-seeklogo.com.png',
      'Yamaha':
          'https://www.car-logos.org/wp-content/uploads/2011/09/yamaha.png',
      'Tata': 'https://www.car-logos.org/wp-content/uploads/2011/09/tata.png',
      'Mahindra':
          'https://seeklogo.com/images/M/Mahindra-logo-63AE37E286-seeklogo.com.png',
      'Maruti Suzuki':
          'https://seeklogo.com/images/M/maruti-suzuki-logo-B7309F69D3-seeklogo.com.png',
      'Jeep': 'https://www.car-logos.org/wp-content/uploads/2011/09/jeep.png',
      'Land Rover':
          'https://www.car-logos.org/wp-content/uploads/2011/09/land-rover.png',
    };

    if (make != null && logoMap.containsKey(make)) {
      return CachedNetworkImage(
        imageUrl: logoMap[make]!,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Center(
          child: Text(
            make.substring(0, 1),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else {
      // For makes not in our map, show the first letter
      return Center(
        child: Text(
          make?.substring(0, 1) ?? 'V',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}
