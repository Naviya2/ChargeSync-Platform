import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../api/station_service.dart';
import '../models/station.dart';
import 'add_edit_station_screen.dart';
import 'station_detail_screen.dart';

class StationManagementScreen extends StatefulWidget {
  const StationManagementScreen({super.key});

  @override
  State<StationManagementScreen> createState() =>
      _StationManagementScreenState();
}

class _StationManagementScreenState extends State<StationManagementScreen> {
  final StationService _stationService = StationService.instance;
  List<Station> _stations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _isLoading = true);
    try {
      final stations = await _stationService.getMyStations();
      setState(() {
        _stations = stations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading stations: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(16, topPadding + 80, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Stations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _loadStations,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddEditStationScreen(),
                        ),
                      );
                      if (result == true) {
                        _loadStations();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _stations.isEmpty
                ? const Center(child: Text('No stations found. Add one!'))
                : ListView.builder(
                    itemCount: _stations.length,
                    itemBuilder: (context, index) {
                      final station = _stations[index];
                      return Card(
                        color: AppColors.surfaceContainer,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            station.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(station.address),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.onSurfaceVariant,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StationDetailScreen(stationId: station.id),
                              ),
                            ).then((_) => _loadStations());
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
