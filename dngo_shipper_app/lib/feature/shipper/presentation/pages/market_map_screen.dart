import 'package:flutter/material.dart';
import '../../../../core/services/shipper_api_service.dart';
import '../../data/models/market_map_stall.dart';

class MarketMapScreen extends StatefulWidget {
  final bool showAppBar;
  const MarketMapScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<MarketMapScreen> createState() => _MarketMapScreenState();
}

class _MarketMapScreenState extends State<MarketMapScreen> {
  bool _isLoading = true;
  List<MarketMapStall> _stalls = [];
  String? _error;

  final double cellWidth = 90.0;
  final double cellHeight = 70.0;
  final double pathWidth = 40.0;
  final double mapMargin = 160.0;
  final int totalCols = 20;
  final int totalRows = 15;

  double getColX(int col) {
    double x = col * cellWidth;
    if (col > 7) x += pathWidth;
    if (col > 9) x += pathWidth;
    return x;
  }

  double getRowY(int row) {
    double y = row * cellHeight;
    if (row > 4) y += pathWidth;
    if (row > 9) y += pathWidth;
    return y;
  }

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

  Widget _buildZone(int startCol, int endCol, int startRow, int endRow, Color color, String label) {
    double left = mapMargin + getColX(startCol);
    double top = mapMargin + getRowY(startRow);
    double width = getColX(endCol) + cellWidth - getColX(startCol);
    double height = getRowY(endRow) + cellHeight - getRowY(startRow);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4), width: 2),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
          ),
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    final mapWidth = getColX(totalCols) + mapMargin * 2;
    final mapHeight = getRowY(totalRows) + mapMargin * 2;

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
            color: const Color(0xFF2C3E50), // Dark theme matching reference map
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Streets Background Lines mapping
              Positioned(
                left: 40,
                top: mapHeight / 2 - 150,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text('NGUYEN BA LAN', style: TextStyle(color: Colors.white30, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 12)),
                ),
              ),
              Positioned(
                bottom: 40,
                left: mapWidth / 4,
                child: Text('NGUYEN BA LAN', style: TextStyle(color: Colors.white30, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 12)),
              ),
              Positioned(
                top: 40,
                left: mapWidth / 4,
                child: Text('STREET MY DA DONG 2', style: TextStyle(color: Colors.white30, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 12)),
              ),
              Positioned(
                right: 40,
                top: mapHeight / 2 - 200,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Text('STREET MY DA DONG 1', style: TextStyle(color: Colors.white30, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 12)),
                ),
              ),

              // Lối đi markers (Internal paths)
              Positioned(
                left: mapMargin + getColX(7) + cellWidth + 5,
                top: mapMargin + 80,
                width: pathWidth,
                bottom: mapMargin + 80,
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text('L Ố I   Đ I', style: TextStyle(color: Colors.white12, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 20)),
                  )
                )
              ),
              Positioned(
                left: mapMargin + getColX(9) + cellWidth + 5,
                top: mapMargin + 80,
                width: pathWidth,
                bottom: mapMargin + 80,
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text('L Ố I   Đ I', style: TextStyle(color: Colors.white12, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 20)),
                  )
                )
              ),
              Positioned(
                top: mapMargin + getRowY(4) + cellHeight + 5,
                left: mapMargin + 80,
                height: pathWidth,
                right: mapMargin + 80,
                child: Center(
                  child: Text('L Ố I   Đ I   N G A N G', style: TextStyle(color: Colors.white12, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 20)),
                )
              ),
              Positioned(
                top: mapMargin + getRowY(9) + cellHeight + 5,
                left: mapMargin + 80,
                height: pathWidth,
                right: mapMargin + 80,
                child: Center(
                  child: Text('L Ố I   Đ I   N G A N G', style: TextStyle(color: Colors.white12, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 20)),
                )
              ),

              // Background Zones
              _buildZone(0, 9, 0, 4, Colors.greenAccent, 'KHU RAU CỦ & TRÁI CÂY'),
              _buildZone(10, 19, 0, 4, Colors.redAccent, 'KHU THỊT CÁC LOẠI'),
              _buildZone(0, 7, 5, 9, Colors.lightBlueAccent, 'KHU HẢI SẢN TƯƠI SỐNG'),
              _buildZone(8, 19, 5, 9, Colors.purpleAccent, 'TẠP HÓA / ĐỒ KHÔ'),
              _buildZone(0, 9, 10, 14, Colors.orangeAccent, 'ẨM THỰC / GIA VỊ'),

              // 4 Entrances
              Positioned(
                left: mapMargin + getColX(10) - 40, top: mapMargin - 50,
                child: Column(
                  children: [
                    const Icon(Icons.arrow_downward, size: 28, color: Colors.amber),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.transparent), child: const Text('CỔNG BẮC', style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              Positioned(
                left: mapMargin + getColX(10) - 60, bottom: mapMargin - 50,
                child: Column(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.transparent), child: const Text('CỔNG NAM (Mặt chính)', style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold))),
                    const Icon(Icons.arrow_upward, size: 28, color: Colors.amber),
                  ],
                ),
              ),
              Positioned(
                left: mapMargin - 70, top: mapMargin + getRowY(7) - 20,
                child: Row(
                  children: [
                    const Icon(Icons.arrow_forward, size: 28, color: Colors.amber),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.transparent), child: const Text('CỔNG\nTÂY', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              Positioned(
                right: mapMargin - 70, top: mapMargin + getRowY(7) - 20,
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.transparent), child: const Text('CỔNG\nĐÔNG', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold))),
                    const Icon(Icons.arrow_back, size: 28, color: Colors.amber),
                  ],
                ),
              ),

              // Render Stalls
              ..._stalls.map((stall) {
                final double left = mapMargin + getColX(stall.xCol);
                final double top = mapMargin + getRowY(stall.yRow);
                final bool isClosed = stall.trangThai == "dong_cua";

                return Positioned(
                  left: left + 4,
                  top: top + 4,
                  width: cellWidth - 8,
                  height: cellHeight - 8,
                  child: GestureDetector(
                    onTap: () => _showStallDetail(context, stall),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isClosed ? Colors.grey.shade400 : Colors.white,
                        border: Border.all(
                          color: isClosed ? Colors.grey.shade600 : const Color(0xFF2F8000),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          if (!isClosed) BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: Offset(0, 2))
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
                              fontSize: 11,
                              color: isClosed ? Colors.white70 : Colors.black87,
                              decoration: isClosed ? TextDecoration.lineThrough : null,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stall.nguoiBan ?? '',
                            style: TextStyle(
                              fontSize: 9,
                              color: isClosed ? Colors.white60 : Colors.blue.shade900,
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
      appBar: widget.showAppBar ? AppBar(
        title: const Text('📍 Bản Đồ Sạp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2F8000),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadStalls(),
          )
        ],
      ) : null,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : (_error != null 
            ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
            : _buildMapContent()
          ),
    );
  }
}
