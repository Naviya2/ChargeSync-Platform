import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/api/api_config.dart';
import '../models/driver_payment_history_item.dart';
import '../models/payment_models.dart';

class PaymentApiClient {
  PaymentApiClient._();
  static final PaymentApiClient instance = PaymentApiClient._();

  final _storage = const FlutterSecureStorage();

  Future<List<DriverPaymentHistoryItem>> getDriverHistory() async {
    final token = await _storage.read(key: ApiConfig.kAccessToken);
    if (token == null) {
      throw Exception('Please sign in to view payment history.');
    }
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/api/payments/history'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response));
    }
    return (jsonDecode(response.body) as List<dynamic>)
        .map(
          (item) =>
              DriverPaymentHistoryItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<PaymentInvoice> settleInvoice({
    required String invoiceId,
    required String paymentMethod,
  }) async {
    final token = await _storage.read(key: ApiConfig.kAccessToken);
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/payments/invoices/$invoiceId/settle'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'paymentMethod': paymentMethod}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return PaymentInvoice.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_errorMessage(response));
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['detail'] as String? ??
          body['title'] as String? ??
          'Payment failed';
    } catch (_) {
      return 'Payment failed (${response.statusCode})';
    }
  }
}
