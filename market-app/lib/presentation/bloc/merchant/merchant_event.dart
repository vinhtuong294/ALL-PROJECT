import 'package:equatable/equatable.dart';

abstract class MerchantEvent extends Equatable {
  const MerchantEvent();

  @override
  List<Object?> get props => [];
}

class GetMerchantsEvent extends MerchantEvent {
  final String? search;
  final String? status;
  final int page;
  final int limit;

  const GetMerchantsEvent({
    this.search,
    this.status,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [search, status, page, limit];
}

class GetGoodsCategoriesEvent extends MerchantEvent {}

class GetPendingMerchantsEvent extends MerchantEvent {
  final int page;
  final int limit;

  const GetPendingMerchantsEvent({
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [page, limit];
}

class ApproveMerchantEvent extends MerchantEvent {
  final String userId;

  const ApproveMerchantEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddMerchantEvent extends MerchantEvent {
  final String tenNguoiDung;
  final String diaChi;
  final String soDienThoai;
  final String maGianHang;
  final String loaiHangHoa;
  final double tienThueMacDinh;
  final String? ghiChu;
  final int gridCol;
  final int gridRow;

  const AddMerchantEvent({
    required this.tenNguoiDung,
    required this.diaChi,
    required this.soDienThoai,
    required this.maGianHang,
    required this.loaiHangHoa,
    required this.tienThueMacDinh,
    this.ghiChu,
    this.gridCol = 0,
    this.gridRow = 0,
  });

  @override
  List<Object?> get props => [
        tenNguoiDung,
        diaChi,
        soDienThoai,
        maGianHang,
        loaiHangHoa,
        tienThueMacDinh,
        ghiChu,
        gridCol,
        gridRow,
      ];
}
