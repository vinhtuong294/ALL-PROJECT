import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/location_tracking_service.dart';
import '../../../../core/utils/helpers.dart';

// ─────────────────────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF2F8000);
const _kOrange = Color(0xFFE65100);
const _kBg = Color(0xFFF0F2F5);

// ─────────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────────
class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage>
    with TickerProviderStateMixin {
  // ── State ──
  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _updating = false;
  final Set<String> _pickingUpIds = {};
  LatLng? _deliveryPos;
  LatLng? _marketGeoPos;
  bool _geocodingMap = false;

  static const _marketFallback = LatLng(16.035415, 108.243501);

  // ── Animation ──
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _lastProgress = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // ─────────────────────────────────────────────────────────
  //  LIFECYCLE
  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _progressAnimation =
        Tween<double>(begin: 0, end: 0).animate(_progressController);

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _loadDetail();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  DATA HELPERS
  // ─────────────────────────────────────────────────────────
  Future<void> _loadDetail() async {
    if (!mounted) return;
    setState(() => _loading = true);
    _fadeController.reset();
    try {
      final data = await ApiService.getOrderDetails(widget.orderId);
      if (mounted) {
        setState(() {
          _order = data['data'];
          _loading = false;
        });
        _animateProgress();
        _fadeController.forward();
        _startGeocoding();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startGeocoding() {
    final raw = _order?['dia_chi_giao_hang'] ?? '';
    final addr = AddressHelper.parse(raw);
    final deliveryAddress = addr.address.isNotEmpty ? addr.address : raw;

    if (deliveryAddress.isEmpty) return;

    // Dùng GPS thực từ API nếu có, không cần geocoding Nominatim
    // Backend trả lat/lng đảo ngược: field 'lat'=longitude (~108), field 'lng'=latitude (~16)
    final choInfo = _order?['cho_info'] as Map<String, dynamic>?;
    final marketLat = (choInfo?['lng'] as num?)?.toDouble();
    final marketLng = (choInfo?['lat'] as num?)?.toDouble();

    setState(() => _geocodingMap = true);

    if (marketLat != null && marketLng != null) {
      // Market GPS có sẵn → chỉ geocode địa chỉ giao hàng
      _geocodeAddress(deliveryAddress).then((deliveryPos) {
        if (!mounted) return;
        final marketPos = LatLng(marketLat, marketLng);
        final distKm = _order?['distance_km'] != null
            ? (_order!['distance_km'] as num).toDouble()
            : 2.5;
        setState(() {
          _marketGeoPos = marketPos;
          _deliveryPos = deliveryPos ?? LatLng(
            marketPos.latitude + (distKm * 0.002),
            marketPos.longitude - (distKm * 0.006),
          );
          _geocodingMap = false;
        });
      });
    } else {
      // Fallback: geocode cả market name
      final marketName = '${_order?['ten_cho'] ?? 'Chợ Bắc Mỹ An'}, Đà Nẵng';
      Future.wait([
        _geocodeAddress(deliveryAddress),
        _geocodeAddress(marketName),
      ]).then((results) {
        if (!mounted) return;
        final distKm = _order?['distance_km'] != null
            ? (_order!['distance_km'] as num).toDouble()
            : 2.5;
        final marketPos = results[1] ?? _marketFallback;
        setState(() {
          _marketGeoPos = marketPos;
          _deliveryPos = results[0] ?? LatLng(
            marketPos.latitude + (distKm * 0.002),
            marketPos.longitude - (distKm * 0.006),
          );
          _geocodingMap = false;
        });
      });
    }
  }

  void _animateProgress() {
    final products = _products();
    if (products.isEmpty) return;
    final picked = _pickedCount();
    final newProg = picked / products.length;
    _progressAnimation = Tween<double>(begin: _lastProgress, end: newProg)
        .animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut));
    _lastProgress = newProg;
    _progressController.forward(from: 0);
  }

  List<dynamic> _products() =>
      ((_order?['san_pham'] as List<dynamic>?) ?? [])
          .where((p) => p['ingredient_id'] != 'NLQD01')
          .toList();

  String get _status => _order?['tinh_trang_don_hang'] ?? '';

  int _pickedCount() =>
      _products().where((p) => p['detail_status'] == 'da_lay_hang').length;

  int _totalCount() => _products().length;

  bool _canTransitionToDelivery() {
    if (_status != 'dang_lay_hang') return true;
    final p = _products();
    if (p.isEmpty) return true;
    return p.every((item) => item['detail_status'] == 'da_lay_hang');
  }

  // ─────────────────────────────────────────────────────────
  //  STATUS HELPERS
  // ─────────────────────────────────────────────────────────
  String? _nextStatus() {
    switch (_status) {
      case 'cho_shipper':   // đơn cũ / API chưa đổi sang da_xac_nhan
      case 'da_xac_nhan':
        return 'dang_lay_hang';
      case 'dang_lay_hang':
        return 'dang_giao';
      case 'dang_giao':
        return 'da_giao';
      default:
        return null;
    }
  }

  int _stepIndex() {
    switch (_status) {
      case 'cho_shipper':
      case 'da_xac_nhan':
        return 0;
      case 'dang_lay_hang':
        return 1;
      case 'dang_giao':
        return 2;
      case 'da_giao':
        return 3;
      default:
        return 0;
    }
  }

  // ─────────────────────────────────────────────────────────
  //  ACTIONS
  // ─────────────────────────────────────────────────────────

  /// Xác nhận lấy 1 nguyên liệu → PATCH .../items/{id}/pickup
  Future<void> _pickupItem(Map<String, dynamic> product) async {
    final id = product['ingredient_id']?.toString() ?? '';
    if (id.isEmpty || _pickingUpIds.contains(id)) return;

    HapticFeedback.lightImpact();
    setState(() => _pickingUpIds.add(id));
    try {
      await ApiService.updateOrderItemPickup(widget.orderId, id);
      final wasPickingUp = _status == 'dang_lay_hang';
      await _loadDetail();
      // DB luôn trả cho_shipper (không lưu dang_lay_hang) → giữ local state
      if (wasPickingUp && mounted && _status == 'cho_shipper') {
        setState(() => _order = {..._order!, 'tinh_trang_don_hang': 'dang_lay_hang'});
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _pickingUpIds.remove(id));
    }
  }

  /// Chuyển trạng thái đơn tổng → PATCH .../status
  Future<void> _updateStatus() async {
    final next = _nextStatus();
    debugPrint('🔄 [_updateStatus] status=$_status → next=$next');
    if (next == null) return;

    // Guard: chưa lấy đủ hàng → không cho chuyển dang_giao
    if (next == 'dang_giao' && !_canTransitionToDelivery()) {
      final remaining = _totalCount() - _pickedCount();
      _showSnack(
        'Còn $remaining mặt hàng chưa lấy!\nTích đủ hết trước khi bắt đầu giao.',
        isError: true,
      );
      return;
    }

    // da_giao → mở dialog POD
    if (next == 'da_giao') {
      _showPodDialog();
      return;
    }

    // dang_lay_hang không lưu DB → cập nhật local state luôn, không gọi API
    if (next == 'dang_lay_hang') {
      setState(() {
        _order = {..._order!, 'tinh_trang_don_hang': 'dang_lay_hang'};
      });
      _animateProgress();
      _showSnack('Bắt đầu lấy hàng tại chợ! Tích từng mặt hàng khi lấy xong.');
      return;
    }

    setState(() => _updating = true);
    try {
      debugPrint('📡 [API] updateOrderStatus orderId=${widget.orderId} status=$next');
      await ApiService.updateOrderStatus(widget.orderId, next);

      if (next == 'dang_giao') {
        await LocationTrackingService().startTracking(widget.orderId);
      }

      if (mounted) {
        _showSnack('Đang giao hàng đến khách. Chúc chuyến tốt! 🚀');
        await _loadDetail();
      }
    } catch (e) {
      debugPrint('❌ [_updateStatus] Error: $e');
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
        await _loadDetail();
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }


  /// Giao hàng thành công + xác nhận POD ảnh
  Future<void> _completeDelivery([String? imageUrl, String? note]) async {
    setState(() => _updating = true);
    try {
      // Submit POD nếu có ảnh – lỗi/timeout thì bỏ qua, không chặn da_giao
      if (imageUrl != null) {
        try {
          await ApiService.submitPod(widget.orderId, imageUrl, note: note)
              .timeout(const Duration(seconds: 10));
        } catch (podErr) {
          debugPrint('⚠️ submitPod skipped: $podErr');
          // Không throw – tiếp tục cập nhật trạng thái
        }
      }

      // Cập nhật trạng thái da_giao (timeout 15 giây)
      await ApiService.updateOrderStatus(widget.orderId, 'da_giao')
          .timeout(const Duration(seconds: 15));

      try {
        await LocationTrackingService().stopTracking();
      } catch (_) {}

      if (mounted) {
        _showSnack('🎉 Giao hàng thành công! Cảm ơn bạn.');
        await _loadDetail();
      }
    } catch (e) {
      debugPrint('❌ [_completeDelivery] $e');
      if (mounted) {
        _showSnack(
          e.toString().contains('TimeoutException')
              ? 'Kết nối chậm, vui lòng thử lại.'
              : e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
        // Reload so shipper sees the actual current status (e.g., order was cancelled)
        await _loadDetail();
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }


  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ]),
      backgroundColor: isError ? Colors.red.shade700 : _kGreen,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: isError ? 4 : 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─────────────────────────────────────────────────────────
  //  DIALOGS
  // ─────────────────────────────────────────────────────────

  void _showPodDialog() {
    final noteCtrl = TextEditingController();
    XFile? picked;
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: _kGreen, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bằng chứng giao hàng',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  Text('Chụp ảnh để hoàn tất đơn hàng',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
              ]),
              const SizedBox(height: 20),
              // Camera picker
              GestureDetector(
                onTap: () async {
                  try {
                    final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                    if (img != null) ss(() => picked = img);
                  } catch (_) {
                    final img = await picker.pickImage(source: ImageSource.gallery);
                    if (img != null) ss(() => picked = img);
                  }
                },
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: picked != null ? _kGreen : Colors.grey.shade300,
                      width: 2,
                    ),
                    image: picked != null
                        ? DecorationImage(
                            image: kIsWeb
                                ? NetworkImage(picked!.path)
                                : FileImage(File(picked!.path)) as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: picked == null
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Chạm để chụp / chọn ảnh',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        ])
                      : Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: GestureDetector(
                              onTap: () => ss(() => picked = null),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ghi chú (không bắt buộc)…',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    String? imageUrl;
                    if (picked != null && !kIsWeb) {
                      try {
                        imageUrl = await ApiService.uploadImage(picked!.path);
                      } catch (_) {
                        // upload thất bại → vẫn tiếp tục giao hàng, không có ảnh POD
                      }
                    }
                    _completeDelivery(imageUrl, noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text('XÁC NHẬN ĐÃ GIAO',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.3)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: _kGreen.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showFailDialog() {
    String? selectedReason;
    final noteCtrl = TextEditingController();
    const reasons = [
      'Không liên lạc được khách',
      'Khách từ chối nhận hàng',
      'Địa chỉ sai / không tìm thấy',
      'Hàng hóa hư hỏng',
      'Sự cố xe cộ',
      'Lý do khác',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Center(
                child: Container(
                    width: 44, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.report_problem, color: Colors.red.shade600, size: 22),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Báo cáo giao thất bại',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.red.shade700)),
                  const Text('Chọn lý do không giao được',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
              ]),
              const SizedBox(height: 16),
              ...reasons.map((r) => GestureDetector(
                onTap: () => ss(() => selectedReason = r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: selectedReason == r ? Colors.red.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedReason == r ? Colors.red.shade300 : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      selectedReason == r ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: selectedReason == r ? Colors.red : Colors.grey.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(r,
                        style: TextStyle(
                            fontWeight: selectedReason == r ? FontWeight.bold : FontWeight.normal,
                            color: selectedReason == r ? Colors.red.shade800 : Colors.black87)),
                  ]),
                ),
              )),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Mô tả chi tiết thêm…',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          setState(() => _updating = true);
                          try {
                            await ApiService.reportFailedDelivery(
                              widget.orderId, selectedReason!,
                              note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                            );
                            await LocationTrackingService().stopTracking();
                            if (mounted) {
                              _showSnack('Đã báo cáo giao thất bại', isError: true);
                              await _loadDetail();
                            }
                          } catch (e) {
                            if (mounted) {
                              _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
                            }
                          } finally {
                            if (mounted) setState(() => _updating = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    disabledBackgroundColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('XÁC NHẬN BÁO CÁO',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _showMapDialog(String deliveryAddress, double distKm) async {
    final marketPos = _marketGeoPos ?? _marketFallback;

    final deliveryPos = _deliveryPos ?? LatLng(
      marketPos.latitude + (distKm * 0.002),
      marketPos.longitude - (distKm * 0.006),
    );
    final center = LatLng(
      (marketPos.latitude + deliveryPos.latitude) / 2,
      (marketPos.longitude + deliveryPos.longitude) / 2,
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: double.infinity,
          height: 480,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              color: _kGreen,
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Bản đồ giao hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Khoảng cách: ${distKm.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
              ]),
            ),
            Expanded(
              child: Stack(children: [
                FlutterMap(
                  options: MapOptions(initialCenter: center, initialZoom: _deliveryPos != null ? 13 : 12),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.dngo.shipper',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: marketPos, width: 40, height: 40,
                        child: Container(
                          decoration: BoxDecoration(color: Colors.orange.shade700, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)),
                          child: const Icon(Icons.storefront, color: Colors.white, size: 18),
                        ),
                      ),
                      Marker(
                        point: deliveryPos, width: 40, height: 40,
                        child: Container(
                          decoration: BoxDecoration(color: Colors.red.shade600, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)),
                          child: const Icon(Icons.home, color: Colors.white, size: 18),
                        ),
                      ),
                    ]),
                  ],
                ),
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 6)]),
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _legendItem(Colors.orange.shade700, 'Chợ lấy hàng'),
                      const SizedBox(height: 5),
                      _legendItem(Colors.red.shade600, 'Điểm giao hàng'),
                      if (_deliveryPos == null) ...[
                        const SizedBox(height: 5),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.warning_amber, size: 11, color: Colors.orange.shade600),
                          const SizedBox(width: 4),
                          Text('Vị trí ước lượng', style: TextStyle(fontSize: 10, color: Colors.orange.shade600)),
                        ]),
                      ],
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 11, height: 11, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
  ]);

  Future<LatLng?> _geocodeAddress(String address) async {
    if (address.isEmpty) return null;
    try {
      final encoded = Uri.encodeComponent(address);
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=1&countrycodes=vn'),
        headers: {'User-Agent': 'dngo-shipper-app/1.0'},
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          return LatLng(double.parse(data[0]['lat'] as String), double.parse(data[0]['lon'] as String));
        }
      }
    } catch (_) {}
    return null;
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDone = _status == 'da_giao';
    final isFailed = _status == 'giao_that_bai' || _status == 'da_huy';

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        surfaceTintColor: Colors.white,
        title: Column(children: [
          const Text('CHI TIẾT ĐƠN HÀNG',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1)),
          Text('#${widget.orderId}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        ]),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _loadDetail,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: _loading
          ? _buildLoadingBody()
          : _order == null
              ? _buildErrorBody()
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildContent(),
                ),
      bottomNavigationBar:
          _loading || _order == null ? null : _buildBottomBar(isDone, isFailed),
    );
  }

  Widget _buildLoadingBody() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _kGreen, strokeWidth: 3),
            SizedBox(height: 16),
            Text('Đang tải thông tin đơn hàng…',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );

  Widget _buildErrorBody() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Không thể tải đơn hàng',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Kiểm tra kết nối và thử lại',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDetail,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ]),
      );

  // ─────────────────────────────────────────────────────────
  //  MAIN CONTENT SCROLL
  // ─────────────────────────────────────────────────────────
  Widget _buildContent() {
    final products = _products();
    final addr = AddressHelper.parse(_order!['dia_chi_giao_hang'] ?? '');
    final buyer = _order!['nguoi_mua'] ?? {};
    final distKm = _order!['distance_km'] != null
        ? (_order!['distance_km'] as num).toDouble()
        : 2.5;
    final storeName = _order!['ten_cho']?.toString().isNotEmpty == true
        ? _order!['ten_cho']
        : 'Chợ Bắc Mỹ An';

    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      physics: const BouncingScrollPhysics(),
      children: [
        // ── STEPPER ──
        if (_status != 'da_huy' && _status != 'giao_that_bai')
          _buildStepper(),

        // ── PICKUP PROGRESS (chỉ khi đang lấy hàng) ──
        if (_status == 'dang_lay_hang') ...[
          const SizedBox(height: 14),
          _buildPickupProgressBanner(products),
        ],

        // ── STATUS BANNER (done / fail) ──
        if (_status == 'da_giao' || _status == 'giao_that_bai' || _status == 'da_huy')
          _buildStatusBanner(),

        const SizedBox(height: 14),

        // ── CONTACT CARD ──
        _buildContactCard(addr, buyer, storeName as String, distKm),

        const SizedBox(height: 14),

        // ── MAP SECTION ──
        _buildMapSection(),

        const SizedBox(height: 14),

        // ── INGREDIENT LIST ──
        _buildIngredientSection(products),

        const SizedBox(height: 14),

        // ── TOTAL ──
        _buildTotalCard(),

        // ── POD (nếu có) ──
        if (_order!['pod_image'] != null) ...[
          const SizedBox(height: 14),
          _buildPodCard(),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  STEPPER
  // ─────────────────────────────────────────────────────────
  Widget _buildStepper() {
    final step = _stepIndex();
    const labels = ['Đã nhận', 'Lấy hàng', 'Đang giao', 'Hoàn tất'];
    const icons = [
      Icons.inbox_rounded,
      Icons.shopping_basket_rounded,
      Icons.local_shipping_rounded,
      Icons.verified_rounded,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('TIẾN ĐỘ ĐƠN HÀNG',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.black45,
                letterSpacing: 0.8)),
        const SizedBox(height: 18),
        Row(
          children: List.generate(4, (i) {
            final isActive = i <= step;
            final isConnected = i < 3;
            return [
              Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isActive ? _kGreen : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [BoxShadow(color: _kGreen.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Icon(icons[i],
                      color: isActive ? Colors.white : Colors.grey.shade400,
                      size: 18),
                ),
                const SizedBox(height: 6),
                Text(labels[i],
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w900 : FontWeight.normal,
                        color: isActive ? _kGreen : Colors.grey.shade400)),
              ]),
              if (isConnected)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i < step ? _kGreen : (i == step ? Colors.grey.shade200 : Colors.grey.shade200),
                    ),
                  ),
                ),
            ];
          }).expand((w) => w).toList(),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  PICKUP PROGRESS BANNER
  // ─────────────────────────────────────────────────────────
  Widget _buildPickupProgressBanner(List<dynamic> products) {
    final picked = _pickedCount();
    final total = _totalCount();
    final allDone = picked == total && total > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: allDone
              ? [const Color(0xFF00B40F), const Color(0xFF34C759)]
              : [const Color(0xFFE65100), const Color(0xFFBF360C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (allDone ? _kGreen : _kOrange).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle),
            child: Icon(allDone ? Icons.check_circle : Icons.shopping_basket,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                allDone ? '🎉 Đã lấy đủ hàng!' : 'Đang lấy hàng tại chợ',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              Text(
                '$picked / $total mặt hàng đã lấy',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13),
              ),
            ]),
          ),
          // Counter badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14)),
            child: Text(
              '$picked/$total',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        // Progress bar animating
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (_, child) => LinearProgressIndicator(
              value: _progressAnimation.value,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ),
        if (!allDone) ...[
          const SizedBox(height: 10),
          Text(
            'Tích vào từng mặt hàng bên dưới sau khi lấy xong',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12),
          ),
        ],
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  STATUS BANNER (done/fail)
  // ─────────────────────────────────────────────────────────
  Widget _buildStatusBanner() {
    final isDone = _status == 'da_giao';
    final isCancel = _status == 'da_huy';
    Color bg;
    IconData icon;
    String label;

    if (isDone) {
      bg = const Color(0xFF2F8000);
      icon = Icons.verified;
      label = 'Đơn hàng đã giao thành công!';
    } else if (isCancel) {
      bg = Colors.grey.shade600;
      icon = Icons.cancel;
      label = 'Đơn hàng đã bị hủy';
    } else {
      bg = Colors.red.shade600;
      icon = Icons.report;
      label = 'Giao hàng thất bại';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  CONTACT CARD
  // ─────────────────────────────────────────────────────────
  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        if (_geocodingMap || _deliveryPos == null)
          Container(
            color: Colors.grey.shade100,
            child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: _kGreen, strokeWidth: 2.5),
              SizedBox(height: 10),
              Text('Đang xác định vị trí...', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ])),
          )
        else
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(
                ((_marketGeoPos ?? _marketFallback).latitude + _deliveryPos!.latitude) / 2,
                ((_marketGeoPos ?? _marketFallback).longitude + _deliveryPos!.longitude) / 2,
              ),
              initialZoom: 13,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dngo.shipper',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: _marketGeoPos ?? _marketFallback, width: 40, height: 40,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.orange.shade700, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)),
                    child: const Icon(Icons.storefront, color: Colors.white, size: 18),
                  ),
                ),
                Marker(
                  point: _deliveryPos!, width: 40, height: 40,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.red.shade600, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)),
                    child: const Icon(Icons.home, color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ],
          ),
        // Legend overlay
        if (_deliveryPos != null)
          Positioned(
            top: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(10), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 6)]),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                _legendItem(Colors.orange.shade700, 'Chợ lấy hàng'),
                const SizedBox(height: 4),
                _legendItem(Colors.red.shade600, 'Điểm giao hàng'),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _buildContactCard(
      AddressHelper addr, Map buyer, String storeName, double distKm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        // Chợ lấy hàng
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.orange.shade50, shape: BoxShape.circle),
              child: Icon(Icons.storefront, color: Colors.orange.shade700)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Điểm lấy hàng',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(storeName,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              Builder(builder: (_) {
                final choInfo = _order?['cho_info'] as Map<String, dynamic>?;
                final addr = choInfo?['dia_chi_cho'] as String? ?? '';
                if (addr.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(addr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                );
              }),
            ]),
          ),
          Builder(builder: (_) {
            final choInfo = _order?['cho_info'] as Map<String, dynamic>?;
            final lat = (choInfo?['lat'] as num?)?.toDouble();
            final lng = (choInfo?['lng'] as num?)?.toDouble();
            if (lat == null || lng == null) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => _openMapsToMarket(lat, lng),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.navigation_rounded, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Text('Đến chợ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange.shade800)),
                ]),
              ),
            );
          }),
        ]),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1),
        ),
        // Người nhận
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.person, color: Colors.green.shade700)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Người nhận',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                addr.name.isNotEmpty ? addr.name : (buyer['ten_nguoi_dung'] ?? 'Khách'),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                addr.address.isNotEmpty
                    ? addr.address
                    : (_order!['dia_chi_giao_hang'] ?? ''),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: _actionBtn(
              icon: Icons.phone_rounded,
              label: 'Gọi điện',
              color: Colors.blue,
              onTap: () {
                final phone = addr.phone.isNotEmpty ? addr.phone : (buyer['sdt'] ?? '');
                if (phone.isNotEmpty) {
                  launchUrl(Uri(scheme: 'tel', path: phone));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionBtn(
              icon: Icons.map_rounded,
              label: 'Bản đồ',
              color: Colors.indigo,
              onTap: () => _showMapDialog(
                addr.address.isNotEmpty ? addr.address : (_order!['dia_chi_giao_hang'] ?? ''),
                distKm,
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  INGREDIENT SECTION
  // ─────────────────────────────────────────────────────────
  Widget _buildIngredientSection(List<dynamic> products) {
    final isPickingUp = _status == 'dang_lay_hang';
    final pickedCount = _pickedCount();
    final totalCount = products.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: isPickingUp ? Colors.orange.shade50 : Colors.grey.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Icon(
              isPickingUp ? Icons.shopping_basket_rounded : Icons.receipt_long_rounded,
              color: isPickingUp ? Colors.orange.shade700 : Colors.grey.shade600,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isPickingUp ? 'DANH SÁCH LẤY HÀNG' : 'NGUYÊN LIỆU ĐƠN HÀNG',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: isPickingUp ? Colors.orange.shade800 : Colors.black54),
            ),
            if (isPickingUp) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '$pickedCount/$totalCount lấy rồi',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900),
                ),
              ),
            ],
          ]),
        ),

        // Items grouped by stall
        ..._buildIngredientsByStall(products, isPickingUp),
      ]),
    );
  }

  List<Widget> _buildIngredientsByStall(List<dynamic> products, bool isPickingUp) {
    // Group by stall_id (fallback to stall name)
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final p in products) {
      final key = (p['stall_id'] as String?) ?? (p['ten_gian_hang'] as String?) ?? 'unknown';
      groups.putIfAbsent(key, () => []).add(p as Map<String, dynamic>);
    }

    final stallKeys = groups.keys.toList();
    final widgets = <Widget>[];

    for (int si = 0; si < stallKeys.length; si++) {
      final items = groups[stallKeys[si]]!;
      final first = items.first;
      final stallName = (first['ten_gian_hang'] as String?) ?? 'Không rõ quầy';
      final stallLocation = (first['stall_location'] as String?) ?? '';
      final gridRow = first['grid_row'] as int?;
      final gridCol = first['grid_col'] as int?;
      final gridFloor = first['grid_floor'] as int?;
      final isLastStall = si == stallKeys.length - 1;

      widgets.add(_buildStallHeader(
        stallName: stallName,
        stallLocation: stallLocation,
        gridRow: gridRow,
        gridCol: gridCol,
        gridFloor: gridFloor,
        itemCount: items.length,
        isPickingUp: isPickingUp,
      ));

      for (int ii = 0; ii < items.length; ii++) {
        final isLastItem = isLastStall && ii == items.length - 1;
        widgets.add(_buildIngredientRow(items[ii], isPickingUp, isLastItem));
      }
    }

    return widgets;
  }

  Widget _buildStallHeader({
    required String stallName,
    required String stallLocation,
    int? gridRow,
    int? gridCol,
    int? gridFloor,
    required int itemCount,
    required bool isPickingUp,
  }) {
    // Build position label: prefer grid info, fallback to stall_location text
    String? posLabel;
    if (gridRow != null || gridCol != null || gridFloor != null) {
      final parts = <String>[];
      if (gridFloor != null && gridFloor > 0) parts.add('Tầng $gridFloor');
      if (gridRow != null) parts.add('Hàng $gridRow');
      if (gridCol != null) parts.add('Cột $gridCol');
      if (parts.isNotEmpty) posLabel = parts.join(' · ');
    }
    if (posLabel == null && stallLocation.isNotEmpty) posLabel = stallLocation;

    return Container(
      padding: EdgeInsets.fromLTRB(18, isPickingUp ? 12 : 10, 18, isPickingUp ? 12 : 10),
      decoration: BoxDecoration(
        color: isPickingUp ? Colors.orange.shade50.withValues(alpha: 0.6) : Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.store_mall_directory, size: 14,
              color: isPickingUp ? Colors.orange.shade700 : Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(stallName,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isPickingUp ? Colors.orange.shade800 : Colors.grey.shade700)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
            child: Text('$itemCount món',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
        ]),
        // Vị trí quầy – chỉ hiện khi đang lấy hàng
        if (isPickingUp && posLabel != null) ...[
          const SizedBox(height: 8),
          _buildStallLocationRow(posLabel),
        ],
      ]),
    );
  }

  Widget _buildStallLocationRow(String posLabel) {
    final choInfo = _order?['cho_info'] as Map<String, dynamic>?;
    final lat = (choInfo?['lat'] as num?)?.toDouble();
    final lng = (choInfo?['lng'] as num?)?.toDouble();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.shade300, width: 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.place_rounded, size: 13, color: Colors.orange.shade800),
            const SizedBox(width: 4),
            Text(posLabel,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade900)),
          ]),
        ),
        if (lat != null && lng != null)
          GestureDetector(
            onTap: () => _openMapsToMarket(lat, lng),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200, width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.navigation_rounded, size: 13, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text('Chỉ đường',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade700)),
              ]),
            ),
          ),
      ],
    );
  }

  void _openMapsToMarket(double lat, double lng) {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildIngredientRow(
      Map<String, dynamic> item, bool isPickingUp, bool isLast) {
    final detailStatus = item['detail_status']?.toString() ?? '';
    final isPicked = detailStatus == 'da_lay_hang';     // ĐÃ LẤY HÀNG
    final isDuyet = detailStatus == 'da_duyet';         // ĐÃ DUYỆT (chưa lấy)
    final ingredientId = item['ingredient_id']?.toString() ?? '';
    final isThisLoading = _pickingUpIds.contains(ingredientId);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isPicked
            ? Colors.green.shade50
            : (isPickingUp ? Colors.orange.shade50.withValues(alpha: 0.5) : Colors.white),
        border: !isLast
            ? Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1))
            : null,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(children: [
          // Status icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPicked
                  ? Colors.green.shade100
                  : (isPickingUp ? Colors.orange.shade100 : Colors.grey.shade100),
            ),
            child: Center(
              child: isThisLoading
                  ? SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.orange.shade700))
                  : Icon(
                      isPicked
                          ? Icons.check_circle_rounded
                          : (isPickingUp
                              ? Icons.shopping_basket_outlined
                              : Icons.inventory_2_outlined),
                      color: isPicked
                          ? Colors.green.shade700
                          : (isPickingUp ? Colors.orange.shade700 : Colors.grey.shade500),
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Name + quantity
              Row(children: [
                Text(
                  '${item['so_luong']}x ',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Colors.green.shade700),
                ),
                Expanded(
                  child: Text(
                    item['ten_nguyen_lieu'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              const SizedBox(height: 3),
              // Stall + unit price
              Row(children: [
                Icon(Icons.store_mall_directory, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${item['ten_gian_hang'] ?? ''} · ${formatVND(item['don_gia'])}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              // Detail status badge
              _buildDetailStatusBadge(detailStatus, isPicked, isDuyet),
            ]),
          ),
          const SizedBox(width: 10),

          // Right column: price + action
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              formatVND(item['thanh_tien']),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            // Pickup checkbox – only when picking up
            if (isPickingUp)
              _buildPickupCheckbox(
                  isPicked: isPicked,
                  isLoading: isThisLoading,
                  onTap: isPicked ? null : () => _pickupItem(item)),
          ]),
        ]),
      ),
    );
  }

  /// Badge hiện trạng thái từng nguyên liệu: da_duyet / da_lay_hang / khác
  Widget _buildDetailStatusBadge(String detailStatus, bool isPicked, bool isDuyet) {
    if (isPicked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, size: 11, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text('ĐÃ LẤY HÀNG',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.green.shade800,
                  letterSpacing: 0.5)),
        ]),
      );
    }
    if (isDuyet) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.verified, size: 11, color: Colors.blue.shade600),
          const SizedBox(width: 4),
          Text('ĐÃ DUYỆT',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.blue.shade700,
                  letterSpacing: 0.5)),
        ]),
      );
    }
    // Fallback - hiển thị raw status nếu có
    if (detailStatus.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8)),
        child: Text(
          detailStatus.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPickupCheckbox({
    required bool isPicked,
    required bool isLoading,
    required VoidCallback? onTap,
  }) {
    if (isLoading) {
      return const SizedBox(
          width: 40,
          height: 40,
          child: Center(
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: _kOrange))));
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isPicked ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPicked ? Colors.green : Colors.orange.shade400,
            width: 2,
          ),
          boxShadow: isPicked
              ? [BoxShadow(color: Colors.green.withValues(alpha: 0.35), blurRadius: 8)]
              : [],
        ),
        child: Icon(
          Icons.check_rounded,
          color: isPicked ? Colors.white : Colors.orange.shade400,
          size: 22,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  TOTAL CARD
  // ─────────────────────────────────────────────────────────
  Widget _buildTotalCard() {
    final payment = _order!['thanh_toan'] as Map<String, dynamic>?;
    final method = payment?['hinh_thuc_thanh_toan'];
    final status = payment?['tinh_trang_thanh_toan'];
    final isPaid = status == 'da_thanh_toan';
    final isOnline = method != null && method != 'tien_mat';

    final Color cardColor = isPaid ? Colors.blue.shade50 : _kGreen.withValues(alpha: 0.06);
    final Color borderColor = isPaid ? Colors.blue.shade200 : _kGreen.withValues(alpha: 0.3);
    final Color iconColor = isPaid ? Colors.blue.shade600 : _kGreen;
    final IconData cardIcon = isPaid ? Icons.check_circle_rounded : Icons.payments_rounded;

    final String label = isPaid ? 'ĐÃ THANH TOÁN' : 'THU TỪ KHÁCH';
    final String sublabel = isPaid
        ? 'Khách đã thanh toán online — không thu tiền'
        : isOnline
            ? 'Chuyển khoản khi giao hàng'
            : 'Tiền mặt khi giao hàng';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(cardIcon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: iconColor, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text(sublabel, style: TextStyle(fontSize: 12, color: isPaid ? Colors.blue.shade700 : Colors.grey, fontWeight: isPaid ? FontWeight.w600 : FontWeight.normal)),
          ]),
        ),
        Text(
          isPaid ? '✓ Đã thu' : formatVND(_order!['tong_tien']),
          style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isPaid ? 16 : 26,
              color: iconColor),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  POD CARD
  // ─────────────────────────────────────────────────────────
  Widget _buildPodCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.verified, color: Colors.green, size: 18),
          SizedBox(width: 8),
          Text('Bằng chứng giao hàng',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
        ]),
        const SizedBox(height: 8),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              '${ApiService.baseUrl}/uploads/${_order!['pod_image']}',
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                alignment: Alignment.center,
                color: Colors.grey.shade100,
                child: Text('Ảnh: ${_order!['pod_image']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ),
            ),
          ),
        ),
        if (_order!['pod_note']?.isNotEmpty == true)
          Text('Ghi chú: ${_order!['pod_note']}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  BOTTOM ACTION BAR
  // ─────────────────────────────────────────────────────────
  Widget? _buildBottomBar(bool isDone, bool isFailed) {
    if (isDone) {
      return _terminalBar(
          '✅  Đơn hàng đã hoàn thành', Colors.green.shade600);
    }
    if (_status == 'giao_that_bai') {
      return _terminalBar('❌  Giao hàng thất bại', Colors.red.shade600);
    }
    if (_status == 'da_huy') {
      return _terminalBar('🚫  Đơn hàng đã hủy', Colors.grey.shade600);
    }

    final canDelivery = _canTransitionToDelivery();
    final picked = _pickedCount();
    final total = _totalCount();
    final isPickingUp = _status == 'dang_lay_hang';
    final isDelivering = _status == 'dang_giao';

    // Label + icon cho nút CTA
    String ctaLabel;
    IconData ctaIcon;
    Color ctaColor;

    if (isDelivering) {
      ctaLabel = 'ĐÃ GIAO – XÁC NHẬN';
      ctaIcon = Icons.camera_alt_rounded;
      ctaColor = _kGreen;
    } else if (isPickingUp) {
      if (canDelivery) {
        ctaLabel = 'BẮT ĐẦU GIAO HÀNG';
        ctaIcon = Icons.local_shipping_rounded;
        ctaColor = _kGreen;
      } else {
        ctaLabel = 'CÒN ${total - picked} HÀNG CHƯA LẤY';
        ctaIcon = Icons.lock_rounded;
        ctaColor = Colors.grey.shade400;
      }
    } else {
      ctaLabel = 'BẮT ĐẦU LẤY HÀNG';
      ctaIcon = Icons.shopping_basket_rounded;
      ctaColor = _kGreen;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Progress hint bar (chỉ khi đang lấy hàng)
          if (isPickingUp) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: canDelivery ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: canDelivery ? Colors.green.shade200 : Colors.orange.shade200),
              ),
              child: Row(children: [
                Icon(
                  canDelivery ? Icons.check_circle : Icons.pending_actions,
                  color: canDelivery ? Colors.green : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    canDelivery
                        ? 'Đã lấy đủ $total/$total mặt hàng. Sẵn sàng giao! 🚀'
                        : '$picked/$total mặt hàng – còn ${total - picked} chưa lấy',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: canDelivery
                            ? Colors.green.shade800
                            : Colors.orange.shade800),
                  ),
                ),
              ]),
            ),
          ],

          // Fail button (chỉ khi đang giao)
          if (isDelivering) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _showFailDialog,
                icon: Icon(Icons.report_problem_rounded, color: Colors.red.shade600, size: 18),
                label: Text('Báo cáo giao thất bại',
                    style: TextStyle(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // CTA Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _updating
                  ? null
                  : (isPickingUp && !canDelivery)
                      ? () => _showSnack(
                            'Còn ${total - picked} mặt hàng chưa lấy!\nHãy tích hết nguyên liệu trước.',
                            isError: true,
                          )
                      : _updateStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPickingUp && !canDelivery
                    ? Colors.grey.shade300
                    : ctaColor,
                foregroundColor: isPickingUp && !canDelivery
                    ? Colors.grey.shade600
                    : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: isPickingUp && !canDelivery ? 0 : 5,
                shadowColor: ctaColor.withValues(alpha: 0.35),
              ),
              child: _updating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: Colors.white))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(ctaIcon, size: 20),
                      const SizedBox(width: 10),
                      Text(ctaLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.5)),
                    ]),
            ),
          ),
          const SizedBox(height: 4),
        ]),
      ),
    );
  }

  Widget _terminalBar(String text, Color color) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(text,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
        ),
      ),
    );
  }
}
