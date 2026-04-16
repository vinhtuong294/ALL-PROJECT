import 'mon_an_model.dart';

/// Model chứa danh sách món ăn và metadata từ API
class MonAnResponse {
  final List<MonAnModel> data;
  final MonAnMeta meta;

  MonAnResponse({
    required this.data,
    required this.meta,
  });

  factory MonAnResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'] as List<dynamic>? ?? [];
    final data = dataJson
        .map((item) => MonAnModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final metaJson = json['meta'] as Map<String, dynamic>?;
    final meta = metaJson != null
        ? MonAnMeta.fromJson(metaJson)
        : MonAnMeta(page: 1, limit: 12, total: data.length, hasNext: false);

    return MonAnResponse(data: data, meta: meta);
  }
}
