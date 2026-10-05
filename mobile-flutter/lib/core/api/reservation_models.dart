class ReservationDto {
  final String id;
  final String? driverId;
  final String chargerId;
  final String? vehicleId;
  final DateTime startTime;
  final DateTime endTime;
  final String? reservationQRCode;
  final double advanceDepositAmount;
  final String status;
  final String stationName;
  final double stationLatitude;
  final double stationLongitude;
  final String chargerName;
  final String vehicleName;
  final String driverName;
  final double? finalEnergyDeliveredKwh;
  final double? invoiceNetAmount;
  final String? invoicePaymentMethod;

  ReservationDto({
    required this.id,
    this.driverId,
    required this.chargerId,
    this.vehicleId,
    required this.startTime,
    required this.endTime,
    this.reservationQRCode,
    required this.advanceDepositAmount,
    required this.status,
    this.stationName = '',
    this.stationLatitude = 0.0,
    this.stationLongitude = 0.0,
    this.chargerName = '',
    this.vehicleName = '',
    this.driverName = '',
    this.finalEnergyDeliveredKwh,
    this.invoiceNetAmount,
    this.invoicePaymentMethod,
  });

  factory ReservationDto.fromJson(Map<String, dynamic> json) {
    return ReservationDto(
      id: json['id'],
      driverId: json['driverId'],
      chargerId: json['chargerId'],
      vehicleId: json['vehicleId'],
      startTime: DateTime.parse(json['startTime']).toLocal(),
      endTime: DateTime.parse(json['endTime']).toLocal(),
      reservationQRCode: json['reservationQRCode'],
      advanceDepositAmount: (json['advanceDepositAmount'] as num).toDouble(),
      status: json['status'],
      stationName: json['stationName'] ?? '',
      stationLatitude: (json['stationLatitude'] as num?)?.toDouble() ?? 0.0,
      stationLongitude: (json['stationLongitude'] as num?)?.toDouble() ?? 0.0,
      chargerName: json['chargerName'] ?? '',
      vehicleName: json['vehicleName'] ?? '',
      driverName: json['driverName'] ?? '',
      finalEnergyDeliveredKwh: (json['finalEnergyDeliveredKwh'] as num?)?.toDouble(),
      invoiceNetAmount: (json['invoiceNetAmount'] as num?)?.toDouble(),
      invoicePaymentMethod: json['invoicePaymentMethod'],
    );
  }
}

class CreateReservationRequest {
  final String chargerId;
  final String? vehicleId;
  final DateTime startTime;
  final DateTime endTime;
  final double advanceDepositAmount;
  final bool requiresApproval;

  CreateReservationRequest({
    required this.chargerId,
    this.vehicleId,
    required this.startTime,
    required this.endTime,
    required this.advanceDepositAmount,
    this.requiresApproval = false,
  });

  Map<String, dynamic> toJson() => {
        'chargerId': chargerId,
        'vehicleId': vehicleId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'advanceDepositAmount': advanceDepositAmount,
        'requiresApproval': requiresApproval,
      };
}

class WaitlistEntryDto {
  final String id;
  final String chargerId;
  final String driverId;
  final DateTime requestedStartTime;
  final int priority;
  final String status;

  WaitlistEntryDto({
    required this.id,
    required this.chargerId,
    required this.driverId,
    required this.requestedStartTime,
    required this.priority,
    required this.status,
  });

  factory WaitlistEntryDto.fromJson(Map<String, dynamic> json) {
    return WaitlistEntryDto(
      id: json['id'],
      chargerId: json['chargerId'],
      driverId: json['driverId'],
      requestedStartTime: DateTime.parse(json['requestedStartTime']),
      priority: json['priority'],
      status: json['status'],
    );
  }
}

class JoinWaitlistRequest {
  final String chargerId;
  final DateTime requestedStartTime;
  final double maxPriceWillingToPay;
  final String pricePreference;

  JoinWaitlistRequest({
    required this.chargerId,
    required this.requestedStartTime,
    required this.maxPriceWillingToPay,
    required this.pricePreference,
  });

  Map<String, dynamic> toJson() => {
        'chargerId': chargerId,
        'requestedStartTime': requestedStartTime.toIso8601String(),
        'maxPriceWillingToPay': maxPriceWillingToPay,
        'pricePreference': pricePreference,
      };
}

class PagedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  PagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PagedResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return PagedResult<T>(
      items: (json['items'] as List).map((e) => fromJsonT(e)).toList(),
      totalCount: json['totalCount'],
      page: json['page'],
      pageSize: json['pageSize'],
      totalPages: json['totalPages'],
    );
  }
}

class TimeSlotDto {
  final DateTime startTime;
  final DateTime endTime;

  TimeSlotDto({required this.startTime, required this.endTime});

  factory TimeSlotDto.fromJson(Map<String, dynamic> json) {
    return TimeSlotDto(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
    );
  }
}
