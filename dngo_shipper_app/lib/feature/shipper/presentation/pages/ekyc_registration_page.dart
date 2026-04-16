import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/api_service.dart';

class EkycRegistrationPage extends StatefulWidget {
  const EkycRegistrationPage({super.key});

  @override
  State<EkycRegistrationPage> createState() => _EkycRegistrationPageState();
}

class _EkycRegistrationPageState extends State<EkycRegistrationPage> {
  int _currentStep = 0;
  final ImagePicker _picker = ImagePicker();

  // Form Data
  final _idController = TextEditingController();
  final _licenseController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  String _vehicleType = 'Xe máy';
  
  XFile? _idFront;
  XFile? _idBack;
  XFile? _licenseFront;
  XFile? _selfie;

  bool _isSubmitting = false;

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
    } else {
      _submitEkyc();
    }
  }

  void _cancelStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage(String target) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (target == 'idFront') _idFront = image;
        if (target == 'idBack') _idBack = image;
        if (target == 'licenseFront') _licenseFront = image;
        if (target == 'selfie') _selfie = image;
      });
    }
  }

  Future<void> _submitEkyc() async {
    // Validate
    if (_idFront == null || _idBack == null || _selfie == null || _licenseFront == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng cung cấp đủ hình ảnh giấy tờ'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Giả lập API gọi eKYC
      // await ApiService.submitEkyc({...});
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Thành công'),
              ],
            ),
            content: const Text('Hồ sơ của bạn đã được gửi để xét duyệt. Quá trình kiểm duyệt tài khoản sẽ diễn ra trong vòng 24h.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Quay lại', style: TextStyle(color: Color(0xFF2F8000), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildImageUploader(String label, XFile? file, String targetKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(targetKey),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              image: file != null
                  ? DecorationImage(
                      image: kIsWeb ? NetworkImage(file.path) : FileImage(File(file.path)) as ImageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: file == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: Colors.grey.shade400, size: 32),
                      const SizedBox(height: 4),
                      Text('Tải ảnh lên', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  )
                : Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                      onPressed: () {
                        setState(() {
                          if (targetKey == 'idFront') _idFront = null;
                          if (targetKey == 'idBack') _idBack = null;
                          if (targetKey == 'licenseFront') _licenseFront = null;
                          if (targetKey == 'selfie') _selfie = null;
                        });
                      },
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Xác thực eKYC', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _isSubmitting ? null : _nextStep,
        onStepCancel: _isSubmitting ? null : _cancelStep,
        onStepTapped: (index) {
          if (!_isSubmitting) setState(() => _currentStep = index);
        },
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F8000),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_currentStep == 2 ? 'Xác nhận' : 'Tiếp tục'),
                  ),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Quay lại', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            isActive: _currentStep >= 0,
            title: const Text('Chứng minh & Chân dung'),
            content: Column(
              children: [
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(labelText: 'Số CCCD / CMND', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                _buildImageUploader('Mặt trước CCCD/CMND', _idFront, 'idFront'),
                _buildImageUploader('Mặt sau CCCD/CMND', _idBack, 'idBack'),
                _buildImageUploader('Ảnh chân dung cận mặt', _selfie, 'selfie'),
              ],
            ),
          ),
          Step(
            isActive: _currentStep >= 1,
            title: const Text('Giấy phép lái xe'),
            content: Column(
              children: [
                TextField(
                  controller: _licenseController,
                  decoration: const InputDecoration(labelText: 'Số GPLX', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                _buildImageUploader('Mặt trước GPLX', _licenseFront, 'licenseFront'),
              ],
            ),
          ),
          Step(
            isActive: _currentStep >= 2,
            title: const Text('Phương tiện giao hàng'),
            content: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _vehicleType,
                  decoration: const InputDecoration(labelText: 'Loại phương tiện', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Xe máy', child: Text('Xe máy')),
                    DropdownMenuItem(value: 'Xe tải nhỏ', child: Text('Xe tải nhỏ')),
                    DropdownMenuItem(value: 'Xe đạp điện', child: Text('Xe đạp điện')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _vehicleType = val);
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _vehiclePlateController,
                  decoration: const InputDecoration(labelText: 'Biển số xe', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
