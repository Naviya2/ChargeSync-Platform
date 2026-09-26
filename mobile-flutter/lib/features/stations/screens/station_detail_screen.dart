import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../api/station_service.dart';
import '../models/station.dart';
import 'add_charger_screen.dart';
import 'add_edit_station_screen.dart';

class StationDetailScreen extends StatefulWidget {
  final String stationId;
  const StationDetailScreen({super.key, required this.stationId});

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  final StationService _stationService = StationService.instance;
  Station? _station;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStation();
  }

  Future<void> _loadStation() async {
    setState(() => _isLoading = true);
    try {
      final station = await _stationService.getStationById(widget.stationId);
      setState(() {
        _station = station;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading station: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_station == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: Text('Station not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(_station!.name, style: const TextStyle(color: AppColors.onSurface)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddChargerScreen(stationId: _station!.id),
            ),
          );
          if (result == true) {
            _loadStation();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: ${_station!.address}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Coordinates: ${_station!.latitude}, ${_station!.longitude}'),
            const SizedBox(height: 8),
            Text('Status: ${_station!.status}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Station'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerHigh,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditStationScreen(station: _station),
                    ),
                  );
                  if (result == true) {
                    _loadStation();
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chargers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_station!.chargers == null || _station!.chargers!.isEmpty)
              const Text('No chargers added yet.')
            else
              ..._station!.chargers!.map((charger) => Card(
                    color: AppColors.surfaceContainer,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(charger.identifier, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Bay: ${charger.bayLabel} | Power: ${charger.powerKw} kW | Tariff: \$${charger.tariff}'),
                      trailing: Text('Status: ${charger.status}'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
