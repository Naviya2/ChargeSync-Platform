import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../features/reservations/screens/reservation_list_screen.dart';
import '../../core/api/reservation_api_client.dart';
import '../../core/api/reservation_models.dart';
import '../../core/api/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<ReservationDto> _upcomingReservations = [];
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchReminders();
  }

  Future<void> _fetchReminders() async {
    try {
      final res = await ReservationApiClient.instance.getMyReservations();
      final dismissedStr = await _storage.read(key: 'dismissed_notifications') ?? '[]';
      final dismissedIds = List<String>.from(jsonDecode(dismissedStr));
      
      if (mounted) {
        setState(() {
          _upcomingReservations = res.items
              .where((r) => 
                  !dismissedIds.contains(r.id) &&
                  (r.status == 'Confirmed' || 
                  r.status == 'Pending' || 
                  r.status == 'CheckedIn' ||
                  r.status == 'Completed' ||
                  (r.status == 'Cancelled' && 
                   r.startTime.toLocal().isAfter(DateTime.now().subtract(const Duration(hours: 24))))))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearAll() async {
    final dismissedStr = await _storage.read(key: 'dismissed_notifications') ?? '[]';
    final dismissedIds = List<String>.from(jsonDecode(dismissedStr));
    dismissedIds.addAll(_upcomingReservations.map((e) => e.id));
    await _storage.write(key: 'dismissed_notifications', value: jsonEncode(dismissedIds));
    
    setState(() {
      _upcomingReservations.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_upcomingReservations.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'Clear All',
                style: GoogleFonts.inter(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _upcomingReservations.isEmpty
          ? Center(
              child: Text(
                'No new notifications',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _upcomingReservations.length,
              itemBuilder: (context, index) {
                final res = _upcomingReservations[index];
                final isLate = res.startTime.toLocal().isBefore(DateTime.now());
                final isCancelled = res.status == 'Cancelled';
                
                final isStationOwner = AuthService.instance.currentUser?.role == 'StationOwner';
                
                return Card(
                  color: AppColors.surfaceContainerLow,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isLate || isCancelled ? AppColors.error.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      res.status == 'CheckedIn' ? Icons.bolt_rounded :
                      res.status == 'Completed' ? Icons.check_circle_rounded :
                      res.status == 'Pending' ? Icons.hourglass_empty_rounded :
                      isCancelled ? Icons.cancel : (isLate ? Icons.warning_amber_rounded : Icons.calendar_today),
                      color: isLate || isCancelled ? AppColors.error : res.status == 'Pending' ? Colors.orange : AppColors.primary,
                    ),
                    title: Text(
                      res.status == 'CheckedIn' ? 'Session Started' :
                      res.status == 'Completed' ? 'Session Completed' :
                      res.status == 'Pending' ? 'Reservation Pending Approval' :
                      isCancelled ? 'Reservation Cancelled / Rejected' : (isLate ? 'Missed Session Alert!' : 'Upcoming Reservation Reminder'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: res.status == 'CheckedIn' || res.status == 'Completed' ? AppColors.primary :
                               isLate || isCancelled ? AppColors.error : res.status == 'Pending' ? Colors.orange.shade800 : AppColors.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      res.status == 'CheckedIn'
                          ? 'Your charging session at ${res.stationName} has started. You can view live usage in your reservations.'
                          : res.status == 'Completed'
                          ? 'Your charging session at ${res.stationName} is completed. Thank you for using ChargeSync!'
                          : res.status == 'Pending'
                          ? (isStationOwner || AuthService.instance.currentUser?.role == 'Staff'
                              ? 'A reservation request at ${DateFormat('HH:mm').format(res.startTime.toLocal())} requires your approval.'
                              : 'Your reservation request at ${DateFormat('HH:mm').format(res.startTime.toLocal())} is awaiting operator approval.')
                          : isCancelled
                          ? (isStationOwner || AuthService.instance.currentUser?.role == 'Staff'
                              ? 'Reservation at ${DateFormat('HH:mm').format(res.startTime.toLocal())} was cancelled or rejected.'
                              : 'Your reservation at ${DateFormat('HH:mm').format(res.startTime.toLocal())} was cancelled or rejected.')
                          : (isLate
                              ? (isStationOwner || AuthService.instance.currentUser?.role == 'Staff'
                                  ? 'Driver is late for the session at ${DateFormat('HH:mm').format(res.startTime.toLocal())}. It will be cancelled 30 mins after start time.'
                                  : 'You haven\'t started your session scheduled for ${DateFormat('HH:mm').format(res.startTime.toLocal())}. It will be automatically cancelled 30 minutes after the start time.')
                              : (isStationOwner || AuthService.instance.currentUser?.role == 'Staff'
                                  ? 'A driver has an approved charging session at ${DateFormat('HH:mm').format(res.startTime.toLocal())}.'
                                  : 'Your reservation for ${DateFormat('HH:mm').format(res.startTime.toLocal())} has been approved and confirmed.')),
                      style: GoogleFonts.inter(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(
                            body: SafeArea(child: ReservationListScreen()),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
