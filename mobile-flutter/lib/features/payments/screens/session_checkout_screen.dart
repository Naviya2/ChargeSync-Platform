import 'dart:async';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/api/session_api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../api/payment_api_client.dart';
import '../models/payment_models.dart';

class SessionCheckoutScreen extends StatefulWidget {
  const SessionCheckoutScreen({super.key, this.active = true});
  final bool active;

  @override
  State<SessionCheckoutScreen> createState() => _SessionCheckoutScreenState();
}

class _SessionCheckoutScreenState extends State<SessionCheckoutScreen> {
  final _overrideController = TextEditingController();
  Timer? _clock;
  List<ChargingSessionSummary> _sessions = const [];
  ChargingSessionSummary? _selected;
  PaymentInvoice? _invoice;
  bool _loadingSessions = true;
  bool _submitting = false;
  bool _useOverride = false;
  String _paymentMethod = 'Cash';
  String? _error;
  Uint8List? _meterPhoto;
  String? _completionNotice;

  @override
  void didUpdateWidget(covariant SessionCheckoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        !oldWidget.active &&
        _invoice == null &&
        !_submitting) {
      _loadSessions();
    }
  }

  Future<void> _pickMeterPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      if (await picked.length() > 5 * 1024 * 1024) {
        throw Exception('Choose a photo smaller than 5 MB.');
      }
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _meterPhoto = bytes;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _cleanError(error));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _selected != null && _invoice == null) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _overrideController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    if (_submitting) return;
    setState(() {
      _loadingSessions = true;
      _error = null;
    });
    try {
      final sessions = await SessionApiClient.instance.getActiveSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _selected = sessions.isEmpty ? null : sessions.first;
        _meterPhoto = null;
        _overrideController.clear();
        _loadingSessions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingSessions = false;
        _error = _cleanError(error);
      });
    }
  }

  double? get _overrideValue {
    if (!_useOverride) return null;
    return double.tryParse(_overrideController.text.trim());
  }

  double? get _discrepancy {
    final session = _selected;
    final override = _overrideValue;
    if (session == null || override == null) return null;
    final estimate = session.estimatedEnergyAt(DateTime.now());
    if (estimate <= 0) return null;
    return ((override - estimate).abs() / estimate) * 100;
  }

  Future<void> _completeSession() async {
    final session = _selected;
    if (session == null) return;
    if (_useOverride &&
        (_overrideValue == null ||
            !_overrideValue!.isFinite ||
            _overrideValue! <= 0)) {
      setState(() => _error = 'Enter a valid physical meter reading.');
      return;
    }
    if (_useOverride && _meterPhoto == null) {
      setState(() => _error = 'Meter photo is required when using a physical meter reading.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final completion = await SessionApiClient.instance.stopSession(
        sessionId: session.id,
        staffOverriddenKwh: _overrideValue,
        meterPhoto: _meterPhoto,
      );
      if (!mounted) return;
      setState(() {
        _invoice = completion.invoice;
        _completionNotice = completion.session.status == 'DiscrepancyFlagged'
            ? 'Session completed. Energy difference flagged for review.'
            : 'Session completed.';
        if (_meterPhoto != null) {
          _completionNotice = '$_completionNotice Meter photo saved.';
        }
        _paymentMethod = completion.invoice.isWalkIn ? 'Cash' : 'Wallet';
        _submitting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _cleanError(error);
      });
    }
  }

  Future<void> _settleInvoice() async {
    final invoice = _invoice;
    if (invoice == null || invoice.isPaid) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final settled = await PaymentApiClient.instance.settleInvoice(
        invoiceId: invoice.id,
        paymentMethod: _paymentMethod,
      );
      if (!mounted) return;
      setState(() {
        _invoice = settled;
        _submitting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _cleanError(error);
      });
    }
  }

  Future<void> _startAnother() async {
    setState(() {
      _invoice = null;
      _overrideController.clear();
      _useOverride = false;
      _meterPhoto = null;
      _completionNotice = null;
    });
    await _loadSessions();
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return RefreshIndicator(
      onRefresh: _loadSessions,
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceContainer,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, top + 82, 16, 110),
        children: [
          Text('Session checkout', style: _text(24, FontWeight.w800)),
          const SizedBox(height: 5),
          Text(
            'Confirm delivered energy, generate the invoice, and record payment.',
            style: _text(13, FontWeight.w400, AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 22),
          if (_loadingSessions)
            const _LoadingCard()
          else if (_invoice != null)
            _buildInvoice(_invoice!)
          else if (_sessions.isEmpty)
            _EmptyState(onRefresh: _loadSessions)
          else ...[
            AbsorbPointer(absorbing: _submitting, child: _buildSessionPicker()),
            const SizedBox(height: 14),
            if (_selected != null) _buildEnergyCard(_selected!),
            const SizedBox(height: 14),
            AbsorbPointer(absorbing: _submitting, child: _buildOverrideCard()),
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _useOverride ? 'Meter photo (required)' : 'Meter photo (optional)',
                    style: _text(14, FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Attach a JPEG or PNG, up to 5 MB. It is saved with this session.',
                    style: _text(12, FontWeight.w400),
                  ),
                  if (_meterPhoto != null) ...[
                    const SizedBox(height: 10),
                    Image.memory(
                      _meterPhoto!,
                      height: 160,
                      fit: BoxFit.contain,
                      errorBuilder: (_, error, stack) =>
                          const Text('Choose a JPEG or PNG image.'),
                    ),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => setState(() => _meterPhoto = null),
                      child: const Text('Remove photo'),
                    ),
                  ],
                  OutlinedButton.icon(
                    onPressed: _submitting ? null : _pickMeterPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Choose meter photo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _primaryButton(
              icon: Icons.receipt_long_rounded,
              label: 'Complete session & generate invoice',
              onPressed: _submitting ? null : _completeSession,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            _MessageCard(message: _error!, isError: true),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionPicker() => _card(
    child: DropdownButtonFormField<String>(
      key: ValueKey(_selected?.id),
      initialValue: _selected?.id,
      dropdownColor: AppColors.surfaceContainerHigh,
      isExpanded: true,
      decoration: _inputDecoration('Active charging session'),
      items: _sessions.map((session) {
        final bay = session.bayLabel.isEmpty ? '' : ' • ${session.bayLabel}';
        return DropdownMenuItem(
          value: session.id,
          child: Text(
            '${session.stationName} • ${session.chargerIdentifier}$bay',
            overflow: TextOverflow.ellipsis,
            style: _text(13, FontWeight.w600),
          ),
        );
      }).toList(),
      onChanged: (id) => setState(() {
        _selected = _sessions.firstWhere((item) => item.id == id);
        _overrideController.clear();
        _meterPhoto = null;
        _useOverride = false;
      }),
    ),
  );

  Widget _buildEnergyCard(ChargingSessionSummary session) {
    final energy = session.estimatedEnergyAt(DateTime.now());
    final estimate = energy * session.tariffPerKwh;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(icon: Icons.bolt_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.isWalkIn
                          ? 'Walk-in session'
                          : 'Registered driver',
                      style: _text(11, FontWeight.w700, AppColors.primary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${session.chargerPowerKw.toStringAsFixed(1)} kW charger',
                      style: _text(16, FontWeight.w700),
                    ),
                  ],
                ),
              ),
              _StatusChip(label: 'IN PROGRESS', color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Live estimate',
                  value: '${energy.toStringAsFixed(2)} kWh',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Tariff',
                  value: 'LKR ${session.tariffPerKwh.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Est. charge',
                  value: 'LKR ${estimate.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Started ${DateFormat('dd MMM, HH:mm').format(session.startTime)}',
            style: _text(11, FontWeight.w500, AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildOverrideCard() {
    final discrepancy = _discrepancy;
    final flagged = (discrepancy ?? 0) > 15;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primary,
            title: Text(
              'Use physical meter reading',
              style: _text(14, FontWeight.w700),
            ),
            subtitle: Text(
              'Optional correction when the charger display differs.',
              style: _text(11, FontWeight.w400, AppColors.onSurfaceVariant),
            ),
            value: _useOverride,
            onChanged: (value) => setState(() {
              _useOverride = value;
              if (!value) _overrideController.clear();
            }),
          ),
          if (_useOverride) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _overrideController,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: _text(15, FontWeight.w600),
              decoration: _inputDecoration(
                'Physical meter reading (kWh)',
              ).copyWith(suffixText: 'kWh'),
            ),
            if (discrepancy != null) ...[
              const SizedBox(height: 12),
              _MessageCard(
                message: flagged
                    ? '${discrepancy.toStringAsFixed(1)}% difference. This exceeds the 15% review threshold.'
                    : '${discrepancy.toStringAsFixed(1)}% difference from the live estimate.',
                isError: flagged,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInvoice(PaymentInvoice invoice) => Column(
    children: [
      if (_completionNotice != null) ...[
        _MessageCard(message: _completionNotice!, isError: false),
        const SizedBox(height: 14),
      ],
      _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _IconBox(icon: Icons.receipt_long_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice generated',
                        style: _text(17, FontWeight.w800),
                      ),
                      Text(
                        '${invoice.stationName} • ${invoice.chargerIdentifier}',
                        style: _text(
                          11,
                          FontWeight.w500,
                          AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(
                  label: invoice.status.toUpperCase(),
                  color: invoice.isPaid ? AppColors.primary : Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _invoiceRow(
              'Energy delivered',
              '${invoice.energyDeliveredKwh.toStringAsFixed(3)} kWh',
            ),
            _invoiceRow(
              'Tariff',
              'LKR ${invoice.tariffPerKwh.toStringAsFixed(2)} / kWh',
            ),
            const Divider(color: AppColors.outlineVariant, height: 24),
            _invoiceRow(
              'Gross amount',
              'LKR ${invoice.grossAmount.toStringAsFixed(2)}',
            ),
            _invoiceRow(
              'Membership / tier savings',
              '- LKR ${invoice.discountAmount.toStringAsFixed(2)}',
              valueColor: AppColors.primary,
            ),
            _invoiceRow(
              'Advance credit',
              '- LKR ${invoice.advanceDeducted.toStringAsFixed(2)}',
              valueColor: AppColors.primary,
            ),
            const Divider(color: AppColors.outlineVariant, height: 24),
            _invoiceRow(
              'Amount due',
              'LKR ${invoice.netAmountDue.toStringAsFixed(2)}',
              emphasize: true,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (!invoice.isPaid)
        _buildSettlement(invoice)
      else
        _MessageCard(
          message:
              'Payment recorded${invoice.paymentMethod == null ? '' : ' • ${invoice.paymentMethod}'}.',
          isError: false,
        ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: _submitting ? null : _startAnother,
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text('Back to active sessions'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(color: AppColors.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ],
  );

  Widget _buildSettlement(PaymentInvoice invoice) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Record payment', style: _text(15, FontWeight.w800)),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: [
            if (!invoice.isWalkIn)
              const ButtonSegment(
                value: 'Wallet',
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: Text('Wallet'),
              ),
            const ButtonSegment(
              value: 'Cash',
              icon: Icon(Icons.payments_rounded),
              label: Text('Cash'),
            ),
          ],
          selected: {_paymentMethod},
          onSelectionChanged: (value) =>
              setState(() => _paymentMethod = value.first),
        ),
        if (invoice.isWalkIn) ...[
          const SizedBox(height: 10),
          Text(
            'Walk-in invoices must be settled in cash.',
            style: _text(11, FontWeight.w500, AppColors.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 16),
        _primaryButton(
          icon: Icons.check_circle_rounded,
          label:
              'Confirm LKR ${invoice.netAmountDue.toStringAsFixed(2)} payment',
          onPressed: _submitting ? null : _settleInvoice,
        ),
      ],
    ),
  );

  Widget _invoiceRow(
    String label,
    String value, {
    bool emphasize = false,
    Color? valueColor,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: _text(
            emphasize ? 14 : 12,
            emphasize ? FontWeight.w700 : FontWeight.w500,
            AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: _text(
            emphasize ? 18 : 13,
            emphasize ? FontWeight.w800 : FontWeight.w700,
            valueColor,
          ),
        ),
      ],
    ),
  );

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) => ElevatedButton.icon(
    onPressed: onPressed,
    icon: _submitting
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.onPrimary,
            ),
          )
        : Icon(icon),
    label: Text(
      _submitting ? 'Processing…' : label,
      style: _text(13, FontWeight.w800, AppColors.onPrimary),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      disabledBackgroundColor: AppColors.primary.withValues(alpha: .45),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    ),
  );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.outlineVariant),
    ),
    child: child,
  );

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: _text(12, FontWeight.w500, AppColors.onSurfaceVariant),
    filled: true,
    fillColor: AppColors.surfaceContainer,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );

  TextStyle _text(double size, FontWeight weight, [Color? color]) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.onSurface,
      );
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: AppColors.primary, size: 23),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
      ),
    ],
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: .5,
      ),
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.isError});
  final String message;
  final bool isError;
  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 180,
    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.ev_station_outlined,
          size: 46,
          color: AppColors.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(
          'No active sessions',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Start a reserved or walk-in charging session first.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
        ),
      ],
    ),
  );
}
