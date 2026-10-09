import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/api/reservation_api_client.dart';
import '../../../../core/theme/app_colors.dart';

class QrScannerScreen extends StatefulWidget {
  final bool active;
  const QrScannerScreen({super.key, this.active = true});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with WidgetsBindingObserver {
  final _qrController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const [BarcodeFormat.qrCode],
  );
  
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;
  bool _isFailed = false;
  bool _hasScanned = false; // Prevent multiple scans at once

  bool _hasPermission = false;
  bool _checkingPermission = false;
  bool _isStartingScanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.active) {
      _checkPermission();
    }
  }

  @override
  void didUpdateWidget(covariant QrScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        if (!_hasPermission) {
          _checkPermission();
        } else {
          _startScanner();
        }
      } else {
        _scannerController.stop();
      }
    }
  }

  Future<void> _startScanner() async {
    if (!mounted || !widget.active || !_hasPermission || _isSuccess || _isFailed || _isStartingScanner) {
      return;
    }

    _isStartingScanner = true;
    try {
      // Delay starting slightly so the MobileScanner widget can mount first
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || !widget.active) return;
      await _scannerController.start();
    } catch (e) {
      debugPrint('Error starting scanner: $e');
    } finally {
      if (mounted) {
        _isStartingScanner = false;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _scannerController.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (widget.active) {
        _startScanner();
      }
    }
  }

  Future<void> _checkPermission() async {
    if (!mounted) return;
    setState(() => _checkingPermission = true);
    try {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }
      if (mounted) {
        setState(() {
          _hasPermission = status.isGranted;
          _checkingPermission = false;
        });
        if (status.isGranted) {
          _startScanner();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _checkingPermission = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _qrController.dispose();
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
      
      if (!mounted) return;
      setState(() {
        _isSuccess = true;
        _message = 'Check-in successful! Session started.';
        _isLoading = false;
      });

      // Show success popup
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 72),
                const SizedBox(height: 16),
                Text('Check-In Successful!',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('The session has been started successfully.',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
    } catch (e) {
      if (!mounted) return;
      String errorMessage = e.toString().replaceAll(RegExp(r'Exception:\s*'), '');
      
      setState(() {
        _isSuccess = false;
        _isFailed = true;
        _isLoading = false;
        _message = errorMessage;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Check-in Failed'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isSuccess = false;
                  _isFailed = false;
                  _message = null;
                  _hasScanned = false;
                  _qrController.clear();
                });
                _startScanner();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
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
                            _isFailed = false;
                            _message = null;
                            _hasScanned = false;
                            _qrController.clear();
                          });
                          _startScanner();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                        child: const Text('Scan Another'),
                      )
                    ],
                  )
                : _isFailed
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 80, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Check-in Failed',
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isSuccess = false;
                            _isFailed = false;
                            _message = null;
                            _hasScanned = false;
                            _qrController.clear();
                          });
                          _startScanner();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                        child: const Text('Try Again'),
                      )
                    ],
                  )
                : !widget.active
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded, size: 64, color: AppColors.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          'Switch to this tab to scan QR code',
                          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : _checkingPermission
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : !_hasPermission
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.videocam_off_rounded, size: 56, color: Colors.orangeAccent),
                          const SizedBox(height: 12),
                          Text(
                            'Camera Permission Required',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Camera access is needed to scan customer QR codes.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _checkPermission,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                            ),
                            child: const Text('Grant Camera Access'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                        errorBuilder: (context, error, child) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'Camera Error: $error',
                                  style: const TextStyle(color: Colors.red, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    if (!_hasPermission) {
                                      _checkPermission();
                                    } else {
                                      _startScanner();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                  ),
                                  child: const Text('Retry Camera'),
                                ),
                              ],
                            ),
                          );
                        },
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
