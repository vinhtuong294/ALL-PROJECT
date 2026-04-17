import 'package:equatable/equatable.dart';
import '../../../data/models/merchant_model.dart';
import '../../../data/models/merchant_response_model.dart';
import '../../../data/models/goods_category_model.dart';

abstract class MerchantState extends Equatable {
  const MerchantState();

  @override
  List<Object?> get props => [];
}

class MerchantInitial extends MerchantState {}

class MerchantLoading extends MerchantState {}

class PendingMerchantsLoading extends MerchantState {}

class MerchantLoaded extends MerchantState {
  final List<MerchantModel> merchants;
  final MerchantMetaModel meta;

  const MerchantLoaded({
    required this.merchants,
    required this.meta,
  });

  @override
  List<Object?> get props => [merchants, meta];
}

class PendingMerchantsLoaded extends MerchantState {
  final List<MerchantModel> merchants;
  final MerchantMetaModel meta;

  const PendingMerchantsLoaded({
    required this.merchants,
    required this.meta,
  });

  @override
  List<Object?> get props => [merchants, meta];
}

class ApproveMerchantLoading extends MerchantState {}

class ApproveMerchantSuccess extends MerchantState {
  final String message;
  const ApproveMerchantSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ApproveMerchantError extends MerchantState {
  final String message;
  const ApproveMerchantError(this.message);

  @override
  List<Object?> get props => [message];
}

class MerchantError extends MerchantState {
  final String message;

  const MerchantError(this.message);

  @override
  List<Object?> get props => [message];
}

class GoodsCategoriesLoaded extends MerchantState {
  final List<GoodsCategoryModel> categories;

  const GoodsCategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class AddMerchantLoading extends MerchantState {}

class AddMerchantSuccess extends MerchantState {
  final String message;
  final String? loginName;
  final String? defaultPassword;
  final String? stallId;
  final String? stallName;
  final String? loaiHangHoa;

  const AddMerchantSuccess(
    this.message, {
    this.loginName,
    this.defaultPassword,
    this.stallId,
    this.stallName,
    this.loaiHangHoa,
  });

  @override
  List<Object?> get props => [message, loginName, defaultPassword, stallId, stallName, loaiHangHoa];
}

class AddMerchantError extends MerchantState {
  final String message;

  const AddMerchantError(this.message);

  @override
  List<Object?> get props => [message];
}
