import 'charger.dart';

class Station {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String ownerId;
  final String status;
  final String? rejectionReason;
  final List<Charger>? chargers;

  Station({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.ownerId,
    required this.status,
    this.rejectionReason,
    this.chargers,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      ownerId: json['ownerId'] as String,
      status: json['status'] as String,
      rejectionReason: json['rejectionReason'] as String?,
      chargers: json['chargers'] != null
          ? (json['chargers'] as List)
              .map((e) => Charger.fromJson(e as Map<String, dynamic>))
              .toList()
          : null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'ownerId': ownerId,
      'status': status,
      'rejectionReason': rejectionReason,
      if (chargers != null) 'chargers': chargers!.map((e) => e.toJson()).toList(),
    };
  }
}
