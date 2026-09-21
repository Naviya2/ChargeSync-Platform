import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class MapCanvas extends StatefulWidget {
  final int activeStationId;
  final ValueChanged<int> onStationSelected;

  const MapCanvas({
    super.key,
    required this.activeStationId,
    required this.onStationSelected,
  });

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas>
    with TickerProviderStateMixin {
  late AnimationController _pingController;
  late AnimationController _routeController;

  @override
  void initState() {
    super.initState();
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _routeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pingController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  // Station positions on map [left%, top%]
  static const Map<int, List<double>> _stationPositions = {
    1: [0.59, 0.37],
    2: [0.76, 0.56],
    3: [0.30, 0.68],
    4: [0.26, 0.24],
  };

  static const Map<int, String> _stationLabels = {
    1: '250 kW • 4 Free • \$0.31',
    2: '150 kW • 6 Free',
    3: '50 kW • 2 Free',
    4: 'Adapter Req.',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Stack(
        children: [
          // Map background
          Positioned.fill(
            child: CustomPaint(painter: _MapPainter()),
          ),

          // Route dash line (animated)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _routeController,
              builder: (_, __) => CustomPaint(
                painter: _RoutePainter(_routeController.value),
              ),
            ),
          ),

          // Map floating controls (right side)
          Positioned(
            right: 12,
            top: 12,
            child: Column(
              children: [
                _MapFab(icon: Icons.traffic_rounded, color: AppColors.primary),
                const SizedBox(height: 8),
                _MapFab(icon: Icons.layers_rounded),
                const SizedBox(height: 8),
                _MapFab(
                  icon: Icons.my_location_rounded,
                  onTap: () => widget.onStationSelected(1),
                ),
              ],
            ),
          ),

          // User location marker (left 45%, top 52%)
          LayoutBuilder(builder: (context, constraints) {
            final cx = constraints.maxWidth * 0.45;
            final cy = 420 * 0.52;
            return Positioned(
              left: cx - 24,
              top: cy - 24,
              child: AnimatedBuilder(
                animation: _pingController,
                builder: (_, __) {
                  return SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ping ring
                        Opacity(
                          opacity:
                              (1.0 - _pingController.value).clamp(0.0, 1.0),
                          child: Container(
                            width: 48 * _pingController.value,
                            height: 48 * _pingController.value,
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withOpacity(0.2 * (1 - _pingController.value)),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Inner glow ring
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.3),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.6),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.navigation_rounded,
                              size: 13,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),

          // YOU label
          LayoutBuilder(builder: (context, constraints) {
            final cx = constraints.maxWidth * 0.45;
            final cy = 420 * 0.52;
            return Positioned(
              left: cx - 16,
              top: cy + 26,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'YOU',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            );
          }),

          // Station pins
          ..._stationPositions.entries.map((e) {
            final id = e.key;
            final pos = e.value;
            final isActive = widget.activeStationId == id;
            return LayoutBuilder(builder: (context, constraints) {
              final left = constraints.maxWidth * pos[0];
              final top = 420 * pos[1];
              return Positioned(
                left: left - 40,
                top: top - 60,
                child: GestureDetector(
                  onTap: () => widget.onStationSelected(id),
                  child: AnimatedScale(
                    scale: isActive ? 1.1 : 0.92,
                    duration: const Duration(milliseconds: 200),
                    child: _StationPin(
                      id: id,
                      label: _stationLabels[id] ?? '',
                      isActive: isActive,
                    ),
                  ),
                ),
              );
            });
          }),
        ],
      ),
    );
  }
}

// ─── Map background painter ───────────────────────────────────────────────────
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base background
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF0A0E13));

    // Bay gradient silhouette
    final bayPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.5, 0)
      ..cubicTo(w * 0.46, h * 0.15, w * 0.40, h * 0.22, w * 0.33, h * 0.27)
      ..cubicTo(w * 0.24, h * 0.33, w * 0.16, h * 0.37, w * 0.10, h * 0.52)
      ..cubicTo(w * 0.06, h * 0.61, w * 0.03, h * 0.73, 0, h * 0.80)
      ..close();

    canvas.drawPath(
      bayPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.7, -0.8),
          radius: 1.2,
          colors: [
            const Color(0xFF182333).withOpacity(0.8),
            const Color(0xFF0A0E13).withOpacity(0.2),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Park patches
    _drawPark(canvas, w * 0.57, h * 0.12, w * 0.15, h * 0.15);
    _drawPark(canvas, w * 0.80, h * 0.40, w * 0.14, h * 0.20);

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1C232D)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final vLines = [0.14, 0.25, 0.36, 0.48, 0.59, 0.71];
    final hLines = [0.20, 0.33, 0.48, 0.63, 0.78];

    for (final v in vLines) {
      canvas.drawLine(Offset(w * v, 0), Offset(w * v, h), gridPaint);
    }
    for (final hh in hLines) {
      canvas.drawLine(Offset(0, h * hh), Offset(w, h * hh), gridPaint);
    }

    // Highway
    final highwayBg = Paint()
      ..color = const Color(0xFF252D3A)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final highwayFg = Paint()
      ..color = const Color(0xFF374355)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final hwPath = Path()
      ..moveTo(w * 0.075, h)
      ..lineTo(w * 0.40, h * 0.60)
      ..lineTo(w * 0.74, h * 0.35)
      ..lineTo(w, h * 0.23);
    canvas.drawPath(hwPath, highwayBg);
    canvas.drawPath(hwPath, highwayFg);

    // Primary avenue
    final avePaint = Paint()
      ..color = const Color(0xFF2C3746)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final avePath = Path()
      ..moveTo(w * 0.15, h * 0.07)
      ..lineTo(w * 0.50, h * 0.40)
      ..lineTo(w * 0.95, h * 0.90);
    canvas.drawPath(avePath, avePaint);

    // Green route highlight
    final greenPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final greenPath = Path()
      ..moveTo(w * 0.35, h * 0.25)
      ..lineTo(w * 0.50, h * 0.40)
      ..lineTo(w * 0.68, h * 0.58);
    canvas.drawPath(greenPath, greenPaint);

    // Minor streets
    final minorPaint = Paint()
      ..color = const Color(0xFF161B22)
      ..strokeWidth = 1;
    final minorLines = [
      [0.22, 0.20, 0.22, 0.48],
      [0.38, 0.20, 0.38, 0.48],
      [0.53, 0.33, 0.53, 0.63],
      [0.66, 0.33, 0.66, 0.63],
      [0.81, 0.48, 0.81, 0.78],
    ];
    for (final l in minorLines) {
      canvas.drawLine(
          Offset(w * l[0], h * l[1]), Offset(w * l[2], h * l[3]), minorPaint);
    }
  }

  void _drawPark(Canvas canvas, double cx, double cy, double rx, double ry) {
    final path = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(cx, cy), width: rx * 2, height: ry * 2));
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF14261E).withOpacity(0.4)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Animated dashed route painter ───────────────────────────────────────────
class _RoutePainter extends CustomPainter {
  final double progress;
  _RoutePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Route: vehicle (45%, 52%) → station 1 (59%, 37%)
    final path = Path()
      ..moveTo(w * 0.45, h * 0.52)
      ..lineTo(w * 0.54, h * 0.47)
      ..lineTo(w * 0.59, h * 0.37);

    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.85)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw dashes
    const dashLen = 8.0;
    const gapLen = 6.0;
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final totalLength = metric.length;
      double offset = (progress * (dashLen + gapLen)) % (dashLen + gapLen);
      while (offset < totalLength) {
        final start = offset;
        final end = math.min(offset + dashLen, totalLength);
        canvas.drawPath(
          metric.extractPath(start, end),
          paint,
        );
        offset += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.progress != progress;
}

// ─── Map floating action button ───────────────────────────────────────────────
class _MapFab extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MapFab({
    required this.icon,
    this.color = AppColors.onSurface,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withOpacity(0.92),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            )
          ],
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

// ─── Station pin ─────────────────────────────────────────────────────────────
class _StationPin extends StatelessWidget {
  final int id;
  final String label;
  final bool isActive;

  const _StationPin({
    required this.id,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Info pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    )
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive) ...[
                Icon(Icons.bolt_rounded,
                    size: 12,
                    color: isActive ? AppColors.onPrimary : AppColors.primary),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.onPrimary : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Pin circle
        Container(
          width: isActive ? 28 : 24,
          height: isActive ? 28 : 24,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.surfaceContainerHigh,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.ev_station_rounded,
            size: isActive ? 15 : 13,
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
        // Dot anchor
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
