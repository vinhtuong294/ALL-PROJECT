import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/common/market_app_bar.dart';
import '../../widgets/common/market_bottom_nav_bar.dart';
import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../bloc/dashboard/dashboard_event.dart';
import '../../bloc/dashboard/dashboard_state.dart';
import '../../../data/models/market_dashboard_model.dart';
import '../../../injection_container.dart';

class MarketBookScreen extends StatefulWidget {
  final MarketNavItem currentNav;
  final ValueChanged<MarketNavItem> onNavTap;

  const MarketBookScreen({
    super.key,
    required this.currentNav,
    required this.onNavTap,
  });

  @override
  State<MarketBookScreen> createState() => _MarketBookScreenState();
}

class _MarketBookScreenState extends State<MarketBookScreen> {
  String _selectedCategory = 'tat_ca';
  String _searchQuery = '';
  
  // Status update form state
  MarketDashboardModel? _lastDashboard;
  String? _formSelectedStall;
  String _formNewStatus = 'mo_cua';
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<DashboardBloc>()..add(GetDashboardV2Event()),
      child: BlocListener<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state is DashboardV2Success) {
            setState(() => _lastDashboard = state.dashboard);
          }
          if (state is UpdateStallStatusSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.primary),
            );
          }
          if (state is DashboardError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: AppColors.background,
            appBar: const MarketAppBar(
              title: 'Cập Nhật Sổ Chợ',
              showBack: true,
            ),
            body: BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading && _lastDashboard == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is DashboardError && _lastDashboard == null) {
                  return Center(child: Text('Lỗi: ${state.message}'));
                }
                
                final dash = (state is DashboardV2Success) ? state.dashboard : _lastDashboard;
                
                if (dash != null) {
                  // Initialize selected stall if not set
                  if (_formSelectedStall == null && dash.stalls.isNotEmpty) {
                    _formSelectedStall = dash.stalls.first.stallId;
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<DashboardBloc>().add(GetDashboardV2Event());
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryStats(dash),
                          const SizedBox(height: 16),
                          _buildFilterSection(dash),
                          const SizedBox(height: 16),
                          _buildStallMapHeader(),
                          const SizedBox(height: 12),
                          _buildStallGrid(dash),
                          const SizedBox(height: 24),
                          _buildUpdateStatusForm(context, dash),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
            bottomNavigationBar: MarketBottomNavBar(
              currentItem: widget.currentNav,
              onTap: widget.onNavTap,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(MarketDashboardModel dash) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(dash.totalStalls.toString(), 'Tổng gian hàng', AppColors.textPrimary),
          _buildDivider(),
          _buildStatItem(dash.openStalls.toString(), 'Đang mở', const Color(0xFF4CAF50)),
          _buildDivider(),
          _buildStatItem(dash.closedStalls.toString(), 'Đã đóng', const Color(0xFFF44336)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.border.withValues(alpha: 0.5),
    );
  }

  Widget _buildFilterSection(MarketDashboardModel dash) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lọc theo loại hàng',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Tìm gian hàng...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textHint),
              filled: true,
              fillColor: const Color(0xFFF7FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dash.categories.map((cat) {
                final isSelected = _selectedCategory == cat.ma;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat.ten,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    showCheckmark: false,
                    shape: const StadiumBorder(),
                    side: BorderSide.none,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat.ma;
                      });
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFFF7FAFC),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStallMapHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Sơ đồ gian hàng',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        Row(
          children: [
            _buildLegendItem('Mở', const Color(0xFF4CAF50)),
            const SizedBox(width: 12),
            _buildLegendItem('Đóng', const Color(0xFFF44336)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStallGrid(MarketDashboardModel dash) {
    final filteredStalls = dash.stalls.where((s) {
      final matchCat = _selectedCategory == 'tat_ca' || s.categoryMa == _selectedCategory;
      final matchSearch = s.stallName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.stallId.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: filteredStalls.length,
        itemBuilder: (context, index) {
          final s = filteredStalls[index];
          final isOpen = s.status == 'mo_cua';

          return Container(
            decoration: BoxDecoration(
              color: isOpen ? const Color(0xFFE8F5E9) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.stallId,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isOpen
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOpen ? 'Mở' : 'Đóng',
                  style: TextStyle(
                    fontSize: 10,
                    color: isOpen
                        ? const Color(0xFF43A047)
                        : const Color(0xFFE53935),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpdateStatusForm(BuildContext context, MarketDashboardModel dash) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cập nhật trạng thái',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildFormLabel('Chọn gian hàng'),
          _buildStallDropdown(dash),
          const SizedBox(height: 16),
          _buildFormLabel('Trạng thái mới'),
          _buildStatusDropdown(),
          const SizedBox(height: 16),
          _buildFormLabel('Ghi chú'),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú về cập nhật (tùy chọn)...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
              filled: true,
              fillColor: const Color(0xFFF7FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSubmitButton(context),
        ],
      ),
    );
  }

  Widget _buildStallDropdown(MarketDashboardModel dash) {
    return DropdownButtonFormField<String>(
      value: _formSelectedStall,
      items: dash.stalls.map((stall) {
        return DropdownMenuItem<String>(
          value: stall.stallId,
          child: Text('${stall.stallId} - ${stall.userName}', style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: (value) => setState(() => _formSelectedStall = value),
      decoration: _getDropdownDecoration(Icons.storefront_outlined),
      hint: const Text('Chọn gian hàng', style: TextStyle(fontSize: 14)),
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _formNewStatus,
      items: const [
        DropdownMenuItem(value: 'mo_cua', child: Text('Đang mở')),
        DropdownMenuItem(value: 'dong_cua', child: Text('Đang đóng')),
      ],
      onChanged: (value) => setState(() => _formNewStatus = value!),
      decoration: _getDropdownDecoration(Icons.toggle_on_outlined),
      hint: const Text('Chọn trạng thái', style: TextStyle(fontSize: 14)),
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
    );
  }

  InputDecoration _getDropdownDecoration(IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF7FAFC),
      prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (_formSelectedStall == null) return;
          print('DEBUG: Button clicked, dispatching UpdateStallStatusEvent for $_formSelectedStall');
          context.read<DashboardBloc>().add(UpdateStallStatusEvent(
            stallId: _formSelectedStall!,
            status: _formNewStatus,
            note: _noteController.text,
          ));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is UpdateStallStatusLoading) {
              return const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              );
            }
            return const Text('Xác nhận cập nhật', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700));
          },
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }

}
