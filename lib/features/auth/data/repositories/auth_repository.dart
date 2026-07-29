import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/push_notification_service.dart';

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
    } catch (_) {
      await SecureStorage.clearTokens();
    }
    return null;
  }
}
