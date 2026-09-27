import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../stations/models/station.dart';
import '../../stations/models/charger.dart';
import '../../../core/api/reservation_api_client.dart';
import '../../../core/api/reservation_models.dart';
import '../../../core/api/vehicle_api_client.dart';
import '../../../core/api/vehicle_models.dart';

class CreateReservationScreen extends StatefulWidget {
  final Station station;

  const CreateReservationScreen({super.key, required this.station});

  @override
  State<CreateReservationScreen> createState() => _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  Charger? _selectedCharger;
  DateTime _selectedDate = DateTime.now();
  
  List<Vehicle> _myVehicles = [];
  Vehicle? _selectedVehicle;

  List<TimeSlotDto> _availableSlots = [];
  TimeSlotDto? _selectedSlot;

  bool _isLoadingVehicles = true;
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.station.chargers != null && widget.station.chargers!.isNotEmpty) {
      _selectedCharger = widget.station.chargers!.first;
    }
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final vehicles = await VehicleApiClient.instance.getMyVehicles();
      if (mounted) {
        setState(() {
          _myVehicles = vehicles;
          if (vehicles.isNotEmpty) {
            _selectedVehicle = vehicles.first;
          }
          _isLoadingVehicles = false;
        });
        _fetchAvailability();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingVehicles = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load vehicles: $e')));
      }
    }
  }

  int get _calculatedDurationMinutes {
    if (_selectedVehicle == null || _selectedCharger == null) return 60; // Default
    
    // Time = Capacity / Power (hours)
    // Power is min of what charger can supply and what vehicle can accept
    final effectivePowerKw = min(_selectedCharger!.powerKw, _selectedVehicle!.maxChargeRateKw);
    if (effectivePowerKw <= 0) return 60;

    final hours = _selectedVehicle!.batteryCapacityKwh / effectivePowerKw;
    return (hours * 60).round();
  }

  Future<void> _fetchAvailability() async {
    if (_selectedCharger == null || _selectedVehicle == null) return;

    setState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
    });

    try {
      final slots = await ReservationApiClient.instance.getAvailability(
        _selectedCharger!.id,
        _selectedDate,
        _calculatedDurationMinutes,
      );
      if (mounted) {
        setState(() {
          _availableSlots = slots;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load availability: $e')));
      }
    }
  }

  Future<void> _makeReservation() async {
    if (_selectedCharger == null || _selectedSlot == null || _selectedVehicle == null) return;

    setState(() => _isSubmitting = true);

    try {
      final request = CreateReservationRequest(
        chargerId: _selectedCharger!.id,
        vehicleId: _selectedVehicle!.id,
        startTime: _selectedSlot!.startTime,
        endTime: _selectedSlot!.endTime,
        advanceDepositAmount: 5.0, // Default deposit
      );

      await ReservationApiClient.instance.createReservation(request);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation created successfully!')),
      );
      Navigator.pop(context); // Go back to map
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to make reservation: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxAllowedDate = DateTime.now().add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        title: Text(
          'Make Reservation',
          style: GoogleFonts.inter(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoadingVehicles
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.station.name,
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.station.address,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  // Charger Selection
                  Text('1. Select Charger', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  const SizedBox(height: 8),
                  if (widget.station.chargers == null || widget.station.chargers!.isEmpty)
                    const Text('No chargers available')
                  else
                    DropdownButtonFormField<Charger>(
                      value: _selectedCharger,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppColors.surfaceContainer,
                      ),
                      items: widget.station.chargers!.map((charger) {
                        return DropdownMenuItem(
                          value: charger,
                          child: Text('${charger.identifier} (${charger.powerKw} kW)'),
                        );
                      }).toList(),
                      onChanged: (c) {
                        setState(() => _selectedCharger = c);
                        _fetchAvailability();
                      },
                    ),
                  const SizedBox(height: 24),

                  // Vehicle Selection
                  Text('2. Select Vehicle', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  const SizedBox(height: 8),
                  if (_myVehicles.isEmpty)
                    const Text('No vehicles registered. Please add a vehicle first.')
                  else
                    DropdownButtonFormField<Vehicle>(
                      value: _selectedVehicle,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppColors.surfaceContainer,
                      ),
                      items: _myVehicles.map((vehicle) {
                        return DropdownMenuItem(
                          value: vehicle,
                          child: Text('${vehicle.make} ${vehicle.model} (${vehicle.batteryCapacityKwh} kWh)'),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setState(() => _selectedVehicle = v);
                        _fetchAvailability();
                      },
                    ),
                  
                  if (_selectedVehicle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Estimated Charge Time: ${_calculatedDurationMinutes} mins',
                        style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  
                  const SizedBox(height: 24),

                  // Date Selection (Constrained to today and tomorrow)
                  Text('3. Select Date', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate.isAfter(maxAllowedDate) ? maxAllowedDate : _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: maxAllowedDate, // Only allow today and tomorrow
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                        _fetchAvailability();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('yyyy-MM-dd').format(_selectedDate), style: GoogleFonts.inter(fontSize: 16)),
                          const Icon(Icons.calendar_today, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Time Slot Selection
                  Text('4. Select Available Time', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  const SizedBox(height: 8),
                  if (_isLoadingSlots)
                    const Center(child: CircularProgressIndicator())
                  else if (_availableSlots.isEmpty)
                    const Text('No slots available for this date.')
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _availableSlots.map((slot) {
                          final isSelected = _selectedSlot == slot;
                          final timeString = '${DateFormat('HH:mm').format(slot.startTime.toLocal())} - ${DateFormat('HH:mm').format(slot.endTime.toLocal())}';
                          
                          return ChoiceChip(
                            label: Text(timeString),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedSlot = slot);
                              }
                            },
                            selectedColor: AppColors.primary,
                            labelStyle: GoogleFonts.inter(
                              color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: AppColors.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (_isSubmitting || _selectedSlot == null) ? null : _makeReservation,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Confirm Reservation', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
