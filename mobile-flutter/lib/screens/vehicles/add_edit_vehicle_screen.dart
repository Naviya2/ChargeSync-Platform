import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/vehicle_models.dart';
import '../../core/api/vehicle_service.dart';
import '../../core/theme/app_colors.dart';

class AddEditVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const AddEditVehicleScreen({super.key, this.vehicle});

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _licensePlateController;

  late ConnectorType _selectedConnector;
  late double _batteryCapacity;
  late double _maxChargeRate;
  bool _isSubmitting = false;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController(text: widget.vehicle?.make ?? '');
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _licensePlateController = TextEditingController(text: widget.vehicle?.licensePlate ?? '');
    _selectedConnector = widget.vehicle?.connector ?? ConnectorType.ccs2;
    _batteryCapacity = widget.vehicle?.batteryCapacityKwh ?? 75.0;
    _maxChargeRate = widget.vehicle?.maxChargeRateKw ?? 150.0;
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final request = VehicleRequest(
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        licensePlate: _licensePlateController.text.trim().isEmpty ? null : _licensePlateController.text.trim(),
        connector: _selectedConnector,
        batteryCapacityKwh: _batteryCapacity,
        maxChargeRateKw: _maxChargeRate,
      );

      if (_isEditing) {
        await VehicleService.instance.updateVehicle(widget.vehicle!.id, request);
      } else {
        await VehicleService.instance.addVehicle(request);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Vehicle updated successfully!' : 'Vehicle registered successfully!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text(
          _isEditing ? 'Edit Vehicle' : 'Register New Vehicle',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car_filled_rounded, color: AppColors.primary, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Update Vehicle Info' : 'EV Vehicle Details',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Connector type and max charge rate enable compatibility scoring and estimated charge times.',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Make & Model Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _makeController,
                      label: 'Make / Brand',
                      hint: 'e.g. Tesla, Hyundai',
                      icon: Icons.business_rounded,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Make is required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _modelController,
                      label: 'Model',
                      hint: 'e.g. Model Y, Ioniq 5',
                      icon: Icons.car_rental_rounded,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Model is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // License Plate
              _buildTextField(
                controller: _licensePlateController,
                label: 'License Plate (Optional)',
                hint: 'e.g. CAB-4921',
                icon: Icons.badge_rounded,
              ),
              const SizedBox(height: 24),

              // Connector Type Selector
              Text(
                'Connector Type',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ConnectorType.values.map((conn) {
                  final isSelected = _selectedConnector == conn;
                  return ChoiceChip(
                    label: Text(conn.displayName),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedConnector = conn);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Battery Capacity Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Battery Capacity',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_batteryCapacity.toStringAsFixed(1)} kWh',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _batteryCapacity,
                min: 10,
                max: 200,
                divisions: 190,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.surfaceContainerHigh,
                onChanged: (val) => setState(() => _batteryCapacity = val),
              ),
              const SizedBox(height: 20),

              // Max Charge Rate Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Max Charge Rate',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_maxChargeRate.toStringAsFixed(0)} kW',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _maxChargeRate,
                min: 3,
                max: 350,
                divisions: 347,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.surfaceContainerHigh,
                onChanged: (val) => setState(() => _maxChargeRate = val),
              ),
              const SizedBox(height: 36),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSubmitting ? null : _saveVehicle,
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(_isEditing ? Icons.save_rounded : Icons.add_circle_outline_rounded),
                  label: Text(
                    _isSubmitting
                        ? 'Saving...'
                        : (_isEditing ? 'Update Vehicle' : 'Register Vehicle'),
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: GoogleFonts.inter(color: AppColors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant),
        filled: true,
        fillColor: AppColors.surfaceContainerHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
