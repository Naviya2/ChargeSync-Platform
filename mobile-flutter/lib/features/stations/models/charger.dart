class Charger {
  final String id;
  final String stationId;
  final String identifier;
  final String bayLabel;
  final String connector;
  final double powerKw;
  final double tariff;
  final String status;

  Charger({
    required this.id,
    required this.stationId,
    required this.identifier,
    required this.bayLabel,
    required this.connector,
    required this.powerKw,
    required this.tariff,
    required this.status,
  });

  factory Charger.fromJson(Map<String, dynamic> json) {
    return Charger(
      id: json['id'] as String,
      stationId: json['stationId'] as String,
      identifier: json['identifier'] as String,
      bayLabel: json['bayLabel'] as String,
      connector: json['connector'] as String,
      powerKw: (json['powerKw'] as num).toDouble(),
      tariff: (json['tariff'] as num).toDouble(),
      status: json['status'] as String
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stationId': stationId,
      'identifier': identifier,
      'bayLabel': bayLabel,
      'connector': connector,
      'powerKw': powerKw,
      'tariff': tariff,
      'status': status
    };
  }
}
