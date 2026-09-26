import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/api/reservation_api_client.dart';
import '../../../../core/theme/app_colors.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _qrController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;
  bool _hasScanned = false; // Prevent multiple scans at once

  @override
  void dispose() {
    _qrController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned || _isLoading) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      _qrController.text = code;
      _hasScanned = true; // Lock it so it doesn't fire 10 times a second
      _checkIn(code);
    }
  }

  Future<void> _checkIn(String qr) async {
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
      
      // Stop scanning on success
      _scannerController.stop();
      
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = 'Check-in failed: $e';
        _isLoading = false;
        // Allow scanning again if it failed
        _hasScanned = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, topPadding + 80, 24, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Live Camera Scanner ──────────────────────────────────
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSuccess ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: _isSuccess 
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 80, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Session Active',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isSuccess = false;
                            _message = null;
                            _hasScanned = false;
                            _qrController.clear();
                          });
                          _scannerController.start();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                        child: const Text('Scan Another'),
                      )
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                      ),
                      // Scanner overlay reticle
                      Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (_isLoading)
                        Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
          ),
          
          const SizedBox(height: 24),
          
          // ── Manual Fallback ──────────────────────────────────────
          Text(
            'Manual Entry Fallback',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _qrController,
            decoration: InputDecoration(
              hintText: 'Enter QR token manually',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.surfaceContainer,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_isLoading || _isSuccess) ? null : () => _checkIn(_qrController.text.trim()),
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
                : Text('Check-In Manually', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          
          // ── Status Messages ──────────────────────────────────────
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
