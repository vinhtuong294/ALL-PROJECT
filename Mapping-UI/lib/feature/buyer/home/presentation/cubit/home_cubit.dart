import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '../../../../../core/services/chat_ai_service.dart';
import '../../../../../core/services/auth/auth_service.dart';
import '../../../../../core/dependency/injection.dart';

/// Cubit quản lý state cho Home Screen
class HomeCubit extends Cubit<HomeState> {
  final ChatAIService _chatAIService = getIt<ChatAIService>();
  final AuthService _authService = getIt<AuthService>();
  
  HomeCubit() : super(const HomeState());

  /// Khởi tạo màn hình home với tin nhắn chào mừng
  Future<void> initializeHome() async {
    // Lấy tên user từ API /me
    String userName = 'bạn';
    try {
      final user = await _authService.getCurrentUser();
      if (user.tenNguoiDung.isNotEmpty) {
        userName = user.tenNguoiDung;
      } else if (user.tenDangNhap.isNotEmpty) {
        userName = user.tenDangNhap;
      }
    } catch (e) {
      // Nếu lỗi, thử lấy từ local storage
      try {
        final userData = await _authService.getUserData();
        if (userData != null && userData.tenDangNhap.isNotEmpty) {
          userName = userData.tenDangNhap;
        }
      } catch (e) {
        // Nếu vẫn lỗi, dùng tên mặc định
      }
    }

    final welcomeMessage = ChatMessage(
      message: 'Chào buổi sáng $userName, bạn muốn nấu món gì hôm nay?',
      isBot: true,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      userName: userName,
      chatMessages: [welcomeMessage],
    ));
  }

  /// Gửi tin nhắn từ người dùng
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final userMessage = ChatMessage(
      message: message,
      isBot: false,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.chatMessages, userMessage];
    emit(state.copyWith(chatMessages: updatedMessages, isTyping: true));

    // Gọi API chat AI
    await _sendToAI(message);
  }

  /// Gửi tin nhắn đến AI và nhận phản hồi
  Future<void> _sendToAI(String message) async {
    try {
      final response = await _chatAIService.sendMessage(
        message: message,
        conversationId: state.conversationId,
      );

      if (isClosed) return;

      // Convert suggestions từ API sang model của HomeState
      List<MonAnSuggestion>? monAnSuggestions;
      if (response.suggestions != null && response.suggestions!.monAn.isNotEmpty) {
        monAnSuggestions = response.suggestions!.monAn
            .map((item) => MonAnSuggestion(
                  maMonAn: item.maMonAn,
                  tenMonAn: item.tenMonAn,
                  hinhAnh: item.hinhAnh,
                ))
            .toList();
      }

      List<NguyenLieuSuggestion>? nguyenLieuSuggestions;
      if (response.suggestions != null && response.suggestions!.nguyenLieu.isNotEmpty) {
        nguyenLieuSuggestions = response.suggestions!.nguyenLieu
            .map((item) => NguyenLieuSuggestion(
                  maNguyenLieu: item.maNguyenLieu,
                  tenNguyenLieu: item.tenNguyenLieu,
                  donVi: item.donVi,
                  dinhLuong: item.dinhLuong,
                  hinhAnh: item.hinhAnh,
                  gianHangSuggest: item.gianHangSuggest != null
                      ? GianHangSuggest(
                          maGianHang: item.gianHangSuggest!.maGianHang,
                          tenGianHang: item.gianHangSuggest!.tenGianHang,
                          viTri: item.gianHangSuggest!.viTri,
                          gia: item.gianHangSuggest!.gia,
                          donViBan: item.gianHangSuggest!.donViBan,
                          soLuong: item.gianHangSuggest!.soLuong,
                        )
                      : null,
                  canAddToCart: item.actions.canAddToCart,
                ))
            .toList();
      }

      // Convert menus từ API sang model của HomeState
      List<MenuSelection>? menus;
      if (response.menus != null && response.menus!.isNotEmpty) {
        menus = response.menus!
            .map((item) => MenuSelection(
                  menuId: item.menuId,
                  tenMenu: item.tenMenu,
                  moTa: item.moTa,
                  phuHopVoi: item.phuHopVoi,
                  icon: item.icon,
                  monAn: item.monAn
                      .map((dish) => MenuDish(
                            maMonAn: dish.maMonAn,
                            tenMonAn: dish.tenMonAn,
                            vaiTro: dish.vaiTro,
                          ))
                      .toList(),
                ))
            .toList();
      }

      // Convert selected menu từ API sang model của HomeState
      SelectedMenuDetail? selectedMenu;
      if (response.selectedMenu != null) {
        selectedMenu = SelectedMenuDetail(
          menuId: response.selectedMenu!.menuId,
          tenMenu: response.selectedMenu!.tenMenu,
          moTa: response.selectedMenu!.moTa,
          phuHopVoi: response.selectedMenu!.phuHopVoi,
          icon: response.selectedMenu!.icon,
          monAn: response.selectedMenu!.monAn
              .map((dish) => MonAnDetail(
                    maMonAn: dish.maMonAn,
                    tenMonAn: dish.tenMonAn,
                    hinhAnh: dish.hinhAnh,
                    khoangThoiGian: dish.khoangThoiGian,
                    doKho: dish.doKho,
                    khauPhanTieuChuan: dish.khauPhanTieuChuan,
                    calories: dish.calories,
                    nguyenLieu: dish.nguyenLieu
                        .map((nl) => NguyenLieuDetail(
                              maNguyenLieu: nl.maNguyenLieu,
                              ten: nl.ten,
                              dinhLuong: nl.dinhLuong,
                              donVi: nl.donVi,
                              gianHang: nl.gianHang
                                  .map((gh) => GianHangDetail(
                                        maGianHang: gh.maGianHang,
                                        tenGianHang: gh.tenGianHang,
                                        viTri: gh.viTri,
                                        maCho: gh.maCho,
                                        gia: gh.gia,
                                        donViBan: gh.donViBan,
                                        soLuong: gh.soLuong,
                                      ))
                                  .toList(),
                            ))
                        .toList(),
                  ))
              .toList(),
        );
      }

      final botMessage = ChatMessage(
        message: response.message,
        isBot: true,
        timestamp: DateTime.now(),
        responseType: response.responseType,
        monAnSuggestions: monAnSuggestions,
        nguyenLieuSuggestions: nguyenLieuSuggestions,
        menus: menus,
        selectedMenu: selectedMenu,
        hint: response.hint,
      );

      final updatedMessages = [...state.chatMessages, botMessage];
      emit(state.copyWith(
        chatMessages: updatedMessages,
        isTyping: false,
        conversationId: response.conversationId,
      ));
    } catch (e) {
      debugPrint('❌ Error sending message to AI: $e');
      
      if (isClosed) return;

      final errorMessage = ChatMessage(
        message: 'Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.',
        isBot: true,
        timestamp: DateTime.now(),
      );

      final updatedMessages = [...state.chatMessages, errorMessage];
      emit(state.copyWith(
        chatMessages: updatedMessages,
        isTyping: false,
      ));
    }
  }

  /// Chọn option từ chat
  void selectOption(ChatOption option) {
    sendMessage(option.label);
  }

  /// Cập nhật search query
  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  /// Thực hiện tìm kiếm
  void performSearch() {
    if (state.searchQuery.trim().isNotEmpty) {
      // Navigate to search results
      sendMessage(state.searchQuery);
      emit(state.copyWith(searchQuery: ''));
    }
  }

  /// Thay đổi bottom navigation index
  void changeBottomNavIndex(int index) {
    emit(state.copyWith(selectedBottomNavIndex: index));
  }

  /// Thêm vào giỏ hàng
  void addToCart() {
    emit(state.copyWith(cartItemCount: state.cartItemCount + 1));
  }
}
