import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/api/api_config.dart';
import '../../../core/api/auth_api_client.dart';
import '../models/driver_payment_history_item.dart';
import '../models/payment_models.dart';

class PaymentHistoryLoadException implements Exception {
  const PaymentHistoryLoadException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PaymentApiClient {
  PaymentApiClient._();
  static final PaymentApiClient instance = PaymentApiClient._();

  final _storage = const FlutterSecureStorage();

  Future<List<DriverPaymentHistoryItem>> getDriverHistory() async {
    final auth = AuthApiClient.instance;
    final url = Uri.parse('${ApiConfig.baseUrl}/api/payments/history');
    Future<http.Response> load(String? token) => http
        .get(
          url,
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 30));

    http.Response response;
    try {
      response = await load(await auth.getAccessToken());
      if (response.statusCode == 401) {
        final refreshToken = await auth.getRefreshToken();
        if (refreshToken == null) {
          throw const PaymentHistoryLoadException(
            'Your session has expired. Sign out and sign in again.',
          );
        }
        final String freshToken;
        try {
          final refreshed = await auth.refresh(refreshToken);
          freshToken = refreshed.accessToken;
        } catch (_) {
          throw const PaymentHistoryLoadException(
            'Your session has expired. Sign out and sign in again.',
          );
        }
        response = await load(freshToken);
      }
    } on PaymentHistoryLoadException {
      rethrow;
    } catch (_) {
      throw PaymentHistoryLoadException(
        'Cannot reach the API at ${ApiConfig.baseUrl}. Check that the backend is running.',
      );
    }

    if (response.statusCode == 401) {
      throw const PaymentHistoryLoadException(
        'Your session has expired. Sign out and sign in again.',
      );
    }
    if (response.statusCode == 403) {
      throw const PaymentHistoryLoadException(
        'Payment history is available only to driver accounts.',
      );
    }
    if (response.statusCode == 404) {
      throw const PaymentHistoryLoadException(
        'The payment history endpoint is unavailable. Restart the updated backend.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentHistoryLoadException(
        'The backend could not load payment history (HTTP ${response.statusCode}).',
      );
    }
    try {
      return (jsonDecode(response.body) as List<dynamic>)
          .map(
            (item) =>
                DriverPaymentHistoryItem.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      throw const PaymentHistoryLoadException(
        'The backend returned an invalid payment history response.',
      );
    }
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
