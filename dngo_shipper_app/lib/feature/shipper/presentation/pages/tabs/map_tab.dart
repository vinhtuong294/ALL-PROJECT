import 'package:flutter/material.dart';
import '../market_map_screen.dart';

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MarketMapScreen()),
                    );
                  },
                  icon: const Icon(Icons.map, color: Colors.white),
                  label: const Text('Mở Bản Đồ Chi Tiết (Sống)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F8000),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildMarketMap(context),
              const SizedBox(height: 16),
              _buildLegend(),
              const SizedBox(height: 16),
              _buildTips(),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 16, right: 16, bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF2F8000),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0), bottomRight: Radius.circular(0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF2F8000), size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Text('Bản đồ Định vị Chợ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.info_outline, color: Color(0xFF2F8000), size: 20),
              )
            ],
          ),
          const SizedBox(height: 8),
          const Text('Chợ Bắc Mỹ An', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMarketMap(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: const Color(0xFFD7FFBD), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_downward, color: Colors.black87, size: 20),
                SizedBox(width: 8),
                Text('LỐI VÀO CHÍNH (Cổng A)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildZoneCard('Khu Bánh Mì', 'A-01', Icons.bakery_dining, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildZoneCard('Khu Cà Phê', 'A-02', Icons.coffee, Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildZoneCard('Khu Rau Củ', 'B-01', Icons.eco, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildZoneCard('Khu Thịt Cá', 'B-02', Icons.set_meal, Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildZoneCard('Khu Gia Vị', 'C-01', Icons.local_fire_department, Colors.deepPurple)),
              const SizedBox(width: 12),
              Expanded(child: _buildZoneCard('Khu Hoa', 'C-02', Icons.local_florist, Colors.pink)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: const Color(0xFFF75555), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('LỐI RA CHÍNH (Cổng B)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(String name, String code, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(code, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chú giải', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildLegendRow(const Color(0xFFD7FFBD), 'Lối vào chính'),
          const SizedBox(height: 12),
          _buildLegendRow(const Color(0xFFF75555), 'Lối ra chính'),
          const SizedBox(height: 12),
          _buildLegendRow(Colors.white, 'Các khu vực bán hàng', hasBorder: true),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String text, {bool hasBorder = false}) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: hasBorder ? Border.all(color: Colors.grey.shade300) : null,
          ),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('Mẹo định vị', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipLine('Sử dụng tên hành lang để định vị nhanh'),
          const SizedBox(height: 8),
          _buildTipLine('Lối vào màu xanh lá, lối ra màu đỏ'),
          const SizedBox(height: 8),
          _buildTipLine('Tìm kiếm quầy hàng bằng thanh tìm kiếm'),
        ],
      ),
    );
  }

  Widget _buildTipLine(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 6, color: Colors.blue),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4))),
      ],
    );
  }
}
