import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/api/vehicle_models.dart';
import '../../../core/api/vehicle_service.dart';
import '../../../screens/vehicles/compatible_stations_sheet.dart';
import '../../stations/api/station_service.dart';
import '../../stations/models/station.dart';
import '../api/routing_service.dart';
import '../../reservations/screens/create_reservation_screen.dart';
import '../../../screens/stations/widgets/stations_app_bar.dart';

class StationMapScreen extends StatefulWidget {
  const StationMapScreen({super.key});

  @override
  State<StationMapScreen> createState() => _StationMapScreenState();
}

class _StationMapScreenState extends State<StationMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _showClear = false;
  final Set<String> _activeFilters = {'compatible', 'available'};

  List<Station> _stations = [];
  Station? _selectedStation;
  CompatibilityEvaluation? _compatibility;
  bool _compatibilityLoading = false;
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  String _distance = '';
  String _duration = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initMap() async {
    await VehicleService.instance.fetchVehicles();
    await _getLocation();
    await _loadStations();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentLocation!, 13.0);
    } catch (e) {
      // Handle location error gracefully
    }
  }

  Future<void> _loadStations() async {
    try {
      final activeVehicle = VehicleService.instance.activeVehicle;
      List<Station> stations = [];
      if (_currentLocation != null) {
        stations = await StationService.instance.searchStations(
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          radiusKm: 25,
          connectorName: activeVehicle?.connector.toBackendString(),
        );
      }
      if (stations.isEmpty) {
        stations = await StationService.instance.getAllStations();
      }
      setState(() {
        _stations = stations;
      });
    } catch (e) {
      // Ignore if unauth
    }
  }

  Future<void> _evaluateCompatibility(Station station) async {
    final activeVehicle = VehicleService.instance.activeVehicle;
    if (activeVehicle == null) {
      setState(() {
        _compatibility = null;
        _compatibilityLoading = false;
      });
      return;
    }

    setState(() {
      _compatibility = null;
      _compatibilityLoading = true;
    });

    final evaluation = await StationService.instance.getCompatibility(
      station.id,
      activeVehicle.id,
      _currentLocation?.latitude,
      _currentLocation?.longitude,
    );

    if (!mounted || _selectedStation?.id != station.id) return;
    setState(() {
      _compatibility = evaluation;
      _compatibilityLoading = false;
    });
  }

  Future<void> _getRouteTo(Station station) async {
    setState(() {
      _selectedStation = station;
      _compatibility = null;
      _compatibilityLoading = VehicleService.instance.activeVehicle != null;
    });
    unawaited(_evaluateCompatibility(station));

    if (_currentLocation == null) {
      return;
    }

    setState(() {
      _selectedStation = station;
      _routePoints = [];
      _distance = 'Calculating...';
      _duration = '';
    });

    try {
      final res = await RoutingService.instance.getDirections(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        station.latitude,
        station.longitude,
      );

      if (res['geometryCoordinates'] != null) {
        final coords = List<List<dynamic>>.from(res['geometryCoordinates']);
        setState(() {
          _routePoints = coords
              .map((c) => LatLng(c[1] as double, c[0] as double))
              .toList();
          _distance =
              '${((res['distanceMeters'] as num) / 1000).toStringAsFixed(1)} km';
          _duration =
              '${((res['durationSeconds'] as num) / 60).toStringAsFixed(0)} min';
        });

        // Fit bounds
        final bounds = LatLngBounds.fromPoints([
          _currentLocation!,
          LatLng(station.latitude, station.longitude),
          ..._routePoints,
        ]);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
        );
      }
    } catch (e) {
      setState(() {
        _distance = 'Routing failed';
      });
    }
  }

  Future<void> _launchGoogleMaps(Station station) async {
    final url = Uri.parse(
      'google.navigation:q=${station.latitude},${station.longitude}',
    );
    final webUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${station.latitude},${station.longitude}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(webUrl, mode: LaunchMode.inAppBrowserView);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map navigation.')),
        );
      }
    }
  }

  List<Station> get _filteredStations {
    final query = _searchController.text.trim().toLowerCase();

    return _stations.where((s) {
      if (query.isNotEmpty) {
        if (!s.name.toLowerCase().contains(query) &&
            !s.address.toLowerCase().contains(query)) {
          return false;
        }
      }

      if (_activeFilters.contains('available')) {
        if (s.chargers == null ||
            !s.chargers!.any((c) => c.status == 'Available'))
          return false;
      }

      if (_activeFilters.contains('compatible')) {
        final activeVehicle = VehicleService.instance.activeVehicle;
        if (activeVehicle != null) {
          if (s.chargers == null) return false;
          final hasCompatible = s.chargers!.any((c) {
            final connStr = c.connector
                .toUpperCase()
                .replaceAll(' ', '')
                .replaceAll('-', '');
            final vehConn = activeVehicle.connector
                .toBackendString()
                .toUpperCase();
            return connStr.contains(vehConn) || vehConn.contains(connStr);
          });
          if (!hasCompatible) return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? const LatLng(6.9271, 79.8612),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.chargesync.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 4.0,
                    color: AppColors.primary,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.my_location,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                  ..._filteredStations.map(
                    (s) => Marker(
                      point: LatLng(s.latitude, s.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _getRouteTo(s),
                        child: Icon(
                          Icons.location_on,
                          color: _selectedStation?.id == s.id
                              ? AppColors.primary
                              : AppColors.error,
                          size: _selectedStation?.id == s.id ? 40 : 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // App Bar Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: StationsAppBar(
              searchController: _searchController,
              showClear: _showClear,
              onSearchChanged: (val) {
                setState(() => _showClear = val.isNotEmpty);
                if (val.trim().isNotEmpty) {
                  final stations = _filteredStations;
                  if (stations.isNotEmpty) {
                    if (stations.length == 1) {
                      _mapController.move(
                        LatLng(stations.first.latitude, stations.first.longitude), 
                        15.0
                      );
                    } else {
                      final bounds = LatLngBounds.fromPoints(
                        stations
                            .map((s) => LatLng(s.latitude, s.longitude))
                            .toList(),
                      );
                      
                      if (bounds.southWest == bounds.northEast) {
                        _mapController.move(
                          LatLng(stations.first.latitude, stations.first.longitude), 
                          15.0
                        );
                      } else {
                        _mapController.fitCamera(
                          CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(50),
                            maxZoom: 15.0,
                          ),
                        );
                      }
                    }
                  }
                }
              },
              onClearSearch: () {
                _searchController.clear();
                setState(() => _showClear = false);
              },
              activeFilters: _activeFilters,
              onFilterToggle: (filter) {
                setState(() {
                  if (_activeFilters.contains(filter)) {
                    _activeFilters.remove(filter);
                  } else {
                    _activeFilters.add(filter);
                  }
                });
              },
            ),
          ),

          // Floating back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.onSurface,
                  size: 20,
                ),
              ),
            ),
          ),

          // Station Details Bottom Card
          if (_selectedStation != null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedStation!.name,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedStation = null;
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                            child: Icon(
                              Icons.close_rounded,
                              color: AppColors.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedStation!.address,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.route,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_distance • $_duration',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    _buildCompatibilityBanner(_selectedStation!),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceContainerHigh,
                              foregroundColor: AppColors.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () =>
                                _launchGoogleMaps(_selectedStation!),
                            icon: const Icon(Icons.directions),
                            label: Text(
                              'Directions',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              if (_selectedStation?.chargers != null &&
                                  _selectedStation!.chargers!.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CreateReservationScreen(
                                          station: _selectedStation!,
                                        ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No available chargers at this station',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.event_available),
                            label: Text(
                              'Reserve',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityBanner(Station station) {
    final activeVehicle = VehicleService.instance.activeVehicle;
    if (activeVehicle == null) {
      return const SizedBox.shrink();
    }

    if (_compatibilityLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Checking AI compatibility for ${activeVehicle.fullName}...',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
              ),
            ),
          ],
        ),
      );
    }

    final evaluation = _compatibility;
    if (evaluation != null) {
      final compatible = evaluation.isCompatible;
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (compatible ? AppColors.primaryContainer : AppColors.error).withValues(alpha: compatible ? 0.35 : 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (compatible ? AppColors.primary : AppColors.error).withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  compatible ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  color: compatible ? AppColors.primary : AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    compatible
                        ? '${evaluation.compatibilityScore}% match with ${activeVehicle.fullName}'
                            '${evaluation.estimatedChargeTimeFormatted != null ? ' • ${evaluation.estimatedChargeTimeFormatted}' : ''}'
                        : 'Incompatible with ${activeVehicle.fullName} (${activeVehicle.connector.shortName})',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: compatible ? AppColors.primary : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            if (evaluation.aiInsight != null && evaluation.aiInsight!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                evaluation.aiInsight!,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
            ],
            if (evaluation.suggestedAlternatives.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Alternatives: ${evaluation.suggestedAlternatives.take(2).map((a) => '${a.name} (${a.compatibilityScore}%)').join(' · ')}',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurface),
              ),
            ],
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => CompatibleStationsSheet.show(context, activeVehicle),
              child: Text(
                compatible ? 'View nearby scored stations →' : 'Tap to view compatible alternatives nearby →',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final chargers = station.chargers ?? [];
    final matchingChargers = chargers.where((c) {
      final connStr = c.connector
          .toUpperCase()
          .replaceAll(' ', '')
          .replaceAll('-', '');
      final vehConn = activeVehicle.connector.toBackendString().toUpperCase();
      return connStr.contains(vehConn) || vehConn.contains(connStr);
    }).toList();

    if (matchingChargers.isNotEmpty) {
      final bestPower = matchingChargers
          .map((c) => c.powerKw)
          .reduce((a, b) => a > b ? a : b);
      final effectiveKw = bestPower < activeVehicle.maxChargeRateKw
          ? bestPower
          : activeVehicle.maxChargeRateKw;
      final mins =
          (activeVehicle.batteryCapacityKwh *
                  0.70 /
                  (effectiveKw > 0 ? effectiveKw : 1) *
                  60)
              .round();

      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Compatible with ${activeVehicle.fullName} (${activeVehicle.connector.shortName}) • ~${mins}m (10-80%)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Incompatible with ${activeVehicle.fullName} (${activeVehicle.connector.shortName})',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () =>
                        CompatibleStationsSheet.show(context, activeVehicle),
                    child: Text(
                      'Tap to view compatible alternatives nearby →',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
