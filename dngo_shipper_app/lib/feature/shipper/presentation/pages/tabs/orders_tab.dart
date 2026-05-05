import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../core/utils/helpers.dart';
import '../order_detail_page.dart';
import '../../../../auth/presentation/pages/login_screen.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> with TickerProviderStateMixin {
  List<dynamic> _available = [];
  List<dynamic> _myOrders = [];
  bool _loadingAvail = true;
  bool _loadingMy = true;
  String? _availError;
  int _totalAvail = 0;
  int _totalMy = 0;
  final Set<String> _acceptingIds = {};

  // ─── Auto-polling ────────────────────────────────────────────
  Timer? _pollingTimer;
  Set<String> _knownOrderIds = {};

  int _newOrderCount = 0;
  String _statusFilter = 'all';
  String _dateFilter = 'all';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  late TabController _tabController;
  static const Duration _pollingInterval = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Pulse animation cho badge
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadAvailable();
    _loadMyOrders();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredMyOrders {
    var orders = List<dynamic>.from(_myOrders);
    if (_statusFilter != 'all') {
      final statuses = <String, List<String>>{
        'waiting': ['cho_shipper'],
        'delivering': ['dang_giao'],
        'done': ['da_giao', 'hoan_thanh'],
      }[_statusFilter] ?? [];
      orders = orders.where((o) => statuses.contains(o['tinh_trang_don_hang'])).toList();
    }
    if (_dateFilter != 'all') {
      final now = DateTime.now();
      orders = orders.where((o) {
        final dateStr = o['ngay_dat_hang']?.toString() ?? '';
        if (dateStr.isEmpty) return true;
        final dt = DateTime.tryParse(dateStr);
        if (dt == null) return true;
        if (_dateFilter == 'today') {
          return dt.year == now.year && dt.month == now.month && dt.day == now.day;
        }
        if (_dateFilter == 'week') return now.difference(dt).abs().inDays < 7;
        if (_dateFilter == 'month') return dt.year == now.year && dt.month == now.month;
        return true;
      }).toList();
    }
    return orders;
  }

  int _countWithStatus(List<String> statuses) =>
      _myOrders.where((o) => statuses.contains(o['tinh_trang_don_hang'])).length;

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
      debugPrint('🔄 [SHIPPER POLLING] Checking for new available orders...');
      await _checkNewAvailableOrders();
    });
    debugPrint('✅ [SHIPPER POLLING] Started (interval: ${_pollingInterval.inSeconds}s)');
  }

  Future<void> _checkNewAvailableOrders() async {
    try {
      final data = await ApiService.getAvailableOrders(page: 1, limit: 50);
      if (!mounted) return;
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      final items = rawItems.where((o) => o['hinh_thuc_thanh_toan'] != 'tien_mat').toList();
      final newIds = items
          .map((o) => (o['ma_don_hang'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      if (_knownOrderIds.isEmpty) {
        // Khoi tao - ghi nho ID hien tai, khong bao
        _knownOrderIds = newIds;
        return;
      }

      final brandNewIds = newIds.difference(_knownOrderIds);
      if (brandNewIds.isNotEmpty && mounted) {
        debugPrint('🆕 [SHIPPER POLLING] ${brandNewIds.length} new order(s) detected!');
        _knownOrderIds = newIds;
        setState(() {
          _available = items;
          _totalAvail = items.length;
          _newOrderCount = brandNewIds.length;
        });
        _showNewOrderBanner(brandNewIds.length);
      } else {
        _knownOrderIds = newIds;
      }
    } on UnauthorizedException {
      debugPrint('🔒 [SHIPPER POLLING] Token expired — redirecting to login');
      await _handleUnauthorized();
    } catch (e) {
      debugPrint('⚠️ [SHIPPER POLLING] Error: $e');
    }
  }

  void _showNewOrderBanner(int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00B40F), Color(0xFF00B40F)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00B40F).withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flash_on, color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Có $count đơn hàng mới!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Nhấn "Xem ngay" để tranh đơn',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  if (mounted) setState(() => _newOrderCount = 0);
                  _tabController.animateTo(0);
                },
                child: const Text('Xem ngay',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadAvailable() async {
    if (mounted) setState(() { _loadingAvail = true; _availError = null; });
    try {
      final data = await ApiService.getAvailableOrders(page: 1, limit: 50);
      if (mounted) {
        final rawItems = (data['items'] as List<dynamic>?) ?? [];
        final items = rawItems.where((o) => o['hinh_thuc_thanh_toan'] != 'tien_mat').toList();
        
        setState(() {
          _available = items;
          _totalAvail = items.length;
          _loadingAvail = false;
          _knownOrderIds = (_available)
              .map((o) => (o['ma_don_hang'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toSet();
          _newOrderCount = 0;
        });
      }
    } on UnauthorizedException {
      await _handleUnauthorized();
    } catch (e) {
      debugPrint('❌ [ORDERS] _loadAvailable error: $e');
      if (mounted) {
        setState(() {
          _loadingAvail = false;
          _availError = 'Lỗi: $e';
        });
      }
    }
  }

  Future<void> _loadMyOrders() async {
    setState(() => _loadingMy = true);
    try {
      final data = await ApiService.getMyOrders(
        page: 1, limit: 100,
        status: 'cho_shipper,dang_lay_hang,dang_giao,da_giao,hoan_thanh',
      );
      if (mounted) {
        setState(() {
          _myOrders = data['items'] ?? [];
          _totalMy = data['total'] ?? 0;
          _loadingMy = false;
        });
      }
    } on UnauthorizedException {
      await _handleUnauthorized();
    } catch (e) {
      if (mounted) setState(() => _loadingMy = false);
    }
  }

  Future<void> _handleUnauthorized() async {
    _pollingTimer?.cancel();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Giao cả chuyến: cập nhật dang_giao cho tất cả đơn trong consolidation
  Future<void> _startDeliveryForTrip(List<Map<String, dynamic>> ordersInGroup) async {
    final activeOrders = ordersInGroup.where((o) {
      final s = o['tinh_trang_don_hang'] ?? '';
      return s == 'cho_shipper' || s == 'dang_lay_hang';
    }).toList();

    if (activeOrders.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Giao cả chuyến?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bắt đầu giao ${activeOrders.length} đơn trong chuyến này?\n\nChỉ những đơn đã lấy đủ hàng mới chuyển được.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B40F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    int success = 0;
    final List<String> failed = [];

    await Future.wait(activeOrders.map((o) async {
      final orderId = o['ma_don_hang'] as String;
      try {
        await ApiService.updateOrderStatus(orderId, 'dang_giao');
        success++;
      } catch (e) {
        failed.add(orderId);
      }
    }));

    if (mounted) {
      if (failed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🚀 Đã bắt đầu giao $success đơn!', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF00B40F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ $success đơn giao được, ❌ ${failed.length} đơn chưa lấy đủ hàng', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
      _loadMyOrders();
      _loadAvailable();
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận nhận đơn', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn nhận đơn hàng $orderId không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Trở lại', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B40F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Nhận đơn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _acceptingIds.add(orderId));
    try {
      await ApiService.acceptOrder(orderId);
      if (mounted) {
        // Optimistic update
        setState(() {
          final idx = _available.indexWhere((o) => o['ma_don_hang'] == orderId);
          if (idx != -1) {
            final acceptedOrder = _available.removeAt(idx);
            _myOrders.insert(0, acceptedOrder);
            if (_totalAvail > 0) _totalAvail--;
            _totalMy++;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Nhận đơn thành công! Bắt đầu lấy hàng...', style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            backgroundColor: const Color(0xFF00B40F),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Navigate directly to OrderDetailPage to start the pickup flow
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: orderId)),
        );
        
        // Refresh after returning from detail page
        _loadAvailable();
        _loadMyOrders();
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(e.toString().replaceFirst('Exception: ', ''))),
            ]),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _acceptingIds.remove(orderId));
    }
  }

  void _showInAppMap(String address, double distanceKm) {
    final marketPos = const LatLng(16.035415, 108.243501);
    final deliveryPos = LatLng(16.035415 + (distanceKm * 0.002), 108.243501 - (distanceKm * 0.006));

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(ctx).size.width * 0.92,
            maxHeight: MediaQuery.of(ctx).size.height * 0.65,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF00B40F),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bản đồ định vị', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(initialCenter: marketPos, initialZoom: 13),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.dngo.shipper',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: marketPos, width: 40, height: 40,
                          child: Container(
                            decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            child: const Icon(Icons.store, color: Colors.white, size: 20),
                          ),
                        ),
                        Marker(
                          point: deliveryPos, width: 40, height: 40,
                          child: Container(
                            decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.route, color: Colors.blue.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quãng đường ước tính', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('${distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: const Color(0xFF00B40F), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black54,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.flash_on, size: 16), const SizedBox(width: 4), Text('Có sẵn ($_totalAvail)')])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.inventory, size: 16), const SizedBox(width: 4), Text('Đã nhận ($_totalMy)')])),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFF3F4F6),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableTab(),
                _buildMyOrdersTab(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 12, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text('Đơn hàng', style: TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          ),
          if (_newOrderCount > 0)
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on, color: Colors.black87, size: 13),
                    const SizedBox(width: 3),
                    Text('$_newOrderCount mới', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 12)),
                  ],
                ),
              ),
            ),
          IconButton(
            onPressed: () { _loadAvailable(); _loadMyOrders(); },
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569), size: 22),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTab() {
    if (_loadingAvail) return const Center(child: CircularProgressIndicator(color: Color(0xFF00B40F)));
    if (_availError != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_off_rounded, size: 72, color: Colors.orange.shade300),
        const SizedBox(height: 16),
        Text(_availError!, style: TextStyle(color: Colors.grey.shade700, fontSize: 15), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _loadAvailable,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Thử lại'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B40F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]));
    }
    if (_available.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Chưa có đơn mới', style: TextStyle(color: Colors.grey.shade600, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Hệ thống sẽ tự cập nhật khi có đơn', style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _loadAvailable, icon: const Icon(Icons.refresh), label: const Text('Tải lại'),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF00B40F), side: const BorderSide(color: Color(0xFF00B40F))),
        ),
      ]));
    }
    return RefreshIndicator(
      color: const Color(0xFF00B40F),
      onRefresh: _loadAvailable,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _available.length,
        itemBuilder: (ctx, i) => _buildAvailOrderCard(_available[i]),
      ),
    );
  }

  Widget _buildMyOrdersTab() {
    if (_loadingMy) return const Center(child: CircularProgressIndicator(color: Color(0xFF00B40F)));

    final filtered = _filteredMyOrders;

    final Map<String, List<Map<String, dynamic>>> groupedOrders = {};
    for (var order in filtered) {
      final gomDon = order['gom_don'] as Map<String, dynamic>?;
      final cId = gomDon?['ma_gom_don'] ?? 'Đơn lẻ ${order['ma_don_hang']}';
      groupedOrders.putIfAbsent(cId, () => []).add(order as Map<String, dynamic>);
    }

    return Column(
      children: [
        // Status filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statusChip('all', 'Tất cả', _myOrders.length, Colors.grey.shade600),
                const SizedBox(width: 8),
                _statusChip('waiting', 'Chờ lấy hàng', _countWithStatus(['cho_shipper']), Colors.orange),
                const SizedBox(width: 8),
                _statusChip('delivering', 'Đang giao', _countWithStatus(['dang_giao']), Colors.blue),
                const SizedBox(width: 8),
                _statusChip('done', 'Hoàn tất', _countWithStatus(['da_giao', 'hoan_thanh']), Colors.green),
              ],
            ),
          ),
        ),
        // Date filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _dateChip('all', 'Mọi ngày'),
                const SizedBox(width: 8),
                _dateChip('today', 'Hôm nay'),
                const SizedBox(width: 8),
                _dateChip('week', 'Tuần này'),
                const SizedBox(width: 8),
                _dateChip('month', 'Tháng này'),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        // Order list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      _myOrders.isEmpty
                          ? Icons.local_shipping_outlined
                          : Icons.filter_list_off_rounded,
                      size: 80, color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _myOrders.isEmpty ? 'Chưa có chuyến' : 'Không có đơn phù hợp',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _myOrders.isEmpty
                          ? 'Qua tab "Có sẵn" để tranh đơn nhé!'
                          : 'Thử thay đổi bộ lọc',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ]),
                )
              : RefreshIndicator(
                  color: const Color(0xFF00B40F),
                  onRefresh: _loadMyOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groupedOrders.keys.length,
                    itemBuilder: (ctx, i) {
                      final cId = groupedOrders.keys.elementAt(i);
                      return _buildConsolidationCard(cId, groupedOrders[cId]!);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _statusChip(String value, String label, int count, Color color) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          )),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : color,
              )),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _dateChip(String value, String label) {
    final isSelected = _dateFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _dateFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00B40F).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF00B40F) : Colors.grey.shade300,
          ),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: isSelected ? const Color(0xFF00B40F) : Colors.grey.shade600,
        )),
      ),
    );
  }

  Widget _buildConsolidationCard(String consolidationId, List<Map<String, dynamic>> ordersInGroup) {
    bool allDelivered = ordersInGroup.every((o) => o['tinh_trang_don_hang'] == 'da_giao' || o['tinh_trang_don_hang'] == 'hoan_thanh');
    final activeOrders = ordersInGroup.where((o) {
      final s = o['tinh_trang_don_hang'] ?? '';
      return s == 'cho_shipper' || s == 'dang_lay_hang';
    }).toList();
    final canStartTrip = !allDelivered && activeOrders.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: allDelivered ? Colors.green.withValues(alpha: 0.3) : const Color(0xFF00B40F).withValues(alpha: 0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header chuyến đi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: allDelivered ? Colors.green.withValues(alpha: 0.1) : const Color(0xFF00B40F).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.route, color: allDelivered ? Colors.green : const Color(0xFF00B40F)),
                    const SizedBox(width: 8),
                    Text(
                      consolidationId.startsWith('Đơn lẻ') ? 'Đơn hàng lẻ' : 'Chuyến đi $consolidationId',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: allDelivered ? Colors.green.shade700 : const Color(0xFF00B40F)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '${ordersInGroup.length} Đơn',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: allDelivered ? Colors.green.shade700 : const Color(0xFF00B40F)),
                  ),
                ),
              ],
            ),
          ),
          
          // Các đơn hàng bên trong
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              children: ordersInGroup.map((o) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildMyOrderCard(o, isInsideGroup: true),
                );
              }).toList(),
            ),
          ),

          // Nút Giao cả chuyến
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Tooltip(
              message: canStartTrip ? '' : 'Cần lấy hàng đủ từ tất cả quầy trước khi giao',
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: canStartTrip ? () => _startDeliveryForTrip(ordersInGroup) : null,
                  icon: Icon(Icons.local_shipping_rounded, size: 18, color: canStartTrip ? Colors.white : Colors.grey[400]),
                  label: Text(
                    'GIAO CẢ CHUYẾN (${activeOrders.length} đơn)',
                    style: TextStyle(color: canStartTrip ? Colors.white : Colors.grey[400], fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.3),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canStartTrip ? const Color(0xFF00B40F) : Colors.grey[200],
                    disabledBackgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: canStartTrip ? 3 : 0,
                    shadowColor: const Color(0xFF00B40F).withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteTimeline(String storeName, AddressHelper addr, {VoidCallback? onMapPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dots
          Column(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.orange.shade500, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
              Container(width: 2, height: 40, color: Colors.grey.shade300),
              Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF00B40F), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
            ],
          ),
          const SizedBox(width: 16),
          // Store and Address Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 6),
                    Expanded(child: Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                  ],
                ),
                const SizedBox(height: 24), // spacing logic for timeline
                // Delivery Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Expanded(child: Text(addr.address.isNotEmpty ? addr.address : 'Địa chỉ giấu kín', style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    if (onMapPressed != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onMapPressed,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.map, size: 20, color: Colors.indigo),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailOrderCard(Map<String, dynamic> order) {
    final addr = AddressHelper.parse(order['dia_chi_giao_hang'] ?? '');
    final payment = order['thanh_toan'] ?? {};
    final distance = order['distance_km'];
    final orderId = order['ma_don_hang'] ?? '';
    final isAccepting = _acceptingIds.contains(orderId);
    final storeName = order['ten_cho']?.toString().isNotEmpty == true ? order['ten_cho'] : 'Chợ Bắc Mỹ An';
    final products = (order['san_pham'] as List<dynamic>?) ?? [];
    final itemCount = products.length;
    final stallCount = products.map((p) => p['ten_gian_hang']).toSet().length;
    // Khung giờ giao hàng
    final khungGio = order['khung_gio'] as Map<String, dynamic>?;
    String? gioGiao;
    if (khungGio != null) {
      final bat = (khungGio['gio_bat_dau'] ?? '').toString();
      final ket = (khungGio['gio_ket_thuc'] ?? '').toString();
      final batStr = bat.length >= 5 ? bat.substring(0, 5) : bat;
      final ketStr = ket.length >= 5 ? ket.substring(0, 5) : ket;
      if (batStr != '00:00' || ketStr != '00:00') {
        gioGiao = '$batStr–$ketStr';
      }
    }

    return GestureDetector(
      onTap: () async {
        await _showAvailableOrderDetail(order);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text('#$orderId', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange.shade800, fontSize: 13, letterSpacing: 0.5)),
              ),
              if (gioGiao != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.access_time_rounded, size: 13, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(gioGiao, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.blue.shade700)),
                  ]),
                ),
              if (itemCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text('$itemCount món · $stallCount quầy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green.shade700)),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    distance != null && distance > 0
                        ? '${distance.toStringAsFixed(1)} km'
                        : '-- km',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildRouteTimeline(
            storeName, 
            addr, 
            onMapPressed: () => _showInAppMap(addr.address.isNotEmpty ? addr.address : (order['dia_chi_giao_hang'] ?? ''), distance != null ? (distance as num).toDouble() : 2.5)
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          // Payment row
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  Icon(payment['hinh_thuc_thanh_toan'] == 'tien_mat' ? Icons.payments : Icons.credit_card, size: 14, color: Colors.grey.shade700),
                  const SizedBox(width: 6),
                  Text(payment['hinh_thuc_thanh_toan'] == 'tien_mat' ? 'Tiền mặt' : 'CK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                ],
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Tổng thu', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(formatVND(order['tong_tien']), style: const TextStyle(color: Color(0xFF00B40F), fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            )
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: isAccepting ? null : () => _acceptOrder(orderId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B40F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: const Color(0xFF00B40F).withValues(alpha: 0.4),
              ),
              child: isAccepting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : const Text('NHẬN ĐƠN NGAY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildMyOrderCard(Map<String, dynamic> order, {bool isInsideGroup = false}) {
    final addr = AddressHelper.parse(order['dia_chi_giao_hang'] ?? '');
    final status = order['tinh_trang_don_hang'] ?? '';
    final isDelivered = status == 'da_giao';
    final orderId = order['ma_don_hang'] ?? '';
    final distance = order['distance_km'];
    final storeName = order['ten_cho']?.toString().isNotEmpty == true ? order['ten_cho'] : 'Chợ Bắc Mỹ An';
    final khungGio = order['khung_gio'] as Map<String, dynamic>?;
    String? gioGiao;
    if (khungGio != null) {
      final bat = (khungGio['gio_bat_dau'] ?? '').toString();
      final ket = (khungGio['gio_ket_thuc'] ?? '').toString();
      final batStr = bat.length >= 5 ? bat.substring(0, 5) : bat;
      final ketStr = ket.length >= 5 ? ket.substring(0, 5) : ket;
      if (batStr != '00:00' || ketStr != '00:00') {
        gioGiao = '$batStr–$ketStr';
      }
    }

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'da_giao':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'dang_giao':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        break;
      case 'dang_lay_hang':
        statusColor = Colors.orange;
        statusIcon = Icons.inventory;
        break;
      case 'giao_that_bai':
      case 'da_huy':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.pending;
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: orderId)));
        _loadMyOrders();
        _loadAvailable();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isInsideGroup ? 12 : 20),
          border: !isInsideGroup 
              ? (!isDelivered ? Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5) : null)
              : Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: isInsideGroup ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 6),
                    Text(statusLabel(status).toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                  ],
                ),
              ),
              if (gioGiao != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.access_time_rounded, size: 13, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(gioGiao, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.blue.shade700)),
                  ]),
                ),
              Text(formatVND(order['tong_tien']), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          _buildRouteTimeline(
            storeName, 
            addr,
            onMapPressed: () => _showInAppMap(addr.address.isNotEmpty ? addr.address : (order['dia_chi_giao_hang'] ?? ''), distance != null ? (distance as num).toDouble() : 2.5)
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: orderId)));
                _loadMyOrders();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDelivered ? Colors.grey.shade100 : statusColor,
                foregroundColor: isDelivered ? Colors.black87 : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: isDelivered ? 0 : 4,
                shadowColor: statusColor.withValues(alpha: 0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isDelivered ? 'XEM CHI TIẾT' : 'TIẾP TỤC CHUYẾN', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
                  const SizedBox(width: 8),
                  Icon(isDelivered ? Icons.visibility : Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _showAvailableOrderDetail(Map<String, dynamic> order) async {
    final orderId = order['ma_don_hang'] ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: FutureBuilder<Map<String, dynamic>>(
            future: ApiService.getOrderDetails(orderId),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF00B40F)));
              }
              if (snap.hasError) {
                return Center(child: Text('Lỗi: ${snap.error}'));
              }
              final data = snap.data?['data'] ?? {};
              final products = (data['san_pham'] as List<dynamic>?) ?? [];
              final addr = AddressHelper.parse(data['dia_chi_giao_hang'] ?? '');

              return ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(child: Container(width: 50, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)))),
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle), child: const Icon(Icons.flash_on, color: Colors.orange)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cơ hội nhận đơn', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text('#$orderId', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Route Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: _buildRouteTimeline(
                      order['ten_cho'] ?? 'Chợ Bắc Mỹ An', 
                      addr,
                      onMapPressed: () => _showInAppMap(addr.address.isNotEmpty ? addr.address : (data['dia_chi_giao_hang'] ?? ''), data['distance_km'] != null ? (data['distance_km'] as num).toDouble() : 2.5)
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Products
                  const Text('Danh sách mua hộ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...products.map((p) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${p['so_luong']}x', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00B40F))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p['ten_nguyen_lieu'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${formatVND(p['don_gia'])} • ${p['ten_gian_hang'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ])),
                      Text(formatVND(p['thanh_tien']), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                  )),
                  const Divider(height: 32),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Tổng thu từ khách', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(formatVND(data['tong_tien']), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF00B40F))),
                  ]),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _acceptOrder(orderId);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B40F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      child: const Text('NHẬN ĐƠN NGAY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
