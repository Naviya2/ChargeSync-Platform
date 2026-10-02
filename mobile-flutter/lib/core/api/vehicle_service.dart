import 'package:flutter/foundation.dart';
import 'vehicle_api_client.dart';
import 'vehicle_models.dart';

class VehicleService extends ChangeNotifier {
  VehicleService._();
  static final VehicleService instance = VehicleService._();

  List<Vehicle> _vehicles = [];
  Vehicle? _activeVehicle;
  bool _isLoading = false;
  String? _error;

  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  Vehicle? get activeVehicle => _activeVehicle;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasVehicles => _vehicles.isNotEmpty;

  /// Fetch vehicles from backend and retain active vehicle
  Future<List<Vehicle>> fetchVehicles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vehicles = await VehicleApiClient.instance.getMyVehicles();
      if (_vehicles.isNotEmpty) {
        // If active vehicle is not set or deleted, select first vehicle
        if (_activeVehicle == null || !_vehicles.any((v) => v.id == _activeVehicle!.id)) {
          _activeVehicle = _vehicles.first;
        } else {
          // Refresh active vehicle reference
          _activeVehicle = _vehicles.firstWhere((v) => v.id == _activeVehicle!.id);
        }
      } else {
        _activeVehicle = null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _vehicles;
  }

  void setActiveVehicle(Vehicle vehicle) {
    if (_vehicles.any((v) => v.id == vehicle.id)) {
      _activeVehicle = vehicle;
      notifyListeners();
    }
  }

  Future<Vehicle> addVehicle(VehicleRequest request) async {
    final vehicle = await VehicleApiClient.instance.createVehicle(request);
    _vehicles.add(vehicle);
    _activeVehicle = vehicle;
    notifyListeners();
    return vehicle;
  }

  Future<Vehicle> updateVehicle(String vehicleId, VehicleRequest request) async {
    final updated = await VehicleApiClient.instance.updateVehicle(vehicleId, request);
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      _vehicles[index] = updated;
    }
    if (_activeVehicle?.id == vehicleId) {
      _activeVehicle = updated;
    }
    notifyListeners();
    return updated;
  }

  Future<bool> deleteVehicle(String vehicleId) async {
    final success = await VehicleApiClient.instance.deleteVehicle(vehicleId);
    if (success) {
      _vehicles.removeWhere((v) => v.id == vehicleId);
      if (_activeVehicle?.id == vehicleId) {
        _activeVehicle = _vehicles.isNotEmpty ? _vehicles.first : null;
      }
      notifyListeners();
    }
    return success;
  }
}
