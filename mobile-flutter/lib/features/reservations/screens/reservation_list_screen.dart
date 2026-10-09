import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/reservation_api_client.dart';
import '../../../../core/api/reservation_models.dart';
import '../../../../core/api/session_api_client.dart';
import '../../payments/models/payment_models.dart';
import '../../../../core/theme/app_colors.dart';
import 'edit_reservation_time_screen.dart';
import 'dart:async';

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({super.key});

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<ReservationDto> _reservations = [];
  List<String> _clearedReservationIds = [];
  List<ChargingSessionSummary> _activeSessions = [];
  Timer? _clock;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadClearedAndFetch();
    _clock = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadClearedAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _clearedReservationIds =
          prefs.getStringList('cleared_reservations') ?? [];
    });
    _fetchReservations();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchReservations() async {
    try {
      final result = await ReservationApiClient.instance.getMyReservations();
      final sessions = await SessionApiClient.instance.getActiveSessions();
      setState(() {
        _reservations = result.items
            .where((r) => !_clearedReservationIds.contains(r.id))
            .toList();
        _reservations.sort((a, b) => b.startTime.compareTo(a.startTime));
        _activeSessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelReservation(String id) async {
    try {
      await ReservationApiClient.instance.cancelReservation(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation cancelled successfully')),
      );
      setState(() => _isLoading = true);
      _fetchReservations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
    }
  }

  Future<void> _clearHistory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _clearedReservationIds.add(id);
    await prefs.setStringList('cleared_reservations', _clearedReservationIds);
    setState(() {
      _reservations.removeWhere((r) => r.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────
        Container(
          width: double.infinity,
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              const Icon(
                Icons.confirmation_number_rounded,
                size: 28,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'My Reservations',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        // ── Content ──────────────────────────────────────────
        Expanded(child: _buildReservationList()),
      ],
    );
  }

  Widget _buildReservationList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load reservations',
              style: GoogleFonts.inter(
                color: AppColors.onSurface,
                fontSize: 16,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchReservations();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reservations.isEmpty) {
      return Center(
        child: Text(
          'No reservations yet.',
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchReservations,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _reservations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final res = _reservations[index];
          final isActive = res.status == 'Confirmed' || res.status == 'Pending';

          return Dismissible(
            key: ValueKey(res.id),
            direction: isActive
                ? DismissDirection.none
                : DismissDirection.endToStart,
            onDismissed: (_) => _clearHistory(res.id),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          res.stationName.isNotEmpty
                              ? res.stationName
                              : 'Station',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        res.status == 'Pending' ? 'Pending Approval' : res.status,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                  const SizedBox(height: 8),
                  Text(
                    'Charger: ${res.chargerName.isNotEmpty ? res.chargerName : res.chargerId.substring(0, 8)}',
                    style: GoogleFonts.inter(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Vehicle: ${res.vehicleName.isNotEmpty ? res.vehicleName : 'N/A'}',
                    style: GoogleFonts.inter(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_fmt(res.startTime)} → ${_fmt(res.endTime)}',
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (res.lateCancellationFee > 0)
                    Text(
                      'Late cancellation fee assessed: LKR ${res.lateCancellationFee.toStringAsFixed(2)}. Collected on the next booking.',
                    ),
                  if (res.cancellationFeesPaid > 0)
                    Text(
                      'Previous cancellation fees paid: LKR ${res.cancellationFeesPaid.toStringAsFixed(2)} (separate from advance).',
                    ),
                  if (res.status == 'CheckedIn' &&
                      _activeSessions.any(
                        (s) => s.reservationId == res.id,
                      )) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final session = _activeSessions.firstWhere(
                          (s) => s.reservationId == res.id,
                        );
                        final energy = session.estimatedEnergyAt(
                          DateTime.now(),
                        );
                        final cost = energy * session.tariffPerKwh;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh.withOpacity(
                              0.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.outlineVariant.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'Live Usage',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${energy.toStringAsFixed(2)} kWh',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    'Est. Cost',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'LKR ${cost.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  if (res.status == 'Completed' &&
                      res.finalEnergyDeliveredKwh != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                'Total Usage',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${res.finalEnergyDeliveredKwh!.toStringAsFixed(2)} kWh',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Final Cost',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'LKR ${res.invoiceNetAmount?.toStringAsFixed(2) ?? '0.00'}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Payment',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                res.invoicePaymentMethod ?? 'N/A',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isActive) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            final now = DateTime.now();
                            if (res.startTime.difference(now).inHours < 2) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Edit Not Allowed'),
                                  content: const Text(
                                    'Editing the time slot is only possible 2 hours or more before the reservation start time.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditReservationTimeScreen(
                                    reservation: res,
                                  ),
                                ),
                              ).then((changed) {
                                if (changed == true) {
                                  setState(() => _isLoading = true);
                                  _fetchReservations();
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.edit_calendar, size: 16),
                          label: const Text(
                            'Edit',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Cancel Reservation'),
                                scrollable: true,
                                content: Text(
                                  'Your LKR ${res.advanceDepositAmount.toStringAsFixed(2)} advance will be refunded.\n\n'
                                  'If you cancel less than 2 hours before the booked start (including after it), '
                                  'a LKR 500 cancellation fee will be collected with your next booking. '
                                  'Cancellation 2 hours or more before start is free.\n\n'
                                  'Previously paid cancellation fees are not refunded.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _cancelReservation(res.id);
                                    },
                                    child: const Text(
                                      'Yes, Cancel',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (res.reservationQRCode != null &&
                            res.reservationQRCode!.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Reservation QR Code'),
                                  content: SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: QrImageView(
                                          data: res.reservationQRCode!,
                                          version: QrVersions.auto,
                                          size: 200.0,
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code, size: 16),
                            label: const Text(
                              'View QR',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final query =
                                '${res.stationLatitude},${res.stationLongitude}';
                            final url = Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=$query',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not launch maps'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.directions, size: 16),
                          label: const Text(
                            'Directions',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.onSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.month}/${local.day} $h:$m';
  }
}
