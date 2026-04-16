import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

/// Widget theo dõi vị trí shipper real-time + vẽ đường đi
class ShipperTrackingMap extends StatefulWidget {
  final String orderId;
  final String? deliveryAddress; // Địa chỉ giao hàng (để geocode)

  const ShipperTrackingMap({
    super.key,
    required this.orderId,
    this.deliveryAddress,
  });

  @override
  State<ShipperTrackingMap> createState() => _ShipperTrackingMapState();
}

class _ShipperTrackingMapState extends State<ShipperTrackingMap> {
  StreamSubscription? _trackingSubscription;
  LatLng? _shipperLatLng;
  LatLng? _destinationLatLng;
  List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();
  bool _hasInitialPosition = false;
  bool _isLoadingRoute = false;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _geocodeDestination();
    _startListening();
  }

  /// Geocode địa chỉ giao hàng bằng Nominatim (OpenStreetMap, miễn phí)
  Future<void> _geocodeDestination() async {
    if (widget.deliveryAddress == null || widget.deliveryAddress!.isEmpty) return;

    try {
      final encoded = Uri.encodeComponent(
        '${widget.deliveryAddress!}, Đà Nẵng, Việt Nam',
      );
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=1',
      );
      final res = await http.get(url, headers: {'User-Agent': 'DNGO-App/1.0'});
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'] ?? '');
          final lng = double.tryParse(data[0]['lon'] ?? '');
          if (lat != null && lng != null && mounted) {
            setState(() => _destinationLatLng = LatLng(lat, lng));
            // Lấy tuyến đường ngay khi có đủ 2 điểm
            if (_shipperLatLng != null) _fetchRoute();
          }
        }
      }
    } catch (_) {}
  }

  /// Gọi OSRM routing API để lấy đường đi thực tế
  Future<void> _fetchRoute() async {
    if (_shipperLatLng == null || _destinationLatLng == null) return;
    if (_isLoadingRoute) return;

    setState(() => _isLoadingRoute = true);
    try {
      final from = _shipperLatLng!;
      final to = _destinationLatLng!;
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final coords = data['routes']?[0]?['geometry']?['coordinates'] as List?;
        if (coords != null && mounted) {
          setState(() {
            _routePoints = coords
                .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
                .toList();
          });
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  void _startListening() {
    final ref = FirebaseDatabase.instance.ref('tracking/${widget.orderId}');
    _trackingSubscription = ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat != null && lng != null && mounted) {
          final newPos = LatLng(lat, lng);
          final bool needRoute = _shipperLatLng == null && _destinationLatLng != null;
          setState(() {
            _shipperLatLng = newPos;
            _lastUpdated = DateTime.now();
            if (!_hasInitialPosition) _hasInitialPosition = true;
          });
          // Cập nhật route khi shipper di chuyển đáng kể (> 50m)
          if (needRoute ||
              (_routePoints.isNotEmpty &&
                  const Distance().as(LengthUnit.Meter, _routePoints.first, newPos) > 50)) {
            _fetchRoute();
          }
          // Di chuyển camera
          _mapController.move(newPos, _mapController.camera.zoom);
        }
      }
    });
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2F8000), Color(0xFF5DBB2E)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              const Icon(Icons.delivery_dining, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Shipper đang trên đường đến bạn!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              if (_isLoadingRoute)
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              else if (_lastUpdated != null)
                const Text('• Live', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        // Bản đồ
        SizedBox(
          height: 300,
          child: _shipperLatLng == null ? _buildWaitingState() : _buildMap(),
        ),

        // Chú thích
        if (_shipperLatLng != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                _legendDot(const Color(0xFF2F8000)),
                const SizedBox(width: 6),
                const Text('Shipper', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                if (_destinationLatLng != null) ...[
                  _legendDot(Colors.red),
                  const SizedBox(width: 6),
                  const Text('Điểm giao', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 16),
                ],
                if (_routePoints.isNotEmpty) ...[
                  Container(width: 20, height: 3, color: Colors.blue.shade600),
                  const SizedBox(width: 6),
                  const Text('Đường đi', style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 12, height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _buildWaitingState() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2F8000)),
            SizedBox(height: 16),
            Text('Đang kết nối vị trí shipper...', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final bounds = _destinationLatLng != null
        ? LatLngBounds.fromPoints([_shipperLatLng!, _destinationLatLng!])
        : null;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _shipperLatLng!,
          initialZoom: 14.5,
          initialCameraFit: bounds != null
              ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50))
              : null,
        ),
        children: [
          // Tile layer
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.dngo.app',
          ),

          // Đường đi (route polyline)
          if (_routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  strokeWidth: 5,
                  color: Colors.blue.shade600.withOpacity(0.85),
                ),
              ],
            ),

          // Markers
          MarkerLayer(
            markers: [
              // Marker Shipper (xe máy di chuyển)
              Marker(
                point: _shipperLatLng!,
                width: 56,
                height: 62,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F8000),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2F8000).withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.delivery_dining, color: Colors.white, size: 22),
                    ),
                    CustomPaint(
                      size: const Size(12, 6),
                      painter: _TrianglePainter(const Color(0xFF2F8000)),
                    ),
                  ],
                ),
              ),

              // Marker điểm giao hàng
              if (_destinationLatLng != null)
                Marker(
                  point: _destinationLatLng!,
                  width: 48,
                  height: 56,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.home, color: Colors.white, size: 20),
                      ),
                      CustomPaint(
                        size: const Size(12, 6),
                        painter: _TrianglePainter(Colors.red),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Vẽ tam giác bên dưới marker
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => false;
}
