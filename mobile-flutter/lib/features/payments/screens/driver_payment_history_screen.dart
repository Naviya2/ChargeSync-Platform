import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../api/payment_api_client.dart';
import '../models/driver_payment_history_item.dart';
import '../models/payment_models.dart';

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

  String _money(double amount) => 'LKR ${amount.toStringAsFixed(2)}';

  String _amountLabel(DriverPaymentHistoryItem item) => item.direction == 'Info'
      ? 'Paid from advance'
      : '${item.isCredit ? '+' : '−'}${_money(item.amount)}';

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _invoiceReceipt(PaymentInvoice invoice) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text('Invoice ID', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SelectableText(invoice.id, key: Key('invoice-id-${invoice.id}')),
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: invoice.id));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice ID copied')),
              );
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy invoice ID'),
        ),
        _detail('Station', invoice.stationName),
        _detail(
          'Charger',
          '${invoice.chargerIdentifier}${invoice.bayLabel.isEmpty ? '' : ' · ${invoice.bayLabel}'}',
        ),
        _detail('Session ID', invoice.sessionId),
        _detail(
          'Energy delivered',
          '${invoice.energyDeliveredKwh.toStringAsFixed(2)} kWh',
        ),
        _detail('Tariff per kWh', _money(invoice.tariffPerKwh)),
        _detail('Gross charge', _money(invoice.grossAmount)),
        _detail('Discount', '−${_money(invoice.discountAmount)}'),
        _detail('Advance applied', '−${_money(invoice.advanceDeducted)}'),
        _detail('Balance paid at checkout', _money(invoice.netAmountDue)),
        if (invoice.refundedAmount > 0)
          _detail('Refunded', _money(invoice.refundedAmount)),
        _detail('Status', invoice.status),
        _detail('Payment method', invoice.paymentMethod ?? 'Advance'),
        _detail(
          'Issued',
          DateFormat('dd MMM yyyy, h:mm a').format(invoice.issuedAt),
        ),
        if (invoice.settledAt != null)
          _detail(
            'Paid',
            DateFormat('dd MMM yyyy, h:mm a').format(invoice.settledAt!),
          ),
        const SizedBox(height: 8),
        const Text(
          'Use this invoice ID to identify the charge when asking support about a refund.',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
      ],
    ),
  );

  Widget _historyCard(DriverPaymentHistoryItem item) {
    final invoice = item.invoice;
    if (invoice != null) {
      return Card(
        child: ExpansionTile(
          key: Key('invoice-${invoice.id}'),
          leading: const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.primary,
          ),
          title: Text('${invoice.stationName} charging invoice'),
          subtitle: Text(
            '${DateFormat('dd MMM yyyy, h:mm a').format(item.occurredAt)} · ${_amountLabel(item)}',
          ),
          children: [_invoiceReceipt(invoice)],
        ),
      );
    }
    return Card(
      child: ListTile(
        leading: Icon(
          item.isCredit
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          color: item.isCredit ? AppColors.primary : AppColors.onSurface,
        ),
        title: Text(item.description),
        subtitle: Text(
          '${DateFormat('dd MMM yyyy, h:mm a').format(item.occurredAt)} · ${item.method}',
        ),
        trailing: Text(
          _amountLabel(item),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: item.isCredit ? AppColors.primary : AppColors.onSurface,
          ),
        ),
      ),
    );
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
                for (final item in _items) _historyCard(item),
              ],
            ),
          ),
  );
}
