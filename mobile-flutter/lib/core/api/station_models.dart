/// Station API models — mirrors backend StationDto, ChargerDto, etc.
library;

// ── Enums ─────────────────────────────────────────────────────────────────────

enum StationStatus {
  pending,
  approved,
  rejected,
  suspended;

  static StationStatus fromString(String v) {
    return StationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == v.toLowerCase(),
      orElse: () => StationStatus.pending,
    );
  }
}

enum ChargerStatus {
  available,
  occupied,
  offline,
  maintenance;

  static ChargerStatus fromString(String v) {
    return ChargerStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == v.toLowerCase(),
      orElse: () => ChargerStatus.offline,
    );
  }
}

enum ConnectorType {
  ccs1,
  ccs2,
  chademo,
  nacs,
  j1772,
  type2,
  gbt,
  unknown;

  static ConnectorType fromString(String v) {
    return ConnectorType.values.firstWhere(
      (e) => e.name.toLowerCase() == v.toLowerCase(),
      orElse: () => ConnectorType.unknown,
    );
  }

  String get displayName {
    switch (this) {
      case ConnectorType.ccs1:    return 'CCS1';
      case ConnectorType.ccs2:    return 'CCS2';
      case ConnectorType.chademo: return 'CHAdeMO';
      case ConnectorType.nacs:    return 'NACS (Tesla)';
      case ConnectorType.j1772:   return 'J1772';
      case ConnectorType.type2:   return 'Type 2';
      case ConnectorType.gbt:     return 'GB/T';
      case ConnectorType.unknown: return 'Unknown';
    }
  }
}

// ── ChargerDto ────────────────────────────────────────────────────────────────

class ChargerDto {
  final String id;
  final String stationId;
  final String identifier;
  final String bayLabel;
  final ConnectorType connector;
  final double powerKw;
  final double tariff;
  final ChargerStatus status;

  const ChargerDto({
    required this.id,
    required this.stationId,
    required this.identifier,
    required this.bayLabel,
    required this.connector,
    required this.powerKw,
    required this.tariff,
    required this.status,
  });

  factory ChargerDto.fromJson(Map<String, dynamic> json) => ChargerDto(
        id:         (json['id'] as String?) ?? '',
        stationId:  (json['stationId'] as String?) ?? '',
        identifier: (json['identifier'] as String?) ?? '',
        bayLabel:   (json['bayLabel'] as String?) ?? '',
        connector:  ConnectorType.fromString((json['connector'] as String?) ?? ''),
        powerKw:    ((json['powerKw'] as num?) ?? 0).toDouble(),
        tariff:     ((json['tariff'] as num?) ?? 0).toDouble(),
        status:     ChargerStatus.fromString((json['status'] as String?) ?? ''),
      );
}

// ── StationDto ────────────────────────────────────────────────────────────────

class StationDto {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final StationStatus status;
  final String? rejectionReason;
  final String ownerId;
  final DateTime createdAt;
  final List<ChargerDto> chargers;

  const StationDto({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.rejectionReason,
    required this.ownerId,
    required this.createdAt,
    required this.chargers,
  });

  factory StationDto.fromJson(Map<String, dynamic> json) => StationDto(
        id:              (json['id'] as String?) ?? '',
        name:            (json['name'] as String?) ?? '',
        address:         (json['address'] as String?) ?? '',
        latitude:        ((json['latitude'] as num?) ?? 0).toDouble(),
        longitude:       ((json['longitude'] as num?) ?? 0).toDouble(),
        status:          StationStatus.fromString((json['status'] as String?) ?? ''),
        rejectionReason: json['rejectionReason'] as String?,
        ownerId:         (json['ownerId'] as String?) ?? '',
        createdAt:       json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        chargers: ((json['chargers'] as List<dynamic>?) ?? [])
            .map((c) => ChargerDto.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  // ── Derived display helpers ──────────────────────────────────────────────────

  int get totalStalls => chargers.length;

  int get freeStalls =>
      chargers.where((c) => c.status == ChargerStatus.available).length;

  double get maxPowerKw =>
      chargers.isEmpty ? 0 : chargers.map((c) => c.powerKw).reduce((a, b) => a > b ? a : b);

  double get avgTariff {
    if (chargers.isEmpty) return 0;
    final sum = chargers.fold<double>(0, (acc, c) => acc + c.tariff);
    return sum / chargers.length;
  }

  List<String> get connectorNames =>
      chargers.map((c) => c.connector.displayName).toSet().toList();

  String get speedLabel =>
      maxPowerKw > 0 ? '${maxPowerKw.toStringAsFixed(0)} kW' : '—';

  String get priceLabel =>
      avgTariff > 0 ? '\$${avgTariff.toStringAsFixed(2)}' : '—';

  String get stallsText => '$freeStalls of $totalStalls stalls ready';
}
