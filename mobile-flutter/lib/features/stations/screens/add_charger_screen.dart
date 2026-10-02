import 'package:flutter/material.dart';
import '../../../core/api/vehicle_models.dart';
import '../../../core/theme/app_colors.dart';
import '../api/station_service.dart';

class AddChargerScreen extends StatefulWidget {
  final String stationId;
  const AddChargerScreen({super.key, required this.stationId});

  @override
  State<AddChargerScreen> createState() => _AddChargerScreenState();
}

class _AddChargerScreenState extends State<AddChargerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _bayLabelController = TextEditingController();
  final _powerKwController = TextEditingController();
  final _tariffController = TextEditingController();
  
  ConnectorType _selectedConnector = ConnectorType.type2;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = {
      'identifier': _identifierController.text,
      'bayLabel': _bayLabelController.text,
      'connector': _selectedConnector.toBackendString(),
      'powerKw': double.parse(_powerKwController.text),
      'tariff': double.parse(_tariffController.text),
      'status': 'Available' // Use string instead of int
    };

    try {
      await StationService.instance.addCharger(widget.stationId, request);
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
        title: const Text('Add Charger', style: TextStyle(color: AppColors.onSurface)),
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
                controller: _identifierController,
                decoration: const InputDecoration(labelText: 'Identifier (e.g. CS-001)'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bayLabelController,
                decoration: const InputDecoration(labelText: 'Bay Label'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ConnectorType>(
                initialValue: _selectedConnector,
                decoration: const InputDecoration(labelText: 'Connector Type'),
                items: ConnectorType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedConnector = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _powerKwController,
                decoration: const InputDecoration(labelText: 'Power Output (kW)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tariffController,
                decoration: const InputDecoration(labelText: 'Tariff (\$/kWh)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid number' : null,
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
                      : const Text('Add Charger'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
