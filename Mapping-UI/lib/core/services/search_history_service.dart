import 'package:shared_preferences/shared_preferences.dart';

/// Service để quản lý lịch sử tìm kiếm
class SearchHistoryService {
  static const String _keySearchHistory = 'search_history';
  static const int _maxHistoryItems = 10;

  final SharedPreferences _prefs;

  SearchHistoryService(this._prefs);

  /// Lấy danh sách lịch sử tìm kiếm
  List<String> getSearchHistory() {
    return _prefs.getStringList(_keySearchHistory) ?? [];
  }

  /// Thêm từ khóa vào lịch sử
  Future<void> addSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    final history = getSearchHistory();
    
    // Xóa query cũ nếu đã tồn tại
    history.remove(query);
    
    // Thêm query mới vào đầu danh sách
    history.insert(0, query);
    
    // Giới hạn số lượng
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }
    
    await _prefs.setStringList(_keySearchHistory, history);
  }

  /// Xóa một item khỏi lịch sử
  Future<void> removeSearchQuery(String query) async {
    final history = getSearchHistory();
    history.remove(query);
    await _prefs.setStringList(_keySearchHistory, history);
  }

  /// Xóa toàn bộ lịch sử
  Future<void> clearSearchHistory() async {
    await _prefs.remove(_keySearchHistory);
  }
}
