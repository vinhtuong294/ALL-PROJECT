import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/services/shipper_api_service.dart';

/// =============================================================
/// Map Tab — Bản đồ giao hàng OSM (không cần Google Maps API key)
/// Hiển thị: marker đánh số 1,2,3... + route tối ưu
/// =============================================================
class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final ShipperApiService _apiService = ShipperApiService();

  // Data
  List<_DeliveryPoint> _deliveryPoints = [];
  List<LatLng> _routePolyline = [];
  LatLng? _marketLocation;
  String _marketName = '';
  double _totalDistanceKm = 0;
  String? _consolidationId;

  // State
  bool _isLoading = true;
  bool _isOptimizing = false;
  String? _error;
  bool _showRouteInfo = true;

  // Đà Nẵng center mặc định
  static const LatLng _defaultCenter = LatLng(16.0544, 108.2022);

  // Chợ Bắc Mỹ An — tọa độ chuẩn (điểm xuất phát)
  static const LatLng _marketBacMyAn = LatLng(16.035415, 108.243501);

  // Cache geocode kết quả (tránh request trùng lặp)
  final Map<String, LatLng> _geocodeCache = {};

  @override
  void initState() {
    super.initState();
    _loadDeliveringOrders();
  }

  /// Load đơn đang giao → geocode → hiển thị trên map
  Future<void> _loadDeliveringOrders() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final orders = await _apiService.getDeliveringOrders();

      if (orders.isEmpty) {
        setState(() { _isLoading = false; _error = 'no_orders'; });
        return;
      }

      // Đặt chợ Bắc Mỹ An làm điểm xuất phát mặc định
      _marketLocation = _marketBacMyAn;
      _marketName = 'Chợ Bắc Mỹ An';

      // Parse delivery addresses → geocode
      final points = <_DeliveryPoint>[];
      String? firstConsolidationId;
      int jitterIndex = 0; // Dùng khi nhiều đơn cùng 1 địa chỉ

      for (final order in orders) {
        // Lấy consolidation_id
        if (firstConsolidationId == null && order.consolidationId != null) {
          firstConsolidationId = order.consolidationId;
        }

        // Parse địa chỉ giao hàng (improved)
        final parsed = _parseDeliveryAddress(order.deliveryAddress ?? '');
        String address = parsed['address'] ?? '';
        String buyerName = parsed['name'] ?? order.buyerName ?? '';

        if (address.isEmpty || address == 'N/A') continue;

        // Geocode (có cache + rate limit)
        LatLng? coords;
        if (_geocodeCache.containsKey(address)) {
          // Thêm jitter nhỏ cho các đơn cùng địa chỉ
          final cached = _geocodeCache[address]!;
          jitterIndex++;
          coords = LatLng(
            cached.latitude + (jitterIndex * 0.0003),
            cached.longitude + (jitterIndex * 0.0002),
          );
        } else {
          coords = await _geocodeAddress(address);
          if (coords != null) {
            _geocodeCache[address] = coords;
          }
          // Rate limit: Nominatim yêu cầu tối đa 1 req/sec
          await Future.delayed(const Duration(milliseconds: 1100));
        }

        if (coords != null) {
          points.add(_DeliveryPoint(
            orderId: order.maDonHang,
            address: address,
            buyerName: buyerName,
            totalAmount: order.totalAmount?.toDouble() ?? 0,
            location: coords,
          ));
        }
      }

      _consolidationId = firstConsolidationId;

      if (points.isEmpty) {
        setState(() { _isLoading = false; _error = 'no_geocode'; });
        return;
      }

      setState(() { _deliveryPoints = points; _isLoading = false; });

      // Fit map
      _fitMapToPoints();

      // Nếu có consolidation, tự động optimize route
      if (_consolidationId != null) {
        await _optimizeRoute();
      }
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  /// Parse địa chỉ giao hàng: xử lý cả JSON string, Unicode escaped, plain text
  Map<String, String> _parseDeliveryAddress(String raw) {
    if (raw.isEmpty) return {'address': '', 'name': ''};

    // Thử parse JSON
    try {
      final json = jsonDecode(raw);
      if (json is Map) {
        String address = (json['address'] ?? '').toString();
        String name = (json['name'] ?? '').toString();
        
        // Clean up address: bỏ Unicode escape sequences đã decode sai
        address = _cleanAddress(address);
        name = _cleanAddress(name);
        
        return {'address': address, 'name': name};
      }
    } catch (_) {}

    // Plain text address
    return {'address': _cleanAddress(raw), 'name': ''};
  }

  /// Làm sạch address: loại bỏ ký tự đặc biệt, chuẩn hóa
  String _cleanAddress(String addr) {
    // Remove multiple spaces
    addr = addr.replaceAll(RegExp(r'\s+'), ' ').trim();
    return addr;
  }

  /// Gọi API optimize-route → nhận thứ tự tối ưu → vẽ route
  Future<void> _optimizeRoute() async {
    if (_consolidationId == null) return;
    setState(() { _isOptimizing = true; });

    try {
      final result = await _apiService.optimizeRoute(_consolidationId!);

      if (result['success'] == true) {
        _marketName = result['ten_cho'] ?? 'Chợ Bắc Mỹ An';
        final routeData = result['data'];
        final optimizedRoute = routeData['optimized_route'] as List? ?? [];
        _totalDistanceKm = (routeData['total_distance_km'] ?? 0).toDouble();

        // Sắp xếp lại delivery points theo thứ tự tối ưu
        final reorderedPoints = <_DeliveryPoint>[];
        for (final stop in optimizedRoute) {
          final orderId = stop['order_id'];
          final point = _deliveryPoints.firstWhere(
            (p) => p.orderId == orderId,
            orElse: () => _deliveryPoints.first,
          );
          reorderedPoints.add(point.copyWith(
            distanceFromPrev: (stop['distance_from_prev_km'] ?? 0).toDouble(),
          ));
        }

        // Nếu optimize trả về ít hơn, thêm các điểm còn lại
        for (final p in _deliveryPoints) {
          if (!reorderedPoints.any((r) => r.orderId == p.orderId)) {
            reorderedPoints.add(p);
          }
        }

        setState(() { _deliveryPoints = reorderedPoints; });

        // Vẽ đường đi bằng OSRM
        await _drawRoute();
      }
    } catch (e) {
      debugPrint('⚠️ Optimize route error: $e');
      // Vẫn vẽ route giữa các điểm nếu optimize API fail
      await _drawRoute();
    } finally {
      setState(() { _isOptimizing = false; });
    }
  }

  /// Vẽ đường đi bằng OSRM (free, không cần API key)
  Future<void> _drawRoute() async {
    if (_deliveryPoints.length < 2 && _marketLocation == null) {
      if (_deliveryPoints.length == 1 && _marketLocation != null) {
        final routeCoords = await _getOsrmRoute([
          _marketLocation!,
          _deliveryPoints[0].location,
        ]);
        setState(() { _routePolyline = routeCoords; });
      }
      return;
    }

    // Tạo danh sách điểm: chợ → điểm 1 → điểm 2 → ...
    final waypoints = <LatLng>[];
    if (_marketLocation != null) waypoints.add(_marketLocation!);
    for (final p in _deliveryPoints) {
      waypoints.add(p.location);
    }

    final routeCoords = await _getOsrmRoute(waypoints);
    setState(() { _routePolyline = routeCoords; });

    _fitMapToPoints();
  }

  /// Gọi OSRM public API để lấy polyline
  Future<List<LatLng>> _getOsrmRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return [];

    final coords = waypoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');

    final url = 'http://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final geometry = data['routes'][0]['geometry']['coordinates'] as List;
          return geometry
              .map<LatLng>((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('OSRM error: $e');
    }
    return [];
  }

  /// Geocode một địa chỉ bằng Nominatim — CẢI THIỆN: 
  /// - Dùng structured query cho kết quả chính xác hơn
  /// - Giới hạn tìm trong Đà Nẵng (viewbox)
  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      // Thử structured query trước (chính xác hơn)
      final structuredUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?street=${Uri.encodeComponent(_extractStreetOnly(address))}'
        '&city=${Uri.encodeComponent("Đà Nẵng")}'
        '&country=${Uri.encodeComponent("Vietnam")}'
        '&format=json&limit=1'
        '&viewbox=108.10,16.12,108.35,15.95&bounded=1'
      );

      var response = await http.get(structuredUrl, headers: {'User-Agent': 'dngo-shipper-app/1.0'});

      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List;
        if (results.isNotEmpty) {
          debugPrint('✅ Geocoded (structured): "$address" → ${results[0]['lat']}, ${results[0]['lon']}');
          return LatLng(
            double.parse(results[0]['lat']),
            double.parse(results[0]['lon']),
          );
        }
      }

      // Fallback: free-form query (ít chính xác hơn)
      await Future.delayed(const Duration(milliseconds: 1100));
      final freeUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent("$address, Đà Nẵng, Việt Nam")}'
        '&format=json&limit=1'
        '&viewbox=108.10,16.12,108.35,15.95&bounded=1'
      );

      response = await http.get(freeUrl, headers: {'User-Agent': 'dngo-shipper-app/1.0'});

      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List;
        if (results.isNotEmpty) {
          debugPrint('✅ Geocoded (free): "$address" → ${results[0]['lat']}, ${results[0]['lon']}');
          return LatLng(
            double.parse(results[0]['lat']),
            double.parse(results[0]['lon']),
          );
        }
      }

      debugPrint('❌ Cannot geocode: "$address"');
    } catch (e) {
      debugPrint('Geocode error for "$address": $e');
    }
    return null;
  }

  /// Trích xuất phần đường từ address (bỏ quận, thành phố)
  String _extractStreetOnly(String address) {
    // Loại bỏ "Đà Nẵng", "Việt Nam", "số nhà"
    String street = address
      .replaceAll(RegExp(r',?\s*Đà Nẵng\b', caseSensitive: false), '')
      .replaceAll(RegExp(r',?\s*Da Nang\b', caseSensitive: false), '')
      .replaceAll(RegExp(r',?\s*Việt Nam\b', caseSensitive: false), '')
      .replaceAll(RegExp(r',?\s*Vietnam\b', caseSensitive: false), '')
      .replaceAll(RegExp(r',?\s*\d{5}\b'), '') // zip code
      .trim();
    
    // Bỏ trailing comma
    if (street.endsWith(',')) street = street.substring(0, street.length - 1).trim();
    
    return street;
  }



  /// Fit bản đồ hiển thị tất cả markers
  void _fitMapToPoints() {
    if (_deliveryPoints.isEmpty) return;

    final allPoints = _deliveryPoints.map((p) => p.location).toList();
    if (_marketLocation != null) allPoints.add(_marketLocation!);

    if (allPoints.length == 1) {
      _mapController.move(allPoints.first, 15);
      return;
    }

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (final p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat - 0.005, minLng - 0.005),
      LatLng(maxLat + 0.005, maxLng + 0.005),
    );

    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Bản đồ OSM ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 14,
            ),
            children: [
              // Tile layer — OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dngo.shipper',
                maxZoom: 19,
              ),

              // Đường đi (polyline)
              if (_routePolyline.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Viền ngoài (shadow)
                    Polyline(
                      points: _routePolyline,
                      strokeWidth: 8,
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                    ),
                    // Đường chính
                    Polyline(
                      points: _routePolyline,
                      strokeWidth: 5,
                      color: const Color(0xFF2E7D32),
                    ),
                  ],
                ),

              // Markers đánh số
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),

          // ── Header overlay ──
          _buildHeaderOverlay(context),

          // ── Loading overlay ──
          if (_isLoading)
            _buildLoadingOverlay(),

          // ── Empty state ──
          if (!_isLoading && _error == 'no_orders')
            _buildEmptyState(),

          // ── Route info panel ──
          if (!_isLoading && _deliveryPoints.isNotEmpty && _showRouteInfo)
            _buildRouteInfoPanel(),

          // ── Optimize button ──
          if (!_isLoading && _deliveryPoints.isNotEmpty && _consolidationId != null)
            Positioned(
              right: 16,
              bottom: _showRouteInfo ? 320 : 100,
              child: Column(
                children: [
                  // Fit map button
                  _buildActionButton(
                    icon: Icons.center_focus_strong,
                    onTap: _fitMapToPoints,
                    tooltip: 'Xem toàn bộ',
                  ),
                  const SizedBox(height: 12),
                  // Re-optimize button
                  _buildActionButton(
                    icon: Icons.route_rounded,
                    onTap: _isOptimizing ? null : _optimizeRoute,
                    tooltip: 'Tối ưu tuyến đường',
                    isLoading: _isOptimizing,
                    color: const Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),

          // ── Toggle route info ──
          if (!_isLoading && _deliveryPoints.isNotEmpty)
            Positioned(
              left: 16,
              bottom: 24,
              child: GestureDetector(
                onTap: () => setState(() => _showRouteInfo = !_showRouteInfo),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showRouteInfo ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        size: 20,
                        color: const Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showRouteInfo ? 'Ẩn danh sách' : 'Hiện danh sách',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build marker list with numbered labels
  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Market marker (nếu có)
    if (_marketLocation != null) {
      markers.add(Marker(
        point: _marketLocation!,
        width: 48,
        height: 48,
        child: _buildMarketMarker(),
      ));
    }

    // Delivery markers đánh số
    for (int i = 0; i < _deliveryPoints.length; i++) {
      final point = _deliveryPoints[i];
      markers.add(Marker(
        point: point.location,
        width: 48,
        height: 56,
        child: _buildNumberedMarker(i + 1, point),
      ));
    }

    return markers;
  }

  Widget _buildMarketMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6F00),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
          ),
          child: const Icon(Icons.store, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildNumberedMarker(int number, _DeliveryPoint point) {
    return GestureDetector(
      onTap: () => _showPointDetail(point, number),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: const Color(0xFF2E7D32).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          // Mũi tên chỉ xuống
          CustomPaint(
            size: const Size(12, 8),
            painter: _TrianglePainter(color: const Color(0xFF1B5E20)),
          ),
        ],
      ),
    );
  }

  void _showPointDetail(_DeliveryPoint point, int number) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Điểm giao #$number', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      if (point.buyerName.isNotEmpty)
                        Text(point.buyerName, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.location_on, point.address),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.receipt, 'Mã đơn: ${point.orderId}'),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.payments, 'Tổng tiền: ${_formatMoney(point.totalAmount)}'),
            if (point.distanceFromPrev > 0) ...[
              const SizedBox(height: 10),
              _buildDetailRow(Icons.straighten, 'Khoảng cách từ điểm trước: ${point.distanceFromPrev.toStringAsFixed(1)} km'),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4))),
      ],
    );
  }

  Widget _buildHeaderOverlay(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16, right: 16, bottom: 14,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1B5E20),
              const Color(0xFF2E7D32).withValues(alpha: 0.85),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.map_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bản đồ giao hàng',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    _deliveryPoints.isNotEmpty
                        ? '${_deliveryPoints.length} điểm giao${_marketName.isNotEmpty ? " • $_marketName" : ""}'
                        : 'Đang tải...',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
            // Refresh button
            GestureDetector(
              onTap: _loadDeliveringOrders,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.refresh, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
              ),
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF2E7D32)),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Đang tải bản đồ...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Geocoding các địa chỉ giao hàng',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delivery_dining, size: 56, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có đơn đang giao',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy nhận đơn hàng từ tab "Đơn hàng" để xem bản đồ tuyến đường giao hàng tối ưu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDeliveringOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfoPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Summary
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_deliveryPoints.length} điểm giao',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_totalDistanceKm > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_totalDistanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (_isOptimizing)
                    const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF2E7D32))),
                    ),
                ],
              ),
            ),
            // Danh sách các điểm giao
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: _deliveryPoints.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final point = _deliveryPoints[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    leading: Container(
                      width: 34, height: 34,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ),
                    ),
                    title: Text(
                      point.buyerName.isNotEmpty ? point.buyerName : 'Đơn ${point.orderId}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      point.address,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatMoney(point.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF2E7D32)),
                        ),
                        if (point.distanceFromPrev > 0)
                          Text(
                            '${point.distanceFromPrev.toStringAsFixed(1)} km',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                    onTap: () {
                      _mapController.move(point.location, 16);
                      _showPointDetail(point, index + 1);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
    bool isLoading = false,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: isLoading
            ? SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(color == Colors.white ? const Color(0xFF2E7D32) : Colors.white),
                ),
              )
            : Icon(
                icon,
                color: color == Colors.white ? const Color(0xFF2E7D32) : Colors.white,
                size: 22,
              ),
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '${amount.toInt()}đ';
  }
}

/// ── Data model cho điểm giao hàng ──
class _DeliveryPoint {
  final String orderId;
  final String address;
  final String buyerName;
  final double totalAmount;
  final LatLng location;
  final double distanceFromPrev;

  _DeliveryPoint({
    required this.orderId,
    required this.address,
    required this.buyerName,
    required this.totalAmount,
    required this.location,
    this.distanceFromPrev = 0,
  });

  _DeliveryPoint copyWith({
    String? orderId,
    String? address,
    String? buyerName,
    double? totalAmount,
    LatLng? location,
    double? distanceFromPrev,
  }) {
    return _DeliveryPoint(
      orderId: orderId ?? this.orderId,
      address: address ?? this.address,
      buyerName: buyerName ?? this.buyerName,
      totalAmount: totalAmount ?? this.totalAmount,
      location: location ?? this.location,
      distanceFromPrev: distanceFromPrev ?? this.distanceFromPrev,
    );
  }
}

/// ── Custom painter cho mũi tên marker ──
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
