import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/driver_models.dart';
import '../../../../core/storage/secure_storage.dart';
import 'package:smarttransit_flutter_driver/features/tracking/service/driver_tracking_service.dart';

class DashboardRepository {
  final ApiClient _apiClient = ApiClient();
  final DriverTrackingService _trackingService = DriverTrackingService();
  bool _isSyncing = false;

  Future<DriverProfile> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      if (response.statusCode == 200) {
        final data = response.data;
        final userJson = data['user'] ?? data;
        return DriverProfile.fromJson(userJson as Map<String, dynamic>);
      }
      throw Exception('Failed to load profile');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to load profile');
    } catch (_) {
      throw Exception('An unexpected error occurred while loading profile');
    }
  }

  Future<DriverProfile> startShift(DriverProfile profile) async {
    try {
      final response = await _apiClient.dio.post('/driver/shift/start');
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refreshed profile containing assignments
        final updatedProfile = await getProfile();

        // Start live location telemetry using assigned values
        final routeId = updatedProfile.assignedRouteId ?? '593';
        final busNumber = updatedProfile.busRegistration ?? 'CP-NA-5930';
        await _trackingService.startTracking(routeId: routeId, busNumber: busNumber);
        
        // Trigger background sync of any offline taps
        _triggerBackgroundSync();
        
        return updatedProfile;
      }
      throw Exception('Failed to start shift');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to start shift');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<DriverProfile> endShift() async {
    try {
      final response = await _apiClient.dio.post('/driver/shift/end');
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Stop location telemetry
        await _trackingService.stopTracking();
        
        // Refreshed profile
        final updatedProfile = await getProfile();
        
        // Trigger background sync of any remaining offline taps
        _triggerBackgroundSync();
        
        return updatedProfile;
      }
      throw Exception('Failed to end shift');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to end shift');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> processBoardingTap(String token, String mode) async {
    try {
      final response = await _apiClient.dio.post('/journey/tap', data: {
        'token': token,
        'mode': mode,
        'latitude': 6.9271, // Colombo default coordinates
        'longitude': 79.8612,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        _triggerBackgroundSync();
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Journey tap failed');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.response == null) {
        // Network connectivity error - cache locally
        final tapData = {
          'token': token,
          'mode': mode,
          'latitude': 6.9271,
          'longitude': 79.8612,
          'timestamp': DateTime.now().toIso8601String(),
        };
        await SecureStorage.addOfflineTap(tapData);
        return {
          'event': 'OFFLINE_SAVED',
          'passengerName': 'Offline Pass',
          'message': 'Saved offline (Will sync when online)',
        };
      }
      final data = e.response?.data;
      throw Exception(data?['message'] ?? 'Failed to complete tap action');
    } catch (_) {
      // General socket exception - cache locally
      final tapData = {
        'token': token,
        'mode': mode,
        'latitude': 6.9271,
        'longitude': 79.8612,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await SecureStorage.addOfflineTap(tapData);
      return {
        'event': 'OFFLINE_SAVED',
        'passengerName': 'Offline Pass',
        'message': 'Saved offline (Will sync when online)',
      };
    }
  }

  Future<void> syncOfflineTaps() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final taps = await SecureStorage.getOfflineTaps();
      if (taps.isEmpty) {
        _isSyncing = false;
        return;
      }
      final remaining = List<Map<String, dynamic>>.from(taps);
      for (final tap in taps) {
        try {
          final response = await _apiClient.dio.post('/journey/tap', data: {
            'token': tap['token'],
            'mode': tap['mode'],
            'latitude': tap['latitude'],
            'longitude': tap['longitude'],
            'offlineTimestamp': tap['timestamp'],
          });
          if (response.statusCode == 200 || response.statusCode == 201) {
            remaining.remove(tap);
          }
        } on DioException catch (e) {
          if (e.response != null) {
            // Server response received (even error) means it has processed, discard from offline cache
            remaining.remove(tap);
          } else {
            // Still no network, keep remaining cache
            break;
          }
        } catch (_) {
          break;
        }
      }
      await SecureStorage.saveOfflineTaps(remaining);
    } finally {
      _isSyncing = false;
    }
  }

  void _triggerBackgroundSync() {
    syncOfflineTaps().catchError((_) {});
  }

  void stopTracking() {
    _trackingService.stopTracking();
  }
}
