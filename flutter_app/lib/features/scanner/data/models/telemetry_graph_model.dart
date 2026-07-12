class TelemetryGraphModel {
  final String productId;
  final String deviceId;
  final TelemetryMeta meta;
  final List<TelemetryPoint> points;

  TelemetryGraphModel({
    required this.productId,
    required this.deviceId,
    required this.meta,
    required this.points,
  });

  factory TelemetryGraphModel.fromJson(Map<String, dynamic> json) {
    return TelemetryGraphModel(
      productId: json['product_id'] ?? '',
      deviceId: json['device_id'] ?? '',
      meta: TelemetryMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? {}),
      points: (json['points'] as List?)
              ?.map((e) => TelemetryPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'device_id': deviceId,
      'meta': meta.toJson(),
      'points': points.map((e) => e.toJson()).toList(),
    };
  }
}

class TelemetryMeta {
  final String zoom;
  final int page;
  final int pageSize;
  final int totalPages;
  final int totalPoints;
  final String periodStart;
  final String periodEnd;
  final double avgTemperature;
  final double minTemperature;
  final double maxTemperature;
  final int excursionCount;

  TelemetryMeta({
    required this.zoom,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.totalPoints,
    required this.periodStart,
    required this.periodEnd,
    required this.avgTemperature,
    required this.minTemperature,
    required this.maxTemperature,
    required this.excursionCount,
  });

  factory TelemetryMeta.fromJson(Map<String, dynamic> json) {
    return TelemetryMeta(
      zoom: json['zoom'] ?? 'day',
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 30,
      totalPages: json['total_pages'] ?? 1,
      totalPoints: json['total_points'] ?? 0,
      periodStart: json['period_start'] ?? '',
      periodEnd: json['period_end'] ?? '',
      avgTemperature: (json['avg_temperature_c'] as num?)?.toDouble() ?? 0.0,
      minTemperature: (json['min_temperature_c'] as num?)?.toDouble() ?? 0.0,
      maxTemperature: (json['max_temperature_c'] as num?)?.toDouble() ?? 0.0,
      excursionCount: json['excursion_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zoom': zoom,
      'page': page,
      'page_size': pageSize,
      'total_pages': totalPages,
      'total_points': totalPoints,
      'period_start': periodStart,
      'period_end': periodEnd,
      'avg_temperature_c': avgTemperature,
      'min_temperature_c': minTemperature,
      'max_temperature_c': maxTemperature,
      'excursion_count': excursionCount,
    };
  }
}

class TelemetryPoint {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final bool continuityOk;

  TelemetryPoint({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.continuityOk,
  });

  factory TelemetryPoint.fromJson(Map<String, dynamic> json) {
    return TelemetryPoint(
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      temperature: (json['temperature_c'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity_pct'] as num?)?.toDouble() ?? 0.0,
      continuityOk: json['continuity_ok'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'temperature_c': temperature,
      'humidity_pct': humidity,
      'continuity_ok': continuityOk,
    };
  }
}
