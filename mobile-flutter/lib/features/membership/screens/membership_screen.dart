import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../api/member_api.dart';
import '../../wallet/screens/wallet_screen.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key, this.embedded = false});

  /// Hides the page app bar when this screen is hosted inside the driver's
  /// main bottom navigation shell.
  final bool embedded;

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final _api = MemberApi.instance;
  final Map<String, String> _redemptionKeys = {};
  List<dynamic> _plans = [],
      _subscriptions = [],
      _rewards = [],
      _history = [],
      _redemptions = [];
  Map<String, dynamic> _balance = {};
  bool _loading = true, _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait([
        _api.request('membership-plans'),
        _api.request('subscriptions'),
        _api.request('loyalty/me'),
        _api.request('loyalty/rewards'),
        _api.request('loyalty/history'),
        _api.request('loyalty/redemptions'),
      ]);
      if (!mounted) return;
      setState(() {
        _plans = values[0];
        _subscriptions = values[1];
        _balance = Map<String, dynamic>.from(values[2]);
        _rewards = values[3];
        _history = values[4];
        _redemptions = values[5];
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

  Map<String, dynamic>? get _current {
    for (final item in _subscriptions) {
      if ((item['status'] == 'Active' || item['status'] == 'Cancelled') &&
          DateTime.parse(item['endDate']).isAfter(DateTime.now())) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  Future<void> _act(
    String title,
    String details,
    Future<dynamic> Function() action,
  ) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(details),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved successfully.')));
      }
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

  String _money(dynamic value) => 'LKR ${(value as num).toStringAsFixed(2)}';
  String _date(dynamic value) =>
      DateFormat('dd MMM yyyy').format(DateTime.parse(value).toLocal());

  @override
  Widget build(BuildContext context) {
    final current = _current;
    final points = (_balance['pointsBalance'] as num?)?.toInt() ?? 0;
    final next = _balance['nextTierPoints'] as num?;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Membership & rewards')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (!_busy) await _load();
              },
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  if (_busy) const LinearProgressIndicator(),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WalletScreen(),
                              ),
                            );
                            if (mounted) await _load();
                          },
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text('Wallet · Add money'),
                  ),
                  if (_error != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                            TextButton(
                              onPressed: _busy ? null : _load,
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Card(
                    color: AppColors.primary.withValues(alpha: .12),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_balance['tier'] ?? 'Bronze'} member',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$points points',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_balance['lifetimePoints'] ?? 0} lifetime points',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Wallet: ${_money(_balance['walletBalance'] ?? 0)}',
                          ),
                          const SizedBox(height: 10),
                          if (next != null) ...[
                            LinearProgressIndicator(
                              value:
                                  (((_balance['lifetimePoints'] as num?) ?? 0) /
                                          next)
                                      .clamp(0, 1)
                                      .toDouble(),
                            ),
                            const SizedBox(height: 8),
                            Text('Next tier at $next lifetime points'),
                          ],
                          const SizedBox(height: 10),
                          const Text(
                            'Earn 1 point per LKR 100 of paid charging. Bronze: 0 • Silver: 1,000 • Gold: 5,000. Tier savings: 0%, 2%, 5%.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  _heading('Your membership'),
                  if (current == null)
                    const Text('Pay as you go. No paid membership active.')
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              current['planName'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${current['discountPercentage']}% charging discount • ${current['status']}',
                            ),
                            Text('Benefits until ${_date(current['endDate'])}'),
                            if (current['status'] == 'Active')
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _act(
                                        'Cancel membership?',
                                        'Benefits remain until ${_date(current['endDate'])}. No refund is issued for the remaining period.',
                                        () => _api.request(
                                          'subscriptions/${current['id']}',
                                          method: 'DELETE',
                                        ),
                                      ),
                                child: const Text('Cancel membership'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Plans last 30 days and are paid from your wallet. Renewal is manual. The higher of your plan or tier discount applies; discounts do not stack.',
                  ),
                  ..._plans.map(
                    (plan) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    plan['name'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${plan['discountPercentage']}% off',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Text('${_money(plan['monthlyFee'])} / 30 days'),
                            Text(plan['description']),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed:
                                  _busy || current?['planId'] == plan['id']
                                  ? null
                                  : () => _act(
                                      current == null
                                          ? 'Subscribe to ${plan['name']}?'
                                          : 'Change to ${plan['name']}?',
                                      'A new 30-day period costs ${_money(plan['monthlyFee'])}, paid from your wallet.${current == null ? '' : ' Unused time on your current plan is credited proportionally before charging the new fee.'}',
                                      () => _api.request(
                                        current == null
                                            ? 'subscriptions'
                                            : 'subscriptions/${current['id']}/change',
                                        method: current == null
                                            ? 'POST'
                                            : 'PUT',
                                        body: {'planId': plan['id']},
                                      ),
                                    ),
                              child: Text(
                                current?['planId'] == plan['id']
                                    ? 'Current plan'
                                    : current == null
                                    ? 'Subscribe'
                                    : 'Change plan',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _heading('Redeem rewards'),
                  ..._rewards.map(
                    (reward) => Card(
                      child: ListTile(
                        title: Text(reward['name']),
                        subtitle: Text(
                          '${reward['pointsCost']} points${reward['requiresApproval'] == true ? ' • Admin approval required; points reserved' : ' • Instant wallet credit'}',
                        ),
                        trailing: TextButton(
                          onPressed:
                              _busy || points < (reward['pointsCost'] as num)
                              ? null
                              : () => _act(
                                  'Redeem reward?',
                                  '${reward['pointsCost']} points will be deducted. ${reward['requiresApproval'] == true ? 'Credit is issued only after admin approval.' : 'The reward is credited to your wallet.'}',
                                  () async {
                                    final key = _redemptionKeys.putIfAbsent(
                                      reward['id'],
                                      MemberApi.requestId,
                                    );
                                    final result = await _api.request(
                                      'loyalty/redeem',
                                      method: 'POST',
                                      body: {
                                        'rewardId': reward['id'],
                                        'requestId': key,
                                      },
                                    );
                                    _redemptionKeys.remove(reward['id']);
                                    return result;
                                  },
                                ),
                          child: const Text('Redeem'),
                        ),
                      ),
                    ),
                  ),
                  _heading('Reward requests'),
                  if (_redemptions.isEmpty)
                    const Text('No rewards redeemed yet.'),
                  ..._redemptions.map(
                    (r) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(r['rewardDescription']),
                      subtitle: Text(
                        '${_date(r['createdAt'])} • ${r['pointsRedeemed']} points',
                      ),
                      trailing: Text(r['status']),
                    ),
                  ),
                  _heading('Points history'),
                  if (_history.isEmpty)
                    const Text(
                      'Complete and pay for a charging session to start earning.',
                    ),
                  ..._history.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry['reason']),
                      subtitle: Text(_date(entry['createdAt'])),
                      trailing: Text(
                        '${(entry['points'] as num) > 0 ? '+' : ''}${entry['points']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  _heading('Membership history'),
                  ..._subscriptions.map(
                    (s) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${s['planName']} • ${s['status']}'),
                      subtitle: Text(
                        '${_date(s['startDate'])} – ${_date(s['endDate'])}\nFee ${_money(s['feePaid'])} • Credit ${_money(s['creditApplied'])}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
    ),
  );
}
