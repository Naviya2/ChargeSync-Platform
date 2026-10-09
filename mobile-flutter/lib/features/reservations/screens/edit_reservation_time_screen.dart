import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/reservation_api_client.dart';
import '../../../core/api/reservation_models.dart';

class EditReservationTimeScreen extends StatefulWidget {
  final ReservationDto reservation;

  const EditReservationTimeScreen({super.key, required this.reservation});

  @override
  State<EditReservationTimeScreen> createState() =>
      _EditReservationTimeScreenState();
}

class _EditReservationTimeScreenState extends State<EditReservationTimeScreen> {
  late DateTime _selectedDate;
  List<TimeSlotDto> _availableSlots = [];
  TimeSlotDto? _selectedSlot;

  bool _isLoadingSlots = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.reservation.startTime;
    _fetchAvailability();
  }

  int get _calculatedDurationMinutes {
    return widget.reservation.endTime.difference(widget.reservation.startTime).inMinutes;
  }

  Future<void> _fetchAvailability() async {
    setState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
    });

    try {
      final slots = await ReservationApiClient.instance.getAvailability(
        widget.reservation.chargerId,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load availability: $e')),
        );
      }
    }
  }

  Future<void> _updateReservation() async {
    if (_isSubmitting || _selectedSlot == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final request = UpdateReservationRequest(
        startTime: _selectedSlot!.startTime,
        endTime: _selectedSlot!.endTime,
      );

      await ReservationApiClient.instance.updateReservation(
        widget.reservation.id,
        request,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Reservation time updated successfully!'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true); // Return true to signal refresh
    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString();
      errorMessage = errorMessage.replaceAll(RegExp(r'ApiException.*:\s*'), '');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Failed'),
          content: Text(errorMessage),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxAllowedDate = DateTime.now().add(const Duration(days: 7));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        title: Text(
          'Edit Time',
          style: GoogleFonts.inter(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.reservation.stationName,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // Date Selection
            Text('1. Select Date', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate.isAfter(maxAllowedDate) ? maxAllowedDate : _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: maxAllowedDate,
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
            Text('2. Select Available Time', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
            const SizedBox(height: 8),
            if (_isLoadingSlots)
              const Center(child: CircularProgressIndicator())
            else if (_availableSlots.isEmpty)
              const Text('No slots available for this date at this time.')
            else
              DropdownButtonFormField<TimeSlotDto>(
                value: _selectedSlot,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  hintText: 'Choose a Time Slot',
                ),
                items: _availableSlots.map((slot) {
                  final timeString = '${DateFormat('HH:mm').format(slot.startTime.toLocal())} - ${DateFormat('HH:mm').format(slot.endTime.toLocal())}';
                  return DropdownMenuItem(
                    value: slot,
                    child: Text(timeString),
                  );
                }).toList(),
                onChanged: (slot) {
                  if (slot != null) {
                    setState(() => _selectedSlot = slot);
                  }
                },
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (_isSubmitting || _selectedSlot == null)
                    ? null
                    : _updateReservation,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Update Time',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
