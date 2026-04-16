import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _items = [];
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getNotifications(page: 1, limit: 50);
      if (mounted) {
        setState(() {
          _items = data['items'] ?? [];
          _unreadCount = data['unread_count'] ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(int notiId, int index) async {
    try {
      await ApiService.markNotificationRead(notiId);
      if (mounted) {
        setState(() {
          _items[index]['is_read'] = true;
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
        });
      }
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      if (mounted) {
        setState(() {
          for (var item in _items) {
            item['is_read'] = true;
          }
          _unreadCount = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu tất cả đã đọc'), backgroundColor: Color(0xFF2F8000)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Đọc tất cả', style: TextStyle(color: Color(0xFF2F8000), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2F8000)))
          : _items.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.notifications_off_outlined, size: 72, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text('Chưa có thông báo', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ]),
                )
              : RefreshIndicator(
                  color: const Color(0xFF2F8000),
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) => _buildNotificationCard(_items[i], i),
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> noti, int index) {
    final isRead = noti['is_read'] == true;
    final dateStr = noti['created_at'] ?? '';
    final date = DateTime.tryParse(dateStr);
    final dateLabel = date != null
        ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
        : '';

    return GestureDetector(
      onTap: () {
        if (!isRead) _markRead(noti['noti_id'], index);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(14),
          border: isRead ? null : Border.all(color: const Color(0xFF2F8000).withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isRead ? Colors.grey.shade100 : const Color(0xFF2F8000).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(noti['title'] ?? ''),
                color: isRead ? Colors.grey : const Color(0xFF2F8000),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noti['title'] ?? 'Thông báo',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      fontSize: 14,
                      color: isRead ? Colors.black54 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    noti['body'] ?? '',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(dateLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(color: Color(0xFF2F8000), shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('đơn hàng') || lower.contains('order')) return Icons.local_shipping;
    if (lower.contains('thanh toán') || lower.contains('ví')) return Icons.payment;
    if (lower.contains('đánh giá')) return Icons.star;
    return Icons.notifications;
  }
}
