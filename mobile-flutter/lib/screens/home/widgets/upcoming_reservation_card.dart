import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/reservation_api_client.dart';
import '../../../core/api/reservation_models.dart';
import '../../../core/theme/app_colors.dart';

class UpcomingReservationCard extends StatefulWidget {
  const UpcomingReservationCard({super.key});

  @override
  State<UpcomingReservationCard> createState() => _UpcomingReservationCardState();
}

class _UpcomingReservationCardState extends State<UpcomingReservationCard> {
  bool _isLoading = true;
  ReservationDto? _upcomingReservation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingReservation();
  }

  Future<void> _fetchUpcomingReservation() async {
    try {
      final result = await ReservationApiClient.instance.getMyReservations();
      // Find the first reservation that is Confirmed or Pending
      final active = result.items.where((r) => r.status == 'Confirmed' || r.status == 'Pending').toList();
      
      if (active.isNotEmpty) {
        // Sort by start time ascending
        active.sort((a, b) => a.startTime.compareTo(b.startTime));
        setState(() {
          _upcomingReservation = active.first;
          _isLoading = false;
        });
      } else {
        setState(() {
          _upcomingReservation = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showQrDialog() {
    if (_upcomingReservation?.reservationQRCode == null) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainer,
          title: Text(
            'Your QR Pass',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.qr_code_2, size: 200, color: Colors.black),
              ),
              const SizedBox(height: 16),
              Text(
                'Show this to the station staff.',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Token: ${_upcomingReservation!.reservationQRCode!.substring(0, 8)}...',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Text('Failed to load reservations', style: TextStyle(color: Colors.red));
    }

    if (_upcomingReservation == null) {
      return const SizedBox.shrink(); // Hide the card if no upcoming reservations
    }

    final res = _upcomingReservation!;
    final diff = res.startTime.difference(DateTime.now());
    final isSoon = diff.inMinutes > 0 && diff.inMinutes < 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming Reservation',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      letterSpacing: -0.005,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  res.status,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                    letterSpacing: 0.06,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Reservation details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Charger ID: ${res.chargerId.substring(0, 8)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                          letterSpacing: -0.005,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.005,
                          ),
                          children: [
                            TextSpan(
                              text: '${res.startTime.month}/${res.startTime.day} • ${res.startTime.hour}:${res.startTime.minute.toString().padLeft(2, '0')} ',
                            ),
                            if (diff.inHours < 24 && diff.inMinutes > 0)
                              TextSpan(
                                text: '(in ${diff.inHours > 0 ? '${diff.inHours}h ' : ''}${diff.inMinutes % 60}m)',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: Material(
                  color: res.reservationQRCode != null ? AppColors.primary : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: res.reservationQRCode != null ? _showQrDialog : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: res.reservationQRCode != null
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.20),
                                  blurRadius: 16,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_rounded,
                            size: 18,
                            color: res.reservationQRCode != null ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Open QR Pass',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: res.reservationQRCode != null ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                              letterSpacing: 0.01,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {},
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.directions_rounded,
                      size: 20,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
