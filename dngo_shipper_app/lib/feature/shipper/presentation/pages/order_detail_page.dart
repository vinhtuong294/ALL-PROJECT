import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/location_tracking_service.dart';
import '../../../../core/utils/helpers.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final data = await ApiService.getOrderDetails(widget.orderId);
      if (mounted) setState(() { _order = data['data']; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _nextStatus() {
    switch (_order?['tinh_trang_don_hang']) {
      case 'da_xac_nhan': return 'dang_lay_hang';
      case 'dang_lay_hang': return 'dang_giao';
      case 'dang_giao': return 'da_giao';
      default: return null;
    }
  }

  String _nextStatusLabel() {
    switch (_order?['tinh_trang_don_hang']) {
      case 'da_xac_nhan': return 'Bắt đầu lấy hàng';
      case 'dang_lay_hang': return 'Bắt đầu giao hàng';
      case 'dang_giao': return 'Đánh dấu đã giao thành công';
      default: return '';
    }
  }

  Future<void> _updateStatus() async {
    final next = _nextStatus();
    if (next == null) return;
    setState(() => _updating = true);
    try {
      await ApiService.updateOrderStatus(widget.orderId, next);

      // 🚀 BẮT ĐẦU tracking GPS khi shipper bắt đầu giao
      if (next == 'dang_giao') {
        await LocationTrackingService().startTracking(widget.orderId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chuyển trạng thái → ${statusLabel(next)}', style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF2F8000)));
        _loadDetail();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(launchUri)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở ứng dụng gọi điện')));
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
          width: 500, height: 480,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF2F8000),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bản đồ giao hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  ],
                ),
              ),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: marketPos,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.dngo.shipper',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: marketPos,
                          width: 40, height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.store, color: Colors.white, size: 20),
                          ),
                        ),
                        Marker(
                          point: deliveryPos,
                          width: 40, height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16), color: Colors.white,
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: const Icon(Icons.route, color: Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Khoảng cách ước tính', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('${distanceKm.toStringAsFixed(1)} KM', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // POD DIALOG
  void _showPodDialog() {
    final noteController = TextEditingController();
    XFile? pickedImage;
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('Bằng chứng giao hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Chụp hình món hàng tại điểm giao để hoàn tất', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () async {
                    try {
                      final XFile? image = await picker.pickImage(source: ImageSource.camera);
                      if (image != null) setSheetState(() => pickedImage = image);
                    } catch (e) {
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) setSheetState(() => pickedImage = image);
                    }
                  },
                  child: Container(
                    height: 180, width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300),
                      image: pickedImage != null ? DecorationImage(image: kIsWeb ? NetworkImage(pickedImage!.path) : FileImage(File(pickedImage!.path)) as ImageProvider, fit: BoxFit.cover) : null,
                    ),
                    child: pickedImage == null ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 40, color: Colors.grey), SizedBox(height: 8),
                        Text('Chạm để mở Camera', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ) : Align(
                      alignment: Alignment.topRight,
                      child: IconButton(icon: const Icon(Icons.close, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.black54), onPressed: () => setSheetState(() => pickedImage = null)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController, maxLines: 2,
                  decoration: InputDecoration(hintText: 'Ghi chú (không bắt buộc)', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: pickedImage == null ? null : () async {
                      Navigator.pop(ctx);
                      try {
                        await ApiService.submitPod(widget.orderId, pickedImage!.name, note: noteController.text.trim());
                        await ApiService.updateOrderStatus(widget.orderId, 'da_giao');
                        // 🛑 DỪNG tracking GPS khi giao hàng thành công
                        await LocationTrackingService().stopTracking();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giao hàng thành công!'), backgroundColor: Color(0xFF2F8000)));
                          _loadDetail();
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                      }
                    },
                    icon: const Icon(Icons.cloud_upload, color: Colors.white),
                    label: const Text('XÁC NHẬN HOÀN THÀNH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F8000), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // FAILED DELIVERY DIALOG
  void _showFailDialog() {
    String? selectedReason;
    final noteController = TextEditingController();
    XFile? pickedEvidence;
    final ImagePicker picker = ImagePicker();

    final reasons = ['Không liên lạc được khách', 'Khách từ chối nhận hàng', 'Địa chỉ sai', 'Hàng hóa hư hỏng', 'Sự cố xe cộ', 'Lý do khác'];

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('Báo cáo giao thất bại', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                ...reasons.map((r) => GestureDetector(
                  onTap: () => setSheetState(() => selectedReason = r),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: selectedReason == r ? Colors.red.shade50 : Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: selectedReason == r ? Colors.red.shade200 : Colors.transparent)),
                    child: Row(children: [
                      Icon(selectedReason == r ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selectedReason == r ? Colors.red : Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Text(r, style: TextStyle(fontWeight: selectedReason == r ? FontWeight.bold : FontWeight.normal)),
                    ]),
                  ),
                )),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController, maxLines: 2,
                  decoration: InputDecoration(hintText: 'Mô tả chi tiết', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: selectedReason == null ? null : () async {
                      Navigator.pop(ctx);
                      try {
                        await ApiService.reportFailedDelivery(widget.orderId, selectedReason!, note: noteController.text.trim());
                        // 🛑 DỪNG tracking GPS khi giao hàng thất bại
                        await LocationTrackingService().stopTracking();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã báo cáo thất bại', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.red));
                        _loadDetail();
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('XÁC NHẬN BÁO CÁO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= MAIN UI ======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black87,
        title: Column(
          children: [
            const Text('Chi tiết đơn hàng', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            Text('#${widget.orderId}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2F8000)))
          : _order == null ? const Center(child: Text('Không tìm thấy đơn hàng')) : _buildContent(),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget? _buildBottomActionBar() {
    if (_loading || _order == null) return null;
    final status = _order!['tinh_trang_don_hang'] ?? '';
    final next = _nextStatus();
    
    // Status terminal states
    if (status == 'da_giao') return _buildTerminalBottomBar('Đơn hàng đã hoàn thành', Colors.green, Icons.verified);
    if (status == 'giao_that_bai') return _buildTerminalBottomBar('Đã hủy / Thất bại', Colors.red, Icons.cancel);
    if (status == 'da_huy') return _buildTerminalBottomBar('Đơn hàng đã hủy', Colors.grey, Icons.not_interested);

    // Active states
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == 'dang_giao') ...[
               SizedBox(
                width: double.infinity, height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showFailDialog(),
                  icon: const Icon(Icons.report_problem, color: Colors.red),
                  label: const Text('Báo cáo giao thất bại', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _updating ? null : (status == 'dang_giao' ? _showPodDialog : _updateStatus),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F8000), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4, shadowColor: const Color(0xFF2F8000).withValues(alpha: 0.4)),
                child: _updating 
                   ? const CircularProgressIndicator(color: Colors.white) 
                   : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_nextStatusLabel().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalBottomBar(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color), const SizedBox(width: 8),
            Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final status = _order!['tinh_trang_don_hang'] ?? '';
    final addr = AddressHelper.parse(_order!['dia_chi_giao_hang'] ?? '');
    final buyer = _order!['nguoi_mua'] ?? {};
    final products = (_order!['san_pham'] as List<dynamic>?) ?? [];
    final distanceKm = _order!['distance_km'] != null ? (_order!['distance_km'] as num).toDouble() : 2.5;
    final storeName = _order!['ten_cho']?.toString().isNotEmpty == true ? _order!['ten_cho'] : 'Chợ Bắc Mỹ An';

    int currentStep = 0;
    if (status == 'dang_lay_hang') currentStep = 1;
    if (status == 'dang_giao') currentStep = 2;
    if (status == 'da_giao') currentStep = 3;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      physics: const BouncingScrollPhysics(),
      children: [
        // Stepper
        if (status != 'da_huy' && status != 'giao_that_bai')
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tiến độ đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStepDot(0, currentStep, 'Đã nhận'),
                    Expanded(child: Container(height: 3, color: currentStep >= 1 ? const Color(0xFF2F8000) : Colors.grey.shade200)),
                    _buildStepDot(1, currentStep, 'Lấy hàng'),
                    Expanded(child: Container(height: 3, color: currentStep >= 2 ? const Color(0xFF2F8000) : Colors.grey.shade200)),
                    _buildStepDot(2, currentStep, 'Đang giao'),
                    Expanded(child: Container(height: 3, color: currentStep >= 3 ? const Color(0xFF2F8000) : Colors.grey.shade200)),
                    _buildStepDot(3, currentStep, 'Hoàn tất'),
                  ],
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 16),

        // Contact Info Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle), child: Icon(Icons.storefront, color: Colors.orange.shade700)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Điểm lấy', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(storeName as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ])),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle), child: Icon(Icons.person, color: Colors.green.shade700)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Người nhận', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(addr.name.isNotEmpty ? addr.name : (buyer['ten_nguoi_dung'] ?? 'Khách'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(addr.address.isNotEmpty ? addr.address : (_order!['dia_chi_giao_hang'] ?? ''), style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    ])),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(addr.phone.isNotEmpty ? addr.phone : (buyer['sdt'] ?? '')),
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Gọi Điện'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue.shade800, elevation: 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showInAppMap(addr.address.isNotEmpty ? addr.address : (_order!['dia_chi_giao_hang'] ?? ''), distanceKm),
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text('Bản Đồ'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade50, foregroundColor: Colors.indigo.shade800, elevation: 0),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        
        // Receipt Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                  child: const Text('CHI TIẾT MUA HỘ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                ),
                ListView.separated(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final p = products[i];
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${p['so_luong']}x', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2F8000), fontSize: 15)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p['ten_nguyen_lieu'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${formatVND(p['don_gia'])} / ${p['ten_gian_hang'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ])),
                      Text(formatVND(p['thanh_tien']), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]);
                  },
                ),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Divider(color: Colors.grey.shade300, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Thu từ khách', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
                    Text(formatVND(_order!['tong_tien']), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF2F8000))),
                  ]),
               ),
              ],
            ),
          ),
        ),

        // POD Details if exists
        if (_order!['pod_image'] != null)
           Padding(
             padding: const EdgeInsets.all(20),
             child: Container(
               padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade200)),
               child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 20), SizedBox(width: 8), Text('Bằng chứng giao hàng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                  const SizedBox(height: 12),
                  Text('Hình ảnh: ${_order!['pod_image']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  if (_order!['pod_note']?.isNotEmpty == true) Text('Ghi chú: ${_order!['pod_note']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
               ]),
             ),
           ),
      ],
    );
  }

  Widget _buildStepDot(int stepIndex, int currentStep, String label) {
    final isActive = stepIndex <= currentStep;
    return Column(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: isActive ? const Color(0xFF2F8000) : Colors.grey.shade200, shape: BoxShape.circle),
          child: isActive ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.black87 : Colors.grey)),
      ],
    );
  }
}
