import 'package:equatable/equatable.dart';

/// Base model cho tất cả các model trong ứng dụng
/// Sử dụng Equatable để so sánh object
abstract class BaseModel extends Equatable {
  const BaseModel();

  /// Convert model to JSON
  Map<String, dynamic> toJson();

  /// Convert JSON to model
  /// Phải được implement ở class con
  // static T fromJson<T>(Map<String, dynamic> json);

  @override
  List<Object?> get props => [];

  @override
  bool get stringify => true;
}
