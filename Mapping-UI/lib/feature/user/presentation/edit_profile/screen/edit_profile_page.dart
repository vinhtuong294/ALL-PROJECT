import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/widgets/buyer_loading.dart';
import '../../../../../core/services/geocoding_service.dart';
import '../cubit/edit_profile_cubit.dart';

/// Trang chỉnh sửa thông tin cá nhân
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditProfileCubit()..loadProfile(),
      child: const EditProfileView(),
    );
  }
}

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _soTaiKhoanController = TextEditingController();
  final _nganHangController = TextEditingController();
  final _canNangController = TextEditingController();
  final _chieuCaoController = TextEditingController();
  String _selectedGioiTinh = 'M';
  bool _isInitialized = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onAddressChanged);
  }

  void _onAddressChanged() {
    if (_isInitialized) {
      context.read<EditProfileCubit>().updateAddress(_addressController.text);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _soTaiKhoanController.dispose();
    _nganHangController.dispose();
    _canNangController.dispose();
    _chieuCaoController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditProfileCubit, EditProfileState>(
      listener: (context, state) {
        if (state is EditProfileSaveSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF00B40F),
            ),
          );
        } else if (state is EditProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is EditProfileLoaded && !_isInitialized) {
          // Chỉ cập nhật controllers lần đầu tiên khi load xong
          // Tránh reset text khi đang gõ tiếng Việt
          _isInitialized = true;
          _nameController.text = state.name;
          _phoneController.text = state.phone;
          _addressController.text = state.address;
          _soTaiKhoanController.text = state.soTaiKhoan ?? '';
          _nganHangController.text = state.nganHang ?? '';
          _canNangController.text = state.canNang?.toString() ?? '';
          _chieuCaoController.text = state.chieuCao?.toString() ?? '';
          setState(() {
            _selectedGioiTinh = state.gioiTinh ?? 'M';
          });
          
          if (state.latitude != null && state.longitude != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(LatLng(state.latitude!, state.longitude!), 15);
            });
          }
        } else if (state is EditProfileLoaded && state.latitude != null && state.longitude != null) {
          // Update map when coordinates change (e.g. from suggestion)
           _mapController.move(LatLng(state.latitude!, state.longitude!), 15);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _buildContent(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SvgPicture.asset(
              'assets/img/back.svg',
              width: 20,
              height: 20,
            ),
          ),
          const Expanded(
            child: Text(
              'Tài khoản của tôi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF202020),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, EditProfileState state) {
    if (state is EditProfileLoading) {
      return const BuyerLoading(
              message: 'Đang tải cập nhật...',
            );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Avatar
          _buildAvatar(),
          
          const SizedBox(height: 32),
          
          // Name field
          _buildFieldLabel('Tên'),
          const SizedBox(height: 8),
          _buildTextField(_nameController, 'Nhập tên của bạn'),
          
          const SizedBox(height: 20),
          
          // Phone field
          _buildFieldLabel('Số điện thoại'),
          const SizedBox(height: 8),
          _buildTextField(_phoneController, 'Nhập số điện thoại', keyboardType: TextInputType.phone),
          
          const SizedBox(height: 20),
          
          // Gender field
          _buildFieldLabel('Giới tính'),
          const SizedBox(height: 8),
          _buildGenderSelector(),
          
          const SizedBox(height: 20),
          
          // Address field
          _buildFieldLabel('Địa chỉ'),
          const SizedBox(height: 8),
          _buildAddressField(context, state),
          
          const SizedBox(height: 20),
          
          // Bank account field
          _buildFieldLabel('Số tài khoản'),
          const SizedBox(height: 8),
          _buildTextField(_soTaiKhoanController, 'Nhập số tài khoản', keyboardType: TextInputType.number),
          
          const SizedBox(height: 20),
          
          // Bank name field
          _buildFieldLabel('Ngân hàng'),
          const SizedBox(height: 8),
          _buildTextField(_nganHangController, 'Nhập tên ngân hàng'),
          
          const SizedBox(height: 20),
          
          // Weight and Height row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Cân nặng (kg)'),
                    const SizedBox(height: 8),
                    _buildTextField(_canNangController, 'VD: 60.5', keyboardType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Chiều cao (cm)'),
                    const SizedBox(height: 8),
                    _buildTextField(_chieuCaoController, 'VD: 170', keyboardType: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Map Section
          _buildMapSection(state),
          
          const SizedBox(height: 32),
          
          // Save button
          _buildSaveButton(context, state),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF5E6FF),
              border: Border.all(
                color: const Color(0xFFE0D0F0),
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: Color(0xFF9C27B0),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                // TODO: Chọn ảnh
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: Color(0xFF202020),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          color: Color(0xFF202020),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Color(0xFF999999),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection(EditProfileState state) {
    if (state is! EditProfileLoaded) return const SizedBox.shrink();

    final lat = state.latitude ?? 16.047079; // Default to Da Nang
    final lon = state.longitude ?? 108.206230;

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(lat, lon),
            initialZoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.market.app',
            ),
            if (state.latitude != null && state.longitude != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(state.latitude!, state.longitude!),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressField(BuildContext context, EditProfileState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_addressController, 'Nhập địa chỉ'),
        if (state is EditProfileLoaded && (state.isSearchingAddress || state.addressSuggestions.isNotEmpty))
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: state.isSearchingAddress
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: state.addressSuggestions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final suggestion = state.addressSuggestions[index] as MapSuggestion;
                      return ListTile(
                        leading: const Icon(Icons.location_on_outlined, color: Color(0xFF00B40F)),
                        title: Text(
                          suggestion.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          _addressController.removeListener(_onAddressChanged);
                          _addressController.text = suggestion.displayName;
                          context.read<EditProfileCubit>().selectSuggestion(suggestion);
                          _addressController.addListener(_onAddressChanged);
                        },
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedGioiTinh = 'M'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedGioiTinh == 'M' 
                      ? const Color(0xFF00B40F) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Nam',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: _selectedGioiTinh == 'M' 
                          ? Colors.white 
                          : const Color(0xFF666666),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedGioiTinh = 'F'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedGioiTinh == 'F' 
                      ? const Color(0xFF00B40F) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Nữ',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: _selectedGioiTinh == 'F' 
                          ? Colors.white 
                          : const Color(0xFF666666),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, EditProfileState state) {
    final isLoading = state is EditProfileSaving;
    
    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              context.read<EditProfileCubit>().saveProfile(
                name: _nameController.text,
                phone: _phoneController.text,
                address: _addressController.text,
                gioiTinh: _selectedGioiTinh,
                soTaiKhoan: _soTaiKhoanController.text.isNotEmpty 
                    ? _soTaiKhoanController.text 
                    : null,
                nganHang: _nganHangController.text.isNotEmpty 
                    ? _nganHangController.text 
                    : null,
                canNang: _canNangController.text.isNotEmpty 
                    ? double.tryParse(_canNangController.text) 
                    : null,
                chieuCao: _chieuCaoController.text.isNotEmpty 
                    ? double.tryParse(_chieuCaoController.text) 
                    : null,
              );
            },
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF00B40F),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B40F).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Lưu thay đổi',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
