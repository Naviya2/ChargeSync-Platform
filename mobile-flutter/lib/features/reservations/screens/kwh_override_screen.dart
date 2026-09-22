import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/api/session_api_client.dart';
import '../../../../core/theme/app_colors.dart';

/// Allows station staff to input a manual kWh reading from the physical charger
/// meter and upload a photo as proof. Discrepancies > 15% are automatically
/// flagged for Platform Administrator review.
class KwhOverrideScreen extends StatefulWidget {
  const KwhOverrideScreen({super.key});

  @override
  State<KwhOverrideScreen> createState() => _KwhOverrideScreenState();
}

class _KwhOverrideScreenState extends State<KwhOverrideScreen> {
  final _sessionIdController = TextEditingController();
  final _autoKwhController = TextEditingController();
  final _overrideKwhController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _meterPhoto;
  bool _isLoading = false;
  String? _resultMessage;
  bool _isSuccess = false;
  double? _discrepancyPercent;

  final _picker = ImagePicker();

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _recalcDiscrepancy() {
    final auto = double.tryParse(_autoKwhController.text.trim());
    final override = double.tryParse(_overrideKwhController.text.trim());
    if (auto != null && override != null && auto > 0) {
      setState(() {
        _discrepancyPercent = ((override - auto).abs() / auto) * 100;
      });
    } else {
      setState(() => _discrepancyPercent = null);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (picked != null) {
        setState(() => _meterPhoto = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not access camera/gallery: $e')),
      );
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: Text('Take Photo', style: GoogleFonts.inter(color: AppColors.onSurface)),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: Text('Choose from Gallery', style: GoogleFonts.inter(color: AppColors.onSurface)),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submitOverride() async {
    if (!_formKey.currentState!.validate()) return;

    if (_meterPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please upload a photo of the meter board as proof.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      await SessionApiClient.instance.stopSessionWithOverride(
        sessionId: _sessionIdController.text.trim(),
        staffOverriddenKwh: double.parse(_overrideKwhController.text.trim()),
        meterPhoto: _meterPhoto,
      );

      final isFlagged = (_discrepancyPercent ?? 0) > 15;

      setState(() {
        _isSuccess = true;
        _resultMessage = isFlagged
            ? 'Session stopped. ⚠️ Discrepancy of ${_discrepancyPercent!.toStringAsFixed(1)}% flagged for Admin review.'
            : 'Session stopped. kWh override recorded with meter proof.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _resultMessage = 'Failed to submit override: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _sessionIdController.dispose();
    _autoKwhController.dispose();
    _overrideKwhController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isFlagged = (_discrepancyPercent ?? 0) > 15;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, topPadding + 84, 20, 96),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title ──────────────────────────────────────────────────
            Text(
              'kWh Override',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
                letterSpacing: -0.01,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter the physical meter reading to correct the system-calculated energy consumption. A photo of the meter board is required as fraud-prevention proof.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // ── Session ID ─────────────────────────────────────────────
            _buildLabel('Session ID'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _sessionIdController,
              style: GoogleFonts.inter(color: AppColors.onSurface),
              decoration: _inputDecoration('Paste or type the session ID'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // ── System-Calculated kWh ──────────────────────────────────
            _buildLabel('System-Calculated kWh (Auto)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _autoKwhController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(color: AppColors.onSurface),
              decoration: _inputDecoration('e.g. 24.50'),
              onChanged: (_) => _recalcDiscrepancy(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Staff Override kWh ─────────────────────────────────────
            _buildLabel('Physical Meter Reading (kWh)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _overrideKwhController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(color: AppColors.onSurface),
              decoration: _inputDecoration('Read from charger display'),
              onChanged: (_) => _recalcDiscrepancy(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Discrepancy Indicator ──────────────────────────────────
            if (_discrepancyPercent != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isFlagged
                      ? Colors.orange.withOpacity(0.15)
                      : AppColors.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFlagged ? Colors.orange : AppColors.primary,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isFlagged ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                      color: isFlagged ? Colors.orange : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isFlagged
                            ? 'Discrepancy: ${_discrepancyPercent!.toStringAsFixed(1)}% — exceeds 15% threshold. Will be flagged for Admin audit.'
                            : 'Discrepancy: ${_discrepancyPercent!.toStringAsFixed(1)}% — within acceptable range.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isFlagged ? Colors.orange : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ── Meter Photo Upload ─────────────────────────────────────
            _buildLabel('Meter Board Photo (Required Proof)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showPickerOptions,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _meterPhoto != null ? 220 : 140,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _meterPhoto != null
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant.withOpacity(0.3),
                    width: _meterPhoto != null ? 2 : 1,
                    style: _meterPhoto != null ? BorderStyle.solid : BorderStyle.solid,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _meterPhoto != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_meterPhoto!, fit: BoxFit.cover),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _showPickerOptions,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withOpacity(0.85),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo_rounded,
                            size: 36,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tap to capture or upload meter photo',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Camera or Gallery',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit Button ──────────────────────────────────────────
            ElevatedButton(
              onPressed: _isLoading ? null : _submitOverride,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor: AppColors.primaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.electric_meter_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Submit Override & Stop Session',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),

            // ── Result Message ─────────────────────────────────────────
            if (_resultMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? (_discrepancyPercent != null && _discrepancyPercent! > 15
                          ? Colors.orange.withOpacity(0.1)
                          : AppColors.primaryContainer.withOpacity(0.2))
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSuccess
                        ? (_discrepancyPercent != null && _discrepancyPercent! > 15
                            ? Colors.orange
                            : AppColors.primary)
                        : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                      color: _isSuccess
                          ? (_discrepancyPercent != null && _discrepancyPercent! > 15
                              ? Colors.orange
                              : AppColors.primary)
                          : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _resultMessage!,
                        style: GoogleFonts.inter(
                          color: _isSuccess
                              ? (_discrepancyPercent != null && _discrepancyPercent! > 15
                                  ? Colors.orange
                                  : AppColors.primary)
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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
  }

  // ── Shared Widgets ───────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        letterSpacing: 0.01,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
      filled: true,
      fillColor: AppColors.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
