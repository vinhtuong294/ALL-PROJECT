import 'dart:convert';

/// Helper to parse dia_chi_giao_hang which can be JSON string or plain text
class AddressHelper {
  final String name;
  final String phone;
  final String address;

  AddressHelper({required this.name, required this.phone, required this.address});

  factory AddressHelper.parse(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AddressHelper(
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
        address: map['address'] ?? '',
      );
    } catch (_) {
      return AddressHelper(name: '', phone: '', address: raw);
    }
  }
}

/// Format VND currency
String formatVND(dynamic amount) {
  if (amount == null) return '0đ';
  final n = (amount is int) ? amount : (amount as num).toInt();
  final s = n.toString();
  final buf = StringBuffer();
  int count = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    buf.write(s[i]);
    count++;
    if (count % 3 == 0 && i > 0 && s[i] != '-') buf.write('.');
  }
  return '${buf.toString().split('').reversed.join()}đ';
}

/// Map order status to Vietnamese label
String statusLabel(String? status) {
  switch (status) {
    case 'cho_xac_nhan': return 'Chờ xác nhận';
    case 'da_xac_nhan': return 'Đã xác nhận';
    case 'cho_shipper': return 'Đã nhận đơn';
    case 'dang_lay_hang': return 'Đang lấy hàng';
    case 'dang_giao': return 'Đang giao hàng';
    case 'da_giao': return 'Đã giao';
    case 'hoan_thanh': return 'Hoàn thành';
    case 'giao_that_bai': return 'Giao thất bại';
    case 'da_huy': return 'Đã hủy';
    default: return status ?? 'N/A';
  }
}
