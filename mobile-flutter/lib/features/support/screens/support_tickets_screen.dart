import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../api/support_api.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});
  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  final _api = SupportApi();
  List<dynamic> _tickets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _api.list();
      if (mounted) {
        setState(() {
          _tickets = rows;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Color _priority(String value) => value == 'Urgent'
      ? AppColors.error
      : value == 'High'
      ? Colors.orangeAccent
      : AppColors.primary;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    appBar: AppBar(
      title: const Text('Support tickets'),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateSupportTicketScreen()),
        );
        await _load();
      },
      icon: const Icon(Icons.add),
      label: const Text('New ticket'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                if (_tickets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No support tickets yet. Tap New ticket when you need help.',
                      ),
                    ),
                  ),
                ..._tickets.map(
                  (item) => Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.support_agent,
                        color: _priority(item['priority'] ?? 'Medium'),
                      ),
                      title: Text(item['subject'] ?? ''),
                      subtitle: Text(
                        '${item['category']} • ${_readable(item['status'])}\nUpdated ${DateFormat('dd MMM, HH:mm').format(DateTime.parse(item['updatedAt']).toLocal())}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SupportTicketDetailScreen(
                              ticket: Map<String, dynamic>.from(item),
                            ),
                          ),
                        );
                        await _load();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
  );
}

class CreateSupportTicketScreen extends StatefulWidget {
  const CreateSupportTicketScreen({super.key});
  @override
  State<CreateSupportTicketScreen> createState() =>
      _CreateSupportTicketScreenState();
}

class _CreateSupportTicketScreenState extends State<CreateSupportTicketScreen> {
  final _api = SupportApi(),
      _form = GlobalKey<FormState>(),
      _subject = TextEditingController(),
      _description = TextEditingController(),
      _refund = TextEditingController();
  String _category = 'Charging';
  String? _invoiceId, _error;
  List<dynamic> _invoices = [];
  bool _busy = false;
  static const categories = [
    'Charging',
    'Reservation',
    'Payment',
    'Refund',
    'Technical',
    'Membership',
    'Other',
  ];
  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      final rows = await _api.paidInvoices();
      if (mounted) setState(() => _invoices = rows);
    } catch (_) {}
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    _refund.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.create({
        'category': _category,
        'subject': _subject.text.trim(),
        'description': _description.text.trim(),
        if (_category == 'Refund') 'invoiceId': _invoiceId,
        if (_category == 'Refund')
          'requestedRefundAmount': double.tryParse(_refund.text),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New support ticket')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: _busy
                ? null
                : (v) => setState(() {
                    _category = v!;
                    _invoiceId = null;
                  }),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _subject,
            maxLength: 150,
            decoration: const InputDecoration(labelText: 'Subject'),
            validator: (v) => (v?.trim().length ?? 0) < 5
                ? 'Enter at least 5 characters.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            minLines: 5,
            maxLines: 8,
            maxLength: 4000,
            decoration: const InputDecoration(
              labelText: 'Describe what happened',
            ),
            validator: (v) => (v?.trim().length ?? 0) < 10
                ? 'Enter at least 10 characters.'
                : null,
          ),
          if (_category == 'Refund') ...[
            DropdownButtonFormField<String>(
              initialValue: _invoiceId,
              decoration: const InputDecoration(labelText: 'Paid invoice'),
              items: _invoices
                  .map(
                    (i) => DropdownMenuItem<String>(
                      value: i['id'],
                      child: Text(
                        '${i['stationName']} • LKR ${((i['grossAmount'] ?? 0) as num).toStringAsFixed(2)}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _invoiceId = v),
              validator: (v) =>
                  v == null ? 'Select the disputed invoice.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _refund,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Requested refund (LKR)',
              ),
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                  ? 'Enter a positive amount.'
                  : null,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Support will verify the invoice. Approval credits your wallet once.',
              ),
            ),
          ],
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Submitting…' : 'Submit ticket'),
          ),
        ],
      ),
    ),
  );
}

class SupportTicketDetailScreen extends StatefulWidget {
  const SupportTicketDetailScreen({super.key, required this.ticket});
  final Map<String, dynamic> ticket;
  @override
  State<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends State<SupportTicketDetailScreen> {
  final _api = SupportApi(), _message = TextEditingController();
  late Map<String, dynamic> _ticket;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_message.text.trim().isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final row = await _api.message(_ticket['id'], _message.text.trim());
      if (mounted) {
        setState(() {
          _ticket = row;
          _message.clear();
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Withdraw ticket?'),
        content: const Text(
          'This open ticket will be closed and cannot receive more messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => _busy = true);
    try {
      final row = await _api.withdraw(_ticket['id']);
      if (mounted) setState(() => _ticket = row);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final closed = ['Closed', 'Withdrawn'].contains(_ticket['status']);
    final messages = (_ticket['messages'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket details')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _ticket['subject'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_ticket['category']} • ${_readable(_ticket['status'])} • ${_ticket['priority']} priority',
                ),
                if (_ticket['refundStatus'] != 'NotRequested')
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.currency_exchange),
                      title: Text(
                        'Refund: ${_readable(_ticket['refundStatus'])}',
                      ),
                      subtitle: Text(
                        'LKR ${((_ticket['requestedRefundAmount'] ?? 0) as num).toStringAsFixed(2)}',
                      ),
                    ),
                  ),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ...messages.map(
                  (m) => Align(
                    alignment: m['isSystem'] == true
                        ? Alignment.center
                        : m['authorRole'] == 'Driver'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: m['isSystem'] == true
                            ? AppColors.surfaceContainerHigh
                            : m['authorRole'] == 'Driver'
                            ? AppColors.primaryContainer
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${m['authorName']} • ${DateFormat('dd MMM, HH:mm').format(DateTime.parse(m['createdAt']).toLocal())}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(m['body']),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_ticket['status'] == 'Open' &&
                    _ticket['assignedToUserId'] == null)
                  TextButton.icon(
                    onPressed: _busy ? null : _withdraw,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Withdraw this ticket'),
                  ),
              ],
            ),
          ),
          if (!closed)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _message,
                        maxLength: 4000,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Add a message',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _busy ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _readable(dynamic value) => (value?.toString() ?? '').replaceAllMapped(
  RegExp(r'([a-z])([A-Z])'),
  (m) => '${m[1]} ${m[2]}',
);
