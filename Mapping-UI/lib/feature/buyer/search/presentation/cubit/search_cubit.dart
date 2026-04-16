import 'dart:async';
// Triggering hot-reload fix
import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_state.dart';
import 'package:dngo/core/services/search_service.dart';
import 'package:dngo/core/services/search_history_service.dart';
import 'package:dngo/core/services/mon_an_service.dart';
import 'package:dngo/core/services/nguyen_lieu_service.dart';
import 'package:dngo/core/models/search_response.dart';
import 'package:dngo/core/models/nguyen_lieu_model.dart';
import 'package:dngo/core/dependency/injection.dart';

/// Cubit quản lý search
class SearchCubit extends Cubit<SearchState> {
  final SearchService _searchService = getIt<SearchService>();
  final SearchHistoryService _historyService = getIt<SearchHistoryService>();
  final MonAnService _monAnService = getIt<MonAnService>();
  final NguyenLieuService _nguyenLieuService = getIt<NguyenLieuService>();

  Timer? _debounceTimer;
  String _lastQuery = '';

  SearchCubit() : super(const SearchInitial());

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  /// Load lịch sử tìm kiếm
  void loadHistory() {
    final history = _historyService.getSearchHistory();
    emit(SearchInitial(searchHistory: history));
  }

  /// Suggest khi gõ - có debounce 300ms
  void suggest(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      loadHistory();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(query.trim());
    });
  }

  /// Fetch suggestions từ API
  Future<void> _fetchSuggestions(String query) async {
    if (query == _lastQuery) return;
    _lastQuery = query;

    final history = _historyService.getSearchHistory();
    emit(SearchSuggesting(query: query));

    try {
      // Composite search for suggestions
      final results = await Future.wait([
        _searchService.search(query),
        _monAnService.getMonAnList(search: query, limit: 5),
        _nguyenLieuService.getNguyenLieuList(search: query, limit: 5),
      ]);

      if (isClosed) return;

      final searchResponse = results[0] as SearchResponse;
      final dishesFromMonAn = results[1] as List;
      final ingredientsFromNguyenLieu = (results[2] as dynamic).data;

      // Merge results
      final mergedData = _mergeSearchResults(
        searchResponse.data,
        dishesFromMonAn,
        ingredientsFromNguyenLieu,
      );

      if (mergedData.isEmpty) {
        emit(SearchInitial(searchHistory: history));
      } else {
        emit(SearchSuggestionsLoaded(
          data: mergedData,
          query: query,
          searchHistory: history,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(SearchInitial(searchHistory: history));
      }
    }
  }

  /// Helper to merge search results from multiple sources
  SearchData _mergeSearchResults(
    SearchData original,
    List dishesFromMonAn,
    List ingredientsFromNguyenLieu,
  ) {
    final dishIds = original.dishes.map((d) => d.id).toSet();
    final ingredientIds = original.ingredients.map((i) => i.id).toSet();

    final mergedDishes = List<SearchDish>.from(original.dishes);
    final mergedIngredients = List<SearchIngredient>.from(original.ingredients);

    // Add unique dishes from MonAnService
    for (var item in dishesFromMonAn) {
      final id = item.maMonAn;
      if (!dishIds.contains(id)) {
        mergedDishes.add(SearchDish(
          id: id,
          name: item.tenMonAn,
          type: 'dish',
          image: item.hinhAnh,
        ));
        dishIds.add(id);
      }
    }

    // Add unique ingredients from NguyenLieuService
    for (var item in ingredientsFromNguyenLieu) {
      final id = item.maNguyenLieu;
      if (!ingredientIds.contains(id)) {
        mergedIngredients.add(SearchIngredient(
          id: id,
          name: item.tenNguyenLieu,
          type: 'ingredient',
          image: item.hinhAnh,
        ));
        ingredientIds.add(id);
      }
    }

    return SearchData(
      stalls: original.stalls,
      dishes: mergedDishes,
      ingredients: mergedIngredients,
    );
  }

  /// Tìm kiếm với query (khi submit)
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      loadHistory();
      return;
    }

    emit(const SearchLoading());

    try {
      await _historyService.addSearchQuery(query.trim());
      
      // Composite search
      final results = await Future.wait([
        _searchService.search(query.trim()),
        _monAnService.getMonAnList(search: query.trim(), limit: 50),
        _nguyenLieuService.getNguyenLieuList(search: query.trim(), limit: 50),
      ]);

      if (isClosed) return;

      final searchResponse = results[0] as SearchResponse;
      final dishesFromMonAn = results[1] as List;
      final ingredientsFromNguyenLieu = (results[2] as dynamic).data;

      // Merge results
      final mergedData = _mergeSearchResults(
        searchResponse.data,
        dishesFromMonAn,
        ingredientsFromNguyenLieu,
      );

      if (mergedData.isEmpty) {
        emit(SearchEmpty(query: query));
      } else {
        emit(SearchSuccess(data: mergedData, query: query));
      }
    } catch (e) {
      emit(SearchError(message: e.toString()));
    }
  }

  /// Xóa một item khỏi lịch sử
  Future<void> removeHistoryItem(String query) async {
    await _historyService.removeSearchQuery(query);
    loadHistory();
  }

  /// Xóa toàn bộ lịch sử
  Future<void> clearHistory() async {
    await _historyService.clearSearchHistory();
    loadHistory();
  }

  /// Clear search
  void clear() {
    _lastQuery = '';
    _debounceTimer?.cancel();
    loadHistory();
  }
}
