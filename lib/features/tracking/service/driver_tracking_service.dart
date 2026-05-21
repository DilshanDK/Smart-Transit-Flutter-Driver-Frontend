import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';

class DriverTrackingService {
  io.Socket? _socket;
  StreamSubscription<Position>? _positionSub;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> startTracking({
    required String routeId,
    required String busNumber,
  }) async {
    await _ensureLocationPermission();

    final token = await SecureStorage.getAccessToken();
    if (token == null) {
      throw Exception('Missing access token');
    }

    _socket?.disconnect();
    _socket?.dispose();

    _socket = io.io(
      '${ApiClient.baseUrl}/tracking',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket?.connect();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen((position) {
      final now = DateTime.now();
      if (now.difference(_lastSent).inSeconds < 4) {
        return;
      }
      _lastSent = now;

      final speed = position.speed.isNaN ? 0 : position.speed;
      final heading = position.heading.isNaN ? 0 : position.heading;

      _socket?.emit('driver_location', {
        'routeId': routeId,
        'busNumber': busNumber,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': speed,
        'heading': heading,
        'status': speed > 0 ? 'ACTIVE' : 'IDLE',
      });
    });
  }

  Future<void> stopTracking() async {
    await _positionSub?.cancel();
    _positionSub = null;

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  Future<void> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }
  }
}
