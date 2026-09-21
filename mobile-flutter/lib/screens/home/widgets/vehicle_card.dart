import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({super.key});

  @override
  Widget build(BuildContext context) {
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
      child: Stack(
        children: [
          // Glow effect
          Positioned(
            right: -32,
            top: -32,
            child: Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: title + switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.electric_car_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tesla Model Y Long Range',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                          letterSpacing: -0.008,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Switch',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.06,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.expand_more_rounded,
                          size: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Battery telemetry row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Battery percentage
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '68',
                              style: GoogleFonts.inter(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                                height: 1.0,
                                letterSpacing: -0.02,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '%',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '+218 mi estimated',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 0.02,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Vehicle SVG silhouette
                  Expanded(
                    flex: 7,
                    child: SizedBox(
                      height: 56,
                      child: CustomPaint(painter: _EvSilhouettePainter()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Battery progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: 0.68,
                    backgroundColor: AppColors.surfaceContainer,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Status flags
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Connected • Standby',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.06,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.thermostat_rounded,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Optimal 72°F',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.06,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the EV silhouette SVG.
class _EvSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onSurfaceVariant.withValues(alpha: 0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Scale from SVG viewBox 160x48 to actual widget size
    final double sx = size.width / 160;
    final double sy = size.height / 48;

    Offset s(double x, double y) => Offset(x * sx, y * sy);

    // Main body path
    final bodyPath = Path()
      ..moveTo(12 * sx, 36 * sy)
      ..lineTo(148 * sx, 36 * sy)
      ..moveTo(22 * sx, 34 * sy)
      ..lineTo(28 * sx, 22 * sy)
      ..cubicTo(30 * sx, 18 * sy, 35 * sx, 15 * sy, 42 * sx, 14 * sy)
      ..lineTo(88 * sx, 12 * sy)
      ..cubicTo(96 * sx, 12 * sy, 110 * sx, 13 * sy, 124 * sx, 20 * sy)
      ..lineTo(138 * sx, 27 * sy)
      ..lineTo(142 * sx, 34 * sy);

    canvas.drawPath(bodyPath, paint);

    // Window highlight path (semi-transparent)
    final windowPaint = Paint()
      ..color = AppColors.onSurfaceVariant.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final windowPath = Path()
      ..moveTo(52 * sx, 14 * sy)
      ..lineTo(50 * sx, 25 * sy)
      ..lineTo(96 * sx, 25 * sy)
      ..lineTo(92 * sx, 12 * sy);

    canvas.drawPath(windowPath, windowPaint);

    // Front wheel
    canvas.drawCircle(s(34, 35), 4.5 * sx, Paint()..color = AppColors.primary);
    // Rear wheel
    canvas.drawCircle(s(126, 35), 4.5 * sx, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
