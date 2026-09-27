import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../features/reservations/screens/reservation_list_screen.dart';
import '../../core/api/reservation_api_client.dart';
import '../../core/api/reservation_models.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<ReservationDto> _upcomingReservations = [];

  @override
  void initState() {
    super.initState();
    _fetchReminders();
  }

  Future<void> _fetchReminders() async {
    try {
      final res = await ReservationApiClient.instance.getMyReservations();
      if (mounted) {
        setState(() {
          _upcomingReservations = res.items
              .where((r) => r.status == 'Confirmed' || r.status == 'Pending')
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
                    return Card(
                      color: AppColors.surfaceContainerLow,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                        title: Text(
                          'Upcoming Reservation Reminder',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.onSurface),
                        ),
                        subtitle: Text(
                          'You have a charging session at ${DateFormat('HH:mm').format(res.startTime.toLocal())}.',
                          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.onSurfaceVariant),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Scaffold(body: SafeArea(child: ReservationListScreen()))),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
