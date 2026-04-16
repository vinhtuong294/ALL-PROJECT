class ChatAIResponse {
  final bool success;
  final String responseType; // 'text', 'menu_selection', 'suggestions', 'menu_detail'
  final String message;
  final ChatSuggestions? suggestions;
  final List<MenuSelection>? menus;
  final SelectedMenuDetail? selectedMenu;
  final String? hint;
  final String conversationId;

  ChatAIResponse({
    required this.success,
    this.responseType = 'text',
    required this.message,
    this.suggestions,
    this.menus,
    this.selectedMenu,
    this.hint,
    required this.conversationId,
  });

  factory ChatAIResponse.fromJson(Map<String, dynamic> json) {
    return ChatAIResponse(
      success: json['success'] as bool,
      responseType: json['response_type'] as String? ?? 'text',
      message: json['message'] as String,
      suggestions: json['suggestions'] != null
          ? ChatSuggestions.fromJson(json['suggestions'] as Map<String, dynamic>)
          : null,
      menus: json['menus'] != null
          ? (json['menus'] as List)
              .map((item) => MenuSelection.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      selectedMenu: json['selected_menu'] != null
          ? SelectedMenuDetail.fromJson(json['selected_menu'] as Map<String, dynamic>)
          : null,
      hint: json['hint'] as String?,
      conversationId: json['conversation_id'] as String,
    );
  }
}

class ChatSuggestions {
  final List<MonAnSuggestion> monAn;
  final List<NguyenLieuSuggestion> nguyenLieu;

  ChatSuggestions({
    required this.monAn,
    required this.nguyenLieu,
  });

  factory ChatSuggestions.fromJson(Map<String, dynamic> json) {
    return ChatSuggestions(
      monAn: (json['mon_an'] as List?)
              ?.map((item) => MonAnSuggestion.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      nguyenLieu: (json['nguyen_lieu'] as List?)
              ?.map((item) => NguyenLieuSuggestion.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MonAnSuggestion {
  final String maMonAn;
  final String tenMonAn;
  final String hinhAnh;

  MonAnSuggestion({
    required this.maMonAn,
    required this.tenMonAn,
    required this.hinhAnh,
  });

  factory MonAnSuggestion.fromJson(Map<String, dynamic> json) {
    return MonAnSuggestion(
      maMonAn: json['ma_mon_an'] as String,
      tenMonAn: json['ten_mon_an'] as String,
      hinhAnh: json['hinh_anh'] as String,
    );
  }
}

class NguyenLieuSuggestion {
  final String maNguyenLieu;
  final String tenNguyenLieu;
  final String? donVi;
  final String? dinhLuong;
  final String? hinhAnh;
  final GianHangSuggest? gianHangSuggest;
  final NguyenLieuActions actions;

  NguyenLieuSuggestion({
    required this.maNguyenLieu,
    required this.tenNguyenLieu,
    this.donVi,
    this.dinhLuong,
    this.hinhAnh,
    this.gianHangSuggest,
    required this.actions,
  });

  factory NguyenLieuSuggestion.fromJson(Map<String, dynamic> json) {
    return NguyenLieuSuggestion(
      maNguyenLieu: json['ma_nguyen_lieu'] as String,
      tenNguyenLieu: json['ten_nguyen_lieu'] as String,
      donVi: json['don_vi'] as String?,
      dinhLuong: json['dinh_luong'] as String?,
      hinhAnh: json['hinh_anh'] as String?,
      gianHangSuggest: json['gian_hang_suggest'] != null
          ? GianHangSuggest.fromJson(json['gian_hang_suggest'] as Map<String, dynamic>)
          : null,
      actions: NguyenLieuActions.fromJson(json['actions'] as Map<String, dynamic>),
    );
  }
}

class GianHangSuggest {
  final String maGianHang;
  final String tenGianHang;
  final String viTri;
  final String gia;
  final String donViBan;
  final double soLuong;

  GianHangSuggest({
    required this.maGianHang,
    required this.tenGianHang,
    required this.viTri,
    required this.gia,
    required this.donViBan,
    required this.soLuong,
  });

  factory GianHangSuggest.fromJson(Map<String, dynamic> json) {
    return GianHangSuggest(
      maGianHang: json['ma_gian_hang'] as String,
      tenGianHang: json['ten_gian_hang'] as String,
      viTri: json['vi_tri'] as String,
      gia: json['gia'] as String,
      donViBan: json['don_vi_ban'] as String,
      soLuong: (json['so_luong'] as num).toDouble(),
    );
  }
}

class NguyenLieuActions {
  final bool canViewDetail;
  final bool canAddToCart;
  final String detailEndpoint;
  final String? addToCartEndpoint;

  NguyenLieuActions({
    required this.canViewDetail,
    required this.canAddToCart,
    required this.detailEndpoint,
    this.addToCartEndpoint,
  });

  factory NguyenLieuActions.fromJson(Map<String, dynamic> json) {
    return NguyenLieuActions(
      canViewDetail: json['can_view_detail'] as bool,
      canAddToCart: json['can_add_to_cart'] as bool,
      detailEndpoint: json['detail_endpoint'] as String,
      addToCartEndpoint: json['add_to_cart_endpoint'] as String?,
    );
  }
}


/// Model cho menu selection
class MenuSelection {
  final String menuId;
  final String tenMenu;
  final String moTa;
  final String phuHopVoi;
  final String icon;
  final List<MenuDish> monAn;

  MenuSelection({
    required this.menuId,
    required this.tenMenu,
    required this.moTa,
    required this.phuHopVoi,
    required this.icon,
    required this.monAn,
  });

  factory MenuSelection.fromJson(Map<String, dynamic> json) {
    return MenuSelection(
      menuId: json['menu_id'] as String,
      tenMenu: json['ten_menu'] as String,
      moTa: json['mo_ta'] as String,
      phuHopVoi: json['phu_hop_voi'] as String,
      icon: json['icon'] as String,
      monAn: (json['mon_an'] as List)
          .map((item) => MenuDish.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Model cho món ăn trong menu
class MenuDish {
  final String maMonAn;
  final String tenMonAn;
  final String vaiTro;

  MenuDish({
    required this.maMonAn,
    required this.tenMonAn,
    required this.vaiTro,
  });

  factory MenuDish.fromJson(Map<String, dynamic> json) {
    return MenuDish(
      maMonAn: json['ma_mon_an'] as String,
      tenMonAn: json['ten_mon_an'] as String,
      vaiTro: json['vai_tro'] as String,
    );
  }
}

/// Model cho menu detail (sau khi chọn menu)
class SelectedMenuDetail {
  final String menuId;
  final String tenMenu;
  final String moTa;
  final String phuHopVoi;
  final String icon;
  final List<MonAnDetail> monAn;

  SelectedMenuDetail({
    required this.menuId,
    required this.tenMenu,
    required this.moTa,
    required this.phuHopVoi,
    required this.icon,
    required this.monAn,
  });

  factory SelectedMenuDetail.fromJson(Map<String, dynamic> json) {
    return SelectedMenuDetail(
      menuId: json['menu_id'] as String,
      tenMenu: json['ten_menu'] as String,
      moTa: json['mo_ta'] as String,
      phuHopVoi: json['phu_hop_voi'] as String,
      icon: json['icon'] as String,
      monAn: (json['mon_an'] as List)
          .map((item) => MonAnDetail.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Model cho món ăn chi tiết
class MonAnDetail {
  final String maMonAn;
  final String tenMonAn;
  final String hinhAnh;
  final int khoangThoiGian;
  final String doKho;
  final int khauPhanTieuChuan;
  final int calories;
  final List<NguyenLieuDetail> nguyenLieu;

  MonAnDetail({
    required this.maMonAn,
    required this.tenMonAn,
    required this.hinhAnh,
    required this.khoangThoiGian,
    required this.doKho,
    required this.khauPhanTieuChuan,
    required this.calories,
    required this.nguyenLieu,
  });

  factory MonAnDetail.fromJson(Map<String, dynamic> json) {
    return MonAnDetail(
      maMonAn: json['ma_mon_an'] as String,
      tenMonAn: json['ten_mon_an'] as String,
      hinhAnh: json['hinh_anh'] as String,
      khoangThoiGian: json['khoang_thoi_gian'] as int,
      doKho: json['do_kho'] as String,
      khauPhanTieuChuan: json['khau_phan_tieu_chuan'] as int,
      calories: json['calories'] as int,
      nguyenLieu: (json['nguyen_lieu'] as List)
          .map((item) => NguyenLieuDetail.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Model cho nguyên liệu chi tiết trong món ăn
class NguyenLieuDetail {
  final String maNguyenLieu;
  final String ten;
  final String? dinhLuong;
  final String? donVi;
  final List<GianHangDetail> gianHang;

  NguyenLieuDetail({
    required this.maNguyenLieu,
    required this.ten,
    this.dinhLuong,
    this.donVi,
    required this.gianHang,
  });

  factory NguyenLieuDetail.fromJson(Map<String, dynamic> json) {
    return NguyenLieuDetail(
      maNguyenLieu: json['ma_nguyen_lieu'] as String,
      ten: json['ten'] as String,
      dinhLuong: json['dinh_luong'] as String?,
      donVi: json['don_vi'] as String?,
      gianHang: (json['gian_hang'] as List)
          .map((item) => GianHangDetail.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Model cho gian hàng chi tiết
class GianHangDetail {
  final String maGianHang;
  final String tenGianHang;
  final String viTri;
  final String maCho;
  final String gia;
  final String donViBan;
  final double soLuong;

  GianHangDetail({
    required this.maGianHang,
    required this.tenGianHang,
    required this.viTri,
    required this.maCho,
    required this.gia,
    required this.donViBan,
    required this.soLuong,
  });

  factory GianHangDetail.fromJson(Map<String, dynamic> json) {
    return GianHangDetail(
      maGianHang: json['ma_gian_hang'] as String,
      tenGianHang: json['ten_gian_hang'] as String,
      viTri: json['vi_tri'] as String,
      maCho: json['ma_cho'] as String,
      gia: json['gia'] as String,
      donViBan: json['don_vi_ban'] as String,
      soLuong: (json['so_luong'] as num).toDouble(),
    );
  }
}
