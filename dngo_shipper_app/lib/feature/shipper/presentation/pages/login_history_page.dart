import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';

class LoginHistoryPage extends StatefulWidget {
  const LoginHistoryPage({super.key});

  @override
  State<LoginHistoryPage> createState() => _LoginHistoryPageState();
}

class _LoginHistoryPageState extends State<LoginHistoryPage> {
  List<dynamic> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getLoginHistory();
      if (mounted) setState(() { _history = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(title: const Text('Lịch sử đăng nhập', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2F8000)))
          : _history.isEmpty
              ? const Center(child: Text('Không có lịch sử'))
              : RefreshIndicator(
                  color: const Color(0xFF2F8000),
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (ctx, i) => _buildCard(_history[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final dt = DateTime.tryParse(item['thoi_gian'] ?? '');
    final dateLabel = dt != null ? '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}' : '';
    final success = item['thanh_cong'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: success ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
          child: Icon(success ? Icons.check_circle : Icons.cancel, color: success ? Colors.green : Colors.red, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${item['thiet_bi'] ?? ''} • ${item['he_dieu_hanh'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text('${item['vi_tri'] ?? ''} (${item['dia_chi_ip'] ?? ''})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ])),
      ]),
    );
  }
}
