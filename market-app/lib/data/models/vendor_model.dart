enum VendorStatus { active, inactive }

class VendorModel {
  final String id;
  final String name;
  final String stallCode;
  final VendorStatus status;
  final String address;
  final String goodsType;
  final double taxAmount;
  final String? phone;
  final String? notes;
  final String? avatarInitial;

  const VendorModel({
    required this.id,
    required this.name,
    required this.stallCode,
    required this.status,
    required this.address,
    required this.goodsType,
    required this.taxAmount,
    this.phone,
    this.notes,
    this.avatarInitial,
  });

  String get initial => name.trim().split(' ').last[0].toUpperCase();

  bool get isActive => status == VendorStatus.active;
  String get statusLabel => isActive ? 'Hoạt động' : 'Tạm nghỉ';
}

// ── Dummy data ────────────────────────────────────────────────────────────────

final List<VendorModel> dummyVendors = [
  const VendorModel(id: '1', name: 'Nguyễn Văn A', stallCode: 'A-01', status: VendorStatus.active, phone: '0901111111', address: 'Quầy gỗ cũ', goodsType: 'Thực phẩm khô', taxAmount: 500000),
  const VendorModel(id: '2', name: 'Trần Thị B',   stallCode: 'A-02', status: VendorStatus.active, phone: '0902222222', address: 'Dãy A trái', goodsType: 'Thời trang', taxAmount: 700000),
  const VendorModel(id: '3', name: 'Lê Văn C',     stallCode: 'B-01', status: VendorStatus.inactive, phone: '0903333333', address: 'Khu trung tâm', goodsType: 'Điện tử', taxAmount: 1000000),
  const VendorModel(id: '4', name: 'Phạm Thị D',   stallCode: 'B-02', status: VendorStatus.active, phone: '0904444444', address: 'Tầng 2 cổng phụ', goodsType: 'Ẩm thực', taxAmount: 450000),
  const VendorModel(id: '5', name: 'Hoàng Văn E',  stallCode: 'C-01', status: VendorStatus.active, phone: '0905555555', address: 'Khu ngoài trời', goodsType: 'Cây cảnh', taxAmount: 300000),
  const VendorModel(id: '6', name: 'Bùi Thị F',    stallCode: 'C-02', status: VendorStatus.inactive, phone: '0906666666', address: 'Dãy sạp rau', goodsType: 'Rau củ quả', taxAmount: 200000),
  const VendorModel(id: '7', name: 'Đinh Văn G',   stallCode: 'D-01', status: VendorStatus.active, phone: '0907777777', address: 'Khu hải sản', goodsType: 'Tươi sống', taxAmount: 600000),
  const VendorModel(id: '8', name: 'Vũ Thị H',     stallCode: 'D-02', status: VendorStatus.active, phone: '0908888888', address: 'Khu bánh kẹo', goodsType: 'Bánh kẹo', taxAmount: 500000),
];
