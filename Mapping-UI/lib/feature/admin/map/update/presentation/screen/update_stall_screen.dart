import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/models/market_map_model.dart';
import '../../../../../../core/widgets/buyer_loading.dart';
import '../cubit/update_stall_cubit.dart';
import '../cubit/update_stall_state.dart';

class UpdateStallScreen extends StatelessWidget {
  final MapStoreInfo? store;

  const UpdateStallScreen({
    super.key,
    this.store,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UpdateStallCubit(store: store),
      child: const UpdateStallView(),
    );
  }
}

class UpdateStallView extends StatelessWidget {
  const UpdateStallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: BlocConsumer<UpdateStallCubit, UpdateStallState>(
          listener: (context, state) {
            if (state.errorMessage != null && !state.isLoading) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }

            if (!state.isLoading &&
                state.errorMessage == null &&
                state.store != null &&
                !state.isNewStall) {
              Navigator.of(context).pop(true);
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const BuyerLoading(message: 'Đang lưu gian hàng...');
            }

            return Column(
              children: [
                _buildHeader(context, state),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(context, state),
                        const SizedBox(height: 20),
                        _buildLocationCard(context, state),
                        const SizedBox(height: 40),
                        _buildActionButtons(context, state),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  Widget _buildHeader(BuildContext context, UpdateStallState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F8000), Color(0xFF2F8000)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              state.isNewStall ? 'Thêm Gian hàng Mới' : 'Cập nhật Gian hàng',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, UpdateStallState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin Gian hàng',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            context,
            label: 'Tên Gian hàng',
            hint: 'Nhập tên gian hàng',
            value: state.name,
            onChanged: (value) => context.read<UpdateStallCubit>().updateName(value),
            icon: Icons.store,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            context,
            label: 'Vị trí mô tả',
            hint: 'VD: Khu A, Dãy 1',
            value: state.viTri ?? '',
            onChanged: (value) => context.read<UpdateStallCubit>().updateViTri(value),
            icon: Icons.location_on,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: onChanged,
          controller: TextEditingController(text: value),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF2F8000), size: 22)
                : null,
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2F8000), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }


  Widget _buildLocationCard(BuildContext context, UpdateStallState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F8000).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.grid_on, color: Color(0xFF2F8000), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Vị trí trên Sơ đồ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGridPositionField(
                  context,
                  label: 'Hàng (Row)',
                  value: state.gridRow,
                  onChanged: (val) {
                    context.read<UpdateStallCubit>().updateGridPosition(val, state.gridCol);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGridPositionField(
                  context,
                  label: 'Cột (Column)',
                  value: state.gridCol,
                  onChanged: (val) {
                    context.read<UpdateStallCubit>().updateGridPosition(state.gridRow, val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: state.gridRow != null && state.gridCol != null
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  state.gridRow != null && state.gridCol != null
                      ? Icons.check_circle
                      : Icons.warning,
                  color: state.gridRow != null && state.gridCol != null
                      ? const Color(0xFF4CAF50)
                      : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  state.gridRow != null && state.gridCol != null
                      ? 'Vị trí: Hàng ${state.gridRow}, Cột ${state.gridCol}'
                      : 'Chưa xếp vị trí trên sơ đồ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: state.gridRow != null && state.gridCol != null
                        ? const Color(0xFF4CAF50)
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridPositionField(
    BuildContext context, {
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Color(0xFF6B6B6B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: value?.toString() ?? ''),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            final intVal = int.tryParse(val);
            onChanged(intVal);
          },
          decoration: InputDecoration(
            hintText: '0',
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2F8000), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, UpdateStallState state) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6B6B6B),
              side: const BorderSide(color: Color(0xFFE5E5E5), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: state.isValid
                ? () => context.read<UpdateStallCubit>().saveStall()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F8000),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
