import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/api/planning_api_client.dart';
import '../../../core/api/planning_models.dart';
import '../../../core/api/station_api_client.dart';
import '../../../core/theme/app_colors.dart';
import 'create_reservation_screen.dart';
import '../../stations/models/station.dart';
import '../../stations/models/charger.dart';

class AiPlanningScreen extends StatefulWidget {
  const AiPlanningScreen({super.key});

  @override
  State<AiPlanningScreen> createState() => _AiPlanningScreenState();
}

class _AiPlanningScreenState extends State<AiPlanningScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double _maxDistance = 10.0;
  String _pricePreference = 'Balanced';

  bool _isLoading = false;
  PlanningResponse? _planningResponse;
  String? _error;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _planningResponse = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      double? currentLat;
      double? currentLon;

      if (serviceEnabled && (permission == LocationPermission.whileInUse || permission == LocationPermission.always)) {
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          currentLat = position.latitude;
          currentLon = position.longitude;
        } catch (_) {
          // ignore timeout or failure to get location
        }
      }

      final deadline = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final req = PlanningRequest(
        deadline: deadline,
        maxDistanceKm: _maxDistance,
        pricePreference: _pricePreference,
        currentLat: currentLat,
        currentLon: currentLon,
      );

      final res = await PlanningApiClient.instance.generateChargingPlan(req);
      setState(() {
        _planningResponse = res;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        title: Text(
          'AI Route Planner',
          style: GoogleFonts.inter(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Your Constraints',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
            ),
            const SizedBox(height: 16),
            // Deadline
            ListTile(
              tileColor: AppColors.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.calendar_today, color: AppColors.primary),
              title: const Text('Target Arrival Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
              onTap: _selectDate,
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: AppColors.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.access_time, color: AppColors.primary),
              title: const Text('Target Arrival Time'),
              subtitle: Text(_selectedTime.format(context)),
              onTap: _selectTime,
            ),
            const SizedBox(height: 16),
            // Distance
            Text('Max Search Radius (${_maxDistance.toInt()} km)', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            Slider(
              value: _maxDistance,
              min: 5,
              max: 50,
              divisions: 9,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _maxDistance = val),
            ),
            const SizedBox(height: 8),
            // Price Preference
            Text('Optimization Goal', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Budget', label: Text('Budget')),
                ButtonSegment(value: 'Balanced', label: Text('Balanced')),
                ButtonSegment(value: 'Speed', label: Text('Speed')),
              ],
              selected: {_pricePreference},
              onSelectionChanged: (set) => setState(() => _pricePreference = set.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return AppColors.surfaceContainer;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.onPrimary;
                  }
                  return AppColors.onSurface;
                }),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generatePlan,
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome),
                label: Text(
                  _isLoading ? 'Analyzing options...' : 'Generate AI Plan',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (_planningResponse != null) ...[
              const SizedBox(height: 24),
              if (_planningResponse!.rankedItineraries.isEmpty) ...[
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.search_off_rounded, size: 64, color: AppColors.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('No recommendations available right now', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _planningResponse!.agentReasoning,
                          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text('Agent Recommendation', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _planningResponse!.agentReasoning,
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._planningResponse!.rankedItineraries.map((itinerary) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                itinerary.stationName,
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Score: ${itinerary.matchScore}',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.onPrimaryContainer),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.flash_on, size: 16, color: AppColors.secondary),
                            const SizedBox(width: 4),
                            Text('${itinerary.estimatedChargeDurationMins} mins charge time', style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.attach_money, size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text('LKR ${itinerary.costEstimate.toStringAsFixed(2)} estimated cost', style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                        if (itinerary.waitlistOverrideRequired) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Requires Waitlist Override (Admin Approval)',
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              try {
                                // Fetch real station to avoid mock data
                                final allStations = await StationApiClient.instance.getAllStations();
                                final realStation = allStations.firstWhere(
                                  (s) => s.id == itinerary.stationId,
                                  orElse: () => throw Exception('Station not found in active directory'),
                                );

                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CreateReservationScreen(
                                        station: Station(
                                          id: realStation.id,
                                          name: realStation.name,
                                          address: realStation.address,
                                          latitude: realStation.latitude,
                                          longitude: realStation.longitude,
                                          ownerId: realStation.ownerId,
                                          status: realStation.status.name,
                                          chargers: realStation.chargers.map<Charger>((c) => Charger(
                                            id: c.id,
                                            stationId: c.stationId,
                                            identifier: c.identifier,
                                            connector: c.connector.name,
                                            powerKw: c.powerKw,
                                            tariff: c.tariff,
                                            status: c.status.name,
                                            bayLabel: c.bayLabel,
                                          )).toList(),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to load station details: $e')),
                                  );
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Select this Plan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
