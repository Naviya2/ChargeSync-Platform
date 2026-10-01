import 'package:flutter/material.dart';

enum ConnectorType {
  ccs2,
  type2,
  chademo,
  nacs,
  gbt,
  mcs;

  static ConnectorType fromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'ccs2':
      case 'ccs 2':
      case 'ccs combo 2':
      case '0':
        return ConnectorType.ccs2;
      case 'type2':
      case 'type 2':
      case 'mennekes':
      case '1':
        return ConnectorType.type2;
      case 'chademo':
      case '2':
        return ConnectorType.chademo;
      case 'nacs':
      case 'tesla':
      case '3':
        return ConnectorType.nacs;
      case 'gbt':
      case 'gb/t':
      case '4':
        return ConnectorType.gbt;
      case 'mcs':
      case '5':
        return ConnectorType.mcs;
      // Tolerant fallback for legacy definitions
      case 'type1':
        return ConnectorType.type2;
      case 'ccs1':
        return ConnectorType.ccs2;
      default:
        return ConnectorType.ccs2;
    }
  }

  String toBackendString() {
    switch (this) {
      case ConnectorType.ccs2:
        return 'CCS2';
      case ConnectorType.type2:
        return 'Type2';
      case ConnectorType.chademo:
        return 'CHAdeMO';
      case ConnectorType.nacs:
        return 'NACS';
      case ConnectorType.gbt:
        return 'GBT';
      case ConnectorType.mcs:
        return 'MCS';
    }
  }

  int toBackendValue() {
    switch (this) {
      case ConnectorType.ccs2:
        return 0;
      case ConnectorType.type2:
        return 1;
      case ConnectorType.chademo:
        return 2;
      case ConnectorType.nacs:
        return 3;
      case ConnectorType.gbt:
        return 4;
      case ConnectorType.mcs:
        return 5;
    }
  }

  String get displayName {
    switch (this) {
      case ConnectorType.ccs2:
        return 'CCS Combo 2';
      case ConnectorType.type2:
        return 'Type 2 (Mennekes)';
      case ConnectorType.chademo:
        return 'CHAdeMO';
      case ConnectorType.nacs:
        return 'NACS (Tesla)';
      case ConnectorType.gbt:
        return 'GB/T Standard';
      case ConnectorType.mcs:
        return 'MCS (Megawatt)';
    }
  }

  String get shortName {
    switch (this) {
      case ConnectorType.ccs2:
        return 'CCS2';
      case ConnectorType.type2:
        return 'Type 2';
      case ConnectorType.chademo:
        return 'CHAdeMO';
      case ConnectorType.nacs:
        return 'NACS';
      case ConnectorType.gbt:
        return 'GB/T';
      case ConnectorType.mcs:
        return 'MCS';
    }
  }

  String get categoryBadge {
    switch (this) {
      case ConnectorType.ccs2:
        return 'DC Fast';
      case ConnectorType.type2:
        return 'AC 3-Phase';
      case ConnectorType.chademo:
        return 'DC Fast';
      case ConnectorType.nacs:
        return 'Supercharging';
      case ConnectorType.gbt:
        return 'National Standard';
      case ConnectorType.mcs:
        return 'Megawatt DC';
    }
  }

  String get description {
    switch (this) {
      case ConnectorType.ccs2:
        return 'Global DC fast charging standard (EU, Asia, Aus)';
      case ConnectorType.type2:
        return 'AC charging standard for homes and destination hubs';
      case ConnectorType.chademo:
        return 'DC fast charging protocol common on Japanese vehicles';
      case ConnectorType.nacs:
        return 'North American Charging Standard (Tesla & modern EVs)';
      case ConnectorType.gbt:
        return 'Standard charging connector used in Chinese market EVs';
      case ConnectorType.mcs:
        return 'High-power commercial megawatt charging for trucks/buses';
    }
  }

  IconData get icon {
    switch (this) {
      case ConnectorType.ccs2:
        return Icons.electric_bolt_rounded;
      case ConnectorType.type2:
        return Icons.power_rounded;
      case ConnectorType.chademo:
        return Icons.battery_charging_full_rounded;
      case ConnectorType.nacs:
        return Icons.flash_on_rounded;
      case ConnectorType.gbt:
        return Icons.ev_station_rounded;
      case ConnectorType.mcs:
        return Icons.offline_bolt_rounded;
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
    final connectorRaw = json['connector'];
    final ConnectorType connector;
    if (connectorRaw is int) {
      connector = connectorRaw >= 0 && connectorRaw < ConnectorType.values.length
          ? ConnectorType.values[connectorRaw]
          : ConnectorType.ccs2;
    } else {
      connector = ConnectorType.fromString(connectorRaw?.toString() ?? '');
    }

    return Vehicle(
      id: json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      licensePlate: json['licensePlate'] as String?,
      connector: connector,
      batteryCapacityKwh: (json['batteryCapacityKwh'] as num?)?.toDouble() ?? 0.0,
      maxChargeRateKw: (json['maxChargeRateKw'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'make': make,
      'model': model,
      if (licensePlate != null && licensePlate!.trim().isNotEmpty)
        'licensePlate': licensePlate!.trim().toUpperCase(),
      'connector': connector.toBackendString(),
      'batteryCapacityKwh': batteryCapacityKwh,
      'maxChargeRateKw': maxChargeRateKw,
      'createdAt': createdAt.toIso8601String(),
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
    final Map<String, dynamic> data = {
      'make': make.trim(),
      'model': model.trim(),
      'connector': connector.toBackendString(),
      'batteryCapacityKwh': batteryCapacityKwh,
      'maxChargeRateKw': maxChargeRateKw,
    };
    if (licensePlate != null && licensePlate!.trim().isNotEmpty) {
      data['licensePlate'] = licensePlate!.trim().toUpperCase();
    }
    return data;
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
    final connectorRaw = json['connector'];
    final ConnectorType connector;
    if (connectorRaw is int) {
      connector = connectorRaw >= 0 && connectorRaw < ConnectorType.values.length
          ? ConnectorType.values[connectorRaw]
          : ConnectorType.ccs2;
    } else {
      connector = ConnectorType.fromString(connectorRaw?.toString() ?? '');
    }

    return CompatibleCharger(
      chargerId: (json['chargerId'] ?? json['charger_id'])?.toString() ?? '',
      identifier: json['identifier'] as String? ?? '',
      connector: connector,
      powerKw: ((json['powerKw'] ?? json['power_kw']) as num?)?.toDouble() ?? 0.0,
      isCompatible: json['isCompatible'] as bool? ?? json['is_compatible'] as bool? ?? false,
      effectiveChargingPowerKw:
          ((json['effectiveChargingPowerKw'] ?? json['effective_power_kw']) as num?)?.toDouble() ?? 0.0,
      estimatedChargeTimeMinutes:
          ((json['estimatedChargeTimeMinutes'] ?? json['estimated_charge_time_minutes']) as num?)?.toDouble(),
      estimatedChargeTimeFormatted:
          (json['estimatedChargeTimeFormatted'] ?? json['estimated_charge_time_formatted']) as String?,
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
      stationId: json['stationId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      compatibilityScore: _asInt(json['compatibilityScore'] ?? json['compatibility_score']),
      isCompatible: json['isCompatible'] as bool? ?? json['is_compatible'] as bool? ?? false,
      chargers: (json['chargers'] as List<dynamic>?)
              ?.map((c) => CompatibleCharger.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class AlternativeStation {
  final String stationId;
  final String name;
  final String? address;
  final double distanceKm;
  final int compatibilityScore;
  final double bestPowerKw;
  final String? estimatedChargeTimeFormatted;
  final String reason;

  AlternativeStation({
    required this.stationId,
    required this.name,
    this.address,
    required this.distanceKm,
    required this.compatibilityScore,
    required this.bestPowerKw,
    this.estimatedChargeTimeFormatted,
    required this.reason,
  });

  factory AlternativeStation.fromJson(Map<String, dynamic> json) {
    return AlternativeStation(
      stationId: (json['stationId'] ?? json['station_id'])?.toString() ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      distanceKm: ((json['distanceKm'] ?? json['distance_km']) as num?)?.toDouble() ?? 0,
      compatibilityScore: _asInt(json['compatibilityScore'] ?? json['compatibility_score']),
      bestPowerKw: ((json['bestPowerKw'] ?? json['best_power_kw']) as num?)?.toDouble() ?? 0,
      estimatedChargeTimeFormatted:
          (json['estimatedChargeTimeFormatted'] ?? json['estimated_charge_time_formatted']) as String?,
      reason: json['reason'] as String? ?? '',
    );
  }
}

class CompatibilityEvaluation {
  final String stationId;
  final bool isCompatible;
  final int compatibilityScore;
  final double effectiveChargingPowerKw;
  final double? estimatedChargeTimeMinutes;
  final String? estimatedChargeTimeFormatted;
  final List<String> warnings;
  final List<AlternativeStation> suggestedAlternatives;
  final String? aiInsight;

  CompatibilityEvaluation({
    required this.stationId,
    required this.isCompatible,
    required this.compatibilityScore,
    required this.effectiveChargingPowerKw,
    this.estimatedChargeTimeMinutes,
    this.estimatedChargeTimeFormatted,
    required this.warnings,
    required this.suggestedAlternatives,
    this.aiInsight,
  });

  factory CompatibilityEvaluation.fromJson(Map<String, dynamic> json) {
    return CompatibilityEvaluation(
      stationId: (json['stationId'] ?? json['station_id'])?.toString() ?? '',
      isCompatible: json['isCompatible'] as bool? ?? json['is_compatible'] as bool? ?? false,
      compatibilityScore: _asInt(json['compatibilityScore'] ?? json['compatibility_score']),
      effectiveChargingPowerKw:
          ((json['effectiveChargingPowerKw'] ?? json['effective_charging_power_kw']) as num?)?.toDouble() ?? 0,
      estimatedChargeTimeMinutes:
          ((json['estimatedChargeTimeMinutes'] ?? json['estimated_charge_time_minutes']) as num?)?.toDouble(),
      estimatedChargeTimeFormatted:
          (json['estimatedChargeTimeFormatted'] ?? json['estimated_charge_time_formatted']) as String?,
      warnings: ((json['warnings'] as List<dynamic>?) ?? const []).map((e) => e.toString()).toList(),
      suggestedAlternatives: ((json['suggestedAlternatives'] ?? json['suggested_alternatives']) as List<dynamic>?)
              ?.map((e) => AlternativeStation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      aiInsight: (json['aiInsight'] ?? json['ai_insight']) as String?,
    );
  }
}
