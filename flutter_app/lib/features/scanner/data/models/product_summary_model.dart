class ProductSummaryModel {
  final String productId;
  final String rfidTag;
  final String name;
  final String category;
  final String manufacturer;
  final String batchNumber;
  final double storageReqMinC;
  final double storageReqMaxC;
  final DateTime? manufacturedAt;
  final DateTime? expiresAt;
  final String location;
  final double latestTemperature;
  final double latestHumidity;
  final bool? latestPresence;
  final DateTime latestReadingTs;
  final int totalReadings;

  ProductSummaryModel({
    required this.productId,
    this.rfidTag = '',
    this.name = '',
    this.category = '',
    this.manufacturer = '',
    this.batchNumber = '',
    this.storageReqMinC = 2.0,
    this.storageReqMaxC = 8.0,
    this.manufacturedAt,
    this.expiresAt,
    this.location = '',
    required this.latestTemperature,
    this.latestHumidity = 0.0,
    this.latestPresence,
    required this.latestReadingTs,
    required this.totalReadings,
  });

  /// Backward-compatible deviceId alias (some older code references this)
  String get deviceId => rfidTag.isNotEmpty ? rfidTag : 'N/A';

  /// Human-readable storage requirement string
  String get storageRequirement =>
      '${storageReqMinC.toStringAsFixed(0)}°C to ${storageReqMaxC.toStringAsFixed(0)}°C';

  /// Whether current temp is within the product's storage range
  bool get isWithinRange =>
      latestTemperature >= storageReqMinC &&
      latestTemperature <= storageReqMaxC;

  factory ProductSummaryModel.fromJson(Map<String, dynamic> json) {
    return ProductSummaryModel(
      productId: json['product_id'] as String? ?? '',
      rfidTag:
          json['rfid_tag'] as String? ?? json['device_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? '',
      batchNumber: json['batch_number'] as String? ?? '',
      storageReqMinC: (json['storage_req_min_c'] as num?)?.toDouble() ?? 2.0,
      storageReqMaxC: (json['storage_req_max_c'] as num?)?.toDouble() ?? 8.0,
      manufacturedAt: json['manufactured_at'] != null
          ? DateTime.tryParse(json['manufactured_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      location: json['location'] as String? ?? '',
      latestTemperature:
          (json['latest_temperature_c'] as num?)?.toDouble() ?? 0.0,
      latestHumidity: (json['latest_humidity_pct'] as num?)?.toDouble() ?? 0.0,
      latestPresence: json['latest_presence'] as bool?,
      latestReadingTs:
          DateTime.tryParse(json['latest_reading_ts'] as String? ?? '') ??
          DateTime.now(),
      totalReadings: json['total_readings'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'rfid_tag': rfidTag,
      'name': name,
      'category': category,
      'manufacturer': manufacturer,
      'batch_number': batchNumber,
      'storage_req_min_c': storageReqMinC,
      'storage_req_max_c': storageReqMaxC,
      'manufactured_at': manufacturedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'location': location,
      'latest_temperature_c': latestTemperature,
      'latest_humidity_pct': latestHumidity,
      'latest_presence': latestPresence,
      'latest_reading_ts': latestReadingTs.toIso8601String(),
      'total_readings': totalReadings,
    };
  }
}
