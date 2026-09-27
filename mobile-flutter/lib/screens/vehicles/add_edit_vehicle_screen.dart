import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/vehicle_models.dart';
import '../../core/api/vehicle_service.dart';
import '../../core/theme/app_colors.dart';

/// Predefined popular EV models for quick 1-tap specification filling.
class _EvPreset {
  final String make;
  final String model;
  final ConnectorType connector;
  final double batteryCapacity;
  final double maxChargeRate;

  const _EvPreset({
    required this.make,
    required this.model,
    required this.connector,
    required this.batteryCapacity,
    required this.maxChargeRate,
  });
}

const _popularPresets = [
  _EvPreset(make: 'Tesla', model: 'Model 3', connector: ConnectorType.nacs, batteryCapacity: 75.0, maxChargeRate: 170.0),
  _EvPreset(make: 'Tesla', model: 'Model Y', connector: ConnectorType.nacs, batteryCapacity: 81.0, maxChargeRate: 250.0),
  _EvPreset(make: 'Hyundai', model: 'Ioniq 5', connector: ConnectorType.ccs2, batteryCapacity: 77.4, maxChargeRate: 233.0),
  _EvPreset(make: 'Kia', model: 'EV6', connector: ConnectorType.ccs2, batteryCapacity: 77.4, maxChargeRate: 239.0),
  _EvPreset(make: 'BYD', model: 'Atto 3', connector: ConnectorType.ccs2, batteryCapacity: 60.5, maxChargeRate: 88.0),
  _EvPreset(make: 'BYD', model: 'Seal', connector: ConnectorType.ccs2, batteryCapacity: 82.5, maxChargeRate: 150.0),
  _EvPreset(make: 'Nissan', model: 'Leaf', connector: ConnectorType.chademo, batteryCapacity: 40.0, maxChargeRate: 50.0),
  _EvPreset(make: 'Porsche', model: 'Taycan', connector: ConnectorType.ccs2, batteryCapacity: 93.4, maxChargeRate: 270.0),
  _EvPreset(make: 'BMW', model: 'i4 eDrive40', connector: ConnectorType.ccs2, batteryCapacity: 83.9, maxChargeRate: 205.0),
  _EvPreset(make: 'MG', model: 'MG4 EV', connector: ConnectorType.ccs2, batteryCapacity: 64.0, maxChargeRate: 135.0),
];

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
  late TextEditingController _batteryCapacityController;
  late TextEditingController _maxChargeRateController;

  late ConnectorType _selectedConnector;
  late double _batteryCapacity;
  late double _maxChargeRate;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _makeController = TextEditingController(text: v?.make ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _licensePlateController = TextEditingController(text: v?.licensePlate ?? '');

    _selectedConnector = v?.connector ?? ConnectorType.ccs2;
    _batteryCapacity = v?.batteryCapacityKwh ?? 75.0;
    _maxChargeRate = v?.maxChargeRateKw ?? 150.0;

    _batteryCapacityController = TextEditingController(
      text: _batteryCapacity.toStringAsFixed(1),
    );
    _maxChargeRateController = TextEditingController(
      text: _maxChargeRate.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _licensePlateController.dispose();
    _batteryCapacityController.dispose();
    _maxChargeRateController.dispose();
    super.dispose();
  }

  void _applyPreset(_EvPreset preset) {
    setState(() {
      _makeController.text = preset.make;
      _modelController.text = preset.model;
      _selectedConnector = preset.connector;
      _batteryCapacity = preset.batteryCapacity;
      _maxChargeRate = preset.maxChargeRate;
      _batteryCapacityController.text = preset.batteryCapacity.toStringAsFixed(1);
      _maxChargeRateController.text = preset.maxChargeRate.toStringAsFixed(0);
      _errorMessage = null;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded ${preset.make} ${preset.model} specifications'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primaryContainer,
      ),
    );
  }

  void _onBatterySliderChanged(double val) {
    setState(() {
      _batteryCapacity = val;
      _batteryCapacityController.text = val.toStringAsFixed(1);
    });
  }

  void _onMaxRateSliderChanged(double val) {
    setState(() {
      _maxChargeRate = val;
      _maxChargeRateController.text = val.toStringAsFixed(0);
    });
  }

  void _onBatteryTextChanged(String text) {
    final parsed = double.tryParse(text);
    if (parsed != null && parsed > 0 && parsed <= 300) {
      setState(() => _batteryCapacity = parsed);
    }
  }

  void _onMaxRateTextChanged(String text) {
    final parsed = double.tryParse(text);
    if (parsed != null && parsed > 0 && parsed <= 500) {
      setState(() => _maxChargeRate = parsed);
    }
  }

  String _calculateBenchmarkEstimate() {
    if (_maxChargeRate <= 0 || _batteryCapacity <= 0) return 'N/A';
    // 10% to 80% charge = 70% of total capacity
    final mins = (_batteryCapacity * 0.7 / _maxChargeRate) * 60;
    final totalMins = mins.round();
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    if (h > 0) {
      return '~${h}h ${m}m (10-80%)';
    }
    return '~$totalMins mins (10-80%)';
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedBattery = double.tryParse(_batteryCapacityController.text.trim());
    if (parsedBattery == null || parsedBattery <= 0) {
      setState(() => _errorMessage = 'Please enter a valid positive battery capacity.');
      return;
    }

    final parsedRate = double.tryParse(_maxChargeRateController.text.trim());
    if (parsedRate == null || parsedRate <= 0) {
      setState(() => _errorMessage = 'Please enter a valid positive maximum charge rate.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final request = VehicleRequest(
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        licensePlate: _licensePlateController.text.trim().isEmpty
            ? null
            : _licensePlateController.text.trim().toUpperCase(),
        connector: _selectedConnector,
        batteryCapacityKwh: parsedBattery,
        maxChargeRateKw: parsedRate,
      );

      if (_isEditing) {
        await VehicleService.instance.updateVehicle(widget.vehicle!.id, request);
      } else {
        await VehicleService.instance.addVehicle(request);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Vehicle specifications updated successfully!'
                  : 'Vehicle registered successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewMake = _makeController.text.trim().isEmpty ? 'Electric' : _makeController.text.trim();
    final previewModel = _modelController.text.trim().isEmpty ? 'Vehicle' : _modelController.text.trim();
    final previewPlate = _licensePlateController.text.trim().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Vehicle Specifications' : 'Register New Vehicle',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Interactive Vehicle Card Preview
              _buildLivePreviewCard(
                fullName: '$previewMake $previewModel',
                plate: previewPlate.isEmpty ? null : previewPlate,
              ),
              const SizedBox(height: 24),

              // Popular EV Quick-Select Presets
              if (!_isEditing) ...[
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Select Popular EV',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap any model to autofill standard manufacturer specifications:',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _popularPresets.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final p = _popularPresets[idx];
                      return ActionChip(
                        avatar: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
                        label: Text('${p.make} ${p.model}'),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                        backgroundColor: AppColors.surfaceContainerHigh,
                        side: BorderSide(color: AppColors.surfaceContainerHighest.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onPressed: () => _applyPreset(p),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Section: Vehicle Identity
              _buildSectionHeader(
                title: 'Vehicle Identity',
                subtitle: 'Enter the make, model, and optional registration plate',
                icon: Icons.directions_car_rounded,
              ),
              const SizedBox(height: 16),

              // Make & Model Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _makeController,
                      label: 'Make / Brand',
                      hint: 'e.g. Tesla, BYD',
                      icon: Icons.business_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Make is required';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTextField(
                      controller: _modelController,
                      label: 'Model',
                      hint: 'e.g. Model 3, Ioniq 5',
                      icon: Icons.drive_eta_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Model is required';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // License Plate (Optional)
              _buildTextField(
                controller: _licensePlateController,
                label: 'License Plate (Optional)',
                hint: 'e.g. CAB-4921',
                icon: Icons.badge_rounded,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),

              // Section: Connector Standard
              _buildSectionHeader(
                title: 'Connector Standard',
                subtitle: 'Used for matching station sockets, compatibility scoring & filtering',
                icon: Icons.electrical_services_rounded,
              ),
              const SizedBox(height: 16),

              // Connector Options Grid
              _buildConnectorGrid(),
              const SizedBox(height: 32),

              // Section: Battery Capacity
              _buildSectionHeader(
                title: 'Battery Capacity (kWh)',
                subtitle: 'Total usable pack capacity for range & charging duration estimations',
                icon: Icons.battery_charging_full_rounded,
              ),
              const SizedBox(height: 14),

              // Battery Input Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _batteryCapacityController,
                      label: 'Capacity in kWh',
                      hint: 'e.g. 75.0',
                      icon: Icons.electric_meter_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = double.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Must be > 0';
                        return null;
                      },
                      onChanged: _onBatteryTextChanged,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_batteryCapacity.toStringAsFixed(1)} kWh',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Pack Size',
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Battery Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.surfaceContainerHigh,
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _batteryCapacity.clamp(5.0, 220.0),
                  min: 5.0,
                  max: 220.0,
                  divisions: 215,
                  onChanged: _onBatterySliderChanged,
                ),
              ),

              // Battery quick preset pills
              Wrap(
                spacing: 8,
                children: [40.0, 60.0, 75.0, 82.0, 100.0].map((val) {
                  final isSelected = (_batteryCapacity - val).abs() < 0.5;
                  return ChoiceChip(
                    label: Text('${val.toInt()} kWh'),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                    ),
                    onSelected: (_) => _onBatterySliderChanged(val),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Section: Maximum Charge Rate
              _buildSectionHeader(
                title: 'Maximum Charge Rate (kW)',
                subtitle: 'Peak charging power supported by onboard vehicle charging electronics',
                icon: Icons.bolt_rounded,
              ),
              const SizedBox(height: 14),

              // Max Rate Input Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _maxChargeRateController,
                      label: 'Max Power in kW',
                      hint: 'e.g. 150',
                      icon: Icons.speed_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = double.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Must be > 0';
                        return null;
                      },
                      onChanged: _onMaxRateTextChanged,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_maxChargeRate.toStringAsFixed(0)} kW',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Max Power',
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Max Rate Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.surfaceContainerHigh,
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _maxChargeRate.clamp(3.0, 350.0),
                  min: 3.0,
                  max: 350.0,
                  divisions: 347,
                  onChanged: _onMaxRateSliderChanged,
                ),
              ),

              // Max rate quick preset pills
              Wrap(
                spacing: 8,
                children: [7.0, 22.0, 50.0, 150.0, 250.0, 350.0].map((val) {
                  final isSelected = (_maxChargeRate - val).abs() < 1.0;
                  return ChoiceChip(
                    label: Text('${val.toInt()} kW'),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                    ),
                    onSelected: (_) => _onMaxRateSliderChanged(val),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // Register / Update Vehicle CTA
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  onPressed: _isSubmitting ? null : _saveVehicle,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Icon(_isEditing ? Icons.save_rounded : Icons.check_circle_rounded, size: 22),
                  label: Text(
                    _isSubmitting
                        ? 'Saving Specifications...'
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

  // --- Sub-widgets ---

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLivePreviewCard({
    required String fullName,
    required String? plate,
  }) {
    final estimate = _calculateBenchmarkEstimate();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PREVIEW',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedConnector.categoryBadge,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              if (plate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    plate,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Vehicle Title
          Text(
            fullName,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),

          // Specs badges
          Row(
            children: [
              _buildPreviewMetric(
                icon: Icons.electrical_services_rounded,
                label: 'Connector',
                value: _selectedConnector.shortName,
              ),
              const SizedBox(width: 14),
              _buildPreviewMetric(
                icon: Icons.battery_charging_full_rounded,
                label: 'Capacity',
                value: '${_batteryCapacity.toStringAsFixed(1)} kWh',
              ),
              const SizedBox(width: 14),
              _buildPreviewMetric(
                icon: Icons.bolt_rounded,
                label: 'Max Rate',
                value: '${_maxChargeRate.toStringAsFixed(0)} kW',
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.surfaceContainerHigh),
          const SizedBox(height: 8),

          // Benchmark time
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text(
                'Optimal DC charging benchmark: ',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
              Text(
                estimate,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectorGrid() {
    return Column(
      children: ConnectorType.values.map((conn) {
        final isSelected = _selectedConnector == conn;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => setState(() => _selectedConnector = conn),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer.withValues(alpha: 0.25)
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      conn.icon,
                      color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              conn.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.primary : AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                conn.categoryBadge,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          conn.description,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: GoogleFonts.inter(color: AppColors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.surfaceContainerHigh),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.surfaceContainerHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
