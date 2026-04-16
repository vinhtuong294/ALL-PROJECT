import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dngo/core/dependency/injection.dart';
import 'package:dngo/core/services/mon_an_service.dart';
import 'package:dngo/core/services/auth/auth_service.dart';
import 'package:dngo/core/error/exceptions.dart';
import 'package:dngo/core/models/mon_an_model.dart';
import 'search_result_state.dart';

/// Cubit for managing SearchResult screen state and business logic
class SearchResultCubit extends Cubit<SearchResultState> {
  final MonAnService _monAnService = getIt<MonAnService>();
  
  SearchResultCubit() : super(SearchResultInitial());

  /// Load search results with products from API
  Future<void> loadSearchResults({String query = ''}) async {
    emit(SearchResultLoading());

    try {
      // Fetch danh sách món ăn từ API với search query
      final monAnList = await _monAnService.getMonAnList(
        page: 1,
        limit: 12,
        search: query,
        sort: 'ten_mon_an',
        order: 'asc',
      );

      // Check if cubit is still open before continuing
      if (isClosed) return;

      // Fetch chi tiết (ảnh) cho từng món ăn
      final monAnWithImages = await _fetchMonAnImages(monAnList);

      // Check if cubit is still open before emitting final state
      if (isClosed) return;

      emit(SearchResultLoaded(
        searchQuery: query,
        selectedMarket: 'MM, ĐÀ NẴNG',
        selectedLocation: 'Chợ Bắc Mỹ An',
        monAnList: monAnWithImages,
        currentPage: 1,
        hasMore: monAnList.length >= 12,
        selectedBottomNavIndex: 0,
      ));
    } on UnauthorizedException {
      // Token hết hạn - logout và yêu cầu đăng nhập lại
      final authService = getIt<AuthService>();
      await authService.logout();
      if (!isClosed) {
        emit(const SearchResultError(
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          requiresLogin: true,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(SearchResultError('Lỗi khi tìm kiếm: $e'));
      }
    }
  }

  /// Fetch chi tiết (ảnh, thời gian nấu, độ khó, khẩu phần) cho danh sách món ăn
  Future<List<MonAnWithImage>> _fetchMonAnImages(List<MonAnModel> monAnList) async {
    final result = <MonAnWithImage>[];

    for (final monAn in monAnList) {
      try {
        // Gọi API detail để lấy ảnh và thông tin chi tiết
        final detail = await _monAnService.getMonAnDetail(monAn.maMonAn);
        result.add(MonAnWithImage(
          monAn: monAn,
          imageUrl: detail.hinhAnh,
          cookTime: detail.khoangThoiGian ?? 40, // khoang_thoi_gian
          difficulty: detail.doKho ?? 'Dễ', // do_kho
          servings: detail.khauPhanTieuChuan ?? 4, // khau_phan_tieu_chuan
        ));
      } catch (e) {
        // Nếu lỗi, dùng giá trị mặc định
        print('Lỗi khi lấy chi tiết cho món ${monAn.maMonAn}: $e');
        result.add(MonAnWithImage(
          monAn: monAn,
          imageUrl: '',
          cookTime: 40,
          difficulty: 'Dễ',
          servings: 4,
        ));
      }
    }

    return result;
  }

  /// Load thêm món ăn (pagination)
  Future<void> loadMoreResults() async {
    // Chỉ load khi đang ở state SearchResultLoaded và không đang load
    if (state is! SearchResultLoaded) return;

    final currentState = state as SearchResultLoaded;

    // Nếu không còn data hoặc đang load thì return
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    // Emit state đang load more
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      // Fetch trang tiếp theo
      final nextPage = currentState.currentPage + 1;
      final newMonAnList = await _monAnService.getMonAnList(
        page: nextPage,
        limit: 12,
        search: currentState.searchQuery,
        sort: 'ten_mon_an',
        order: 'asc',
      );

      // Check if cubit is still open
      if (isClosed) return;

      // Fetch ảnh cho món ăn mới
      final newMonAnWithImages = await _fetchMonAnImages(newMonAnList);

      // Check if cubit is still open
      if (isClosed) return;

      // Merge danh sách cũ với danh sách mới
      final updatedList = [...currentState.monAnList, ...newMonAnWithImages];

      // Emit state mới với dữ liệu đã merge
      emit(currentState.copyWith(
        monAnList: updatedList,
        currentPage: nextPage,
        hasMore: newMonAnList.length >= 12,
        isLoadingMore: false,
      ));
    } catch (e) {
      // Nếu lỗi, chỉ tắt loading indicator
      if (!isClosed && state is SearchResultLoaded) {
        emit((state as SearchResultLoaded).copyWith(isLoadingMore: false));
      }
      print('Lỗi khi load thêm kết quả: $e');
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    if (state is SearchResultLoaded) {
      emit((state as SearchResultLoaded).copyWith(searchQuery: query));
    }
  }

  /// Quick add item to cart
  void quickAddItem(String productName) {
    print('Quick adding item: $productName');
    // In a real app, this would add the item to cart
  }

  /// Navigate to product detail
  void navigateToProductDetail(SearchResultProduct product) {
    print('Navigating to product: ${product.name}');
    // In a real app, this would navigate to product detail screen
  }

  /// Navigate to filter screen
  void navigateToFilter() {
    print('Navigating to filter');
    // In a real app, this would navigate to filter screen
  }

  /// Handle market/location selection
  void selectMarketLocation(String market, String location) {
    if (state is SearchResultLoaded) {
      emit((state as SearchResultLoaded).copyWith(
        selectedMarket: market,
        selectedLocation: location,
      ));
    }
  }

  /// Handle bottom navigation bar item tap
  void changeBottomNavIndex(int index) {
    if (state is SearchResultLoaded) {
      emit((state as SearchResultLoaded).copyWith(selectedBottomNavIndex: index));
    }
  }

  /// Navigate back
  void navigateBack() {
    print('Navigating back');
    // In a real app, this would pop the navigation stack
  }
}
