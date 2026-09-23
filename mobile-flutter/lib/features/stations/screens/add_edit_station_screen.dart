import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../api/station_service.dart';
import '../models/station.dart';

class AddEditStationScreen extends StatefulWidget {
  final Station? station;
  const AddEditStationScreen({super.key, this.station});

  @override
  State<AddEditStationScreen> createState() => _AddEditStationScreenState();
}

class _AddEditStationScreenState extends State<AddEditStationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.station != null) {
      _nameController.text = widget.station!.name;
      _addressController.text = widget.station!.address;
      _latitudeController.text = widget.station!.latitude.toString();
      _longitudeController.text = widget.station!.longitude.toString();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = {
      'name': _nameController.text,
      'address': _addressController.text,
      'latitude': double.parse(_latitudeController.text),
      'longitude': double.parse(_longitudeController.text),
    };

    try {
      if (widget.station == null) {
        await StationService.instance.registerStation(request);
      } else {
        await StationService.instance.updateStation(widget.station!.id, request);
      }
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
        title: Text(widget.station == null ? 'Register Station' : 'Edit Station', style: const TextStyle(color: AppColors.onSurface)),
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
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Station Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _latitudeController,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _longitudeController,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
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
                      : Text(widget.station == null ? 'Register' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
