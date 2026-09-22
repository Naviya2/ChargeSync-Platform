import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/api/reservation_api_client.dart';
import '../../../../core/theme/app_colors.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _qrController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _checkIn() async {
    final qr = _qrController.text.trim();
    if (qr.isEmpty) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await ReservationApiClient.instance.staffCheckin(qr);
      
      setState(() {
        _isSuccess = true;
        _message = 'Check-in successful! Session started.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = 'Check-in failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _qrController.dispose();
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
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_scanner_rounded, size: 80, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Manual Entry (Mock Scanner)',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.onSurface),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _qrController,
              decoration: InputDecoration(
                hintText: 'Enter QR Token string',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.surfaceContainer,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkIn,
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
                  : Text('Check-In Driver', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
