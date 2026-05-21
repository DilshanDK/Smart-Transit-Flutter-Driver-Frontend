import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/driver_models.dart';
import '../../tracking/service/driver_tracking_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final DriverTrackingService _trackingService = DriverTrackingService();

  bool _isLoading = true;
  bool _isShiftToggling = false;
  DriverProfile? _profile;
  String? _error;
  bool _isTracking = false;

  bool get isLoading => _isLoading;
  bool get isShiftToggling => _isShiftToggling;
  DriverProfile? get profile => _profile;
  String? get error => _error;
  bool get isTracking => _isTracking;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/auth/me');
      if (response.statusCode == 200) {
        final data = response.data;
        final userJson = data['user'] ?? data;
        _profile = DriverProfile.fromJson(userJson as Map<String, dynamic>);
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to load profile';
    } catch (_) {
      _error = 'An unexpected error occurred';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> toggleShift() async {
    if (_profile == null) return false;
    _isShiftToggling = true;
    notifyListeners();

    final startingShift = !(_profile?.isOnShift ?? false);
    final endpoint = _profile!.isOnShift ? '/driver/shift/end' : '/driver/shift/start';
    try {
      final response = await _apiClient.dio.post(endpoint);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Reload profile to get updated shift status
        await loadProfile();
        if (startingShift) {
          final routeId = _profile?.busRegistration ?? _profile?.driverId ?? _profile?.id ?? 'UNKNOWN';
          final busNumber = _profile?.busRegistration ?? _profile?.driverId ?? _profile?.id ?? 'UNKNOWN';
          try {
            await _trackingService.startTracking(routeId: routeId, busNumber: busNumber);
            _isTracking = true;
          } catch (e) {
            _error = e.toString();
            _isTracking = false;
          }
        } else {
          await _trackingService.stopTracking();
          _isTracking = false;
        }
        _isShiftToggling = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to toggle shift';
    } catch (_) {
      _error = 'Shift update failed';
    }

    _isShiftToggling = false;
    notifyListeners();
    return false;
  }

  /// Submits a boarding ticket tap (QR or NFC) from the scanner console
  Future<Map<String, dynamic>?> processBoardingTap(String token, String mode) async {
    try {
      final response = await _apiClient.dio.post('/journey/tap', data: {
        'token': token,
        'mode': mode,
        'latitude': 6.9271, // Colombo coordinates
        'longitude': 79.8612,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final statusCode = e.response?.statusCode;
      return {
        'error': true,
        'statusCode': statusCode,
        'message': data?['message'] ?? 'Failed to complete tap action',
      };
    } catch (_) {
      return {
        'error': true,
        'message': 'Network/Server connection error',
      };
    }
    return null;
  }

  @override
  void dispose() {
    _trackingService.stopTracking();
    super.dispose();
  }
}
