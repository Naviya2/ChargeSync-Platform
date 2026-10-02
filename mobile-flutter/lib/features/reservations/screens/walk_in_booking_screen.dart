import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/api/reservation_api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../stations/api/station_service.dart';
import '../../stations/models/charger.dart';

class WalkInBookingScreen extends StatefulWidget {
  const WalkInBookingScreen({super.key});

  @override
  State<WalkInBookingScreen> createState() => _WalkInBookingScreenState();
}

class _WalkInBookingScreenState extends State<WalkInBookingScreen> {
  final _nameController = TextEditingController();
  final _vehicleNoController = TextEditingController();
  final _batteryCapacityController = TextEditingController();
  final _durationController = TextEditingController(text: '60'); // Minutes
  List<Charger> _chargers = [];
  Map<String, String> _stationNames = {};
  String? _selectedChargerId;
  bool _isLoadingChargers = true;
  String? _chargerLoadError;
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadChargers();
    _batteryCapacityController.addListener(_calculateDuration);
  }

  void _calculateDuration() {
    if (_selectedChargerId == null) return;
    final capacityText = _batteryCapacityController.text.trim();
    if (capacityText.isEmpty) return;
    
    final capacity = double.tryParse(capacityText);
    if (capacity == null || capacity <= 0) return;

    final charger = _chargers.firstWhere((c) => c.id == _selectedChargerId);
    final powerKw = charger.powerKw > 0 ? charger.powerKw : 7.0; // fallback

    final hours = capacity / powerKw;
    final mins = (hours * 60).round();
    _durationController.text = mins.toString();
  }

  Future<void> _loadChargers() async {
    setState(() {
      _isLoadingChargers = true;
      _chargerLoadError = null;
    });

    try {
      final stations = await StationService.instance.getMyStations();
      final res = await ReservationApiClient.instance.getMyReservations();
      
      final now = DateTime.now();
      final activeReservations = res.items.where((r) => r.status != 'Cancelled' && r.status != 'Completed');
      final busyChargerIds = activeReservations
          .where((r) => r.startTime.isBefore(now.add(const Duration(minutes: 60))) && r.endTime.isAfter(now))
          .map((r) => r.chargerId)
          .toSet();

      final chargers = stations
          .expand((station) => station.chargers ?? const <Charger>[])
          .where((charger) => charger.status.toLowerCase() == 'available' && !busyChargerIds.contains(charger.id))
          .toList();

      if (!mounted) return;
      setState(() {
        _chargers = chargers;
        _stationNames = {
          for (final station in stations) station.id: station.name,
        };
        _selectedChargerId = chargers.any((c) => c.id == _selectedChargerId)
            ? _selectedChargerId
            : null;
        _isLoadingChargers = false;
      });
      _calculateDuration();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chargerLoadError = 'Could not load your chargers.';
        _isLoadingChargers = false;
      });
    }
  }

  Future<void> _admitWalkIn() async {
    final chargerId = _selectedChargerId;
    final durationMins = int.tryParse(_durationController.text.trim()) ?? 60;

    if (chargerId == null) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final now = DateTime.now();
      final endTime = now.add(Duration(minutes: durationMins));

      await ReservationApiClient.instance.createWalkIn(chargerId, now, endTime);

      setState(() {
        _isSuccess = true;
        final charger = _chargers.firstWhere((item) => item.id == chargerId);
        _message =
            'Walk-In admitted! Charger ${charger.identifier} is locked and session started.';
        _isLoading = false;
      });
      await _loadChargers();
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = 'Failed to admit Walk-in: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _vehicleNoController.dispose();
    _batteryCapacityController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, topPadding + 80, 24, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Unregistered Customer',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Admitting a walk-in will instantly lock the charger and start a charging session without requiring a driver account.',
            style: GoogleFonts.inter(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoadingChargers)
            const Center(child: CircularProgressIndicator())
          else if (_chargerLoadError != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _chargerLoadError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                IconButton(
                  onPressed: _loadChargers,
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                ),
              ],
            )
          else if (_chargers.isEmpty)
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'No available chargers found. Add a charger from the Stations tab first.',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ),
                IconButton(
                  onPressed: _loadChargers,
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                ),
              ],
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedChargerId,
              isExpanded: true,
              dropdownColor: AppColors.surfaceContainer,
              decoration: InputDecoration(
                labelText: 'Available Charger',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.surfaceContainer,
              ),
              items: _chargers.map((charger) {
                final stationName =
                    _stationNames[charger.stationId] ?? 'Station';
                return DropdownMenuItem(
                  value: charger.id,
                  child: Text(
                    '$stationName • ${charger.identifier} • ${charger.bayLabel}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedChargerId = value);
                _calculateDuration();
              },
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Customer Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.surfaceContainer,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _vehicleNoController,
            decoration: InputDecoration(
              labelText: 'Vehicle Number',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.surfaceContainer,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _batteryCapacityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Battery Capacity (kWh)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.surfaceContainer,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Estimated Duration (Minutes)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.surfaceContainer,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading || _selectedChargerId == null
                ? null
                : _admitWalkIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Admit & Lock Charger',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isSuccess
                    ? AppColors.primaryContainer
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _message!,
                style: GoogleFonts.inter(
                  color: _isSuccess ? AppColors.onPrimaryContainer : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
