part of 'cart_cubit.dart';

/// Base class cho tất cả các state của Cart
abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

/// State khởi tạo ban đầu
class CartInitial extends CartState {}

/// State đang tải giỏ hàng
class CartLoading extends CartState {}

/// State tải giỏ hàng thành công
class CartLoaded extends CartState {
  final List<CartItem> items;
  final double totalAmount;
  final Set<String> selectedItemIds;
  final double? apiTotalAmount; // Tổng tiền từ API
  final String? orderCode; // Mã đơn hàng từ API

  const CartLoaded({
    required this.items,
    required this.totalAmount,
    this.selectedItemIds = const {},
    this.apiTotalAmount,
    this.orderCode,
  });

  @override
  List<Object?> get props => [items, totalAmount, selectedItemIds, apiTotalAmount, orderCode];

  CartLoaded copyWith({
    List<CartItem>? items,
    double? totalAmount,
    Set<String>? selectedItemIds,
    double? apiTotalAmount,
    String? orderCode,
  }) {
    return CartLoaded(
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      apiTotalAmount: apiTotalAmount ?? this.apiTotalAmount,
      orderCode: orderCode ?? this.orderCode,
    );
  }
}

/// State cập nhật giỏ hàng
class CartUpdating extends CartState {}

/// State cập nhật thành công
class CartUpdateSuccess extends CartState {
  final String message;

  const CartUpdateSuccess({this.message = 'Cập nhật thành công!'});

  @override
  List<Object?> get props => [message];
}

/// State xóa item thành công
class CartItemRemoved extends CartState {
  final String message;

  const CartItemRemoved({this.message = 'Đã xóa sản phẩm khỏi giỏ hàng!'});

  @override
  List<Object?> get props => [message];
}

/// State lỗi
class CartFailure extends CartState {
  final String errorMessage;

  const CartFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

/// State checkout
class CartCheckoutInProgress extends CartState {}

/// State checkout thành công
class CartCheckoutSuccess extends CartState {
  final String message;

  const CartCheckoutSuccess({this.message = 'Đặt hàng thành công!'});

  @override
  List<Object?> get props => [message];
}

/// Model cho CartItem
class CartItem {
  final String id;
  final String productId;
  final String? shopId;
  final String shopName;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final bool isSelected;

  const CartItem({
    required this.id,
    required this.productId,
    this.shopId,
    required this.shopName,
    required this.productName,
    required this.productImage,
    required this.price,
    this.quantity = 1,
    this.isSelected = false,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      shopName: json['shopName'] ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      isSelected: json['isSelected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'shopName': shopName,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'isSelected': isSelected,
    };
  }

  CartItem copyWith({
    String? id,
    String? productId,
    String? shopId,
    String? shopName,
    String? productName,
    String? productImage,
    double? price,
    int? quantity,
    bool? isSelected,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  double get totalPrice => price * quantity;
}
