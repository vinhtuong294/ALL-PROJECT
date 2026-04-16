import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/helpers.dart';
import 'order_detail_page.dart';

class DeliveryRoutePage extends StatefulWidget {
  const DeliveryRoutePage({super.key});

  @override
  State<DeliveryRoutePage> createState() => _DeliveryRoutePageState();
}

class _DeliveryRoutePageState extends State<DeliveryRoutePage> {
  List<dynamic> _activeOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      // Get orders that are in progress (not yet delivered)
      final results = await Future.wait([
        ApiService.getMyOrders(page: 1, limit: 50, status: 'dang_lay_hang'),
        ApiService.getMyOrders(page: 1, limit: 50, status: 'dang_giao'),
      ]);
      final list = <dynamic>[
        ...results[0]['items'] ?? [],
        ...results[1]['items'] ?? [],
      ];
      if (mounted) setState(() { _activeOrders = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(title: const Text('Tuyến giao hàng', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2F8000)))
          : _activeOrders.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: const Color(0xFF2F8000),
                  onRefresh: _loadOrders,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFF2F8000), borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          const Icon(Icons.route, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Text('${_activeOrders.length} đơn đang thực hiện', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      ..._activeOrders.asMap().entries.map((entry) => _buildRouteCard(entry.key + 1, entry.value)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('Chưa có đơn nào đang giao', style: TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Hãy nhận đơn hàng trong tab "Đơn hàng"', style: TextStyle(color: Colors.grey, fontSize: 13)),
      ]),
    );
  }

  Widget _buildRouteCard(int index, Map<String, dynamic> order) {
    final addr = AddressHelper.parse(order['dia_chi_giao_hang'] ?? '');
    final buyer = order['nguoi_mua'] ?? {};
    final status = order['tinh_trang_don_hang'] ?? '';
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order['ma_don_hang'])));
        _loadOrders();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            CircleAvatar(radius: 16, backgroundColor: const Color(0xFF2F8000), child: Text('$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
            if (index < _activeOrders.length) Container(width: 2, height: 60, color: Colors.grey.shade300),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(order['ma_don_hang'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: status == 'dang_giao' ? Colors.blue.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(statusLabel(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: status == 'dang_giao' ? Colors.blue : Colors.orange)),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(addr.name.isNotEmpty ? addr.name : (buyer['ten_nguoi_dung'] ?? ''), style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(addr.address.isNotEmpty ? addr.address : (order['dia_chi_giao_hang'] ?? ''), style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(formatVND(order['tong_tien']), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2F8000), fontSize: 16)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
