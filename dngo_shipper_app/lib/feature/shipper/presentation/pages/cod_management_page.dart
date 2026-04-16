import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/helpers.dart';

class CODManagementPage extends StatefulWidget {
  const CODManagementPage({super.key});

  @override
  State<CODManagementPage> createState() => _CODManagementPageState();
}

class _CODManagementPageState extends State<CODManagementPage> {
  Map<String, dynamic>? _wallet;
  bool _loading = true;
  String _filter = 'all'; // all, hom_nay, tuan_nay, thang_nay

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() => _loading = true);
    try {
      final filterType = _filter == 'all' ? null : _filter;
      final data = await ApiService.getWalletBalance(filterType: filterType);
      if (mounted) setState(() { _wallet = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(title: const Text('Ví Shipper', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2F8000)))
          : RefreshIndicator(
              color: const Color(0xFF2F8000),
              onRefresh: _loadWallet,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Balance summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2F8000), Color(0xFF4CAF50)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(children: [
                      const Text('Số dư hiện tại', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(formatVND(_wallet?['so_du'] ?? 0), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32)),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(child: _summaryItem('Thu nhập', formatVND(_wallet?['tong_tien_vao'] ?? 0), Colors.greenAccent)),
                        Container(width: 1, height: 40, color: Colors.white30),
                        Expanded(child: _summaryItem('Chi tiêu', formatVND(_wallet?['tong_tien_ra'] ?? 0), Colors.redAccent)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _filterChip('Tất cả', 'all'),
                      _filterChip('Hôm nay', 'hom_nay'),
                      _filterChip('Tuần này', 'tuan_nay'),
                      _filterChip('Tháng này', 'thang_nay'),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Transaction list
                  const Text('Lịch sử giao dịch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...(_wallet?['chi_tiet'] as List<dynamic>? ?? []).map((tx) => _buildTxCard(tx)),
                  if ((_wallet?['chi_tiet'] as List<dynamic>?)?.isEmpty ?? true)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: const Text('Không có giao dịch nào', style: TextStyle(color: Colors.grey)),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _summaryItem(String label, String value, Color accentColor) {
    return Column(children: [
      Text(label, style: TextStyle(color: accentColor, fontSize: 12)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
    ]);
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: const Color(0xFF2F8000),
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.w500),
        onSelected: (_) { setState(() => _filter = value); _loadWallet(); },
      ),
    );
  }

  Widget _buildTxCard(Map<String, dynamic> tx) {
    final isIn = tx['huong'] == 'vao';
    final loai = tx['loai'] ?? '';
    String typeLabel;
    IconData icon;
    switch (loai) {
      case 'phi_ship': typeLabel = 'Phí ship'; icon = Icons.local_shipping; break;
      case 'loi_giao_hang': typeLabel = 'Lỗi giao hàng'; icon = Icons.warning_amber; break;
      case 'thuong': typeLabel = 'Thưởng'; icon = Icons.star; break;
      default: typeLabel = loai; icon = Icons.receipt; break;
    }
    final dateStr = tx['ngay'] ?? '';
    final date = DateTime.tryParse(dateStr);
    final dateLabel = date != null ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: isIn ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: isIn ? Colors.green : Colors.red, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(typeLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (tx['order_id'] != null) Text('Đơn: ${tx['order_id']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (tx['cancel_reason'] != null) Text(tx['cancel_reason'], style: const TextStyle(fontSize: 12, color: Colors.red)),
          if (dateLabel.isNotEmpty) Text(dateLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ])),
        Text(
          '${isIn ? '+' : '-'}${formatVND(tx['so_tien'])}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isIn ? Colors.green : Colors.red),
        ),
      ]),
    );
  }
}
