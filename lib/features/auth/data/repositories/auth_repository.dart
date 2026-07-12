import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/push_notification_service.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> verifyDriver(String driverId, String busRegistration) async {
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
        return data['user'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['message'] ?? 'Verification failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Driver verification failed.');
    } catch (e) {
      throw Exception('An unexpected error occurred during verification.');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (_) {
      // Gracefully continue clearing local tokens
    } finally {
      await SecureStorage.clearTokens();
    }
  }

  Future<Map<String, dynamic>?> checkSession() async {
    final token = await SecureStorage.getAccessToken();
    if (token == null) return null;

    try {
      final response = await _apiClient.dio.get('/auth/me');
      if (response.statusCode == 200) {
        await PushNotificationService.instance.registerDeviceToken();
        return response.data['user'] as Map<String, dynamic>;
      }
    } catch (_) {
      await SecureStorage.clearTokens();
    }
    return null;
  }
}
