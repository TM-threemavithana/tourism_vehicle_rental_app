
// Vehicle data model
class VehicleFormData {
  String? vehicleType;
  String? make;
  String? model;
  String? category;
  String? grade;
  String? year;
  String vehicleNo;
  String chassisNo;
  String engineNo;
  String engineCapacity;
  String? transmission;
  String? fuelType;
  String? color;
  String seatingCapacity;
  String doors;

  // Collection point
  String? district;
  String city;
  String address;

  // Rental conditions
  String minRentalPeriod;
  String minRentalPeriodUnit;
  String maxRentalPeriod;
  String maxRentalPeriodUnit;
  String advanceRentalPeriod;
  String advanceRentalPeriodUnit;
  String? rentMode;

  // Driver details (optional)
  String? driverName;
  String? driverLicenseNo;

  // Pricing
  String vehicleValue;
  Map<String, bool> rentalPeriods;
  PricingData? hourlyPricing;
  PricingData? dailyPricing;
  PricingData? weeklyPricing;
  PricingData? monthlyPricing;

  VehicleFormData({
    this.vehicleType,
    this.make,
    this.model,
    this.category,
    this.grade,
    this.year,
    this.vehicleNo = '',
    this.chassisNo = '',
    this.engineNo = '',
    this.engineCapacity = '',
    this.transmission,
    this.fuelType,
    this.color,
    this.seatingCapacity = '',
    this.doors = '',
    this.district,
    this.city = '',
    this.address = '',
    this.minRentalPeriod = '',
    this.minRentalPeriodUnit = 'Day(s)',
    this.maxRentalPeriod = '',
    this.maxRentalPeriodUnit = 'Day(s)',
    this.advanceRentalPeriod = '',
    this.advanceRentalPeriodUnit = 'Hour(s)',
    this.rentMode,
    this.driverName,
    this.driverLicenseNo,
    this.vehicleValue = '',
    this.rentalPeriods = const {
      'Hourly': false,
      'Daily': false,
      'Weekly': false,
      'Monthly': false,
    },
    this.hourlyPricing,
    this.dailyPricing,
    this.weeklyPricing,
    this.monthlyPricing,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'type': vehicleType,
      'make': make,
      'model': model,
      'category': category,
      'grade': grade,
      'year': year,
      'vehicleNo': vehicleNo,
      'chassisNo': chassisNo,
      'engineNo': engineNo,
      'engineCapacity': engineCapacity,
      'transmission': transmission,
      'fuelType': fuelType,
      'color': color,
      'seatingCapacity': seatingCapacity,
      'doors': doors,
      'collectionPoint': {
        'district': district,
        'city': city,
        'address': address,
      },
      'rentalConditions': {
        'minRentalPeriod': {
          'value': minRentalPeriod,
          'unit': minRentalPeriodUnit,
        },
        'maxRentalPeriod': {
          'value': maxRentalPeriod,
          'unit': maxRentalPeriodUnit,
        },
        'advanceRentalPeriod': {
          'value': advanceRentalPeriod,
          'unit': advanceRentalPeriodUnit,
        },
        'rentMode': rentMode,
      },
      'pricing': {
        'vehicleValue': vehicleValue,
        'rentalPeriods': rentalPeriods,
      },
    };

    // Add driver details if applicable
    if (rentMode == 'With Driver' || rentMode == 'With or Without Driver') {
      map['driverDetails'] = {
        'name': driverName,
        'licenseNo': driverLicenseNo,
      };
    }

    // Add pricing details for selected rental periods
    if (rentalPeriods['Hourly'] == true && hourlyPricing != null) {
      map['pricing']['hourly'] = hourlyPricing!.toMap();
    }

    if (rentalPeriods['Daily'] == true && dailyPricing != null) {
      map['pricing']['daily'] = dailyPricing!.toMap();
    }

    if (rentalPeriods['Weekly'] == true && weeklyPricing != null) {
      map['pricing']['weekly'] = weeklyPricing!.toMap();
    }

    if (rentalPeriods['Monthly'] == true && monthlyPricing != null) {
      map['pricing']['monthly'] = monthlyPricing!.toMap();
    }

    return map;
  }
}

// Pricing data model for each time period
class PricingData {
  // Vehicle only pricing
  String? vehicleOnlyPrice;
  String? vehicleOnlyMileageLimit;
  String? vehicleOnlyExtraMileage;

  // With driver pricing
  String? withDriverPrice;
  String? withDriverMileageLimit;
  String? withDriverExtraMileage;

  PricingData({
    this.vehicleOnlyPrice,
    this.vehicleOnlyMileageLimit,
    this.vehicleOnlyExtraMileage,
    this.withDriverPrice,
    this.withDriverMileageLimit,
    this.withDriverExtraMileage,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (vehicleOnlyPrice != null) {
      map['vehicleOnly'] = {
        'price': vehicleOnlyPrice,
        'mileageLimit': vehicleOnlyMileageLimit,
        'extraMileageCharge': vehicleOnlyExtraMileage,
      };
    }

    if (withDriverPrice != null) {
      map['withDriver'] = {
        'price': withDriverPrice,
        'mileageLimit': withDriverMileageLimit,
        'extraMileageCharge': withDriverExtraMileage,
      };
    }

    return map;
  }
}

// Let's add the missing model classes needed for section components
class VehicleBasicDetails {
  String? vehicleType;
  String? make;
  String? model;
  String? category;
  String? grade;
  String? year;
  String vehicleNo;
  String chassisNo;
  String engineNo;
  String engineCapacity;
  String? transmission;
  String? fuelType;
  String? color;
  String seatingCapacity;
  String doors;

  VehicleBasicDetails({
    this.vehicleType,
    this.make,
    this.model,
    this.category,
    this.grade,
    this.year,
    this.vehicleNo = '',
    this.chassisNo = '',
    this.engineNo = '',
    this.engineCapacity = '',
    this.transmission,
    this.fuelType,
    this.color,
    this.seatingCapacity = '',
    this.doors = '',
  });
}

class CollectionPoint {
  String? district;
  String city;
  String address;

  CollectionPoint({
    this.district,
    this.city = '',
    this.address = '',
  });
}

class RentalPeriod {
  String value;
  String unit;

  RentalPeriod({
    this.value = '',
    this.unit = 'Day(s)',
  });
}

class RentalConditions {
  RentalPeriod minRentalPeriod;
  RentalPeriod maxRentalPeriod;
  RentalPeriod advanceRentalPeriod;
  String? rentMode;
  Map<String, bool> rentalPeriods; // Added this field

  RentalConditions({
    RentalPeriod? minRentalPeriod,
    RentalPeriod? maxRentalPeriod,
    RentalPeriod? advanceRentalPeriod,
    this.rentMode,
    Map<String, bool>? rentalPeriods, // Added this parameter
  })  : minRentalPeriod = minRentalPeriod ?? RentalPeriod(),
        maxRentalPeriod = maxRentalPeriod ?? RentalPeriod(),
        advanceRentalPeriod =
            advanceRentalPeriod ?? RentalPeriod(unit: 'Hour(s)'),
        rentalPeriods = rentalPeriods ??
            {
              'Hourly': false,
              'Daily': false,
              'Weekly': false,
              'Monthly': false,
            };
}

class DriverDetails {
  String name;
  String licenseNo;

  DriverDetails({
    this.name = '',
    this.licenseNo = '',
  });
}

class PeriodPricing {
  String? vehicleOnlyPrice;
  String? vehicleOnlyMileageLimit;
  String? vehicleOnlyExtraMileage;
  String? withDriverPrice;
  String? withDriverMileageLimit;
  String? withDriverExtraMileage;

  PeriodPricing({
    this.vehicleOnlyPrice,
    this.vehicleOnlyMileageLimit,
    this.vehicleOnlyExtraMileage,
    this.withDriverPrice,
    this.withDriverMileageLimit,
    this.withDriverExtraMileage,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (vehicleOnlyPrice != null) {
      map['vehicleOnly'] = {
        'price': vehicleOnlyPrice,
        'mileageLimit': vehicleOnlyMileageLimit,
        'extraMileageCharge': vehicleOnlyExtraMileage,
      };
    }

    if (withDriverPrice != null) {
      map['withDriver'] = {
        'price': withDriverPrice,
        'mileageLimit': withDriverMileageLimit,
        'extraMileageCharge': withDriverExtraMileage,
      };
    }

    return map;
  }
}

class VehiclePricing {
  String vehicleValue;
  Map<String, bool> rentalPeriods; // Moving this from RentalConditions to here
  PeriodPricing? hourly;
  PeriodPricing? daily;
  PeriodPricing? weekly;
  PeriodPricing? monthly;

  VehiclePricing({
    this.vehicleValue = '',
    Map<String, bool>? rentalPeriods,
    this.hourly,
    this.daily,
    this.weekly,
    this.monthly,
  }) : rentalPeriods = rentalPeriods ??
            {
              'Hourly': false,
              'Daily': false,
              'Weekly': false,
              'Monthly': false,
            };
}
