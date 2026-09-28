import '../../membership/api/member_api.dart';

class WalletApi {
  final _client = MemberApi.instance;

  Future<Map<String, dynamic>> load() async =>
      Map<String, dynamic>.from(await _client.request('wallet'));

  Future<Map<String, dynamic>> start({
    required String requestId,
    required double amount,
    required String phone,
    required String address,
    required String city,
  }) async => Map<String, dynamic>.from(
    await _client.request(
      'wallet/top-ups',
      method: 'POST',
      body: {
        'requestId': requestId,
        'amount': amount,
        'phone': phone,
        'address': address,
        'city': city,
      },
    ),
  );
}
