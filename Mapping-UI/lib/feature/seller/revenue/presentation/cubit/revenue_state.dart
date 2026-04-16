import 'package:equatable/equatable.dart';

enum BalanceTab { pending, paid }
enum DateFilter { today, week, month, year, custom }
enum ChartType { column, line }

class BestSellingProduct extends Equatable {
  final String name;
  final String imageUrl;
  final int orderCount;
  final double totalAmount;
  final double changePercentage;

  const BestSellingProduct({
    required this.name,
    required this.imageUrl,
    required this.orderCount,
    required this.totalAmount,
    required this.changePercentage,
  });

  @override
  List<Object?> get props => [name, imageUrl, orderCount, totalAmount, changePercentage];
}


class Transaction extends Equatable {
  final String id;
  final String orderId;
  final BalanceTab status;
  final double totalValue;
  final double serviceFee;
  final double actualAmount;

  const Transaction({
    required this.id,
    required this.orderId,
    required this.status,
    required this.totalValue,
    required this.serviceFee,
    required this.actualAmount,
  });

  @override
  List<Object?> get props => [id, orderId, status, totalValue, serviceFee, actualAmount];
}

class SellerRevenueState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final BalanceTab selectedBalanceTab;
  final DateFilter selectedDateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final ChartType chartType;
  final double pendingBalance;
  final double paidBalance;
  final double revenueChangePercentage;
  final int orderCount;
  final double averageOrderValue;
  final double conversionRate;
  final List<Transaction> transactions;
  final List<BestSellingProduct> bestSellingProducts;
  final String nextSettlementCycle;
  final Map<String, double> dailyRevenue; // New field for chart data

  const SellerRevenueState({
    this.isLoading = false,
    this.errorMessage,
    this.selectedBalanceTab = BalanceTab.pending,
    this.selectedDateFilter = DateFilter.month,
    this.customStartDate,
    this.customEndDate,
    this.chartType = ChartType.line,
    this.pendingBalance = 0,
    this.paidBalance = 0,
    this.revenueChangePercentage = 15.0,
    this.orderCount = 452,
    this.averageOrderValue = 284000,
    this.conversionRate = 3.2,
    this.transactions = const [],
    this.bestSellingProducts = const [],
    this.nextSettlementCycle = 'Thứ Sáu, 17:00',
    this.dailyRevenue = const {},
  });

  SellerRevenueState copyWith({
    bool? isLoading,
    String? errorMessage,
    BalanceTab? selectedBalanceTab,
    DateFilter? selectedDateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    ChartType? chartType,
    double? pendingBalance,
    double? paidBalance,
    double? revenueChangePercentage,
    int? orderCount,
    double? averageOrderValue,
    double? conversionRate,
    List<Transaction>? transactions,
    List<BestSellingProduct>? bestSellingProducts,
    String? nextSettlementCycle,
    Map<String, double>? dailyRevenue,
  }) {
    return SellerRevenueState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedBalanceTab: selectedBalanceTab ?? this.selectedBalanceTab,
      selectedDateFilter: selectedDateFilter ?? this.selectedDateFilter,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      chartType: chartType ?? this.chartType,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      paidBalance: paidBalance ?? this.paidBalance,
      revenueChangePercentage: revenueChangePercentage ?? this.revenueChangePercentage,
      orderCount: orderCount ?? this.orderCount,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      conversionRate: conversionRate ?? this.conversionRate,
      transactions: transactions ?? this.transactions,
      bestSellingProducts: bestSellingProducts ?? this.bestSellingProducts,
      nextSettlementCycle: nextSettlementCycle ?? this.nextSettlementCycle,
      dailyRevenue: dailyRevenue ?? this.dailyRevenue,
    );
  }

  List<Transaction> get filteredTransactions {
    return transactions.where((t) => t.status == selectedBalanceTab).toList();
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        selectedBalanceTab,
        selectedDateFilter,
        customStartDate,
        customEndDate,
        chartType,
        pendingBalance,
        paidBalance,
        revenueChangePercentage,
        orderCount,
        averageOrderValue,
        conversionRate,
        transactions,
        bestSellingProducts,
        nextSettlementCycle,
        dailyRevenue,
      ];

  /// Factory method để tạo state với dữ liệu mẫu
  factory SellerRevenueState.withMockData() {
    final transactions = [
      const Transaction(
        id: '1',
        orderId: '#ORD-2024-001',
        status: BalanceTab.pending,
        totalValue: 250000,
        serviceFee: 25000,
        actualAmount: 225000,
      ),
      const Transaction(
        id: '2',
        orderId: '#ORD-2024-002',
        status: BalanceTab.paid,
        totalValue: 180000,
        serviceFee: 18000,
        actualAmount: 162000,
      ),
      const Transaction(
        id: '3',
        orderId: '#ORD-2024-003',
        status: BalanceTab.paid,
        totalValue: 320000,
        serviceFee: 32000,
        actualAmount: 288000,
      ),
    ];

    final bestSellingProducts = [
      const BestSellingProduct(
        name: 'Áo thun nam cao cấp',
        imageUrl: 'https://example.com/ao_thun.jpg',
        orderCount: 120,
        totalAmount: 12000000,
        changePercentage: 15.2,
      ),
      const BestSellingProduct(
        name: 'Quần jean nữ ống rộng',
        imageUrl: 'https://example.com/quan_jean.jpg',
        orderCount: 95,
        totalAmount: 10500000,
        changePercentage: 10.1,
      ),
      const BestSellingProduct(
        name: 'Giày thể thao unisex',
        imageUrl: 'https://example.com/giay_the_thao.jpg',
        orderCount: 80,
        totalAmount: 9800000,
        changePercentage: 8.5,
      ),
    ];

    return SellerRevenueState(
      isLoading: false,
      selectedBalanceTab: BalanceTab.pending,
      selectedDateFilter: DateFilter.month,
      chartType: ChartType.line,
      pendingBalance: 350000,
      paidBalance: 2120000,
      revenueChangePercentage: 15.0,
      orderCount: 452,
      averageOrderValue: 284000,
      conversionRate: 3.2,
      transactions: transactions,
      bestSellingProducts: bestSellingProducts,
      nextSettlementCycle: 'Thứ Sáu, 17:00',
      dailyRevenue: const {
        '2024-03-12': 100000,
        '2024-03-13': 150000,
        '2024-03-14': 120000,
        '2024-03-15': 200000,
        '2024-03-16': 180000,
        '2024-03-17': 250000,
        '2024-03-18': 300000,
      },
    );
  }
}
