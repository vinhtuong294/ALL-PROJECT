import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/widgets/buyer_loading.dart';
import '../../../../../core/config/route_name.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_state.dart';

class SellerUserScreen extends StatelessWidget {
  const SellerUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerUserCubit()..loadUserInfo(),
      child: const _SellerUserView(),
    );
  }
}

class _SellerUserView extends StatelessWidget {
  const _SellerUserView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocConsumer<SellerUserCubit, SellerUserState>(
        listener: (context, state) {
          if (state.isLoggedOut) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              RouteName.login,
              (route) => false,
            );
          }
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.sellerInfo == null) {
            return const BuyerLoading(message: 'Đang tải thông tin...');
          }

          final info = state.sellerInfo;
          if (info == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          return Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => context.read<SellerUserCubit>().refreshData(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildShopHeader(context, info),
                            const SizedBox(height: 16),
                            _buildProductCountCard(context, info),
                            const SizedBox(height: 16),
                            _buildPerformanceCard(context, info),
                            const SizedBox(height: 16),
                            _buildInfoSection(context, info),
                            const SizedBox(height: 24),
                            _buildLogoutButton(context),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (state.isLoading)
                Container(
                  color: Colors.black12,
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFF26CD3A))),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          ),
          const Expanded(
            child: Text(
              'GIAN HÀNG CỦA TÔI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildShopHeader(BuildContext context, SellerInfo info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showImageSourceDialog(context),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: info.avatarUrl.startsWith('http')
                        ? Image.network(info.avatarUrl, fit: BoxFit.cover)
                        : Image.asset(
                            info.avatarUrl, 
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.store, color: Colors.white, size: 40),
                            ),
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Color(0xFF26CD3A), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.shopName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${info.rating.toStringAsFixed(0)} ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const Icon(Icons.star, color: Color(0xFFFFB300), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '(Người bán uy tín)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCountCard(BuildContext context, SellerInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: Color(0xFF1B5E20), size: 24),
          const SizedBox(width: 12),
          Text(
            '${info.productCount} sản phẩm',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Danh mục',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(BuildContext context, SellerInfo info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF388E3C), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HIỆU SUẤT BÁN HÀNG',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã bán hơn ${info.soldCount} đơn hàng',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Icon(Icons.trending_up, color: Colors.white54, size: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, SellerInfo info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoItem(
            label: 'HỌ VÀ TÊN',
            value: info.fullName,
            onEdit: () => _showEditDialog(context, 'Họ và tên', info.fullName, (val) {
              context.read<SellerUserCubit>().updateProfile(fullName: val);
            }),
          ),
          const Divider(height: 24),
          _buildInfoItem(
            label: 'CHỢ',
            value: info.marketName,
            // Không cho chỉnh sửa theo yêu cầu
          ),
          const Divider(height: 24),
          _buildInfoItem(
            label: 'SỐ LÔ (MÃ GIAN HÀNG)',
            value: info.stallNumber,
            // Không cho chỉnh sửa theo yêu cầu
          ),
          const Divider(height: 24),
          _buildInfoItem(
            label: 'SỐ TÀI KHOẢN',
            value: info.accountNumber,
            onEdit: () => _showEditDialog(context, 'Số tài khoản', info.accountNumber, (val) {
              context.read<SellerUserCubit>().updateProfile(bankAccount: val);
            }),
          ),
          const Divider(height: 24),
          _buildInfoItem(
            label: 'NGÂN HÀNG',
            value: info.bankName,
            onEdit: () => _showEditDialog(context, 'Ngân hàng', info.bankName, (val) {
              context.read<SellerUserCubit>().updateProfile(bankName: val);
            }),
          ),
          const Divider(height: 24),
          _buildInfoItem(
            label: 'SỐ ĐIỆN THOẠI',
            value: info.phoneNumber,
            onEdit: () => _showEditDialog(context, 'Số điện thoại', info.phoneNumber, (val) {
              context.read<SellerUserCubit>().updateProfile(phone: val);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    bool isNavigation = false,
    VoidCallback? onEdit,
  }) {
    return InkWell(
      onTap: onEdit,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          if (isNavigation)
            Icon(Icons.chevron_right, color: Colors.grey[400])
          else if (onEdit != null)
            Icon(Icons.edit, color: Colors.grey[300], size: 20),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton(
        onPressed: () => context.read<SellerUserCubit>().logout(),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFFFFEBEE)),
          backgroundColor: const Color(0xFFFFFBFA),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Đăng Xuất',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String title, String initialValue, Function(String) onSave) {
    final controller = TextEditingController(text: initialValue == 'Chưa cập nhật' ? '' : initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chỉnh sửa $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Nhập $title mới',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26CD3A)),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      if (context.mounted) {
        context.read<SellerUserCubit>().updateShopAvatar(File(pickedFile.path));
      }
    }
  }
}
