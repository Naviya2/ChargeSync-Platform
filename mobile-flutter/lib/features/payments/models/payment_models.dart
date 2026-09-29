class ChargingSessionSummary {
  const ChargingSessionSummary({
    required this.id,
    required this.reservationId,
    required this.chargerId,
    required this.driverId,
    required this.stationName,
    required this.chargerIdentifier,
    required this.bayLabel,
    required this.chargerPowerKw,
    required this.tariffPerKwh,
    required this.startTime,
    required this.endTime,
    required this.autoCalculatedKwh,
    required this.staffOverriddenKwh,
    required this.finalEnergyDeliveredKwh,
    required this.status,
  });

  final String id;
  final String reservationId;
  final String chargerId;
  final String? driverId;
  final String stationName;
  final String chargerIdentifier;
  final String bayLabel;
  final double chargerPowerKw;
  final double tariffPerKwh;
  final DateTime startTime;
  final DateTime? endTime;
  final double? autoCalculatedKwh;
  final double? staffOverriddenKwh;
  final double? finalEnergyDeliveredKwh;
  final String status;

  bool get isWalkIn => driverId == null;

  double estimatedEnergyAt(DateTime now) {
    final hours = now.difference(startTime).inSeconds / 3600;
    return hours.clamp(0, double.infinity) * chargerPowerKw;
  }

  factory ChargingSessionSummary.fromJson(Map<String, dynamic> json) {
    double? number(String key) => (json[key] as num?)?.toDouble();
    return ChargingSessionSummary(
      id: json['id'] as String,
      reservationId: json['reservationId'] as String,
      chargerId: json['chargerId'] as String,
      driverId: json['driverId'] as String?,
      stationName: json['stationName'] as String? ?? 'Charging station',
      chargerIdentifier: json['chargerIdentifier'] as String? ?? 'Charger',
      bayLabel: json['bayLabel'] as String? ?? '',
      chargerPowerKw: number('chargerPowerKw') ?? 0,
      tariffPerKwh: number('tariffPerKwh') ?? 0,
      startTime: DateTime.parse(json['startTime'] as String).toLocal(),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String).toLocal(),
      autoCalculatedKwh: number('autoCalculatedKwh'),
      staffOverriddenKwh: number('staffOverriddenKwh'),
      finalEnergyDeliveredKwh: number('finalEnergyDeliveredKwh'),
      status: json['status'] as String? ?? 'Unknown',
    );
  }
}

class PaymentInvoice {
  const PaymentInvoice({
    required this.id,
    required this.sessionId,
    required this.driverId,
    required this.stationName,
    required this.chargerIdentifier,
    required this.bayLabel,
    required this.energyDeliveredKwh,
    required this.tariffPerKwh,
    required this.grossAmount,
    this.discountAmount = 0,
    required this.advanceDeducted,
    required this.netAmountDue,
    required this.paymentMethod,
    required this.status,
    required this.issuedAt,
    required this.settledAt,
  });

  final String id;
  final String sessionId;
  final String? driverId;
  final String stationName;
  final String chargerIdentifier;
  final String bayLabel;
  final double energyDeliveredKwh;
  final double tariffPerKwh;
  final double grossAmount;
  final double discountAmount;
  final double advanceDeducted;
  final double netAmountDue;
  final String? paymentMethod;
  final String status;
  final DateTime issuedAt;
  final DateTime? settledAt;

  bool get isWalkIn => driverId == null;
  bool get isPaid => status.toLowerCase() == 'paid';

  factory PaymentInvoice.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return PaymentInvoice(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      driverId: json['driverId'] as String?,
      stationName: json['stationName'] as String? ?? 'Charging station',
      chargerIdentifier: json['chargerIdentifier'] as String? ?? 'Charger',
      bayLabel: json['bayLabel'] as String? ?? '',
      energyDeliveredKwh: number('energyDeliveredKwh'),
      tariffPerKwh: number('tariffPerKwh'),
      grossAmount: number('grossAmount'),
      discountAmount: number('discountAmount'),
      advanceDeducted: number('advanceDeducted'),
      netAmountDue: number('netAmountDue'),
      paymentMethod: json['paymentMethod'] as String?,
      status: json['status'] as String? ?? 'Pending',
      issuedAt: DateTime.parse(json['issuedAt'] as String).toLocal(),
      settledAt: json['settledAt'] == null
          ? null
          : DateTime.parse(json['settledAt'] as String).toLocal(),
    );
  }
}

class SessionCompletion {
  const SessionCompletion({required this.session, required this.invoice});
  final ChargingSessionSummary session;
  final PaymentInvoice invoice;

  factory SessionCompletion.fromJson(Map<String, dynamic> json) =>
      SessionCompletion(
        session: ChargingSessionSummary.fromJson(
          json['session'] as Map<String, dynamic>,
        ),
        invoice: PaymentInvoice.fromJson(
          json['invoice'] as Map<String, dynamic>,
        ),
      );
}
