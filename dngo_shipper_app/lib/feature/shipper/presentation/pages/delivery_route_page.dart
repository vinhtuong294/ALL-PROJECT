import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/helpers.dart';
import 'order_detail_page.dart';

// ── Road polyline via OSRM ───────────────────────────────────────────────────

Future<List<LatLng>> fetchRoadPolyline(List<LatLng> waypoints) async {
  if (waypoints.length < 2) return waypoints;
  final coords = waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
  try {
    final resp = await http
        .get(Uri.parse(
            'http://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson'))
        .timeout(const Duration(seconds: 10));
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return waypoints;
    final coordsList = (routes[0] as Map<String, dynamic>)['geometry']
        ['coordinates'] as List<dynamic>;
    return coordsList
        .map((c) =>
            LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
  } catch (_) {
    return waypoints;
  }
}

// ── Data models ──────────────────────────────────────────────────────────────

class TripData {
  final String consolidationId;
  final List<Map<String, dynamic>> orders;
  final List<RouteStop>? optimizedRoute;
  final double? totalKm;
  final LatLng? marketLatLng;
  final List<LatLng> stopLatLngs;
  final List<LatLng>? roadPolyline;
  final bool isLoadingMap;

  const TripData({
    required this.consolidationId,
    required this.orders,
    this.optimizedRoute,
    this.totalKm,
    this.marketLatLng,
    this.stopLatLngs = const [],
    this.roadPolyline,
    this.isLoadingMap = false,
  });
}

class RouteStop {
  final String orderId;
  final String address;
  final double distanceFromPrev;

  const RouteStop({
    required this.orderId,
    required this.address,
    required this.distanceFromPrev,
  });
}

// ── DeliveryRoutePage (list) ─────────────────────────────────────────────────

class DeliveryRoutePage extends StatefulWidget {
  const DeliveryRoutePage({super.key});

  @override
  State<DeliveryRoutePage> createState() => _DeliveryRoutePageState();
}

class _DeliveryRoutePageState extends State<DeliveryRoutePage> {
  Map<String, TripData> _trips = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() { _loading = true; _trips = {}; });
    try {
      final results = await Future.wait([
        ApiService.getMyOrders(page: 1, limit: 100, status: 'cho_shipper'),
        ApiService.getMyOrders(page: 1, limit: 100, status: 'dang_giao'),
      ]);

      final allOrders = <Map<String, dynamic>>[
        for (final r in results)
          for (final o in (r['items'] as List<dynamic>? ?? []))
            o as Map<String, dynamic>,
      ];

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final o in allOrders) {
        final cId =
            (o['gom_don'] as Map<String, dynamic>?)?['ma_gom_don'] ??
                'don_le_${o['ma_don_hang']}';
        grouped.putIfAbsent(cId, () => []).add(o);
      }

      if (mounted) setState(() => _loading = false);

      for (final entry in grouped.entries) {
        if (!mounted) break;
        final cId = entry.key;
        final orders = entry.value;

        // Hiện card ngay với trạng thái loading map
        setState(() {
          _trips[cId] =
              TripData(consolidationId: cId, orders: orders, isLoadingMap: true);
        });

        // Lấy tọa độ + thứ tự tối ưu từ optimize-route (backend dùng GraphHopper)
        LatLng? marketLatLng;
        List<LatLng> stopLatLngs = [];
        List<RouteStop>? optimized;
        double? totalKm;

        if (!cId.startsWith('don_le_')) {
          try {
            final res = await ApiService.optimizeRoute(cId)
                .timeout(const Duration(seconds: 60));
            final data = res['data'] as Map<String, dynamic>? ?? {};
            totalKm = (data['total_distance_km'] as num?)?.toDouble();

            final mLat = (data['market_lat'] as num?)?.toDouble();
            final mLng = (data['market_lng'] as num?)?.toDouble();
            if (mLat != null && mLng != null) {
              marketLatLng = LatLng(mLat, mLng);
            }

            final raw = data['optimized_route'] as List<dynamic>? ?? [];
            optimized = raw.map((s) => RouteStop(
              orderId: s['order_id'] as String,
              address: s['address'] as String? ?? '',
              distanceFromPrev: (s['distance_from_prev_km'] as num?)?.toDouble() ?? 0,
            )).toList();

            stopLatLngs = raw
                .where((s) => s['lat'] != null && s['lng'] != null)
                .map((s) => LatLng((s['lat'] as num).toDouble(), (s['lng'] as num).toDouble()))
                .toList();
          } catch (_) {}
        }

        List<LatLng>? roadPolyline;
        if (marketLatLng != null && stopLatLngs.isNotEmpty) {
          roadPolyline = await fetchRoadPolyline([marketLatLng, ...stopLatLngs]);
        }

        if (mounted) {
          setState(() {
            _trips[cId] = TripData(
              consolidationId: cId,
              orders: orders,
              optimizedRoute: optimized,
              totalKm: totalKm,
              marketLatLng: marketLatLng,
              stopLatLngs: stopLatLngs,
              roadPolyline: roadPolyline,
              isLoadingMap: false,
            );
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Tuyến giao hàng',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2F8000)))
          : _trips.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: const Color(0xFF2F8000),
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _trips.values.map(_buildTripCard).toList(),
                  ),
                ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.route, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Chưa có chuyến đang thực hiện',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Hãy nhận đơn hàng trong tab "Đơn hàng"',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
      );

  String? _tripTimeLabel(TripData trip) {
    if (trip.orders.isEmpty) return null;
    final o = trip.orders.first;
    final slot = o['khung_gio'] as Map<String, dynamic>?;
    final slotId = slot?['time_slot_id'] as String?;
    final start = slot?['gio_bat_dau'] as String?;
    final end = slot?['gio_ket_thuc'] as String?;
    final rawDate = o['thoi_gian_giao_hang'] as String?;

    DateTime? dt;
    if (rawDate != null) {
      try { dt = DateTime.parse(rawDate); } catch (_) {}
    }

    // KG00 hoặc 00:00:00 = không có khung giờ hợp lệ → dùng thoi_gian_giao_hang
    final hasValidSlot = slotId != null &&
        slotId != 'KG00' &&
        start != null &&
        start != '00:00:00';

    if (dt == null && !hasValidSlot) return null;

    final dateStr = dt != null
        ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}'
        : '';

    String timeStr;
    if (hasValidSlot) {
      timeStr = '${_fmtTime(start!)} – ${_fmtTime(end ?? '')}';
    } else if (dt != null) {
      timeStr =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return dateStr.isEmpty ? null : dateStr;
    }

    return '$dateStr  $timeStr';
  }

  String _fmtTime(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return t;
    return '${parts[0]}:${parts[1]}';
  }

  Widget _buildTripCard(TripData trip) {
    final isLone = trip.consolidationId.startsWith('don_le_');
    final allPoints = trip.marketLatLng != null
        ? [trip.marketLatLng!, ...trip.stopLatLngs]
        : <LatLng>[];
    final hasMap = allPoints.length >= 2;

    return GestureDetector(
      onTap: () {
        if (!trip.isLoadingMap) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TripDetailPage(
                    trip: trip, onRefresh: _loadData)),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            color: const Color(0xFF2F8000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.route, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isLone ? 'Đơn lẻ' : 'Chuyến ${trip.consolidationId}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                  if (trip.totalKm != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.straighten,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text('${trip.totalKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ]),
                    ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('${trip.orders.length} đơn',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ]),
                if (_tripTimeLabel(trip) != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      _tripTimeLabel(trip)!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ]),
                ],
              ],
            ),
          ),

          // Mini map preview
          _buildMiniMap(trip, allPoints, hasMap),

          // Footer: địa chỉ đầu tiên + nút xem chi tiết
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text('Lấy hàng tại chợ',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500)),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Color(0xFF2F8000),
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${trip.orders.length} điểm giao hàng',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500),
                        ),
                      ]),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: trip.isLoadingMap
                      ? Colors.grey.shade200
                      : const Color(0xFF2F8000),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    trip.isLoadingMap ? 'Đang tải...' : 'Xem chi tiết',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: trip.isLoadingMap
                            ? Colors.grey
                            : Colors.white),
                  ),
                  if (!trip.isLoadingMap) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward,
                        size: 14, color: Colors.white),
                  ],
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildMiniMap(TripData trip, List<LatLng> allPoints, bool hasMap) {
    if (trip.isLoadingMap) {
      return Container(
        height: 140,
        color: Colors.grey.shade100,
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(
                color: Color(0xFF2F8000), strokeWidth: 2.5),
            SizedBox(height: 8),
            Text('Đang tải bản đồ...',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
      );
    }

    if (!hasMap) {
      return Container(
        height: 80,
        color: Colors.grey.shade100,
        child: Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.location_off, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Text('Không geocode được địa chỉ',
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ]),
        ),
      );
    }

    final bounds = LatLngBounds.fromPoints(allPoints);
    return SizedBox(
      height: 160,
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit:
              CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32)),
          interactionOptions:
              const InteractionOptions(flags: InteractiveFlag.none),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.dngo.shipper',
          ),
          if (trip.roadPolyline != null && trip.roadPolyline!.length > 1)
            PolylineLayer(polylines: [
              Polyline(
                  points: trip.roadPolyline!,
                  strokeWidth: 3.5,
                  color: const Color(0xFF2F8000)),
            ]),
          MarkerLayer(markers: [
            Marker(
              point: trip.marketLatLng!,
              width: 28, height: 28,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.storefront, color: Colors.white, size: 13),
              ),
            ),
            ...trip.stopLatLngs.asMap().entries.map((e) => Marker(
                  point: e.value,
                  width: 24, height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F8000),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text('${e.key + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9)),
                    ),
                  ),
                )),
          ]),
        ],
      ),
    );
  }
}

// ── TripDetailPage ────────────────────────────────────────────────────────────

class TripDetailPage extends StatefulWidget {
  final TripData trip;
  final VoidCallback? onRefresh;

  const TripDetailPage({super.key, required this.trip, this.onRefresh});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  late TripData _trip;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  List<Map<String, dynamic>> get _orderedOrders {
    if (_trip.optimizedRoute == null || _trip.optimizedRoute!.isEmpty) {
      return _trip.orders;
    }
    final idToOrder = {
      for (final o in _trip.orders) o['ma_don_hang'] as String: o
    };
    final ordered = _trip.optimizedRoute!
        .map((s) => idToOrder[s.orderId])
        .whereType<Map<String, dynamic>>()
        .toList();
    for (final o in _trip.orders) {
      if (!ordered.contains(o)) ordered.add(o);
    }
    return ordered;
  }

  void _flyToStop(LatLng point) {
    _mapController.move(point, 15);
  }

  @override
  Widget build(BuildContext context) {
    final isLone = _trip.consolidationId.startsWith('don_le_');
    final hasMap =
        _trip.marketLatLng != null && _trip.stopLatLngs.isNotEmpty;
    final allPoints = hasMap
        ? [_trip.marketLatLng!, ..._trip.stopLatLngs]
        : <LatLng>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar với bản đồ ──────────────────────────────────
          SliverAppBar(
            expandedHeight: hasMap ? 340 : 0,
            pinned: true,
            backgroundColor: const Color(0xFF2F8000),
            foregroundColor: Colors.white,
            surfaceTintColor: const Color(0xFF2F8000),
            title: Text(
              isLone ? 'Đơn lẻ' : 'Chuyến ${_trip.consolidationId}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
            actions: [
              if (hasMap)
                IconButton(
                  icon: const Icon(Icons.center_focus_strong),
                  tooltip: 'Về trung tâm',
                  onPressed: () {
                    if (allPoints.length >= 2) {
                      _mapController.fitCamera(CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(allPoints),
                        padding: const EdgeInsets.all(48),
                      ));
                    }
                  },
                ),
            ],
            flexibleSpace: hasMap
                ? FlexibleSpaceBar(
                    background: _buildDetailMap(allPoints),
                  )
                : null,
          ),

          // ── Stats bar ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(Icons.local_shipping, '${_trip.orders.length}', 'Đơn hàng', Colors.blue),
                  Container(width: 1, height: 36, color: Colors.grey.shade200),
                  _statItem(Icons.straighten, _trip.totalKm != null ? '${_trip.totalKm!.toStringAsFixed(1)} km' : '--', 'Quãng đường', Colors.orange),
                  Container(width: 1, height: 36, color: Colors.grey.shade200),
                  _statItem(Icons.location_on, '${_trip.stopLatLngs.length}', 'Điểm giao', const Color(0xFF2F8000)),
                ],
              ),
            ),
          ),

          // ── Divider ────────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Tiêu đề danh sách điểm ────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(children: [
                const Icon(Icons.format_list_numbered, size: 18, color: Color(0xFF2F8000)),
                const SizedBox(width: 8),
                const Text('Tuyến đường', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (_trip.optimizedRoute != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.auto_awesome, size: 11, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text('Đã tối ưu', style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
              ]),
            ),
          ),

          // ── Xuất phát ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: _buildDetailStop(
                icon: Icons.storefront,
                iconColor: Colors.orange.shade700,
                bgColor: Colors.orange.shade50,
                index: 0,
                isStart: true,
                isLast: false,
                title: 'Xuất phát — Lấy hàng tại chợ',
                subtitle: _trip.orders.isNotEmpty
                    ? (_trip.orders.first['ten_cho'] as String? ?? '')
                    : '',
                onTap: _trip.marketLatLng != null
                    ? () => _flyToStop(_trip.marketLatLng!)
                    : null,
              ),
            ),
          ),

          // ── Từng điểm giao ────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, idx) {
                final order = _orderedOrders[idx];
                final addr =
                    AddressHelper.parse(order['dia_chi_giao_hang'] ?? '');
                final status = order['tinh_trang_don_hang'] ?? '';
                final isDone =
                    status == 'da_giao' || status == 'hoan_thanh';
                final stopLatLng = idx < _trip.stopLatLngs.length
                    ? _trip.stopLatLngs[idx]
                    : null;
                double? distKm;
                if (_trip.optimizedRoute != null &&
                    idx < _trip.optimizedRoute!.length) {
                  distKm = _trip.optimizedRoute![idx].distanceFromPrev;
                }

                return Container(
                  color: Colors.white,
                  child: _buildDetailStop(
                    icon: isDone ? Icons.check_circle : Icons.location_on,
                    iconColor: isDone ? Colors.green : const Color(0xFF2F8000),
                    bgColor: isDone ? Colors.green.shade50 : Colors.green.shade50,
                    index: idx + 1,
                    isStart: false,
                    isLast: idx == _orderedOrders.length - 1,
                    title: addr.address.isNotEmpty
                        ? addr.address
                        : (order['dia_chi_giao_hang'] ?? ''),
                    subtitle:
                        '${statusLabel(status)}  •  ${formatVND(order['tong_tien'])}',
                    badge: distKm != null
                        ? '+${distKm.toStringAsFixed(1)} km'
                        : null,
                    isDone: isDone,
                    onTap: () async {
                      if (stopLatLng != null) _flyToStop(stopLatLng);
                      await Navigator.push(
                          ctx,
                          MaterialPageRoute(
                              builder: (_) => OrderDetailPage(
                                  orderId: order['ma_don_hang'])));
                      widget.onRefresh?.call();
                    },
                  ),
                );
              },
              childCount: _orderedOrders.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildDetailMap(List<LatLng> allPoints) {
    final bounds = LatLngBounds.fromPoints(allPoints);
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCameraFit:
                CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(56)),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.dngo.shipper',
            ),
            if (_trip.roadPolyline != null && _trip.roadPolyline!.length > 1)
              PolylineLayer(polylines: [
                Polyline(
                    points: _trip.roadPolyline!,
                    strokeWidth: 5,
                    color: const Color(0xFF2F8000)),
              ]),
            MarkerLayer(markers: [
              Marker(
                point: _trip.marketLatLng!,
                width: 44, height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                  ),
                  child: const Icon(Icons.storefront, color: Colors.white, size: 22),
                ),
              ),
              ..._trip.stopLatLngs.asMap().entries.map((e) => Marker(
                    point: e.value,
                    width: 38, height: 38,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F8000),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5)],
                      ),
                      child: Center(
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                    ),
                  )),
            ]),
          ],
        ),
        // Gradient overlay phía trên để chữ AppBar dễ đọc hơn
        Positioned(
          top: 0, left: 0, right: 0,
          height: 110,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailStop({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required int index,
    required bool isStart,
    required bool isLast,
    required String title,
    required String subtitle,
    String? badge,
    bool isDone = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Timeline
            SizedBox(
              width: 40,
              child: Column(children: [
                const SizedBox(height: 16),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor, width: 2),
                  ),
                  child: isStart
                      ? Icon(icon, color: iconColor, size: 18)
                      : Center(
                          child: Text('$index',
                              style: TextStyle(
                                  color: iconColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14))),
                ),
                if (!isLast)
                  Expanded(
                      child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.grey.shade200)),
              ]),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDone ? Colors.grey : Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(badge,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    Expanded(
                      child: Text(subtitle,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ),
                    if (!isStart && onTap != null)
                      Icon(Icons.chevron_right,
                          size: 18, color: Colors.grey.shade400),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
    ]);
  }
}
