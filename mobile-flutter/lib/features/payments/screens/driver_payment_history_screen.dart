import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../api/payment_api_client.dart';
import '../models/driver_payment_history_item.dart';

class DriverPaymentHistoryScreen extends StatefulWidget {
  const DriverPaymentHistoryScreen({super.key, this.loadHistory});

  final Future<List<DriverPaymentHistoryItem>> Function()? loadHistory;

  @override
  State<DriverPaymentHistoryScreen> createState() =>
      _DriverPaymentHistoryScreenState();
}

class _DriverPaymentHistoryScreenState
    extends State<DriverPaymentHistoryScreen> {
  List<DriverPaymentHistoryItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items =
          await (widget.loadHistory ??
              PaymentApiClient.instance.getDriverHistory)();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is PaymentHistoryLoadException
            ? error.message
            : 'Could not load payment history. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    appBar: AppBar(
      title: const Text('Payment history'),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Refresh payments',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Wallet payments, charging, memberships, refunds and credits',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text('No payments or wallet activity yet.'),
                    ),
                  ),
                for (final item in _items)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        item.isCredit
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: item.isCredit
                            ? AppColors.primary
                            : AppColors.onSurface,
                      ),
                      title: Text(item.description),
                      subtitle: Text(
                        '${DateFormat('dd MMM yyyy, h:mm a').format(item.occurredAt)} · ${item.method}',
                      ),
                      trailing: Text(
                        '${item.isCredit ? '+' : '−'}LKR ${item.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.isCredit
                              ? AppColors.primary
                              : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );
}
