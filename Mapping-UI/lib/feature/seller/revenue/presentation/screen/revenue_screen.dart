import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/widgets/buyer_loading.dart';
import '../cubit/revenue_cubit.dart';
import '../cubit/revenue_state.dart';

class SellerRevenueScreen extends StatelessWidget {
  const SellerRevenueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerRevenueCubit(),
      child: const SellerRevenueView(),
    );
  }
}

class SellerRevenueView extends StatelessWidget {
  const SellerRevenueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Thống kê doanh thu',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<SellerRevenueCubit, SellerRevenueState>(
        builder: (context, state) {
          debugPrint('🖥️ [REVENUE_VIEW] Building with state: isLoading=${state.isLoading}, error=${state.errorMessage}, revenue=${state.paidBalance}');
          if (state.isLoading) {
            return const BuyerLoading(
              message: 'Đang tải dữ liệu doanh thu...',
            );
          }

          if (state.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<SellerRevenueCubit>().loadRevenue(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<SellerRevenueCubit>().loadRevenue(),
            color: const Color(0xFFF97316),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterTabs(context, state),
                  const SizedBox(height: 16),
                  _buildDateRangeSelector(context, state),
                  const SizedBox(height: 20),
                  _buildMainRevenueCard(state),
                  const SizedBox(height: 24),
                  _buildTrendChart(state),
                  const SizedBox(height: 24),
                  _buildStatsRow(state),
                  const SizedBox(height: 24),
                  _buildBestSellingSection(state),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, SellerRevenueState state) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabItem(context, 'Ngày', DateFilter.today, state.selectedDateFilter),
          _buildTabItem(context, 'Tuần', DateFilter.week, state.selectedDateFilter),
          _buildTabItem(context, 'Tháng', DateFilter.month, state.selectedDateFilter),
          _buildTabItem(context, 'Năm', DateFilter.year, state.selectedDateFilter),
          _buildTabItem(context, 'Tùy chỉnh', DateFilter.custom, state.selectedDateFilter),
        ],
      ),
    );
  }

  Widget _buildTabItem(
      BuildContext context, String label, DateFilter filter, DateFilter selected) {
    final isActive = filter == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (filter == DateFilter.custom) {
            _showDateRangePicker(context);
          } else {
            context.read<SellerRevenueCubit>().selectDateFilter(filter);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFFF97316) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context, SellerRevenueState state) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    String dateRangeText = '';

    final now = DateTime.now();
    if (state.selectedDateFilter == DateFilter.today) {
      dateRangeText = dateFormat.format(now);
    } else if (state.selectedDateFilter == DateFilter.week) {
      final start = now.subtract(const Duration(days: 7));
      dateRangeText = '${dateFormat.format(start)} - ${dateFormat.format(now)}';
    } else if (state.selectedDateFilter == DateFilter.month) {
      final start = DateTime(now.year, now.month, 1);
      dateRangeText = '${dateFormat.format(start)} - ${dateFormat.format(now)}';
    } else if (state.selectedDateFilter == DateFilter.year) {
      dateRangeText = 'Năm ${now.year}';
    } else {
      dateRangeText = state.customStartDate != null && state.customEndDate != null
          ? '${dateFormat.format(state.customStartDate!)} - ${dateFormat.format(state.customEndDate!)}'
          : 'Chọn khoảng thời gian';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Text(
            dateRangeText,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF6B7280)),
        ],
      ),
    );
  }

  Widget _buildMainRevenueCard(SellerRevenueState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDCFCE7), Color(0xFFF0FDF4)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.payments_outlined,
              size: 100,
              color: const Color(0xFF22C55E).withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TỔNG DOANH THU',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF166534),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${_formatCurrency(state.paidBalance)}đ',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF14532D),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, size: 16, color: Color(0xFF22C55E)),
                    const SizedBox(width: 4),
                    Text(
                      '${state.revenueChangePercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'so với tháng trước',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(SellerRevenueState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Biểu đồ xu hướng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Color(0xFF6B7280)),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: state.dailyRevenue.isEmpty
                ? const Center(child: Text('Không có dữ liệu'))
                : CustomPaint(
                    painter: AreaChartPainter(state.dailyRevenue),
                  ),
          ),
          const SizedBox(height: 12),
          // X-axis labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChartLabel('T1'),
              _buildChartLabel('T2'),
              _buildChartLabel('T3'),
              _buildChartLabel('T4'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
    );
  }

  Widget _buildStatsRow(SellerRevenueState state) {
    return Row(
      children: [
        _buildStatCard('ĐƠN HÀNG', state.orderCount.toString()),
        const SizedBox(width: 12),
        _buildStatCard('GIÁ TRỊ TB', '${(state.averageOrderValue / 1000).toStringAsFixed(0)}k'),
        const SizedBox(width: 12),
        _buildStatCard('CHUYỂN ĐỔI', '${state.conversionRate}%'),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellingSection(SellerRevenueState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sản phẩm bán chạy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Tất cả',
                style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...state.bestSellingProducts.map((product) => _buildProductItem(product)),
      ],
    );
  }

  Widget _buildProductItem(BestSellingProduct product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              product.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: const Color(0xFFF3F4F6),
                child: const Icon(Icons.image_outlined, color: Color(0xFF9CA3AF)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.orderCount} đơn hàng',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(product.totalAmount / 1000000).toStringAsFixed(1)}M',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    product.changePercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: product.changePercentage >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${product.changePercentage >= 0 ? '+' : ''}${product.changePercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: product.changePercentage >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF97316),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (context.mounted) {
        context.read<SellerRevenueCubit>().setCustomDateRange(picked.start, picked.end);
      }
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return formatter.format(amount);
  }
}

class AreaChartPainter extends CustomPainter {
  final Map<String, double> data;

  AreaChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final List<double> values = data.isEmpty
        ? [0.3, 0.6, 0.4, 0.8, 0.5, 0.9, 0.7] // Mock trend
        : data.values.toList();
    
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFFF97316)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFB923C).withOpacity(0.3),
          const Color(0xFFFB923C).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final widthStep = size.width / (values.length > 1 ? values.length - 1 : 1);

    for (var i = 0; i < values.length; i++) {
      final x = i * widthStep;
      final normalizedValue = maxValue > 0 ? (values[i] / maxValue) : values[i];
      final y = size.height - (normalizedValue * size.height * 0.8);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * widthStep;
        final prevY = size.height - (maxValue > 0 ? (values[i-1] / maxValue) * size.height * 0.8 : values[i-1] * size.height * 0.8);
        
        path.cubicTo((prevX + x) / 2, prevY, (prevX + x) / 2, y, x, y);
        fillPath.cubicTo((prevX + x) / 2, prevY, (prevX + x) / 2, y, x, y);
      }

      if (i == values.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
