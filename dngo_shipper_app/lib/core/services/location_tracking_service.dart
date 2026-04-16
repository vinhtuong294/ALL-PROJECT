import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationTrackingService {
  // Biến singleton
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  String? _currentOrderId;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Xin quyền truy cập vị trí
  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Bắt đầu lắng nghe và đẩy dữ liệu vị trí lên Firebase
  Future<void> startTracking(String orderId) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    // Ngừng tracking luồng cũ nếu có
    await stopTracking();
    
    _currentOrderId = orderId;

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Chỉ cập nhật khi di chuyển > 10m
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position? position) {
          if (position != null && _currentOrderId != null) {
            _updateFirebaseLocation(position, _currentOrderId!);
          }
        });
  }

  /// Ghi đè toạ độ mới nhất lên Firebase
  Future<void> _updateFirebaseLocation(Position position, String orderId) async {
    try {
      await _dbRef.child('tracking').child(orderId).set({
        'lat': position.latitude,
        'lng': position.longitude,
        'heading': position.heading,
        'speed': position.speed,
        'updated_at': ServerValue.timestamp,
      });
    } catch (e) {
      print("Lỗi khi update Firebase location: \$e");
    }
  }

  /// Dừng tracking (Gọi khi shipper đã giao xong đơn hàng)
  Future<void> stopTracking() async {
    if (_positionStreamSubscription != null) {
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
    }
    _currentOrderId = null;
  }
}
