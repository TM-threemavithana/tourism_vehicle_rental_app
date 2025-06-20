import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class DynamicLinksService {
  // Simplified share method without Firebase Dynamic Links
  static Future<void> shareVehicle(Map<String, dynamic> vehicleData, BuildContext context) async {
    final String vehicleId = vehicleData['id'] ?? '';
    if (vehicleId.isEmpty) return;

    // Create vehicle information for sharing
    final String vehicleName = '${vehicleData['make'] ?? ''} ${vehicleData['model'] ?? ''}';
    final String vehicleType = vehicleData['type'] ?? 'Vehicle';
    final String year = vehicleData['year'] != null ? '(${vehicleData['year']})' : '';
    final String transmission = vehicleData['transmission'] ?? '';
    final String fuelType = vehicleData['fuelType'] ?? '';
    
    // Get price information
    String priceText = 'Contact for pricing';
    if (vehicleData['pricing']?['daily']?['vehicleOnly']?['price'] != null) {
      final price = vehicleData['pricing']['daily']['vehicleOnly']['price'];
      priceText = 'LKR ${price.toString()}/day';
    }
    
    // Get location
    final String location = '${vehicleData['collectionPoint']?['city'] ?? ''} ${vehicleData['collectionPoint']?['district'] ?? ''}';
    
    // Construct share text without dynamic link
    String shareText = '🚗 $vehicleName $year\n\n'
        '💰 Price: $priceText\n'
        '📍 Location: $location\n'
        '🔑 $transmission, $fuelType\n\n'
        'Check out this vehicle on Wayz.lk!';
    
    // Share using share_plus package
    await Share.share(shareText, subject: 'Check out this $vehicleType: $vehicleName!');
  }

  // Dummy method to keep any existing references working
  static void initDynamicLinks(BuildContext context) {
    // No-op since we're not using Firebase Dynamic Links
  }
}