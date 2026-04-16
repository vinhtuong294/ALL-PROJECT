import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'category_ingredient_state.dart';
import '../../../../../../core/services/nguyen_lieu_service.dart';
import '../../../../../../core/dependency/injection.dart';
import '../../../../../../core/utils/price_formatter.dart';

/// Cubit quản lý state cho Category Ingredient Screen
class CategoryIngredientCubit extends Cubit<CategoryIngredientState> {
  NguyenLieuService? _nguyenLieuService;

  CategoryIngredientCubit() : super(const CategoryIngredientInitial()) {
    try {
      _nguyenLieuService = getIt<NguyenLieuService>();
    } catch (e) {
      debugPrint('⚠️ NguyenLieuService not registered');
    }
  }

  /// Load nguyên liệu theo danh mục
  Future<void> loadIngredientsByCategory(String categoryId, String categoryName) async {
    emit(const CategoryIngredientLoading());

    try {
      if (_nguyenLieuService == null) {
        throw Exception('NguyenLieuService not available');
      }

      debugPrint('🔍 [CategoryIngredientCubit] Loading ingredients for category: $categoryName ($categoryId)');

      // Gọi API với maNhomNguyenLieu để server filter
      final response = await _nguyenLieuService!.getNguyenLieuList(
        page: 1,
        limit: 20,
        sort: 'ten_nguyen_lieu',
        order: 'asc',
        hinhAnh: true,
        maNhomNguyenLieu: categoryId,
      );

      if (isClosed) return;

      debugPrint('✅ [CategoryIngredientCubit] Found ${response.data.length} ingredients in category');

      final ingredients = response.data.map((item) {
        return CategoryIngredientItem(
          maNguyenLieu: item.maNguyenLieu,
          tenNguyenLieu: item.tenNguyenLieu,
          hinhAnh: item.hinhAnh,
          price: _formatPrice(item.giaCuoi, item.giaGoc),
          originalPrice: _formatOriginalPrice(item.giaGoc, item.giaCuoi),
          hasDiscount: _hasDiscount(item.giaGoc, item.giaCuoi),
          tenNhomNguyenLieu: item.tenNhomNguyenLieu,
          soGianHang: item.soGianHang,
        );
      }).toList();

      emit(CategoryIngredientLoaded(
        categoryId: categoryId,
        categoryName: categoryName,
        ingredients: ingredients,
        currentPage: 1,
        hasMore: response.meta.hasNext,
        isLoadingMore: false,
      ));
    } catch (e) {
      debugPrint('❌ [CategoryIngredientCubit] Error: $e');
      if (!isClosed) {
        emit(CategoryIngredientError('Lỗi khi tải nguyên liệu: $e'));
      }
    }
  }

  /// Load more ingredients
  Future<void> loadMore() async {
    if (state is! CategoryIngredientLoaded) return;

    final currentState = state as CategoryIngredientLoaded;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      if (_nguyenLieuService == null) return;

      final nextPage = currentState.currentPage + 1;
      // Gọi API với maNhomNguyenLieu để server filter
      final response = await _nguyenLieuService!.getNguyenLieuList(
        page: nextPage,
        limit: 20,
        sort: 'ten_nguyen_lieu',
        order: 'asc',
        hinhAnh: true,
        maNhomNguyenLieu: currentState.categoryId,
      );

      if (isClosed) return;

      final newIngredients = response.data.map((item) {
        return CategoryIngredientItem(
          maNguyenLieu: item.maNguyenLieu,
          tenNguyenLieu: item.tenNguyenLieu,
          hinhAnh: item.hinhAnh,
          price: _formatPrice(item.giaCuoi, item.giaGoc),
          originalPrice: _formatOriginalPrice(item.giaGoc, item.giaCuoi),
          hasDiscount: _hasDiscount(item.giaGoc, item.giaCuoi),
          tenNhomNguyenLieu: item.tenNhomNguyenLieu,
          soGianHang: item.soGianHang,
        );
      }).toList();

      emit(currentState.copyWith(
        ingredients: [...currentState.ingredients, ...newIngredients],
        currentPage: nextPage,
        hasMore: response.meta.hasNext,
        isLoadingMore: false,
      ));
    } catch (e) {
      debugPrint('❌ [CategoryIngredientCubit] Load more error: $e');
      if (!isClosed && state is CategoryIngredientLoaded) {
        emit((state as CategoryIngredientLoaded).copyWith(isLoadingMore: false));
      }
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    if (state is CategoryIngredientLoaded) {
      final currentState = state as CategoryIngredientLoaded;
      await loadIngredientsByCategory(currentState.categoryId, currentState.categoryName);
    }
  }

  // Helper methods
  String _formatPrice(String? giaCuoi, double? giaGoc) {
    if (giaCuoi != null && giaCuoi.isNotEmpty && giaCuoi != 'null') {
      final parsed = PriceFormatter.parsePrice(giaCuoi);
      if (parsed != null && parsed > 0) {
        return PriceFormatter.formatPrice(parsed);
      }
    }
    if (giaGoc != null && giaGoc > 0) {
      return PriceFormatter.formatPrice(giaGoc);
    }
    return '0đ';
  }

  String? _formatOriginalPrice(double? giaGoc, String? giaCuoi) {
    if (giaGoc == null || giaGoc <= 0) return null;
    if (giaCuoi == null || giaCuoi.isEmpty || giaCuoi == 'null') return null;
    return PriceFormatter.formatPrice(giaGoc);
  }

  bool _hasDiscount(double? giaGoc, String? giaCuoi) {
    if (giaGoc == null || giaGoc <= 0) return false;
    if (giaCuoi == null || giaCuoi.isEmpty || giaCuoi == 'null') return false;
    return true;
  }
}
