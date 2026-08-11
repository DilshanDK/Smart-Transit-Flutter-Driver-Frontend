import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/push_notification_service.dart';

/// Thrown only when the backend is unreachable (network timeout / ECONNREFUSED).
/// Distinct from an authentication failure (401/403).
class NetworkUnavailableException implements Exception {
  final String message;
  const NetworkUnavailableException([this.message = 'Backend unreachable']);
}

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> verifyDriver(String loginInput, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/driver/verify',
        data: {
          'loginInput': loginInput,
          'password': password,
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
      final msg = e.response?.data?['message'];
      if (msg != null) {
        if (msg is List) throw Exception(msg.join(', '));
        throw Exception(msg.toString());
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to reach backend server. Check network connection.');
      }
      throw Exception('Driver verification failed: ${e.message}');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/driver/google',
        data: {'idToken': idToken},
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
        throw Exception(response.data['message'] ?? 'Google Login failed');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (msg != null) {
        if (msg is List) throw Exception(msg.join(', '));
        throw Exception(msg.toString());
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to reach backend server. Check network connection.');
      }
      throw Exception('Google sign-in failed: ${e.message}');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
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
      // Non-200 but got a response — treat as unauthenticated
      return null;
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      if (status == 401 || status == 403) {
        // Token is genuinely expired or revoked — clear and force re-login
        await SecureStorage.clearTokens();
        return null;
      }

      // Network error, timeout, backend restarting — throw so caller knows
      // NOT to treat this as "logged out"
      throw const NetworkUnavailableException();
    } catch (_) {
      // Any other unexpected error — treat as network issue, keep session
      throw const NetworkUnavailableException();
    }
  }
}
