import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api/station_models.dart';
import '../../../core/theme/app_colors.dart';

class StationBottomSheet extends StatefulWidget {
  final List<StationDto> stations;
  final int activeStationIndex;
  final ValueChanged<int> onStationSelected;

  const StationBottomSheet({
    super.key,
    required this.stations,
    required this.activeStationIndex,
    required this.onStationSelected,
  });

  @override
  State<StationBottomSheet> createState() => _StationBottomSheetState();
}

class _StationBottomSheetState extends State<StationBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(StationBottomSheet old) {
    super.didUpdateWidget(old);
    if (old.activeStationIndex != widget.activeStationIndex) {
      _glowController.forward(from: 0).then((_) => _glowController.reverse());
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  StationDto get _active => widget.stations[widget.activeStationIndex];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grab handle
          Center(
            child: Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: count + sort
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Nearby Chargers',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            letterSpacing: -0.005,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${widget.stations.length} Found',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.sort_rounded,
                            color: AppColors.onSurfaceVariant, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Optimal Speed',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Active station card
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (_, child) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary
                            .withValues(alpha: _glowController.value * 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: child,
                  ),
                  child: _ActiveStationCard(station: _active),
                ),

                const SizedBox(height: 16),

                // Nearby list header
                Text(
                  'Other Locations Nearby',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                // Other stations
                ...widget.stations.asMap().entries
                    .where((e) => e.key != widget.activeStationIndex)
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _StationListCard(
                            station: e.value,
                            onTap: () => widget.onStationSelected(e.key),
                          ),
                        )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Active Station Detail Card ───────────────────────────────────────────────
class _ActiveStationCard extends StatelessWidget {
  final StationDto station;
  const _ActiveStationCard({required this.station});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ambient glow
          // Title + bookmark
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            station.name,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                              letterSpacing: -0.01,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded,
                            color: AppColors.primary, size: 17),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      station.address,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bookmark_border_rounded,
                    color: AppColors.onSurfaceVariant, size: 17),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: station.status == StationStatus.approved
                  ? AppColors.primaryContainer.withValues(alpha: 0.15)
                  : AppColors.tertiaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  station.status == StationStatus.approved
                      ? Icons.verified_user_rounded
                      : Icons.info_rounded,
                  size: 15,
                  color: station.status == StationStatus.approved
                      ? AppColors.primary
                      : AppColors.tertiary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    station.status == StationStatus.approved
                        ? 'Approved Station'
                        : 'Status: ${station.status.name}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: station.status == StationStatus.approved
                          ? AppColors.primary
                          : AppColors.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 4-metric row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _MetricCell(label: 'SPEED', value: station.speedLabel, isHighlight: true),
                _MetricCell(label: 'CHARGERS', value: '${station.totalStalls}'),
                _MetricCell(label: 'FREE', value: '${station.freeStalls}'),
                _MetricCell(label: 'PRICE', value: station.priceLabel),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Stall availability
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: station.freeStalls > 0
                          ? AppColors.primary
                          : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    station.stallsText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                station.freeStalls > 0 ? 'Stalls available' : 'All stalls occupied',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Stall bar segments
          Row(
            children: List.generate(station.totalStalls, (i) {
              final isFree = i < station.freeStalls;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 6,
                  decoration: BoxDecoration(
                    color: isFree
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isFree
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // Connectors
          Row(
            children: [
              Text(
                'CONNECTORS:',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.06,
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                children: station.connectorNames
                    .map((c) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt_rounded,
                            color: AppColors.onPrimary, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Start Charging / Reserve',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Route',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
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

// ─── Metric cell ─────────────────────────────────────────────────────────────
class _MetricCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _MetricCell({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.06,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isHighlight ? AppColors.primary : AppColors.onSurface,
              letterSpacing: -0.005,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Secondary station list card ─────────────────────────────────────────────
class _StationListCard extends StatelessWidget {
  final StationDto station;
  final VoidCallback onTap;

  const _StationListCard({required this.station, required this.onTap});

  Color get _speedColor {
    final kw = station.maxPowerKw;
    if (kw >= 150) return AppColors.primary;
    if (kw >= 50)  return AppColors.secondary;
    return AppColors.onSurface;
  }

  Color get _dotColor {
    return station.freeStalls > 0 ? AppColors.primary : AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: title + address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              station.name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: station.status == StationStatus.approved
                                  ? AppColors.primaryContainer
                                      .withValues(alpha: 0.2)
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              station.status.name.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: station.status == StationStatus.approved
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        station.address,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right: speed + stalls
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      station.speedLabel,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _speedColor,
                      ),
                    ),
                    Text(
                      '${station.freeStalls}/${station.totalStalls} free',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${station.freeStalls} of ${station.totalStalls} stalls available',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      ' • ${station.priceLabel}/kWh',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Details',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
