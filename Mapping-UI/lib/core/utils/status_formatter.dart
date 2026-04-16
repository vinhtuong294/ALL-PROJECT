/// Utility class để format các trạng thái từ server
class StatusFormatter {
  StatusFormatter._();

  /// Map các từ tiếng Việt không dấu sang có dấu
  static const Map<String, String> _vietnameseWords = {
    'chua': 'Chưa',
    'da': 'Đã',
    'dang': 'Đang',
    'cho': 'Chờ',
    'thanh': 'thanh',
    'toan': 'toán',
    'xac': 'xác',
    'nhan': 'nhận',
    'xu': 'xử',
    'ly': 'lý',
    'giao': 'giao',
    'hang': 'hàng',
    'hoan': 'hoàn',
    'huy': 'hủy',
    'tra': 'trả',
    'tien': 'tiền',
    'that': 'thất',
    'bai': 'bại',
    'mat': 'mặt',
    'chuyen': 'chuyển',
    'khoan': 'khoản',
    'nguoi': 'người',
    'mua': 'mua',
    'ban': 'bán',
    'quan': 'quản',
    'tri': 'trị',
    'vien': 'viên',
    'nam': 'Nam',
    'nu': 'Nữ',
    'khac': 'Khác',
    'xong': 'xong',
    'moi': 'mới',
    'cu': 'cũ',
    'tot': 'tốt',
    'xau': 'xấu',
    'lon': 'lớn',
    'nho': 'nhỏ',
    'nhieu': 'nhiều',
    'it': 'ít',
    'het': 'hết',
    'con': 'còn',
    'san': 'sẵn',
    'sang': 'sàng',
    'doi': 'đợi',
    'duyet': 'duyệt',
    'tu': 'từ',
    'choi': 'chối',
    'dong': 'đóng',
    'mo': 'mở',
    'bat': 'bật',
    'tat': 'tắt',
    'hoat': 'hoạt',
    'khong': 'không',
    'co': 'có',
    'la': 'là',
    'va': 'và',
    'cua': 'của',
    'trong': 'trong',
    'ngoai': 'ngoài',
    'tren': 'trên',
    'duoi': 'dưới',
    'truoc': 'trước',
    'sau': 'sau',
    'giua': 'giữa',
    'ben': 'bên',
    'canh': 'cạnh',
  };

  /// Format trạng thái đơn hàng
  /// Ví dụ: 'chua_thanh_toan' -> 'Chưa thanh toán'
  static String formatOrderStatus(String? status) {
    if (status == null || status.isEmpty) return 'Không xác định';

    switch (status.toLowerCase()) {
      // Trạng thái thanh toán
      case 'chua_thanh_toan':
        return 'Chưa thanh toán';
      case 'da_thanh_toan':
        return 'Đã thanh toán';
      case 'cho_thanh_toan':
        return 'Chờ thanh toán';
      case 'thanh_toan_that_bai':
        return 'Thanh toán thất bại';

      // Trạng thái đơn hàng
      case 'chua_xac_nhan':
      case 'cho_xac_nhan':
        return 'Chờ xác nhận';
      case 'da_xac_nhan':
        return 'Đã xác nhận';
      case 'dang_xu_ly':
        return 'Đang xử lý';
      case 'dang_giao':
        return 'Đang giao hàng';
      case 'da_giao':
        return 'Đã giao hàng';
      case 'hoan_thanh':
        return 'Hoàn thành';
      case 'da_huy':
      case 'huy':
        return 'Đã hủy';
      case 'tra_hang':
        return 'Trả hàng';
      case 'hoan_tien':
        return 'Hoàn tiền';

      // Trạng thái chung
      case 'pending':
        return 'Đang chờ';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'paid':
        return 'Đã thanh toán';
      case 'unpaid':
        return 'Chưa thanh toán';

      default:
        // Nếu không match, convert snake_case thành tiếng Việt có dấu
        return formatSnakeCaseToVietnamese(status);
    }
  }

  /// Format bất kỳ snake_case nào thành tiếng Việt có dấu
  /// Ví dụ: 'chua_thanh_toan' -> 'Chưa thanh toán'
  static String formatSnakeCaseToVietnamese(String text) {
    if (text.isEmpty) return text;

    final words = text.toLowerCase().split('_');
    final result = <String>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;

      // Tìm từ trong map
      final vietnameseWord = _vietnameseWords[word];
      if (vietnameseWord != null) {
        // Viết hoa chữ cái đầu nếu là từ đầu tiên
        if (i == 0) {
          result.add(vietnameseWord[0].toUpperCase() + vietnameseWord.substring(1));
        } else {
          result.add(vietnameseWord.toLowerCase());
        }
      } else {
        // Nếu không tìm thấy, giữ nguyên và viết hoa chữ đầu nếu là từ đầu
        if (i == 0) {
          result.add(word[0].toUpperCase() + word.substring(1));
        } else {
          result.add(word);
        }
      }
    }

    return result.join(' ');
  }

  /// Format phương thức thanh toán
  static String formatPaymentMethod(String? method) {
    if (method == null || method.isEmpty) return 'Không xác định';

    switch (method.toLowerCase()) {
      case 'tien_mat':
      case 'cash':
      case 'cod':
        return 'Tiền mặt';
      case 'chuyen_khoan':
      case 'bank_transfer':
        return 'Chuyển khoản';
      case 'vnpay':
        return 'VNPay';
      case 'momo':
        return 'MoMo';
      case 'zalopay':
        return 'ZaloPay';
      default:
        return _snakeCaseToTitleCase(method);
    }
  }

  /// Format giới tính
  static String formatGender(String? gender) {
    if (gender == null || gender.isEmpty) return 'Không xác định';

    switch (gender.toUpperCase()) {
      case 'M':
      case 'MALE':
      case 'NAM':
        return 'Nam';
      case 'F':
      case 'FEMALE':
      case 'NU':
        return 'Nữ';
      default:
        return 'Khác';
    }
  }

  /// Format vai trò
  static String formatRole(String? role) {
    if (role == null || role.isEmpty) return 'Không xác định';

    switch (role.toLowerCase()) {
      case 'buyer':
      case 'nguoi_mua':
        return 'Người mua';
      case 'seller':
      case 'nguoi_ban':
        return 'Người bán';
      case 'admin':
        return 'Quản trị viên';
      default:
        return _snakeCaseToTitleCase(role);
    }
  }

  /// Convert snake_case thành Title Case (fallback)
  /// Ví dụ: 'chua_thanh_toan' -> 'Chua Thanh Toan'
  static String _snakeCaseToTitleCase(String text) {
    // Sử dụng formatSnakeCaseToVietnamese để có dấu tiếng Việt
    return formatSnakeCaseToVietnamese(text);
  }

  /// Lấy màu cho trạng thái đơn hàng
  static StatusColor getOrderStatusColor(String? status) {
    if (status == null || status.isEmpty) {
      return StatusColor.grey;
    }

    switch (status.toLowerCase()) {
      case 'da_thanh_toan':
      case 'paid':
      case 'hoan_thanh':
      case 'completed':
      case 'da_giao':
        return StatusColor.green;

      case 'dang_xu_ly':
      case 'processing':
      case 'dang_giao':
      case 'da_xac_nhan':
        return StatusColor.blue;

      case 'chua_thanh_toan':
      case 'unpaid':
      case 'cho_thanh_toan':
      case 'pending':
      case 'chua_xac_nhan':
        return StatusColor.orange;

      case 'da_huy':
      case 'huy':
      case 'cancelled':
      case 'thanh_toan_that_bai':
        return StatusColor.red;

      default:
        return StatusColor.grey;
    }
  }
}

/// Enum cho màu trạng thái
enum StatusColor {
  green,
  blue,
  orange,
  red,
  grey,
}
