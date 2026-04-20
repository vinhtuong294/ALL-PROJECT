import 'package:flutter/material.dart';
import '../../../../core/services/shipper_api_service.dart';
import '../../data/models/market_map_stall.dart';

class MarketMapScreen extends StatefulWidget {
  const MarketMapScreen({Key? key}) : super(key: key);

  @override
  State<MarketMapScreen> createState() => _MarketMapScreenState();
}

class _MarketMapScreenState extends State<MarketMapScreen> {
  bool _isLoading = true;
  List<MarketMapStall> _stalls = [];
  String? _error;

  final double cellWidth = 120.0;
  final double cellHeight = 90.0;
  final int totalCols = 14;
  final int totalRows = 5;

  final ShipperApiService _apiService = ShipperApiService();

  @override
  void initState() {
    super.initState();
    _loadStalls();
  }

  Future<void> _loadStalls() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _apiService.getMapStalls();
      setState(() {
        _stalls = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi hệ thống: $e';
        _isLoading = false;
      });
    }
  }

  void _showStallDetail(BuildContext context, MarketMapStall stall) {
    showDialog(
      context: context,
      builder: (context) {
        final bool isClosed = stall.trangThai == "dong_cua";
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(stall.tenGianHang ?? 'Gian Hàng Trống'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chủ sạp: ${stall.nguoiBan ?? "Chưa rõ"}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Tọa độ: X=${stall.xCol}, Y=${stall.yRow}'),
              const SizedBox(height: 8),
              if (stall.loaiHang != null) Text('Loại hàng: ${stall.loaiHang}'),
              const SizedBox(height: 8),
              Row(
                children: [
               	  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: isClosed ? Colors.grey : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(isClosed ? 'Đang đóng cửa' : 'Đang hoạt động', style: TextStyle(color: isClosed ? Colors.grey : Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng', style: TextStyle(color: Color(0xFF2F8000))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapContent() {
    // 14 columns x 5 rows. 
    // Data coordinates: X=0..11, Y=0..2
    // We offset them by UX: offset X by +1, offset Y by +1
    
    final mapWidth = totalCols * cellWidth;
    final mapHeight = totalRows * cellHeight;

    return Center(
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.2,
        maxScale: 3.0,
        constrained: false,
        child: Container(
          width: mapWidth,
          height: mapHeight,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            border: Border.all(color: Colors.grey, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background Zones (Offset X by +1, Y by +1)
              // Zone Rau (X: 0->3) -> Cols 1 to 4
              Positioned(
                left: 1 * cellWidth, top: 1 * cellHeight,
                width: 4 * cellWidth, height: 3 * cellHeight,
                child: Container(color: Colors.green.withOpacity(0.15)),
              ),
              // Zone Thịt (X: 4->7) -> Cols 5 to 8
              Positioned(
                left: 5 * cellWidth, top: 1 * cellHeight,
                width: 4 * cellWidth, height: 3 * cellHeight,
                child: Container(color: Colors.red.withOpacity(0.1)),
              ),
              // Zone Cá (X: 8->11) -> Cols 9 to 12
              Positioned(
                left: 9 * cellWidth, top: 1 * cellHeight,
                width: 4 * cellWidth, height: 3 * cellHeight,
                child: Container(color: Colors.blue.withOpacity(0.15)),
              ),

              // Labels for Zones
              Positioned(
                left: 2.5 * cellWidth, top: 0.2 * cellHeight,
                child: Text('KHU RAU CỦ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800], fontSize: 18)),
              ),
              Positioned(
                left: 6.5 * cellWidth, top: 0.2 * cellHeight,
                child: Text('KHU THỊT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800], fontSize: 18)),
              ),
              Positioned(
                left: 10.5 * cellWidth, top: 0.2 * cellHeight,
                child: Text('KHU HẢI SẢN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800], fontSize: 18)),
              ),
              
              // 4 Ngã vào (Mũi tên chỉ lối vào)
              Positioned(
                left: mapWidth / 2 - 30, top: -10,
                child: const Icon(Icons.arrow_downward, size: 40, color: Colors.orange),
              ),
              Positioned(
                left: mapWidth / 2 - 30, bottom: -10,
                child: const Icon(Icons.arrow_upward, size: 40, color: Colors.orange),
              ),
              Positioned(
                left: -10, top: mapHeight / 2 - 30,
                child: const Icon(Icons.arrow_forward, size: 40, color: Colors.orange),
              ),
              Positioned(
                right: -10, top: mapHeight / 2 - 30,
                child: const Icon(Icons.arrow_back, size: 40, color: Colors.orange),
              ),

              // Render Stalls
              ..._stalls.map((stall) {
                final double left = (stall.xCol + 1) * cellWidth;
                final double top = (stall.yRow + 1) * cellHeight;
                final bool isClosed = stall.trangThai == "dong_cua";

                return Positioned(
                  left: left + 4, // Padding
                  top: top + 4, 
                  width: cellWidth - 8,
                  height: cellHeight - 8,
                  child: GestureDetector(
                    onTap: () => _showStallDetail(context, stall),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isClosed ? Colors.grey.shade300 : Colors.white,
                        border: Border.all(
                          color: isClosed ? Colors.grey.shade500 : const Color(0xFF2F8000),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          if (!isClosed) const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                        ]
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            stall.tenGianHang ?? 'Trống',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isClosed ? Colors.grey.shade600 : Colors.black,
                              decoration: isClosed ? TextDecoration.lineThrough : null,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stall.nguoiBan ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              color: isClosed ? Colors.grey.shade600 : Colors.blue.shade800,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('📍 Bản Đồ Sạp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2F8000),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadStalls(),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : (_error != null 
            ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
            : _buildMapContent()
          ),
    );
  }
}
