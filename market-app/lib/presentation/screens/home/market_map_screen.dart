import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../../domain/repositories/market_repository.dart';
import '../../../../data/models/market_map_model.dart';

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

  final TransformationController _transformController = TransformationController();
  double _currentScale = 0.7;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final double newScale = (_currentScale + 0.2).clamp(0.2, 3.0);
    _setScale(newScale);
  }

  void _zoomOut() {
    final double newScale = (_currentScale - 0.2).clamp(0.2, 3.0);
    _setScale(newScale);
  }

  void _resetZoom() {
    _setScale(0.7);
    _transformController.value = Matrix4.identity()..scale(0.7);
  }

  void _setScale(double scale) {
    setState(() => _currentScale = scale);
    final Matrix4 matrix = _transformController.value.clone();
    final double currentScaleInMatrix = matrix.getMaxScaleOnAxis();
    final double factor = scale / currentScaleInMatrix;
    matrix.scale(factor);
    _transformController.value = matrix;
  }

  @override
  void initState() {
    super.initState();
    // Set initial zoom to 0.7 so full map is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transformController.value = Matrix4.identity()..scale(0.7);
    });
    _loadStalls();
  }

  Future<void> _loadStalls() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = sl<MarketRepository>();
      final response = await repo.getMapStalls();
      if (response.success) {
        setState(() {
          _stalls = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Không thể tải bản đồ';
          _isLoading = false;
        });
      }
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
              child: const Text('Đóng', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapContent() {
    // 14 columns x 5 rows. 
    final mapWidth = totalCols * cellWidth;
    final mapHeight = totalRows * cellHeight;

    return Stack(
      children: [
        // Map canvas
        InteractiveViewer(
          transformationController: _transformController,
          boundaryMargin: const EdgeInsets.all(200),
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
                // Background Zones
                Positioned(
                  left: 1 * cellWidth, top: 1 * cellHeight,
                  width: 4 * cellWidth, height: 3 * cellHeight,
                  child: Container(color: Colors.green.withOpacity(0.15)),
                ),
                Positioned(
                  left: 5 * cellWidth, top: 1 * cellHeight,
                  width: 4 * cellWidth, height: 3 * cellHeight,
                  child: Container(color: Colors.red.withOpacity(0.1)),
                ),
                Positioned(
                  left: 9 * cellWidth, top: 1 * cellHeight,
                  width: 4 * cellWidth, height: 3 * cellHeight,
                  child: Container(color: Colors.blue.withOpacity(0.15)),
                ),
                // Zone labels
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
                // 4 Entrances
                Positioned(
                  left: mapWidth / 2 - 30, top: -10,
                  child: Column(
                    children: [
                      const Icon(Icons.arrow_downward, size: 28, color: Colors.orange),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)), child: const Text('CỬA BẮC', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                Positioned(
                  left: mapWidth / 2 - 30, bottom: -10,
                  child: Column(
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)), child: const Text('CỬA NAM', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                      const Icon(Icons.arrow_upward, size: 28, color: Colors.orange),
                    ],
                  ),
                ),
                Positioned(
                  left: -10, top: mapHeight / 2 - 30,
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_forward, size: 28, color: Colors.orange),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)), child: const Text('CỬA\nTÂY', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                Positioned(
                  right: -10, top: mapHeight / 2 - 30,
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)), child: const Text('CỬA\nĐÔNG', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                      const Icon(Icons.arrow_back, size: 28, color: Colors.orange),
                    ],
                  ),
                ),
                // Render Stalls
                ..._stalls.map((stall) {
                  final double left = (stall.xCol + 1) * cellWidth;
                  final double top = (stall.yRow + 1) * cellHeight;
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
                          color: isClosed ? Colors.grey.shade300 : Colors.white,
                          border: Border.all(
                            color: isClosed ? Colors.grey.shade500 : AppColors.primary,
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

        // Zoom control buttons overlay
        Positioned(
          bottom: 24,
          right: 16,
          child: Column(
            children: [
              _zoomButton(Icons.add, _zoomIn, tooltip: 'Phóng to'),
              const SizedBox(height: 8),
              _zoomButton(Icons.remove, _zoomOut, tooltip: 'Thu nhỏ'),
              const SizedBox(height: 8),
              _zoomButton(Icons.fit_screen, _resetZoom, tooltip: 'Vừa màn hình'),
            ],
          ),
        ),

        // Legend overlay
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chú giải', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                _legendRow(Colors.green.withOpacity(0.3), 'Khu Rau Củ & Gia Vị'),
                _legendRow(Colors.red.withOpacity(0.2), 'Khu Thịt'),
                _legendRow(Colors.blue.withOpacity(0.3), 'Khu Hải Sản'),
                const SizedBox(height: 4),
                _legendRow(AppColors.primary, 'Đang mở cửa', isCircle: true),
                _legendRow(Colors.grey, 'Đóng cửa', isCircle: true),
              ],
            ),
          ),
        ),

        // Stall count badge
        Positioned(
          top: 12,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${_stalls.length} sạp', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap, {String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, {bool isCircle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: isCircle ? 10 : 16,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle ? null : BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📍 Sơ Đồ Chợ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadStalls(),
            tooltip: 'Tải lại',
          )
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : (_error != null
            ? Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadStalls,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ))
            : _buildMapContent()
          ),
    );
  }
}
