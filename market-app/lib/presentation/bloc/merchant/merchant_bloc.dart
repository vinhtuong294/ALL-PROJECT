import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/market_repository.dart';
import 'merchant_event.dart';
import 'merchant_state.dart';

class MerchantBloc extends Bloc<MerchantEvent, MerchantState> {
  final MarketRepository repository;

  MerchantBloc(this.repository) : super(MerchantInitial()) {
    on<GetMerchantsEvent>((event, emit) async {
      emit(MerchantLoading());
      try {
        final response = await repository.getMerchants(
          page: event.page,
          limit: event.limit,
          search: event.search,
          status: event.status,
        );
        if (response.success) {
          emit(MerchantLoaded(
            merchants: response.data,
            meta: response.meta,
          ));
        } else {
          emit(const MerchantError('Failed to load merchants'));
        }
      } catch (e) {
        emit(MerchantError(e.toString()));
      }
    });

    on<GetPendingMerchantsEvent>((event, emit) async {
      emit(PendingMerchantsLoading());
      try {
        final response = await repository.getPendingMerchants(
          page: event.page,
          limit: event.limit,
        );
        if (response.success) {
          emit(PendingMerchantsLoaded(
            merchants: response.data,
            meta: response.meta,
          ));
        } else {
          emit(const MerchantError('Failed to load pending merchants'));
        }
      } catch (e) {
        emit(MerchantError(e.toString()));
      }
    });

    on<GetGoodsCategoriesEvent>((event, emit) async {
      try {
        final response = await repository.getGoodsCategories();
        if (response.success) {
          emit(GoodsCategoriesLoaded(response.data));
        } else {
          emit(const MerchantError('Failed to load categories'));
        }
      } catch (e) {
        emit(MerchantError(e.toString()));
      }
    });

    on<ApproveMerchantEvent>((event, emit) async {
      emit(ApproveMerchantLoading());
      try {
        final response = await repository.approveMerchant(event.userId);
        if (response.success) {
          emit(ApproveMerchantSuccess(response.message ?? 'Duyệt thành công'));
          // Trigger refresh
          add(const GetPendingMerchantsEvent());
        } else {
          emit(ApproveMerchantError(response.message ?? 'Duyệt thất bại'));
        }
      } catch (e) {
        emit(ApproveMerchantError(e.toString()));
      }
    });

    on<AddMerchantEvent>((event, emit) async {
      emit(AddMerchantLoading());
      try {
        final data = {
          'ten_nguoi_dung': event.tenNguoiDung,
          'dia_chi': event.diaChi,
          'so_dien_thoai': event.soDienThoai,
          'loai_hang_hoa': event.loaiHangHoa,
          'tien_thue_mac_dinh': event.tienThueMacDinh,
          'ghi_chu': event.ghiChu,
          'grid_col': event.gridCol,
          'grid_row': event.gridRow,
        };
        final response = await repository.createMerchant(data);
        if (response.success) {
          final resData = response.data;
          emit(AddMerchantSuccess(
            response.message ?? 'Thêm tiểu thương thành công',
            loginName: resData?.loginName,
            defaultPassword: resData?.defaultPassword,
            stallId: resData?.stallId,
            stallName: resData?.stallName,
            loaiHangHoa: resData?.loaiHangHoa,
          ));
        } else {
          emit(AddMerchantError(
              response.message ?? 'Thêm tiểu thương thất bại'));
        }
      } catch (e) {
        emit(AddMerchantError(e.toString()));
      }
    });
  }
}
