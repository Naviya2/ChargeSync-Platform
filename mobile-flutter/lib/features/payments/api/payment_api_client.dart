import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/api/api_config.dart';
import '../models/payment_models.dart';

class PaymentApiClient {
  PaymentApiClient._();
  static final PaymentApiClient instance = PaymentApiClient._();

  final _storage = const FlutterSecureStorage();

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
