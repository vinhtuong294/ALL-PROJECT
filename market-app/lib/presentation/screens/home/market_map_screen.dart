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

class _MarketMapScreenState extends State<MarketMapScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<MarketMapStall> _stalls = [];
  String? _error;

  static const double cellW = 90.0;
  static const double cellH = 70.0;
  static const double pathW = 44.0;
  static const double margin = 160.0;
  static const int cols = 20;
  static const int rows = 15;
  static const double depth = 6.0;

  late AnimationController _pulse;
  late Animation<double> _pulseAnim;
  final TransformationController _transform = TransformationController();
  double _currentScale = 0.5;

  static Color _zoneColor(int col, int row) {
    if (row <= 4 && col <= 9) return const Color(0xFF22C55E);
    if (row <= 4) return const Color(0xFFEF4444);
    if (row <= 9 && col <= 7) return const Color(0xFF38BDF8);
    if (row <= 9) return const Color(0xFFA855F7);
    return const Color(0xFFF97316);
  }

  double _cx(int col) {
    double x = col * cellW;
    if (col > 7) x += pathW;
    if (col > 9) x += pathW;
    return x;
  }

  double _ry(int row) {
    double y = row * cellH;
    if (row > 4) y += pathW;
    if (row > 9) y += pathW;
    return y;
  }

  void _zoomIn()   => _setScale((_currentScale + 0.2).clamp(0.1, 3.0));
  void _zoomOut()  => _setScale((_currentScale - 0.2).clamp(0.1, 3.0));
  void _resetZoom() {
    _setScale(0.5);
    _transform.value = Matrix4.identity()..scaleByDouble(0.5, 0.5, 0.5, 1.0);
  }

  void _setScale(double scale) {
    setState(() => _currentScale = scale);
    final m = _transform.value.clone();
    final factor = scale / m.getMaxScaleOnAxis();
    m.scaleByDouble(factor, factor, factor, 1.0);
    _transform.value = m;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transform.value = Matrix4.identity()..scaleByDouble(0.5, 0.5, 0.5, 1.0);
    });
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    _loadStalls();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _transform.dispose();
    super.dispose();
  }

  Future<void> _loadStalls() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final repo = sl<MarketRepository>();
      final res = await repo.getMapStalls();
      if (res.success) {
        setState(() { _stalls = res.data; _isLoading = false; });
      } else {
        setState(() { _error = 'Không thể tải bản đồ'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Lỗi hệ thống: $e'; _isLoading = false; });
    }
  }

  // ── Stall with 3-D box effect ─────────────────────────────────────
  Widget _buildStall(MarketMapStall stall) {
    final closed = stall.trangThai == 'dong_cua';
    final base   = closed ? const Color(0xFF374151) : _zoneColor(stall.xCol, stall.yRow);
    final shadow = closed ? const Color(0xFF1F2937) : Color.lerp(base, Colors.black, 0.45)!;
    final left   = margin + _cx(stall.xCol) + 3;
    final top    = margin + _ry(stall.yRow)  + 3;
    const w = cellW - 6;
    const h = cellH - 6;

    return Positioned(
      left: left, top: top,
      child: GestureDetector(
        onTap: () => _showDetail(stall),
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) => SizedBox(
            width: w + depth, height: h + depth,
            child: Stack(
              children: [
                Positioned(
                  left: depth, top: depth,
                  child: Container(
                    width: w, height: h,
                    decoration: BoxDecoration(color: shadow, borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                Container(
                  width: w, height: h,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: closed
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.28),
                      width: 1,
                    ),
                    boxShadow: closed
                        ? const []
                        : [BoxShadow(
                            color: base.withValues(alpha: _pulseAnim.value * 0.55),
                            blurRadius: 12,
                            spreadRadius: 1,
                          )],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stall.tenGianHang ?? 'Trống',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: closed ? Colors.white38 : Colors.white,
                          decoration: closed ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.white38,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!closed && stall.nguoiBan != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          stall.nguoiBan!,
                          style: TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: 0.6)),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  // ── Detail dialog ─────────────────────────────────────────────────
  void _showDetail(MarketMapStall stall) {
    final closed = stall.trangThai == 'dong_cua';
    final color  = _zoneColor(stall.xCol, stall.yRow);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF0D1B2A),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Icon(Icons.storefront, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stall.tenGianHang ?? 'Gian Hàng Trống',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(stall.nguoiBan ?? 'Chưa rõ chủ sạp',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13)),
                  ],
                )),
              ]),
              const SizedBox(height: 14),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),
              _dRow(Icons.grid_on_outlined, 'Vị trí', 'Cột ${stall.xCol} · Hàng ${stall.yRow}'),
              if (stall.loaiHang != null)
                _dRow(Icons.category_outlined, 'Loại hàng', stall.loaiHang!),
              _dRow(
                closed ? Icons.cancel_outlined : Icons.check_circle_outline,
                'Trạng thái', closed ? 'Đóng cửa' : 'Đang mở',
                valueColor: closed ? Colors.red.shade400 : Colors.green.shade400,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: color.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Đóng', style: TextStyle(color: color)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(children: [
        Icon(icon, size: 15, color: Colors.white30),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.white38, fontSize: 13)),
        Expanded(child: Text(value,
          style: TextStyle(color: valueColor ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  // ── Zone border ───────────────────────────────────────────────────
  Widget _buildZone(int c0, int c1, int r0, int r1, Color color, String label) {
    return Positioned(
      left: margin + _cx(c0) - 3, top: margin + _ry(r0) - 3,
      width: _cx(c1) + cellW - _cx(c0) + 6,
      height: _ry(r1) + cellH - _ry(r0) + 6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.22), width: 1.5),
        ),
        padding: const EdgeInsets.only(left: 8, top: 6),
        child: Text(label, style: TextStyle(
          color: color.withValues(alpha: 0.55), fontSize: 10,
          fontWeight: FontWeight.bold, letterSpacing: 0.6,
        )),
      ),
    );
  }

  Widget _entrance({double? l, double? t, double? r, double? b, required String label, required IconData icon}) {
    return Positioned(
      left: l, top: t, right: r, bottom: b,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.45)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: Colors.amber),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  // ── Full map ──────────────────────────────────────────────────────
  Widget _buildMapContent() {
    final mw = _cx(cols) + margin * 2;
    final mh = _ry(rows) + margin * 2;
    final openCount = _stalls.where((s) => s.trangThai != 'dong_cua').length;

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transform,
          boundaryMargin: const EdgeInsets.all(200),
          minScale: 0.1,
          maxScale: 3.0,
          constrained: false,
          child: SizedBox(
            width: mw, height: mh,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _BgPainter(mw, mh))),
                _path(l: margin + _cx(7) + cellW, t: margin - 8, w: pathW, h: _ry(rows) + 16),
                _path(l: margin + _cx(9) + cellW, t: margin - 8, w: pathW, h: _ry(rows) + 16),
                _path(l: margin - 8, t: margin + _ry(4) + cellH, w: _cx(cols) + 16, h: pathW),
                _path(l: margin - 8, t: margin + _ry(9) + cellH, w: _cx(cols) + 16, h: pathW),
                _buildZone(0, 9, 0, 4, const Color(0xFF22C55E), 'RAU CỦ & TRÁI CÂY'),
                _buildZone(10, 19, 0, 4, const Color(0xFFEF4444), 'THỊT CÁC LOẠI'),
                _buildZone(0, 7, 5, 9, const Color(0xFF38BDF8), 'HẢI SẢN TƯƠI SỐNG'),
                _buildZone(8, 19, 5, 9, const Color(0xFFA855F7), 'TẠP HÓA / ĐỒ KHÔ'),
                _buildZone(0, 9, 10, 14, const Color(0xFFF97316), 'ẨM THỰC / GIA VỊ'),
                _street(l: 14, t: mh / 2 - 80, label: 'NGUYỄN BA LAN', rotate: true),
                _street(b: 18, l: mw / 5, label: 'NGUYỄN BA LAN'),
                _street(t: 18, l: mw / 5, label: 'MỸ ĐA ĐÔNG 2'),
                _street(r: 14, t: mh / 2 - 100, label: 'MỸ ĐA ĐÔNG 1', rotate: true),
                ..._stalls.map(_buildStall),
                _entrance(l: margin + _cx(10) - 52, t: margin - 42, label: 'CỔNG BẮC', icon: Icons.north),
                _entrance(l: margin + _cx(10) - 78, b: margin - 42, label: 'CỔNG NAM (Mặt chính)', icon: Icons.south),
                _entrance(l: margin - 86, t: margin + _ry(7) - 13, label: 'CỔNG TÂY', icon: Icons.west),
                _entrance(r: margin - 86, t: margin + _ry(7) - 13, label: 'CỔNG ĐÔNG', icon: Icons.east),
              ],
            ),
          ),
        ),

        // Zoom controls
        Positioned(
          bottom: 24, right: 16,
          child: Column(children: [
            _zoomBtn(Icons.add, _zoomIn, 'Phóng to'),
            const SizedBox(height: 8),
            _zoomBtn(Icons.remove, _zoomOut, 'Thu nhỏ'),
            const SizedBox(height: 8),
            _zoomBtn(Icons.fit_screen, _resetZoom, 'Vừa màn hình'),
          ]),
        ),

        // Legend
        Positioned(
          top: 12, left: 12,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CHÚ GIẢI',
                    style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                _lgRow(const Color(0xFF22C55E), 'Rau Củ & Trái Cây'),
                _lgRow(const Color(0xFFEF4444), 'Thịt Các Loại'),
                _lgRow(const Color(0xFF38BDF8), 'Hải Sản Tươi Sống'),
                _lgRow(const Color(0xFFA855F7), 'Tạp Hóa / Đồ Khô'),
                _lgRow(const Color(0xFFF97316), 'Ẩm Thực / Gia Vị'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                _lgRow(Colors.white, 'Đang mở', dot: true),
                _lgRow(Colors.grey, 'Đóng cửa', dot: true),
              ],
            ),
          ),
        ),

        // Stats
        Positioned(
          top: 12, right: 16,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _badge('${_stalls.length}', 'tổng sạp', const Color(0xFF1D4ED8)),
            const SizedBox(height: 6),
            _badge('$openCount', 'đang mở', const Color(0xFF15803D)),
          ]),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────
  Widget _path({required double l, required double t, required double w, required double h}) {
    return Positioned(left: l, top: t, width: w, height: h,
      child: CustomPaint(painter: _PathPainter(w, h)));
  }

  Widget _street({double? l, double? t, double? r, double? b, required String label, bool rotate = false}) {
    final child = Text(label,
      style: TextStyle(color: Colors.white.withValues(alpha: 0.05), fontSize: 26,
          fontWeight: FontWeight.bold, letterSpacing: 10));
    return Positioned(left: l, top: t, right: r, bottom: b,
      child: rotate ? RotatedBox(quarterTurns: 3, child: child) : child);
  }

  Widget _lgRow(Color color, String label, {bool dot = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(
          width: dot ? 8 : 14, height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: dot ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: dot ? null : BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ]),
    );
  }

  Widget _badge(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
      ]),
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A).withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        title: const Text('📍 Sơ Đồ Chợ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStalls,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadStalls,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ))
              : _buildMapContent(),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────

class _BgPainter extends CustomPainter {
  final double w, h;
  _BgPainter(this.w, this.h);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF0A1628));
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.045);
    const step = 28.0;
    for (double x = 0; x < w; x += step) {
      for (double y = 0; y < h; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => false;
}

class _PathPainter extends CustomPainter {
  final double w, h;
  _PathPainter(this.w, this.h);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF0F1E30));
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashLen = 8.0;
    const gap = 6.0;
    if (w > h) {
      double x = 0;
      final y = h / 2;
      while (x < w) {
        canvas.drawLine(Offset(x, y), Offset((x + dashLen).clamp(0, w), y), paint);
        x += dashLen + gap;
      }
    } else {
      double y = 0;
      final x = w / 2;
      while (y < h) {
        canvas.drawLine(Offset(x, y), Offset(x, (y + dashLen).clamp(0, h)), paint);
        y += dashLen + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => false;
}
