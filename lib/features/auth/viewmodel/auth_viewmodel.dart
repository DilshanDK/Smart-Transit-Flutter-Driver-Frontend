import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/push_notification_service.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? _driverData;
  Map<String, dynamic>? get driverData => _driverData;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> verifyDriver({
    required String driverId,
    required String busRegistration,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiClient.dio.post(
        '/auth/driver/verify',
        data: {
          'driverId': driverId,
          'busRegistration': busRegistration,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        await SecureStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        await PushNotificationService.instance.registerDeviceToken();
        _driverData = data['user'];
        _setLoading(false);
        return true;
      }
    } on DioException catch (e) {
      _setError(e.response?.data['message'] ?? 'Driver verification failed.');
    } catch (e) {
      _setError('An unexpected error occurred.');
    }

    _setLoading(false);
    return false;
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (_) {
    } finally {
      await SecureStorage.clearTokens();
      _driverData = null;
      _setLoading(false);
    }
  }

  Future<bool> checkInitialAuth() async {
    final token = await SecureStorage.getAccessToken();
    if (token == null) return false;

    try {
      final response = await _apiClient.dio.get('/auth/me');
      if (response.statusCode == 200) {
        _driverData = response.data['user'];
        await PushNotificationService.instance.registerDeviceToken();
        notifyListeners();
        return true;
      }
    } catch (_) {
      await SecureStorage.clearTokens();
    }
    return false;
  }
}
