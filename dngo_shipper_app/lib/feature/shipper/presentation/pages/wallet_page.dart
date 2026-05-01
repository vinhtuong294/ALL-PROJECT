import 'package:flutter/material.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../core/utils/helpers.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  int _walletBalance = 0;
  int _tienDangChoRut = 0;
  List<dynamic> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final b = await ApiService.getWalletBalance();
      if (mounted) {
        setState(() {
          _walletBalance = b['so_du_kha_dung'] ?? b['so_du'] ?? 0;
          _tienDangChoRut = b['tien_dang_cho_rut'] ?? 0;
          // chi_tiet is the transaction history from the balance endpoint
          _transactions = (b['chi_tiet'] as List<dynamic>?) ?? [];
        });
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  void _requestCashout() {
    final amountCtrl = TextEditingController();
    final bankBinCtrl = TextEditingController(text: '970436'); // default VCB for example
    final accountNoCtrl = TextEditingController();
    final accountNameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yêu cầu rút tiền'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số tiền (VNĐ)'),
              ),
              TextField(
                controller: bankBinCtrl,
                decoration: const InputDecoration(labelText: 'Mã Ngân Hàng (BIN)'),
              ),
              TextField(
                controller: accountNoCtrl,
                decoration: const InputDecoration(labelText: 'Số tài khoản'),
              ),
              TextField(
                controller: accountNameCtrl,
                decoration: const InputDecoration(labelText: 'Tên chủ tài khoản'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số tiền không hợp lệ')));
                return;
              }
              try {
                // Hiển thị loading
                showDialog(context: ctx, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                
                await ApiService.requestWithdraw(
                  amount,
                  bankBinCtrl.text,
                  accountNoCtrl.text,
                  accountNameCtrl.text,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx); // close loading
                Navigator.pop(ctx); // close form
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yêu cầu rút tiền thành công!')));
                  _loadData();
                }
              } catch (e) {
                if (!ctx.mounted) return;
                Navigator.pop(ctx); // close loading
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B40F)),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Ví Tài Xế', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00B40F)))
          : RefreshIndicator(
              color: const Color(0xFF00B40F),
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Lịch sử giao dịch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Tất cả', style: TextStyle(color: Color(0xFF00B40F))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('Chưa có giao dịch nào', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    ..._transactions.map((tx) => _buildTransactionItem(tx)),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF00B40F),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B40F).withValues(alpha:0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white70, size: 24),
              SizedBox(width: 8),
              Text('Số dư khả dụng', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatVND(_walletBalance), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              if (_tienDangChoRut > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.orangeAccent, size: 14),
                      const SizedBox(width: 4),
                      Text('Chờ duyệt: ${formatVND(_tienDangChoRut)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _requestCashout,
                  icon: const Icon(Icons.arrow_upward, color: Color(0xFF00B40F), size: 18),
                  label: const Text('Rút tiền', style: TextStyle(color: Color(0xFF00B40F), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.history, color: Colors.white, size: 18),
                  label: const Text('Thống kê', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _loaiLabel = {
    'phi_ship': 'Phí giao hàng',
    'loi_giao_hang': 'Phạt giao trễ',
    'hoan_tien': 'Hoàn tiền',
    'nap_tien': 'Nạp tiền',
    'rut_tien': 'Rút tiền',
  };

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final amount = (tx['so_tien'] ?? 0) as num;
    final isAdd = (tx['huong'] ?? '') == 'vao';
    final date = _formatDate(tx['ngay']?.toString());
    final loai = tx['loai']?.toString() ?? '';
    final description = _loaiLabel[loai] ?? loai.replaceAll('_', ' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAdd ? Colors.green.shade50 : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAdd ? Icons.arrow_downward : Icons.arrow_upward,
              color: isAdd ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                if (tx['cancel_reason'] != null)
                  Text(tx['cancel_reason'], style: TextStyle(color: Colors.orange.shade700, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (tx['order_id'] != null)
                  Text('Đơn: ${tx['order_id']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${isAdd ? '+' : '-'}${formatVND(amount.toInt())}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isAdd ? const Color(0xFF00B40F) : Colors.red),
          ),
        ],
      ),
    );
  }
}
