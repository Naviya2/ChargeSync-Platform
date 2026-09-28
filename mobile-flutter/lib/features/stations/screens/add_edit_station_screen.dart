import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../api/station_service.dart';
import '../models/station.dart';

class AddEditStationScreen extends StatefulWidget {
  final Station? station;
  const AddEditStationScreen({super.key, this.station});

  @override
  State<AddEditStationScreen> createState() => _AddEditStationScreenState();
}

class _AddEditStationScreenState extends State<AddEditStationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  Timer? _debounce;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _addressController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.station != null) {
      _nameController.text = widget.station!.name;
      _addressController.text = widget.station!.address;
      _selectedLocation = LatLng(widget.station!.latitude, widget.station!.longitude);
    } else {
      _getLocation();
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    
    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        final loc = LatLng(position.latitude, position.longitude);
        setState(() {
          _selectedLocation = loc;
          _mapController.move(loc, 15.0);
        });
        _fetchAddress(loc);
      }
    } catch (e) {
      // Ignore location error
    }
  }

  void _onLocationChanged(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      _fetchAddress(location);
    });
  }

  Future<void> _fetchAddress(LatLng location) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}');
      final response = await http.get(url, headers: {'User-Agent': 'com.chargesync.app'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['display_name'] != null) {
          if (mounted) {
            setState(() {
              _addressController.text = data['display_name'];
            });
          }
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final request = {
      'name': _nameController.text,
      'address': _addressController.text,
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
    };

    try {
      if (widget.station == null) {
        await StationService.instance.registerStation(request);
      } else {
        await StationService.instance.updateStation(widget.station!.id, request);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(widget.station == null ? 'Register Station' : 'Edit Station', style: const TextStyle(color: AppColors.onSurface)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Station Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Location', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
              ),
              const SizedBox(height: 8),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLocation ?? const LatLng(6.9271, 79.8612),
                      initialZoom: 15.0,
                      onPositionChanged: (position, hasGesture) {
                        if (hasGesture && position.center != null) {
                          _onLocationChanged(position.center!);
                        }
                      },
                      onTap: (tapPosition, point) {
                        _mapController.move(point, _mapController.camera.zoom);
                        _onLocationChanged(point);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.chargesync.app',
                      ),
                      if (_selectedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Drag the map or tap to place the station marker',
                style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.station == null ? 'Register' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
