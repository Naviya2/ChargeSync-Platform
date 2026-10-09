import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/api/auth_service.dart';
import '../../../core/api/reservation_api_client.dart';
import '../../../core/api/reservation_models.dart';
import '../../../core/theme/app_colors.dart';
import 'qr_scanner_screen.dart';
import 'walk_in_booking_screen.dart';
import '../../payments/screens/session_checkout_screen.dart';
import '../../stations/screens/station_management_screen.dart';
import '../../../screens/auth/sign_in_screen.dart';
import 'package:permission_handler/permission_handler.dart';

// ── Simple notification model ─────────────────────────────────────────────────
class _StaffNotification {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final IconData icon;
  final Color color;

  const _StaffNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
  });
}

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  late AnimationController _pulseController;
  Timer? _pollingTimer;

  // Reservation tracking
  int _lastReservationCount = 0;
  Map<String, String> _lastStatuses = {};
  List<ReservationDto> _currentReservations = [];
  bool _reservationsLoading = true;

  // Notifications
  final List<_StaffNotification> _notifications = [];
  bool _notifPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _requestPermissions();
    _startPolling();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.location,
    ].request();
  }

  void _addNotification({
    required String title,
    required String body,
    required IconData icon,
    required Color color,
  }) {
    setState(() {
      _notifications.insert(0, _StaffNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        time: DateTime.now(),
        icon: icon,
        color: color,
      ));
    });
  }

  void _startPolling() async {
    await _loadReservations(initial: true);
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadReservations());
  }

  Future<void> _loadReservations({bool initial = false}) async {
    try {
      final res = await ReservationApiClient.instance.getMyReservations();
      if (!mounted) return;

      final items = res.items;

      // Detect new reservations and cancellations
      if (!initial) {
        for (var r in items) {
          if (!_lastStatuses.containsKey(r.id)) {
            if (r.status == 'Pending') {
              // New approval-required reservation
              _addNotification(
                title: 'Approval Request Received',
                body: 'A driver is requesting approval for a session at ${r.stationName}. Tap Approvals tab to review.',
                icon: Icons.pending_actions_rounded,
                color: Colors.orange,
              );
            } else {
              _addNotification(
                title: 'New Reservation',
                body: 'A driver just made a new reservation at your station.',
                icon: Icons.confirmation_number_rounded,
                color: AppColors.primary,
              );
            }
          } else {
            final prev = _lastStatuses[r.id];
            if (prev != null && prev != 'Cancelled' && r.status == 'Cancelled') {
              _addNotification(
                title: 'Reservation Cancelled',
                body: 'Reservation at ${r.stationName} was cancelled.',
                icon: Icons.cancel_rounded,
                color: Colors.red,
              );
            }
          }
        }
      }

      setState(() {
        _lastReservationCount = items.length;
        for (var r in items) {
          _lastStatuses[r.id] = r.status;
        }
        _currentReservations = items;
        _reservationsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _reservationsLoading = false);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _approveReservation(String id) async {
    try {
      await ReservationApiClient.instance.approveReservation(id);
      _addNotification(
        title: 'Reservation Approved',
        body: 'The reservation has been approved and the advance fee deducted.',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
      );
      await _loadReservations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectReservation(String id) async {
    try {
      await ReservationApiClient.instance.rejectReservation(id);
      _addNotification(
        title: 'Reservation Rejected',
        body: 'The reservation request has been declined.',
        icon: Icons.cancel_rounded,
        color: Colors.orange,
      );
      await _loadReservations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final unread = _notifications.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // ── Content ──────────────────────────────────────────────
          IndexedStack(
            index: _currentTab < 7 ? _currentTab : 0,
            children: [
              _StaffHomeTab(
                reservations: _currentReservations,
                onTabSelected: (idx) => setState(() => _currentTab = idx),
              ),
              _currentTab == 1 ? const QrScannerScreen() : const SizedBox(),
              const StationManagementScreen(),
              const WalkInBookingScreen(),
              SessionCheckoutScreen(active: _currentTab == 4),
              _CurrentReservationsTab(
                reservations: _currentReservations,
                isLoading: _reservationsLoading,
                onRefresh: () => _loadReservations(),
                onApprove: _approveReservation,
                onReject: _rejectReservation,
              ),
            ],
          ),

          // ── Notification Panel Overlay ────────────────────────────
          if (_notifPanelOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _notifPanelOpen = false),
                child: Container(color: Colors.black.withValues(alpha: 0.5)),
              ),
            ),
          if (_notifPanelOpen)
            Positioned(
              top: topPadding + 64,
              right: 12,
              left: 12,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(20),
                color: AppColors.surfaceContainerLow,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Notifications',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppColors.onSurface)),
                            if (_notifications.isNotEmpty)
                              TextButton(
                                onPressed: () => setState(() => _notifications.clear()),
                                child: const Text('Clear all'),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      if (_notifications.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const Icon(Icons.notifications_none_rounded,
                                  size: 48, color: AppColors.onSurfaceVariant),
                              const SizedBox(height: 12),
                              Text('No notifications yet',
                                  style: GoogleFonts.inter(
                                      color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _notifications.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1, indent: 56),
                            itemBuilder: (_, i) {
                              final n = _notifications[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      n.color.withValues(alpha: 0.15),
                                  child: Icon(n.icon, color: n.color, size: 20),
                                ),
                                title: Text(n.title,
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: AppColors.onSurface)),
                                subtitle: Text(n.body,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant)),
                                trailing: Text(
                                    DateFormat('hh:mm a').format(n.time),
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant)),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // ── App Bar ──────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.92),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: topPadding),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.bolt_rounded, size: 20,
                                  color: AppColors.onPrimaryContainer),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ChargeSync',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface,
                                        letterSpacing: -0.005)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (_, _) => Container(
                                        width: 6, height: 6,
                                        decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Staff Mode • ${user?.fullName ?? 'Staff'}',
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onSurfaceVariant,
                                          letterSpacing: 0.06),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Notification Bell
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _notifPanelOpen = !_notifPanelOpen),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.surfaceContainer,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                        Icons.notifications_outlined,
                                        size: 18,
                                        color: AppColors.onSurface),
                                  ),
                                  if (unread > 0)
                                    Positioned(
                                      right: 0, top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppColors.surface, width: 2),
                                        ),
                                        child: Text('$unread',
                                            style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Logout
                            GestureDetector(
                              onTap: _logout,
                              child: Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withValues(alpha: 0.1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withValues(alpha: 0.15),
                                        blurRadius: 4,
                                      ),
                                    ],
                                ),
                                child: const Icon(Icons.logout_rounded,
                                    size: 18, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Nav ───────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.90),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: SizedBox(
                  height: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        isActive: _currentTab == 0,
                        onTap: () => setState(() => _currentTab = 0),
                      ),
                      _NavItem(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Scan QR',
                        isActive: _currentTab == 1,
                        onTap: () => setState(() => _currentTab = 1),
                      ),
                      _NavItem(
                        icon: Icons.calendar_today_rounded,
                        label: 'Reservations',
                        isActive: _currentTab == 5,
                        onTap: () => setState(() => _currentTab = 5),
                      ),
                      _NavItem(
                        icon: Icons.ev_station_rounded,
                        label: 'Stations',
                        isActive: _currentTab == 2,
                        onTap: () => setState(() => _currentTab = 2),
                      ),
                      _NavItem(
                        icon: Icons.directions_walk_rounded,
                        label: 'Walk-In',
                        isActive: _currentTab == 3,
                        onTap: () => setState(() => _currentTab = 3),
                      ),
                      _NavItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Checkout',
                        isActive: _currentTab == 4,
                        onTap: () => setState(() => _currentTab = 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Staff Home Tab ────────────────────────────────────────────────────────────
class _StaffHomeTab extends StatelessWidget {
  final List<ReservationDto> reservations;
  final ValueChanged<int> onTabSelected;
  const _StaffHomeTab({required this.reservations, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final user = AuthService.instance.currentUser;
    final ongoingReservations = reservations.where((r) => r.status == 'CheckedIn').toList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, topPadding + 80, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Welcome, ${user?.fullName ?? 'Staff'}',
            style: GoogleFonts.inter(
              fontSize: 24, fontWeight: FontWeight.w700,
              color: AppColors.onSurface, letterSpacing: -0.01,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.shield_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${user?.role ?? 'Staff'} • On-Site POS Mode',
                style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant, letterSpacing: 0.02,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          if (ongoingReservations.isNotEmpty) ...[
            Text(
              'Ongoing Sessions',
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
            ),
            const SizedBox(height: 12),
            ...ongoingReservations.map((res) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Checked In',
                          style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        Text(
                          '${DateFormat('hh:mm a').format(res.startTime.toLocal())} → ${DateFormat('hh:mm a').format(res.endTime.toLocal())}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Driver: ${res.driverName.isNotEmpty ? res.driverName : 'N/A'}',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Charger: ${res.chargerName.isNotEmpty ? res.chargerName : res.chargerId.substring(0, 8)}',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
          _ActionCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan QR Check-in',
            subtitle: 'Scan a driver\'s reservation QR code to start their session.',
            onTap: () => onTabSelected(1),
          ),
          const SizedBox(height: 16),
          _ActionCard(
            icon: Icons.directions_walk_rounded,
            title: 'Admit Walk-In',
            subtitle: 'Lock an available charger for an unregistered customer.',
            onTap: () => onTabSelected(3),
          ),
          const SizedBox(height: 16),
          _ActionCard(
            icon: Icons.receipt_long_rounded,
            title: 'Session Checkout',
            subtitle: 'Complete charging, verify energy, invoice, and take payment.',
            onTap: () => onTabSelected(4),
          ),
          const SizedBox(height: 16),
          _ActionCard(
            icon: Icons.pending_actions_rounded,
            title: 'Pending Approvals',
            subtitle: 'Review AI-flagged reservations requiring approval.',
            onTap: () => onTabSelected(5),
          ),
        ],
      ),
    );
  }
}

// ── Current Reservations Tab ──────────────────────────────────────────────────
class _CurrentReservationsTab extends StatelessWidget {
  final List<ReservationDto> reservations;
  final bool isLoading;
  final VoidCallback onRefresh;
  final void Function(String) onApprove;
  final void Function(String) onReject;

  const _CurrentReservationsTab({
    required this.reservations,
    required this.isLoading,
    required this.onRefresh,
    required this.onApprove,
    required this.onReject,
  });

  String _fmt(DateTime dt) {
    return DateFormat('MMM d, hh:mm a').format(dt.toLocal());
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed': return AppColors.primary;
      case 'Pending': return Colors.orange;
      case 'CheckedIn': return Colors.green;
      case 'Cancelled': return Colors.red;
      case 'Completed': return Colors.grey;
      default: return AppColors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    if (isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: topPadding + 80),
          child: const CircularProgressIndicator(),
        ),
      );
    }

    final active = reservations
        .where((r) => r.status == 'Confirmed' || r.status == 'Pending' || r.status == 'CheckedIn')
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, topPadding + 88, 16, 100),
        itemCount: active.isEmpty ? 1 : active.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (active.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    const Icon(Icons.event_available_rounded,
                        size: 64, color: AppColors.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text('No active reservations',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            );
          }

          final res = active[i];
          final statusColor = _statusColor(res.status);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: statusColor.withValues(alpha: 0.4), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        res.stationName.isNotEmpty ? res.stationName : 'Station',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(res.status,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Driver: ${res.driverName.isNotEmpty ? res.driverName : 'N/A'}',
                    style: GoogleFonts.inter(
                        color: AppColors.onSurfaceVariant, fontSize: 13)),
                Text('Charger: ${res.chargerName.isNotEmpty ? res.chargerName : res.chargerId.substring(0, 8)}',
                    style: GoogleFonts.inter(
                        color: AppColors.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${_fmt(res.startTime)} → ${_fmt(res.endTime)}',
                        style: GoogleFonts.inter(
                            color: AppColors.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
                if (res.status == 'Pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => onReject(res.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => onApprove(res.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                    color: AppColors.primaryContainer, shape: BoxShape.circle),
                child: Icon(icon, size: 26, color: AppColors.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: color),
                if (badge != null && badge! > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge.toString(),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: 0.04,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}







