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
  double? _walletBalance;

  @override
  void initState() {
    super.initState();
    if (widget.station.chargers != null && widget.station.chargers!.isNotEmpty) {
      _selectedCharger = widget.station.chargers!.first;
    }
    _loadVehicles();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final balance = await ReservationApiClient.instance.getWalletBalance();
      if (mounted) {
        setState(() => _walletBalance = balance);
      }
    } catch (_) {}
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

  Future<void> _showTopUpDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text('Reload Wallet', style: GoogleFonts.inter(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advance reservations require a \$5.00 deposit from your virtual wallet (refundable upon cancellation).',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              'Would you like to top up \$50.00 to your ChargeSync virtual wallet now?',
              style: GoogleFonts.inter(color: AppColors.onSurface, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Top Up +\$50.00'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final newBal = await ReservationApiClient.instance.topUpWallet(50.0);
        if (mounted) {
          setState(() => _walletBalance = newBal);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Wallet credited with \$50.00! New Balance: \$${newBal.toStringAsFixed(2)}'),
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Automatically retry reservation
          _makeReservation();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to top up wallet: $e')),
          );
        }
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
      if (e.toString().contains('Insufficient wallet balance') || e.toString().contains('400')) {
        _showTopUpDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to make reservation: $e')),
        );
      }
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
                      initialValue: _selectedCharger,
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
                      initialValue: _selectedVehicle,
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
                        'Estimated Charge Time: $_calculatedDurationMinutes mins',
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

                  const SizedBox(height: 24),

                  // Wallet Deposit Strip (SRS FR-3.1 & ADR-05)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_walletBalance != null && _walletBalance! < 5.0)
                            ? AppColors.error.withValues(alpha: 0.5)
                            : AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Advance Deposit: \$5.00',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Text(
                                  _walletBalance != null
                                      ? 'Wallet Balance: \$${_walletBalance!.toStringAsFixed(2)}'
                                      : 'Wallet Balance: Loading...',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: (_walletBalance != null && _walletBalance! < 5.0)
                                        ? AppColors.error
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _showTopUpDialog,
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                          label: Text(
                            '+ Top Up',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

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
