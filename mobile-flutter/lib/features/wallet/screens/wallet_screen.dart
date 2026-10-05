import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../membership/api/member_api.dart';
import '../api/wallet_api.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
  final _api = WalletApi();
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(text: '1000');
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  Map<String, dynamic>? _wallet;
  String? _error, _checkoutUrl, _requestId, _requestAmount;
  bool _busy = false, _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final controller in [_amount, _phone, _address, _city]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  Future<void> _load() async {
    try {
      final wallet = await _api.load();
      if (!mounted) return;
      setState(() {
        _wallet = wallet;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _start() async {
    if (_busy || !_form.currentState!.validate()) return;
    final amount = double.parse(_amount.text.trim());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add money to your wallet?'),
        content: Text(
          'LKR ${amount.toStringAsFixed(2)} through PayHere. '
          '${_wallet?['sandbox'] == true ? 'This is a sandbox test payment. ' : ''}'
          'Your balance updates after the payment is verified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    // Retain the key on a network failure so retrying cannot create a second order.
    if (_requestAmount != amount.toStringAsFixed(2)) {
      _requestId = MemberApi.requestId();
      _requestAmount = amount.toStringAsFixed(2);
    }
    _requestId ??= MemberApi.requestId();
    try {
      final result = await _api.start(
        requestId: _requestId!,
        amount: amount,
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _checkoutUrl = result['checkoutUrl'];
      });
      // Use a separate user click to avoid browser popup blocking after an API request.
      await _load();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openCheckout() async {
    try {
      final opened = await launchUrl(
        Uri.parse(_checkoutUrl!),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!opened) throw Exception('Could not open checkout. Try again.');
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  String _money(dynamic n) => 'LKR ${((n ?? 0) as num).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final available = _wallet?['gatewayAvailable'] == true;
    final history = (_wallet?['topUps'] as List?) ?? [];
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            tooltip: 'Refresh wallet',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    color: AppColors.primary.withValues(alpha: .12),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Available balance'),
                          const SizedBox(height: 8),
                          Text(
                            _money(_wallet?['balance']),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Use your wallet for charging and memberships.',
                          ),
                          if ((_wallet?['pendingCancellationFees'] as num? ??
                                  0) >
                              0) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Outstanding cancellation fees: ${_money(_wallet?['pendingCancellationFees'])}',
                            ),
                            const Text(
                              'Collected once with your next driver booking, in addition to its advance.',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  if (_wallet?['sandbox'] == true)
                    const ListTile(
                      leading: Icon(Icons.science_outlined),
                      title: Text('Sandbox payments'),
                      subtitle: Text(
                        'Use PayHere test cards only. No real money is charged.',
                      ),
                    ),
                  if (!available)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'Online top-up is not available yet. The ChargeSync team needs to finish payment setup.',
                        ),
                      ),
                    ),
                  if (available && _checkoutUrl == null)
                    Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Add money',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [500, 1000, 2000, 5000]
                                .map(
                                  (amount) => ActionChip(
                                    label: Text('LKR $amount'),
                                    onPressed: _busy
                                        ? null
                                        : () => _amount.text = '$amount',
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _amount,
                            enabled: !_busy,
                            decoration: const InputDecoration(
                              labelText: 'Amount (LKR)',
                              helperText: 'LKR 100–50,000',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              final amount = double.tryParse(text);
                              if (!RegExp(
                                    r'^\d+(\.\d{1,2})?$',
                                  ).hasMatch(text) ||
                                  amount == null ||
                                  amount < 100 ||
                                  amount > 50000) {
                                return 'Enter LKR 100–50,000 (up to 2 decimal places).';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _field(
                            _phone,
                            'Phone number',
                            25,
                            keyboard: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          _field(_address, 'Billing address', 200),
                          const SizedBox(height: 12),
                          _field(_city, 'City', 100),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: _busy ? null : _start,
                            icon: const Icon(Icons.add_card),
                            label: Text(
                              _busy ? 'Preparing…' : 'Continue to payment',
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Card details are entered securely on PayHere. ChargeSync does not store them.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_checkoutUrl != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Your checkout is ready',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Open PayHere to pay, then return here and refresh. Do not pay twice if verification takes a moment.',
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _openCheckout,
                              child: const Text('Open secure checkout'),
                            ),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Refresh payment status'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _checkoutUrl = null;
                                  _requestId = null;
                                  _requestAmount = null;
                                });
                              },
                              child: const Text('Start another top-up'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Top-up history',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Latest 50 payments. Only verified payments increase your balance.',
                  ),
                  if (history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No top-ups yet.'),
                    ),
                  ...history.map(
                    (item) => Card(
                      child: ListTile(
                        leading: Icon(
                          item['creditedAt'] != null
                              ? Icons.check_circle_outline
                              : Icons.schedule,
                        ),
                        title: Text(_money(item['amount'])),
                        subtitle: Text(
                          '${item['status']} • ${DateFormat('dd MMM, HH:mm').format(DateTime.parse(item['createdAt']).toLocal())}${item['sandbox'] == true ? ' • Test' : ''}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    int max, {
    TextInputType? keyboard,
  }) => TextFormField(
    controller: controller,
    enabled: !_busy,
    maxLength: max,
    keyboardType: keyboard,
    decoration: InputDecoration(labelText: label, counterText: ''),
    validator: (value) =>
        value == null || value.trim().isEmpty ? '$label is required.' : null,
  );
}
