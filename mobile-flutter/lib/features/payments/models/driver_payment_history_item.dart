class DriverPaymentHistoryItem {
  const DriverPaymentHistoryItem({
    required this.referenceId,
    required this.type,
    required this.description,
    required this.amount,
    required this.direction,
    required this.occurredAt,
    required this.method,
  });

  final String referenceId;
  final String type;
  final String description;
  final double amount;
  final String direction;
  final DateTime occurredAt;
  final String method;

  bool get isCredit => direction == 'In';

  factory DriverPaymentHistoryItem.fromJson(Map<String, dynamic> json) =>
      DriverPaymentHistoryItem(
        referenceId: json['referenceId'] as String,
        type: json['type'] as String,
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
        direction: json['direction'] as String,
        occurredAt: DateTime.parse(json['occurredAt'] as String).toLocal(),
        method: json['method'] as String,
      );
}
