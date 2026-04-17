import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../core/services/auth_storage.dart';
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
  int _totalAvail = 0;
  int _totalMy = 0;
  Set<String> _acceptingIds = {};

  // ─── Auto-polling ────────────────────────────────────────────
  Timer? _pollingTimer;
  Set<String> _knownOrderIds = {};
  bool _hasNewOrders = false;
  int _newOrderCount = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  late TabController _tabController;

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

    _loadAvailable(isInitial: true);
    _loadMyOrders();

    // Bắt đầu polling mỗi 10 giây
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _pollNewOrders();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Poll silent — không show loading spinner
  Future<void> _pollNewOrders() async {
    if (!mounted) return;
    try {
      final data = await ApiService.getAvailableOrders(page: 1, limit: 50);
      final items = (data['items'] ?? []) as List<dynamic>;
      final newIds = items.map((o) => o['ma_don_hang']?.toString() ?? '').toSet();

      if (_knownOrderIds.isEmpty) {
        _knownOrderIds = newIds;
        return;
      }

      final brandNew = newIds.difference(_knownOrderIds);
      if (brandNew.isNotEmpty && mounted) {
        setState(() {
          _available = items;
          _totalAvail = data['total'] ?? items.length;
          _hasNewOrders = true;
          _newOrderCount = brandNew.length;
          _knownOrderIds = newIds;
        });
        _showNewOrderAlert(brandNew.length);
      } else {
        _knownOrderIds = newIds;
        if (mounted) {
          setState(() {
            _available = items;
            _totalAvail = data['total'] ?? items.length;
          });
        }
      }
    } on UnauthorizedException {
      _pollingTimer?.cancel(); // Dừng polling khi token hết hạn
      await _handleUnauthorized();
    } catch (_) {
      // Silent fail
    }
  }

  void _showNewOrderAlert(int count) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _tabController.animateTo(0);
            setState(() { _hasNewOrders = false; _newOrderCount = 0; });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2F8000)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2F8000).withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        count == 1 ? '🔔 Có đơn mới!' : '🔔 $count đơn hàng mới!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Nhấn để xem ngay →',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  /// Xử lí khi token hết hạn: xóa token + chuyển về Login
  Future<void> _handleUnauthorized() async {
    await AuthStorage.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.lock_outline, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'),
        ]),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _loadAvailable({bool isInitial = false}) async {
    setState(() => _loadingAvail = true);
    try {
      final data = await ApiService.getAvailableOrders(page: 1, limit: 50);
      if (mounted) {
        final items = (data['items'] ?? []) as List<dynamic>;
        final ids = items.map((o) => o['ma_don_hang']?.toString() ?? '').toSet();
        setState(() {
          _available = items;
          _totalAvail = data['total'] ?? 0;
          _loadingAvail = false;
        });
        if (isInitial || _knownOrderIds.isEmpty) {
          _knownOrderIds = ids;
        }
        if (!isInitial) {
          setState(() { _hasNewOrders = false; _newOrderCount = 0; });
          _knownOrderIds = ids;
        }
      }
    } on UnauthorizedException {
      await _handleUnauthorized();
    } catch (e, stackTrace) {
      print('Load Available Error: $e');
      print('Stacktrace: $stackTrace');
      if (mounted) setState(() => _loadingAvail = false);
    }
  }

  Future<void> _loadMyOrders() async {
    setState(() => _loadingMy = true);
    try {
      final data = await ApiService.getMyOrders(page: 1, limit: 50);
      if (mounted) setState(() {
        _myOrders = data['items'] ?? [];
        _totalMy = data['total'] ?? 0;
        _loadingMy = false;
      });
    } on UnauthorizedException {
      await _handleUnauthorized();
    } catch (e) {
      if (mounted) setState(() => _loadingMy = false);
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận nhận đơn', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn bắt đầu giao đơn hàng $orderId không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Trở lại', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F8000), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
              Text('Nhận đơn thành công!', style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            backgroundColor: const Color(0xFF2F8000),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        
        // Vẫn gọi lại API để đồng bộ dữ liệu chuẩn nhất từ Server
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
        child: SizedBox(
          width: 500,
          height: 480,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF2F8000),
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
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: marketPos, zoom: 13),
                  markers: {
                    Marker(
                      markerId: const MarkerId('market'),
                      position: marketPos,
                      infoWindow: const InfoWindow(title: 'Chợ Bắc Mỹ An', snippet: 'Điểm lấy hàng'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                    ),
                    Marker(
                      markerId: const MarkerId('delivery'),
                      position: deliveryPos,
                      infoWindow: InfoWindow(title: 'Giao đến', snippet: address),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                  },
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
              indicator: BoxDecoration(color: const Color(0xFF2F8000), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]),
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
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20, right: 20, bottom: 20,
      ),
      color: const Color(0xFF2F8000),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Đơn hàng', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              if (_hasNewOrders)
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$_newOrderCount đơn mới!',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          GestureDetector(
            onTap: () {
              _loadAvailable();
              _loadMyOrders();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTab() {
    if (_loadingAvail) return const Center(child: CircularProgressIndicator(color: Color(0xFF2F8000)));
    if (_available.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Trống', style: TextStyle(color: Colors.grey.shade600, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Không có đơn hàng nào ở lúc này', style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _loadAvailable, icon: const Icon(Icons.refresh), label: const Text('Tải lại trạng thái'),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2F8000), side: const BorderSide(color: Color(0xFF2F8000))),
        ),
      ]));
    }
    return RefreshIndicator(
      color: const Color(0xFF2F8000),
      onRefresh: _loadAvailable,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _available.length,
        itemBuilder: (ctx, i) => _buildAvailOrderCard(_available[i]),
      ),
    );
  }

  Widget _buildMyOrdersTab() {
    if (_loadingMy) return const Center(child: CircularProgressIndicator(color: Color(0xFF2F8000)));
    if (_myOrders.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Chưa có chuyến', style: TextStyle(color: Colors.grey.shade600, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Qua tab "Có sẵn" để tranh đơn nhé!', style: TextStyle(color: Colors.grey, fontSize: 14)),
      ]));
    }
    return RefreshIndicator(
      color: const Color(0xFF2F8000),
      onRefresh: _loadMyOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myOrders.length,
        itemBuilder: (ctx, i) => _buildMyOrderCard(_myOrders[i]),
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
              Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF2F8000), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
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
    final buyer = order['nguoi_mua'] ?? {};
    final payment = order['thanh_toan'] ?? {};
    final distance = order['distance_km'];
    final orderId = order['ma_don_hang'] ?? '';
    final isAccepting = _acceptingIds.contains(orderId);
    final storeName = order['ten_cho']?.toString().isNotEmpty == true ? order['ten_cho'] : 'Chợ Bắc Mỹ An';

    return GestureDetector(
      onTap: () async {
        await _showAvailableOrderDetail(order);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text('#$orderId', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange.shade800, fontSize: 13, letterSpacing: 0.5)),
            ),
            Row(
              children: [
                const Icon(Icons.route, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${(distance != null ? (distance as num) : 0).toStringAsFixed(1)} KM', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            )
          ]),
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
                Text(formatVND(order['tong_tien']), style: const TextStyle(color: Color(0xFF2F8000), fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            )
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: isAccepting ? null : () => _acceptOrder(orderId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F8000),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: const Color(0xFF2F8000).withValues(alpha: 0.4),
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

  Widget _buildMyOrderCard(Map<String, dynamic> order) {
    final addr = AddressHelper.parse(order['dia_chi_giao_hang'] ?? '');
    final status = order['tinh_trang_don_hang'] ?? '';
    final isDelivered = status == 'da_giao';
    final orderId = order['ma_don_hang'] ?? '';
    final distance = order['distance_km'];
    final storeName = order['ten_cho']?.toString().isNotEmpty == true ? order['ten_cho'] : 'Chợ Bắc Mỹ An';

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
          borderRadius: BorderRadius.circular(20),
          border: !isDelivered ? Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 14),
                  const SizedBox(width: 6),
                  Text(statusLabel(status).toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                ],
              ),
            ),
            Text(formatVND(order['tong_tien']), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ]),
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
                return const Center(child: CircularProgressIndicator(color: Color(0xFF2F8000)));
              }
              if (snap.hasError) {
                return Center(child: Text('Lỗi: ${snap.error}'));
              }
              final data = snap.data?['data'] ?? {};
              final products = (data['san_pham'] as List<dynamic>?) ?? [];
              final addr = AddressHelper.parse(data['dia_chi_giao_hang'] ?? '');
              final buyer = data['nguoi_mua'] ?? {};

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
                      Text('${p['so_luong']}x', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2F8000))),
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
                    Text(formatVND(data['tong_tien']), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF2F8000))),
                  ]),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _acceptOrder(orderId);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F8000), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
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
