import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/api/reservation_api_client.dart';
import '../../../../core/theme/app_colors.dart';

class WalkInBookingScreen extends StatefulWidget {
  const WalkInBookingScreen({super.key});

  @override
  State<WalkInBookingScreen> createState() => _WalkInBookingScreenState();
}

class _WalkInBookingScreenState extends State<WalkInBookingScreen> {
  final _chargerIdController = TextEditingController();
  final _durationController = TextEditingController(text: '60'); // Minutes
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _admitWalkIn() async {
    final chargerId = _chargerIdController.text.trim();
    final durationMins = int.tryParse(_durationController.text.trim()) ?? 60;
    
    if (chargerId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final now = DateTime.now();
      final endTime = now.add(Duration(minutes: durationMins));
      
      await ReservationApiClient.instance.createWalkIn(chargerId, now, endTime);
      
      setState(() {
        _isSuccess = true;
        _message = 'Walk-In admitted! Charger $chargerId is locked and session started.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = 'Failed to admit Walk-in: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _chargerIdController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, topPadding + 80, 24, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            Text(
              'Unregistered Customer',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Admitting a walk-in will instantly lock the charger and start a charging session without requiring a driver account.',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _chargerIdController,
              decoration: InputDecoration(
                labelText: 'Charger ID',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.surfaceContainer,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Estimated Duration (Minutes)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.surfaceContainer,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _admitWalkIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Admit & Lock Charger', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
            if (_message != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess ? AppColors.primaryContainer : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _message!,
                  style: GoogleFonts.inter(
                    color: _isSuccess ? AppColors.onPrimaryContainer : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
        ],
      ),
    );
  }
}
