class ScanResultModel {
  final ProductModel product;
  final CurrentConditionModel current;
  final LifeModel life;

  ScanResultModel({
    required this.product,
    required this.current,
    required this.life,
  });

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    // Check if it's the new flat structure
    if (json.containsKey('product_id') && !json.containsKey('product')) {
      final productId = json['product_id'] as String? ?? '';

      // Read real product metadata from API response
      final String name = json['name'] as String? ?? 'Product $productId';
      final String category = json['category'] as String? ?? 'General';
      final String manufacturer = json['manufacturer'] as String? ?? 'Unknown';
      final String batchNumber =
          json['batch_number'] as String? ??
          json['device_id'] as String? ??
          'BATCH-UNK';
      final String location = json['location'] as String? ?? 'In Transit';

      // Build storage requirement string from min/max if available
      String storageRequirement = '2°C to 8°C';
      if (json.containsKey('storage_req_min_c') &&
          json.containsKey('storage_req_max_c')) {
        final minC = (json['storage_req_min_c'] as num?)?.toDouble();
        final maxC = (json['storage_req_max_c'] as num?)?.toDouble();
        if (minC != null && maxC != null) {
          storageRequirement =
              '${minC.toStringAsFixed(0)}°C to ${maxC.toStringAsFixed(0)}°C';
        }
      }

      final product = ProductModel(
        productId: productId,
        name: name,
        batchNumber: batchNumber,
        manufacturer: manufacturer,
        category: category,
        storageRequirement: storageRequirement,
        manufacturedAt:
            json['manufactured_at'] as String? ??
            json['first_reading_ts'] as String? ??
            '',
        expiresAt:
            json['expires_at'] as String? ??
            json['last_reading_ts'] as String? ??
            '',
        currentLocation: location,
      );

      final currentMap = json['current'] as Map<String, dynamic>? ?? {};
      final continuityOk = currentMap['continuity_ok'] as bool? ?? true;
      final temp = (currentMap['temperature_c'] as num?)?.toDouble() ?? 0.0;
      final hum = (currentMap['humidity_pct'] as num?)?.toDouble() ?? 0.0;
      final current = CurrentConditionModel(
        temperature: temp,
        humidity: hum,
        status: continuityOk ? 'OK' : 'EXCURSION',
        lastUpdated: currentMap['reading_ts'] as String? ?? '',
      );

      final excursionCount = json['excursion_count'] as int? ?? 0;
      final healthScore = continuityOk
          ? 98
          : (100 - excursionCount * 10).clamp(30, 95);
      final life = LifeModel(
        daysRemaining: 14,
        healthScore: healthScore,
        estimatedExpiry:
            json['expires_at'] as String? ??
            json['last_reading_ts'] as String? ??
            '',
        adjustedDaysRemaining: 12,
        status: continuityOk ? 'HEALTHY' : 'WARNING',
        totalExcursions: excursionCount,
      );

      return ScanResultModel(product: product, current: current, life: life);
    }

    // Default to parsing the standard nested structure
    return ScanResultModel(
      product: ProductModel.fromJson(
        json['product'] as Map<String, dynamic>? ?? {},
      ),
      current: CurrentConditionModel.fromJson(
        json['current'] as Map<String, dynamic>? ?? {},
      ),
      life: LifeModel.fromJson(json['life'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'current': current.toJson(),
      'life': life.toJson(),
    };
  }
}

class ProductModel {
  final String productId;
  final String name;
  final String batchNumber;
  final String manufacturer;
  final String category;
  final String storageRequirement;
  final String manufacturedAt;
  final String expiresAt;
  final String currentLocation;

  ProductModel({
    required this.productId,
    required this.name,
    required this.batchNumber,
    required this.manufacturer,
    required this.category,
    required this.storageRequirement,
    required this.manufacturedAt,
    required this.expiresAt,
    required this.currentLocation,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['product_id'] ?? '',
      name: json['name'] ?? '',
      batchNumber: json['batch_number'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      category: json['category'] ?? '',
      storageRequirement: json['storage_requirement'] ?? '',
      manufacturedAt: json['manufactured_at'] ?? '',
      expiresAt: json['expires_at'] ?? '',
      currentLocation: json['current_location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'batch_number': batchNumber,
      'manufacturer': manufacturer,
      'category': category,
      'storage_requirement': storageRequirement,
      'manufactured_at': manufacturedAt,
      'expires_at': expiresAt,
      'current_location': currentLocation,
    };
  }
}

class CurrentConditionModel {
  final double temperature;
  final double humidity;
  final String status;
  final String lastUpdated;

  CurrentConditionModel({
    required this.temperature,
    required this.humidity,
    required this.status,
    required this.lastUpdated,
  });

  factory CurrentConditionModel.fromJson(Map<String, dynamic> json) {
    return CurrentConditionModel(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'UNKNOWN',
      lastUpdated: json['last_updated'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'status': status,
      'last_updated': lastUpdated,
    };
  }
}

class LifeModel {
  final int daysRemaining;
  final int healthScore;
  final String estimatedExpiry;
  final int adjustedDaysRemaining;
  final String status;
  final int totalExcursions;

  LifeModel({
    required this.daysRemaining,
    required this.healthScore,
    required this.estimatedExpiry,
    required this.adjustedDaysRemaining,
    required this.status,
    required this.totalExcursions,
  });

  factory LifeModel.fromJson(Map<String, dynamic> json) {
    return LifeModel(
      daysRemaining: json['days_remaining'] as int? ?? 0,
      healthScore: json['health_score'] as int? ?? 0,
      estimatedExpiry: json['estimated_expiry'] ?? '',
      adjustedDaysRemaining: json['adjusted_days_remaining'] as int? ?? 0,
      status: json['status'] ?? 'UNKNOWN',
      totalExcursions: json['total_excursions'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days_remaining': daysRemaining,
      'health_score': healthScore,
      'estimated_expiry': estimatedExpiry,
      'adjusted_days_remaining': adjustedDaysRemaining,
      'status': status,
      'total_excursions': totalExcursions,
    };
  }
}
