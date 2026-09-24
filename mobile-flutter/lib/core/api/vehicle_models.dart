enum ConnectorType {
  type1,
  type2,
  ccs1,
  ccs2,
  chademo,
  nacs,
  gbt;

  static ConnectorType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'type1':
      case '0':
        return ConnectorType.type1;
      case 'type2':
      case '1':
        return ConnectorType.type2;
      case 'ccs1':
      case '2':
        return ConnectorType.ccs1;
      case 'ccs2':
      case '3':
        return ConnectorType.ccs2;
      case 'chademo':
      case '4':
        return ConnectorType.chademo;
      case 'nacs':
      case 'tesla':
      case '5':
        return ConnectorType.nacs;
      case 'gbt':
      case '6':
        return ConnectorType.gbt;
      default:
        return ConnectorType.type2;
    }
  }

  int toBackendValue() {
    switch (this) {
      case ConnectorType.type1:
        return 0;
      case ConnectorType.type2:
        return 1;
      case ConnectorType.ccs1:
        return 2;
      case ConnectorType.ccs2:
        return 3;
      case ConnectorType.chademo:
        return 4;
      case ConnectorType.nacs:
        return 5;
      case ConnectorType.gbt:
        return 6;
    }
  }

  String get displayName {
    switch (this) {
      case ConnectorType.type1:
        return 'Type 1 (J1772)';
      case ConnectorType.type2:
        return 'Type 2 (Mennekes)';
      case ConnectorType.ccs1:
        return 'CCS Combo 1';
      case ConnectorType.ccs2:
        return 'CCS Combo 2';
      case ConnectorType.chademo:
        return 'CHAdeMO';
      case ConnectorType.nacs:
        return 'NACS / Tesla';
      case ConnectorType.gbt:
        return 'GB/T';
    }
  }

  String get shortName {
    switch (this) {
      case ConnectorType.type1:
        return 'Type 1';
      case ConnectorType.type2:
        return 'Type 2';
      case ConnectorType.ccs1:
        return 'CCS1';
      case ConnectorType.ccs2:
        return 'CCS2';
      case ConnectorType.chademo:
        return 'CHAdeMO';
      case ConnectorType.nacs:
        return 'NACS';
      case ConnectorType.gbt:
        return 'GB/T';
    }
  }
}

class Vehicle {
  final String id;
  final String ownerId;
  final String make;
  final String model;
  final String? licensePlate;
  final ConnectorType connector;
  final double batteryCapacityKwh;
  final double maxChargeRateKw;
  final DateTime createdAt;

  const Vehicle({
    required this.id,
    required this.ownerId,
    required this.make,
    required this.model,
    this.licensePlate,
    required this.connector,
    required this.batteryCapacityKwh,
    required this.maxChargeRateKw,
    required this.createdAt,
  });

  String get fullName => '$make $model';

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String? ?? '',
      make: json['make'] as String,
      model: json['model'] as String,
      licensePlate: json['licensePlate'] as String?,
      connector: json['connector'] is int
          ? ConnectorType.values[json['connector'] as int]
          : ConnectorType.fromString(json['connector'].toString()),
      batteryCapacityKwh: (json['batteryCapacityKwh'] as num).toDouble(),
      maxChargeRateKw: (json['maxChargeRateKw'] as num).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'licensePlate': licensePlate,
      'connector': connector.toBackendValue(),
      'batteryCapacityKwh': batteryCapacityKwh,
      'maxChargeRateKw': maxChargeRateKw,
    };
  }
}

class VehicleRequest {
  final String make;
  final String model;
  final String? licensePlate;
  final ConnectorType connector;
  final double batteryCapacityKwh;
  final double maxChargeRateKw;

  VehicleRequest({
    required this.make,
    required this.model,
    this.licensePlate,
    required this.connector,
    required this.batteryCapacityKwh,
    required this.maxChargeRateKw,
  });

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'licensePlate': licensePlate?.trim().isEmpty == true ? null : licensePlate,
      'connector': connector.toBackendValue(),
      'batteryCapacityKwh': batteryCapacityKwh,
      'maxChargeRateKw': maxChargeRateKw,
    };
  }
}

class CompatibleCharger {
  final String chargerId;
  final String identifier;
  final ConnectorType connector;
  final double powerKw;
  final bool isCompatible;
  final double effectiveChargingPowerKw;
  final double? estimatedChargeTimeMinutes;
  final String? estimatedChargeTimeFormatted;

  CompatibleCharger({
    required this.chargerId,
    required this.identifier,
    required this.connector,
    required this.powerKw,
    required this.isCompatible,
    required this.effectiveChargingPowerKw,
    this.estimatedChargeTimeMinutes,
    this.estimatedChargeTimeFormatted,
  });

  factory CompatibleCharger.fromJson(Map<String, dynamic> json) {
    return CompatibleCharger(
      chargerId: json['chargerId'] as String,
      identifier: json['identifier'] as String,
      connector: json['connector'] is int
          ? ConnectorType.values[json['connector'] as int]
          : ConnectorType.fromString(json['connector'].toString()),
      powerKw: (json['powerKw'] as num).toDouble(),
      isCompatible: json['isCompatible'] as bool? ?? false,
      effectiveChargingPowerKw: (json['effectiveChargingPowerKw'] as num?)?.toDouble() ?? 0.0,
      estimatedChargeTimeMinutes: (json['estimatedChargeTimeMinutes'] as num?)?.toDouble(),
      estimatedChargeTimeFormatted: json['estimatedChargeTimeFormatted'] as String?,
    );
  }
}

class CompatibleStation {
  final String stationId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final int compatibilityScore;
  final bool isCompatible;
  final List<CompatibleCharger> chargers;

  CompatibleStation({
    required this.stationId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.compatibilityScore,
    required this.isCompatible,
    required this.chargers,
  });

  factory CompatibleStation.fromJson(Map<String, dynamic> json) {
    return CompatibleStation(
      stationId: json['stationId'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      compatibilityScore: json['compatibilityScore'] as int? ?? 0,
      isCompatible: json['isCompatible'] as bool? ?? false,
      chargers: (json['chargers'] as List<dynamic>?)
              ?.map((c) => CompatibleCharger.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
