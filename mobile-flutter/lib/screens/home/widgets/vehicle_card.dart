import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/vehicle_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../vehicles/add_edit_vehicle_screen.dart';
import '../../vehicles/vehicles_list_screen.dart';

class VehicleCard extends StatefulWidget {
  const VehicleCard({super.key});

  @override
  State<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard> {
  final VehicleService _vehicleService = VehicleService.instance;

  @override
  void initState() {
    super.initState();
    _vehicleService.fetchVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _vehicleService,
      builder: (context, _) {
        final activeVehicle = _vehicleService.activeVehicle;

        if (_vehicleService.isLoading && activeVehicle == null) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (activeVehicle == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.electric_car_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Vehicle Registered',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            'Add your EV to check charging compatibility & estimates',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddEditVehicleScreen()),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text('Register Your EV Now', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        }

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
                  // Top row: title + switch button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.electric_car_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                activeVehicle.fullName,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                  letterSpacing: -0.008,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VehiclesListScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _vehicleService.vehicles.length > 1 ? 'Switch' : 'Manage',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: 0.06,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.swap_horiz_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Battery & Specs row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                                  '${activeVehicle.batteryCapacityKwh.toInt()}',
                                  style: GoogleFonts.inter(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                    height: 1.0,
                                    letterSpacing: -0.02,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'kWh',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
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
                                  'Max ${activeVehicle.maxChargeRateKw.toInt()} kW',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
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
                          height: 54,
                          child: CustomPaint(painter: _EvSilhouettePainter()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Battery progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        value: 0.75,
                        backgroundColor: AppColors.surfaceContainer,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Status & Connector badge
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
                            activeVehicle.connector.displayName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        activeVehicle.licensePlate ?? 'Registered EV',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EvSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onSurfaceVariant.withValues(alpha: 0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double sx = size.width / 160;
    final double sy = size.height / 48;

    Offset s(double x, double y) => Offset(x * sx, y * sy);

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

    canvas.drawCircle(s(34, 35), 4.5 * sx, Paint()..color = AppColors.primary);
    canvas.drawCircle(s(126, 35), 4.5 * sx, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
