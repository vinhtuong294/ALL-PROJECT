import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';

class EditVehiclePage extends StatefulWidget {
  final String? vehicleType;
  final String? vehiclePlate;

  const EditVehiclePage({super.key, this.vehicleType, this.vehiclePlate});

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  late TextEditingController _plateCtrl;
  String _selectedType = 'xe_may';
  bool _saving = false;

  final _vehicleTypes = {
    'xe_may': 'Xe máy',
    'xe_dap': 'Xe đạp',
    'xe_dien': 'Xe điện',
    'o_to': 'Ô tô',
  };

  @override
  void initState() {
    super.initState();
    _plateCtrl = TextEditingController(text: widget.vehiclePlate ?? '');
    _selectedType = widget.vehicleType ?? 'xe_may';
    if (!_vehicleTypes.containsKey(_selectedType)) _selectedType = 'xe_may';
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_plateCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập biển số xe'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.updateShipperProfile({
        'vehicle_type': _selectedType,
        'vehicle_plate': _plateCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thông tin phương tiện'), backgroundColor: Color(0xFF2F8000)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Thông tin phương tiện', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vehicle icon
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2F8000), Color(0xFF45A012)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getVehicleIcon(), color: Colors.white, size: 48),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_vehicleTypes[_selectedType] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                    Text(_plateCtrl.text.isEmpty ? '---' : _plateCtrl.text, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),

          // Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Loại xe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedType,
                      items: _vehicleTypes.entries.map((e) {
                        return DropdownMenuItem(value: e.key, child: Text(e.value));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedType = v ?? 'xe_may'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Biển số xe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _plateCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: 43A-12345',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.directions_car, color: Color(0xFF2F8000)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      _saving ? 'Đang lưu...' : 'Lưu thay đổi',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F8000),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getVehicleIcon() {
    switch (_selectedType) {
      case 'xe_may': return Icons.two_wheeler;
      case 'xe_dap': return Icons.pedal_bike;
      case 'xe_dien': return Icons.electric_moped;
      case 'o_to': return Icons.directions_car;
      default: return Icons.two_wheeler;
    }
  }
}
