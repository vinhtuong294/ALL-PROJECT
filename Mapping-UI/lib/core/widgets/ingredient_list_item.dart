import 'package:flutter/material.dart';

/// Ingredient List Item Widget
/// Hiển thị từng nguyên liệu trong danh sách (tên, định lượng, đơn vị)
class IngredientListItem extends StatelessWidget {
  final String tenNguyenLieu;
  final String? dinhLuong;
  final String? donViGoc;

  const IngredientListItem({
    super.key,
    required this.tenNguyenLieu,
    this.dinhLuong,
    this.donViGoc,
  });

  /// Format định lượng: loại bỏ số 0 thừa ở cuối
  /// VD: "0.500000000" -> "0.5", "2.000000" -> "2"
  String _formatDinhLuong(String? value) {
    if (value == null || value.isEmpty) return '';
    
    // Thử parse thành số
    final number = double.tryParse(value);
    if (number == null) return value;
    
    // Nếu là số nguyên, hiển thị không có phần thập phân
    if (number == number.toInt()) {
      return number.toInt().toString();
    }
    
    // Nếu có phần thập phân, loại bỏ số 0 thừa
    String formatted = number.toString();
    // Loại bỏ các số 0 ở cuối sau dấu thập phân
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      // Nếu chỉ còn dấu chấm, xóa luôn
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final formattedDinhLuong = _formatDinhLuong(dinhLuong);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tenNguyenLieu,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF000000),
              ),
            ),
          ),
          if (formattedDinhLuong.isNotEmpty)
            Text(
              formattedDinhLuong,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF000000),
              ),
            ),
          if (formattedDinhLuong.isNotEmpty) const SizedBox(width: 8),
          if (donViGoc != null)
            Text(
              donViGoc!,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF757575),
              ),
            ),
        ],
      ),
    );
  }
}
