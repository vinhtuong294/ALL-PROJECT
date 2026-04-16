import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  List<dynamic> _items = [];
  double _avgRating = 0;
  int _totalReviews = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getReviews(page: 1, limit: 50);
      if (mounted) {
        setState(() {
          _items = data['items'] ?? [];
          _avgRating = (data['danh_gia_trung_binh'] ?? 0).toDouble();
          _totalReviews = data['tong_danh_gia'] ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Đánh giá của tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2F8000)))
          : RefreshIndicator(
              color: const Color(0xFF2F8000),
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2F8000), Color(0xFF4CAF50)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF2F8000).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: Column(children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        _avgRating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 48),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          return Icon(
                            i < _avgRating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 28,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_totalReviews đánh giá',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // Reviews list
                  Text('Đánh giá gần đây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade800)),
                  const SizedBox(height: 12),

                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(children: [
                        Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('Chưa có đánh giá nào', style: TextStyle(color: Colors.grey, fontSize: 15)),
                      ]),
                    )
                  else
                    ..._items.map((r) => _buildReviewCard(r)),
                ],
              ),
            ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] ?? 0) as num;
    final dateStr = review['ngay'] ?? '';
    final date = DateTime.tryParse(dateStr);
    final dateLabel = date != null ? '${date.day}/${date.month}/${date.year}' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.shade50,
                radius: 20,
                child: Text(
                  (review['ten_nguoi_mua'] ?? 'K')[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2F8000), fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['ten_nguoi_mua'] ?? 'Khách hàng',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(dateLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating.toInt() ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
            ],
          ),
          if (review['comment'] != null && review['comment'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Text(
                review['comment'],
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
              ),
            ),
          ],
          if (review['order_id'] != null) ...[
            const SizedBox(height: 8),
            Text('Đơn: ${review['order_id']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ],
      ),
    );
  }
}
