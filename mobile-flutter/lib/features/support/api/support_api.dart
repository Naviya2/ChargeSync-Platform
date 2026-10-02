import '../../membership/api/member_api.dart';

class SupportApi {
  final _client = MemberApi.instance;
  Future<Map<String, dynamic>> get(String id) async =>
      Map<String, dynamic>.from(await _client.request('support-tickets/$id'));
  Future<Map<String, dynamic>> workflow(String id) async =>
      Map<String, dynamic>.from(
        await _client.request('agent-workflows/support-ticket/$id'),
      );
  Future<List<dynamic>> list() async =>
      List<dynamic>.from(await _client.request('support-tickets'));
  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(
        await _client.request('support-tickets', method: 'POST', body: body),
      );
  Future<Map<String, dynamic>> message(String id, String body) async =>
      Map<String, dynamic>.from(
        await _client.request(
          'support-tickets/$id/messages',
          method: 'POST',
          body: {'body': body},
        ),
      );
  Future<Map<String, dynamic>> withdraw(String id) async =>
      Map<String, dynamic>.from(
        await _client.request('support-tickets/$id', method: 'DELETE'),
      );
  Future<List<dynamic>> paidInvoices() async => List<dynamic>.from(
    await _client.request('payments/invoices?status=Paid'),
  );
}
