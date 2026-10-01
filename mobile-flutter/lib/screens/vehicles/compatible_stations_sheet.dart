import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/vehicle_api_client.dart';
import '../../core/api/vehicle_models.dart';
import '../../core/theme/app_colors.dart';

class CompatibleStationsSheet extends StatefulWidget {
  final Vehicle vehicle;

  const CompatibleStationsSheet({
    super.key,
    required this.vehicle,
  });

  static Future<void> show(BuildContext context, Vehicle vehicle) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompatibleStationsSheet(vehicle: vehicle),
    );
  }

  @override
  State<CompatibleStationsSheet> createState() => _CompatibleStationsSheetState();
}

class _CompatibleStationsSheetState extends State<CompatibleStationsSheet> {
  double _radiusKm = 25.0;
  bool _isLoading = true;
  String? _errorMessage;
  List<CompatibleStation> _stations = [];
  double _latitude = 6.9271;
  double _longitude = 79.8612;

  @override
  void initState() {
    super.initState();
    _fetchCompatibleStations();
  }

  Future<void> _resolveLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      _latitude = position.latitude;
      _longitude = position.longitude;
    } catch (_) {
      // Keep Colombo fallback when GPS is unavailable.
    }
  }

  Future<void> _fetchCompatibleStations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _resolveLocation();
      final stations = await VehicleApiClient.instance.getCompatibleStations(
        vehicleId: widget.vehicle.id,
        latitude: _latitude,
        longitude: _longitude,
        radiusKm: _radiusKm,
      );

      if (mounted) {
        setState(() {
          _stations = stations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header: Vehicle Context
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Compatible Stations',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stations with matching ${v.connector.displayName} sockets for ${v.fullName}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Vehicle Spec Summary Strip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSpecItem(Icons.electrical_services_rounded, v.connector.shortName),
                _buildSpecDivider(),
                _buildSpecItem(Icons.battery_charging_full_rounded, '${v.batteryCapacityKwh.toStringAsFixed(1)} kWh'),
                _buildSpecDivider(),
                _buildSpecItem(Icons.speed_rounded, 'Max ${v.maxChargeRateKw.toStringAsFixed(0)} kW'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Radius Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Search Radius:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [10.0, 25.0, 50.0, 100.0].map((r) {
                        final isSel = _radiusKm == r;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('${r.toInt()} km'),
                            selected: isSel,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceContainerHigh,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? AppColors.onPrimary : AppColors.onSurface,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() => _radiusKm = r);
                                _fetchCompatibleStations();
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.surfaceContainerHigh),

          // Content List
          Expanded(
            child: _buildStationContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStationContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Scoring nearby stations with the Compatibility Agent...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Could not load stations',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                onPressed: _fetchCompatibleStations,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_stations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off_rounded, size: 48, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Text(
                'No Compatible Stations in ${_radiusKm.toInt()} km',
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'No charging stations with ${widget.vehicle.connector.displayName} sockets were found within the selected radius.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerHigh,
                  foregroundColor: AppColors.primary,
                ),
                onPressed: () {
                  setState(() => _radiusKm = 100.0);
                  _fetchCompatibleStations();
                },
                icon: const Icon(Icons.expand_rounded),
                label: const Text('Expand Radius to 100 km'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: _stations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final st = _stations[index];
        final compatibleChargers = st.chargers.where((c) => c.isCompatible).toList();
        final bestCharger = compatibleChargers.isNotEmpty
            ? compatibleChargers.reduce((a, b) => a.effectiveChargingPowerKw > b.effectiveChargingPowerKw ? a : b)
            : null;

        final isFullMatch = st.compatibilityScore >= 70;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isFullMatch ? AppColors.primary.withValues(alpha: 0.4) : AppColors.surfaceContainerHigh,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name + Compatibility Score Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          st.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${st.distanceKm.toStringAsFixed(1)} km away • ${st.address}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isFullMatch ? AppColors.primary : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFullMatch ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          size: 13,
                          color: isFullMatch ? AppColors.onPrimary : AppColors.onSurface,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${st.compatibilityScore}% MATCH',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isFullMatch ? AppColors.onPrimary : AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Compatible Charging Info Box
              if (!st.isCompatible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No ${widget.vehicle.connector.shortName} socket at this station. Score ${st.compatibilityScore}/100.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                )
              else if (st.compatibilityScore > 0 && st.compatibilityScore < 70)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Partial match (${st.compatibilityScore}/100). Power or distance may not be ideal for this vehicle.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                ),
              if (bestCharger != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${bestCharger.effectiveChargingPowerKw.toStringAsFixed(0)} kW Delivery',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                '${bestCharger.identifier} (${bestCharger.connector.displayName})',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (bestCharger.estimatedChargeTimeFormatted != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              bestCharger.estimatedChargeTimeFormatted!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                            Text(
                              '10% → 80% SoC',
                              style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
      ],
    );
  }

  Widget _buildSpecDivider() {
    return Container(
      width: 1,
      height: 14,
      color: AppColors.surfaceContainerHighest,
    );
  }
}
