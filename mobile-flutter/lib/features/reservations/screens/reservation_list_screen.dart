import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/api/reservation_api_client.dart';
import '../../../../core/api/reservation_models.dart';
import '../../../../core/theme/app_colors.dart';
import 'waitlist_screen.dart';

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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchReservations() async {
    try {
      final result = await ReservationApiClient.instance.getMyReservations();
      setState(() {
        _reservations = result.items;
        _reservations.sort((a, b) => b.startTime.compareTo(a.startTime));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab Bar ──────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(icon: Icon(Icons.confirmation_number_rounded, size: 18), text: 'Reservations'),
              Tab(icon: Icon(Icons.queue_rounded, size: 18), text: 'Waitlist'),
            ],
          ),
        ),
        // ── Tab Content ──────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReservationList(),
              const WaitlistScreen(),
            ],
          ),
        ),
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
              style: GoogleFonts.inter(color: AppColors.onSurface, fontSize: 16),
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
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final res = _reservations[index];
          final isActive = res.status == 'Confirmed' || res.status == 'Pending';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent,
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
                        'Charger: ${res.chargerId.substring(0, 8)}…',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
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
                        res.status,
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
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${_fmt(res.startTime)} → ${_fmt(res.endTime)}',
                      style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(height: 12),
                  if (res.reservationQRCode != null && res.reservationQRCode!.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Center(
                      child: Column(
                        children: [
                          Text('Scan at Station', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.white,
                            child: QrImageView(
                              data: res.reservationQRCode!,
                              version: QrVersions.auto,
                              size: 150.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _cancelReservation(res.id),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Cancel Reservation'),
                    ),
                  ),
                ],
              ],
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
