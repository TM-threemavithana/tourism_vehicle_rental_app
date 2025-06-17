import 'package:flutter/material.dart';

class VehicleFormConstants {
  // Vehicle types
  static const List<String> vehicleTypes = ['Car', 'Bike', 'Three-Wheeler'];
  
  // Makes/Brands for different vehicle types
  static const Map<String, List<String>> makesMap = {
    'Car': [
      'Toyota', 'Honda', 'Nissan', 'Suzuki', 'Mitsubishi',
      'BMW', 'Mercedes-Benz', 'Audi', 'Ford', 'Other'
    ],
    'Bike': [
      'Honda', 'Yamaha', 'Suzuki', 'Kawasaki', 'Royal Enfield',
      'Bajaj', 'TVS', 'Hero', 'KTM', 'Other'
    ],
    'Three-Wheeler': ['Bajaj', 'TVS', 'Piaggio', 'Mahindra', 'Atul', 'Other'],
  };
  
  // Models for different makes
  static const Map<String, Map<String, List<String>>> modelsMap = {
    // Car models
    'Car': {
      'Toyota': [
        'Corolla', 'Camry', 'Prius', 'RAV4',
        'Land Cruiser', 'Hilux', 'Yaris', 'Other'
      ],
      'Honda': [
        'Civic', 'Accord', 'CR-V', 'City',
        'Jazz', 'Fit', 'HR-V', 'Other'
      ],
      // Add other car makes and models...
      'Other': ['Other']
    },
    
    // Bike models
    'Bike': {
      'Honda': ['CBR', 'CB', 'Hornet', 'Dio', 'Activa', 'Other'],
      'Yamaha': ['YZF', 'FZ', 'MT', 'R15', 'R3', 'Fascino', 'Other'],
      // Add other bike makes and models...
      'Other': ['Other']
    },
    
    // Three-wheeler models
    'Three-Wheeler': {
      'Bajaj': ['RE', 'Maxima', 'Compact', 'Other'],
      // Add other three-wheeler makes and models...
      'Other': ['Other']
    }
  };
  
  // Vehicle categories
  static const Map<String, List<String>> categoriesMap = {
    'Car': ['Budget', 'Compact', 'Full-Size', 'Luxury', 'SUV', 'Van'],
    'Bike': ['Standard', 'Sports', 'Cruiser', 'Touring', 'Scooter', 'Offroad'],
    'Three-Wheeler': ['Passenger', 'Cargo', 'Mixed Use']
  };
  
  // Transmission options
  static const List<String> transmissionOptions = [
    'Automatic', 'Manual', 'Semi-Automatic', 'CVT'
  ];
  
  // Fuel types
  static const List<String> fuelTypeOptions = [
    'Petrol', 'Diesel', 'Hybrid', 'Electric', 'LPG/CNG'
  ];
  
  // Colors
  static const List<String> colorOptions = [
    'Black', 'White', 'Silver', 'Gray', 'Red',
    'Blue', 'Green', 'Yellow', 'Orange', 'Brown',
    'Purple', 'Gold', 'Beige', 'Other'
  ];
  
  // Sri Lankan districts
  static const List<String> districtOptions = [
    'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo',
    'Galle', 'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara',
    'Kandy', 'Kegalle', 'Kilinochchi', 'Kurunegala', 'Mannar',
    'Matale', 'Matara', 'Monaragala', 'Mullaitivu', 'Nuwara Eliya',
    'Polonnaruwa', 'Puttalam', 'Ratnapura', 'Trincomalee', 'Vavuniya'
  ];
  
  // Time units
  static const List<String> timeUnits = ['Hour(s)', 'Day(s)', 'Week(s)', 'Month(s)'];
  
  // Rent modes
  static const List<String> rentModeOptions = [
    'Vehicle Only', 'With Driver', 'With or Without Driver'
  ];
  
  // Rental periods
  static const List<String> rentalPeriods = ['Hourly', 'Daily', 'Weekly', 'Monthly'];

  // Get vehicle icon based on type
  static IconData getVehicleIcon(String type) {
    switch (type) {
      case 'Car':
        return Icons.directions_car;
      case 'Bike':
        return Icons.two_wheeler;
      case 'Three-Wheeler':
        return Icons.electric_rickshaw;
      default:
        return Icons.directions_car;
    }
  }

  // Get color from name
  static Color getColorValue(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'silver':
        return Colors.grey[300]!;
      case 'gray':
        return Colors.grey;
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'brown':
        return Colors.brown;
      case 'purple':
        return Colors.purple;
      case 'gold':
        return Colors.amber;
      case 'beige':
        return const Color(0xFFF5F5DC);
      default:
        return Colors.grey[500]!;
    }
  }
  
  // Generate year options dynamically (from current year to 1990)
  static List<String> generateYearOptions() {
    final currentYear = DateTime.now().year;
    return List.generate(
      currentYear - 1990 + 1,
      (index) => (currentYear - index).toString(),
    );
  }
}