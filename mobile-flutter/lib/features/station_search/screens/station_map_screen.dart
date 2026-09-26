import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
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
      // Fetch all stations instead of just my stations so drivers can see them
      final stations = await StationService.instance.getAllStations();
      setState(() {
        _stations = stations;
      });
    } catch (e) {
      // Ignore if unauth
    }
  }

  Future<void> _getRouteTo(Station station) async {
    if (_currentLocation == null) return;
    
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
          _routePoints = coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
          _distance = '${((res['distanceMeters'] as num) / 1000).toStringAsFixed(1)} km';
          _duration = '${((res['durationSeconds'] as num) / 60).toStringAsFixed(0)} min';
        });
        
        // Fit bounds
        final bounds = LatLngBounds.fromPoints([_currentLocation!, LatLng(station.latitude, station.longitude), ..._routePoints]);
        _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
      }
    } catch (e) {
      setState(() {
        _distance = 'Routing failed';
      });
    }
  }

  Future<void> _launchGoogleMaps(Station station) async {
    final url = Uri.parse('google.navigation:q=${station.latitude},${station.longitude}');
    final webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${station.latitude},${station.longitude}');

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
                  ..._stations.map(
                    (s) => Marker(
                      point: LatLng(s.latitude, s.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _getRouteTo(s),
                        child: Icon(
                          Icons.location_on,
                          color: _selectedStation?.id == s.id ? AppColors.primary : AppColors.error,
                          size: _selectedStation?.id == s.id ? 40 : 30,
                        ),
                      ),
                    ),
                  )
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
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedStation!.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
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
                        const Icon(Icons.route, color: AppColors.primary, size: 20),
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
                    const SizedBox(height: 16),
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
                            onPressed: () => _launchGoogleMaps(_selectedStation!),
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
                              if (_selectedStation?.chargers != null && _selectedStation!.chargers!.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateReservationScreen(station: _selectedStation!),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No available chargers at this station')),
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
}
