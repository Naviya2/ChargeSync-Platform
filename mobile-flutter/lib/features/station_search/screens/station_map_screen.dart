import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
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
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  String _distance = '';
  String _duration = '';
  bool _isLoading = true;
  bool _isMapReady = false;

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
    _loadStations();
    await _getLocation();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable GPS to see nearby stations and calculate routes'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Step 1: Immediately use last known position if available for instant map centering
    try {
      Position? lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() {
          _currentLocation = LatLng(lastPos.latitude, lastPos.longitude);
        });
        if (_isMapReady) {
          _mapController.move(_currentLocation!, 13.5);
        }
      }
    } catch (_) {}

    // Step 2: Query high accuracy GPS with timeout
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
      
      if (!mounted) return;
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      
      if (_isMapReady) {
        _mapController.move(_currentLocation!, 13.5);
      }
    } catch (e) {
      // Step 3: Fast fallback to medium accuracy (network/Wi-Fi)
      try {
        Position fallbackPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(fallbackPos.latitude, fallbackPos.longitude);
          });
          if (_isMapReady) {
            _mapController.move(_currentLocation!, 13.5);
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _loadStations() async {
    try {
      final stations = await StationService.instance.getAllStations();
      if (mounted) {
        setState(() {
          _stations = stations;
        });
      }
    } catch (e) {
      // Ignore if unauth
    }
  }

  void _onStationTapped(Station station) {
    setState(() {
      _selectedStation = station;
    });

    // Center map on selected station
    _mapController.move(
      LatLng(station.latitude, station.longitude),
      _mapController.camera.zoom < 14.0 ? 14.5 : _mapController.camera.zoom,
    );

    // If location is available, calculate route
    if (_currentLocation != null) {
      _getRouteTo(station);
    } else {
      setState(() {
        _routePoints = [];
        _distance = 'Location required';
        _duration = '';
      });
    }
  }

  Future<void> _getRouteTo(Station station) async {
    if (_currentLocation == null) {
      setState(() {
        _selectedStation = station;
        _routePoints = [];
        _distance = 'Location required';
        _duration = '';
      });
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
            !s.chargers!.any((c) => c.status == 'Available')) {
          return false;
        }
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
              onMapReady: () {
                _isMapReady = true;
                if (_currentLocation != null) {
                  _mapController.move(_currentLocation!, 13.5);
                }
              },
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
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ..._filteredStations.map(
                    (s) {
                      final isSelected = _selectedStation?.id == s.id;
                      return Marker(
                        point: LatLng(s.latitude, s.longitude),
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _onStationTapped(s),
                          child: Center(
                            child: Container(
                              width: isSelected ? 46 : 38,
                              height: isSelected ? 46 : 38,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : AppColors.primary,
                                  width: isSelected ? 2.5 : 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isSelected ? AppColors.primary : Colors.black)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.ev_station_rounded,
                                color: isSelected ? AppColors.onPrimary : AppColors.primary,
                                size: isSelected ? 24 : 20,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

          // Loading indicator below app bar
          if (_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 130,
              left: 0,
              right: 0,
              child: const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: AppColors.primary,
                minHeight: 3,
              ),
            ),

          // Floating back button (only shown when route can be popped)
          if (Navigator.of(context).canPop())
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

          // My Location FAB (above bottom navigation bar and station details card)
          Positioned(
            bottom: _selectedStation != null ? 430 : 96,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'my_location_fab',
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              elevation: 4,
              onPressed: () {
                if (_currentLocation != null && _isMapReady) {
                  _mapController.move(_currentLocation!, 15.0);
                }
                _getLocation();
              },
              child: const Icon(Icons.my_location),
            ),
          ),

          // Station Details Bottom Card
          if (_selectedStation != null)
            Positioned(
              bottom: 96,
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
                              _routePoints = [];
                              _distance = '';
                              _duration = '';
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
