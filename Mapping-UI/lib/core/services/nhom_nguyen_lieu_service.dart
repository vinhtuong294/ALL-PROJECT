import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import '../models/nhom_nguyen_lieu_model.dart';
import 'auth/simple_auth_helper.dart';

class NhomNguyenLieuService {
  static const String _baseUrl = AppConfig.baseUrl;

  /// Lấy headers với token authentication
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Lấy danh sách nhóm nguyên liệu
  static Future<NhomNguyenLieuResponse> getNhomNguyenLieu() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/seller/nhom-nguyen-lieu'),
        headers: headers,
      );

      debugPrint('NhomNguyenLieuService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return NhomNguyenLieuResponse.fromJson(jsonData);
      } else {
        debugPrint('NhomNguyenLieuService: Error - ${response.body}');
        return NhomNguyenLieuResponse(success: false, data: []);
      }
    } catch (e) {
      debugPrint('NhomNguyenLieuService: Exception - $e');
      return NhomNguyenLieuResponse(success: false, data: []);
    }
  }

  /// Lấy danh sách nguyên liệu theo nhóm
  static Future<NguyenLieuTheoNhomResponse> getNguyenLieuTheoNhom(String maNhomNguyenLieu) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/seller/nguyen-lieu?ma_nhom_nguyen_lieu=$maNhomNguyenLieu'),
        headers: headers,
      );

      debugPrint('NhomNguyenLieuService: getNguyenLieuTheoNhom status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return NguyenLieuTheoNhomResponse.fromJson(jsonData);
      } else {
        debugPrint('NhomNguyenLieuService: Error - ${response.body}');
        return NguyenLieuTheoNhomResponse(success: false, data: []);
      }
    } catch (e) {
      debugPrint('NhomNguyenLieuService: Exception - $e');
      return NguyenLieuTheoNhomResponse(success: false, data: []);
    }
  }

  /// Lấy danh sách sản phẩm của seller (GET /api/seller/products)
  static Future<SellerProductsResponse> getSellerProducts({
    int page = 1,
    int limit = 12,
    String sort = 'ngay_cap_nhat',
    String order = 'desc',
  }) async {
    try {
      final headers = await _getHeaders();
      final url = '$_baseUrl/seller/products?page=$page&limit=$limit&sort=$sort&order=$order';
      
      debugPrint('[SELLER_PRODUCTS] Fetching: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('[SELLER_PRODUCTS] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return SellerProductsResponse.fromJson(jsonData);
      } else {
        debugPrint('[SELLER_PRODUCTS] Error - ${response.body}');
        return SellerProductsResponse(
          data: [],
          meta: SellerProductsMeta(page: 1, limit: limit, total: 0, hasNext: false),
        );
      }
    } catch (e) {
      debugPrint('[SELLER_PRODUCTS] Exception - $e');
      return SellerProductsResponse(
        data: [],
        meta: SellerProductsMeta(page: 1, limit: limit, total: 0, hasNext: false),
      );
    }
  }

  /// Thêm sản phẩm mới (POST /api/seller/products)
  static Future<AddProductResponse> addProduct({
    required String maNguyenLieu,
    required int giaGoc,
    required int soLuongBan,
    required String donViBan,
    String? hinhAnh,
    int phanTramGiamGia = 0,
    DateTime? thoiGianBatDauGiam,
    DateTime? thoiGianKetThucGiam,
  }) async {
    debugPrint('========== ADD PRODUCT API DEBUG ==========');
    debugPrint('[ADD_PRODUCT] Starting API call...');
    debugPrint('[ADD_PRODUCT] ma_nguyen_lieu: $maNguyenLieu');
    debugPrint('[ADD_PRODUCT] gia_goc: $giaGoc');
    debugPrint('[ADD_PRODUCT] so_luong_ban: $soLuongBan');
    debugPrint('[ADD_PRODUCT] don_vi_ban: $donViBan');
    debugPrint('[ADD_PRODUCT] phan_tram_giam_gia: $phanTramGiamGia');
    debugPrint('[ADD_PRODUCT] hinh_anh: $hinhAnh');
    debugPrint('[ADD_PRODUCT] thoi_gian_bat_dau_giam: $thoiGianBatDauGiam');
    debugPrint('[ADD_PRODUCT] thoi_gian_ket_thuc_giam: $thoiGianKetThucGiam');
    
    try {
      final headers = await _getHeaders();
      debugPrint('[ADD_PRODUCT] Headers: $headers');
      
      final Map<String, dynamic> body = {
        'ma_nguyen_lieu': maNguyenLieu,
        'gia_goc': giaGoc,
        'so_luong_ban': soLuongBan,
        'don_vi_ban': donViBan,
        'phan_tram_giam_gia': phanTramGiamGia,
      };

      // Thêm hình ảnh nếu có
      if (hinhAnh != null && hinhAnh.isNotEmpty) {
        body['hinh_anh'] = hinhAnh;
      }

      // Thêm thời gian giảm giá nếu có
      if (thoiGianBatDauGiam != null) {
        body['thoi_gian_bat_dau_giam'] = thoiGianBatDauGiam.toIso8601String();
      }
      if (thoiGianKetThucGiam != null) {
        body['thoi_gian_ket_thuc_giam'] = thoiGianKetThucGiam.toIso8601String();
      }

      final jsonBody = json.encode(body);
      debugPrint('[ADD_PRODUCT] Request URL: $_baseUrl/seller/products');
      debugPrint('[ADD_PRODUCT] Request Body: $jsonBody');

      final response = await http.post(
        Uri.parse('$_baseUrl/seller/products'),
        headers: headers,
        body: jsonBody,
      );

      debugPrint('[ADD_PRODUCT] Response Status: ${response.statusCode}');
      debugPrint('[ADD_PRODUCT] Response Body: ${response.body}');
      debugPrint('============================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        debugPrint('[ADD_PRODUCT] ✅ SUCCESS - Parsed response: $jsonData');
        return AddProductResponse.fromJson(jsonData);
      } else {
        final jsonData = json.decode(response.body);
        final message = jsonData['message'] ?? 'Không thể thêm sản phẩm';
        debugPrint('[ADD_PRODUCT] ❌ FAILED - Message: $message');
        return AddProductResponse(success: false, message: message);
      }
    } catch (e, stackTrace) {
      debugPrint('[ADD_PRODUCT] ❌ EXCEPTION: $e');
      debugPrint('[ADD_PRODUCT] Stack trace: $stackTrace');
      debugPrint('============================================');
      return AddProductResponse(success: false, message: 'Lỗi kết nối: $e');
    }
  }

  /// Cập nhật sản phẩm (PUT /api/seller/products/:ma_nguyen_lieu)
  static Future<AddProductResponse> updateProduct({
    required String maNguyenLieu,
    required int giaGoc,
    required int soLuongBan,
    required String donViBan,
    String? hinhAnh,
    int phanTramGiamGia = 0,
    DateTime? thoiGianBatDauGiam,
    DateTime? thoiGianKetThucGiam,
  }) async {
    debugPrint('========== UPDATE PRODUCT API DEBUG ==========');
    debugPrint('[UPDATE_PRODUCT] Starting API call...');
    debugPrint('[UPDATE_PRODUCT] ma_nguyen_lieu: $maNguyenLieu');
    debugPrint('[UPDATE_PRODUCT] gia_goc: $giaGoc');
    debugPrint('[UPDATE_PRODUCT] so_luong_ban: $soLuongBan');
    debugPrint('[UPDATE_PRODUCT] don_vi_ban: $donViBan');
    debugPrint('[UPDATE_PRODUCT] phan_tram_giam_gia: $phanTramGiamGia');
    debugPrint('[UPDATE_PRODUCT] hinh_anh: $hinhAnh');
    
    try {
      final headers = await _getHeaders();
      
      final Map<String, dynamic> body = {
        'gia_goc': giaGoc,
        'so_luong_ban': soLuongBan,
        'don_vi_ban': donViBan,
        'phan_tram_giam_gia': phanTramGiamGia,
      };

      // Luôn gửi hình ảnh (API có thể yêu cầu bắt buộc)
      if (hinhAnh != null && hinhAnh.isNotEmpty) {
        body['hinh_anh'] = hinhAnh;
      }

      // Thêm thời gian giảm giá nếu có
      if (thoiGianBatDauGiam != null) {
        body['thoi_gian_bat_dau_giam'] = thoiGianBatDauGiam.toIso8601String();
      }
      if (thoiGianKetThucGiam != null) {
        body['thoi_gian_ket_thuc_giam'] = thoiGianKetThucGiam.toIso8601String();
      }

      final jsonBody = json.encode(body);
      final url = '$_baseUrl/seller/products/$maNguyenLieu';
      debugPrint('[UPDATE_PRODUCT] Request URL: $url');
      debugPrint('[UPDATE_PRODUCT] Request Body: $jsonBody');

      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonBody,
      );

      debugPrint('[UPDATE_PRODUCT] Response Status: ${response.statusCode}');
      debugPrint('[UPDATE_PRODUCT] Response Body: ${response.body}');
      debugPrint('==============================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        debugPrint('[UPDATE_PRODUCT] ✅ SUCCESS');
        return AddProductResponse.fromJson(jsonData);
      } else {
        final jsonData = json.decode(response.body);
        final message = jsonData['message'] ?? 'Không thể cập nhật sản phẩm';
        debugPrint('[UPDATE_PRODUCT] ❌ FAILED - Message: $message');
        return AddProductResponse(success: false, message: message);
      }
    } catch (e, stackTrace) {
      debugPrint('[UPDATE_PRODUCT] ❌ EXCEPTION: $e');
      debugPrint('[ADD_PRODUCT] Stack trace: $stackTrace');
      debugPrint('============================================');
      return AddProductResponse(success: false, message: 'Lỗi kết nối: $e');
    }
  }

  /// Xóa sản phẩm (DELETE /api/seller/products/:ma_nguyen_lieu)
  static Future<DeleteProductResponse> deleteProduct(String maNguyenLieu) async {
    debugPrint('========== DELETE PRODUCT API DEBUG ==========');
    debugPrint('[DELETE_PRODUCT] ma_nguyen_lieu: $maNguyenLieu');
    
    try {
      final headers = await _getHeaders();
      final url = '$_baseUrl/seller/products/$maNguyenLieu';
      debugPrint('[DELETE_PRODUCT] Request URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('[DELETE_PRODUCT] Response Status: ${response.statusCode}');
      debugPrint('[DELETE_PRODUCT] Response Body: ${response.body}');
      debugPrint('==============================================');

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('[DELETE_PRODUCT] ✅ SUCCESS');
        if (response.body.isNotEmpty) {
          final jsonData = json.decode(response.body);
          return DeleteProductResponse.fromJson(jsonData);
        }
        return DeleteProductResponse(success: true, message: 'Xóa sản phẩm thành công');
      } else {
        final jsonData = json.decode(response.body);
        final message = jsonData['message'] ?? 'Không thể xóa sản phẩm';
        debugPrint('[DELETE_PRODUCT] ❌ FAILED - Message: $message');
        return DeleteProductResponse(success: false, message: message);
      }
    } catch (e) {
      debugPrint('[DELETE_PRODUCT] ❌ EXCEPTION: $e');
      return DeleteProductResponse(success: false, message: 'Lỗi kết nối: $e');
    }
  }

  /// Upload nhiều ảnh (POST /api/upload/multiple)
  /// 
  /// Parameters:
  /// - files: Danh sách File ảnh (tối đa 10)
  /// - folder: Tên thư mục lưu ảnh (mặc định: uploads)
  /// 
  /// Returns: UploadResponse với danh sách URL ảnh đã upload
  static Future<UploadResponse> uploadImages({
    required List<File> files,
    String folder = 'uploads',
  }) async {
    debugPrint('========== UPLOAD IMAGES API DEBUG ==========');
    debugPrint('[UPLOAD] Starting upload - ${files.length} files');
    debugPrint('[UPLOAD] Folder: $folder');

    if (files.isEmpty) {
      debugPrint('[UPLOAD] ❌ No files to upload');
      return UploadResponse(success: false, message: 'Không có ảnh để upload', urls: []);
    }

    if (files.length > 10) {
      debugPrint('[UPLOAD] ❌ Too many files (max 10)');
      return UploadResponse(success: false, message: 'Tối đa 10 ảnh', urls: []);
    }

    try {
      final token = await getToken();
      
      // Tạo multipart request
      final uri = Uri.parse('$_baseUrl/upload/multiple');
      final request = http.MultipartRequest('POST', uri);
      
      // Thêm headers
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Thêm folder field
      request.fields['folder'] = folder;
      
      // Thêm các file ảnh
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = file.path.split('/').last;
        final extension = fileName.split('.').last.toLowerCase();
        
        // Xác định content type dựa trên extension
        String contentType;
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'png':
            contentType = 'image/png';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
          default:
            contentType = 'image/jpeg'; // fallback
        }
        
        debugPrint('[UPLOAD] Adding file $i: $fileName (contentType: $contentType)');
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            file.path,
            filename: fileName,
            contentType: MediaType.parse(contentType),
          ),
        );
      }

      debugPrint('[UPLOAD] Request URL: $uri');
      debugPrint('[UPLOAD] Sending request...');

      // Gửi request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[UPLOAD] Response Status: ${response.statusCode}');
      debugPrint('[UPLOAD] Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        debugPrint('[UPLOAD] ✅ SUCCESS');
        return UploadResponse.fromJson(jsonData);
      } else {
        final jsonData = json.decode(response.body);
        final message = jsonData['message'] ?? 'Không thể upload ảnh';
        debugPrint('[UPLOAD] ❌ FAILED - Message: $message');
        return UploadResponse(success: false, message: message, urls: []);
      }
    } catch (e, stackTrace) {
      debugPrint('[UPLOAD] ❌ EXCEPTION: $e');
      debugPrint('[UPLOAD] Stack trace: $stackTrace');
      return UploadResponse(success: false, message: 'Lỗi upload: $e', urls: []);
    }
  }
}

/// Response model cho API upload ảnh
class UploadResponse {
  final bool success;
  final String? message;
  final List<String> urls;

  UploadResponse({
    required this.success,
    this.message,
    required this.urls,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    // Parse URLs từ response
    // Response format: { "success": true, "data": { "url": "...", "originalName": "...", ... } }
    List<String> parsedUrls = [];
    
    if (json['data'] != null) {
      final data = json['data'];
      if (data is Map) {
        // Single file upload: data.url
        if (data['url'] != null) {
          parsedUrls.add(data['url'].toString());
        }
        // Multiple files: data.urls (array)
        else if (data['urls'] != null && data['urls'] is List) {
          parsedUrls = (data['urls'] as List).map((e) => e.toString()).toList();
        }
      } else if (data is List) {
        // Array of URLs or objects with url field
        for (final item in data) {
          if (item is String) {
            parsedUrls.add(item);
          } else if (item is Map && item['url'] != null) {
            parsedUrls.add(item['url'].toString());
          }
        }
      }
    }

    debugPrint('[UPLOAD] Parsed ${parsedUrls.length} URLs: $parsedUrls');

    return UploadResponse(
      success: json['success'] ?? false,
      message: json['message'],
      urls: parsedUrls,
    );
  }
}

/// Response model cho API thêm sản phẩm
class AddProductResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  AddProductResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory AddProductResponse.fromJson(Map<String, dynamic> json) {
    // Kiểm tra nếu response có field 'success'
    if (json.containsKey('success')) {
      return AddProductResponse(
        success: json['success'] ?? false,
        message: json['message'],
        data: json['data'],
      );
    }
    
    // Nếu response trả về data trực tiếp (có ma_nguyen_lieu = thành công)
    if (json.containsKey('ma_nguyen_lieu') || json.containsKey('ma_gian_hang')) {
      return AddProductResponse(
        success: true,
        message: 'Thêm sản phẩm thành công',
        data: json,
      );
    }
    
    // Fallback
    return AddProductResponse(
      success: false,
      message: json['message'] ?? 'Không thể thêm sản phẩm',
      data: null,
    );
  }
}

/// Response model cho API lấy danh sách sản phẩm seller
class SellerProductsResponse {
  final List<Map<String, dynamic>> data;
  final SellerProductsMeta meta;

  SellerProductsResponse({
    required this.data,
    required this.meta,
  });

  factory SellerProductsResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final metaJson = json['meta'] as Map<String, dynamic>? ?? {};
    
    return SellerProductsResponse(
      data: dataList,
      meta: SellerProductsMeta.fromJson(metaJson),
    );
  }
}

/// Meta info cho pagination
class SellerProductsMeta {
  final int page;
  final int limit;
  final int total;
  final bool hasNext;

  SellerProductsMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.hasNext,
  });

  factory SellerProductsMeta.fromJson(Map<String, dynamic> json) {
    return SellerProductsMeta(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 12,
      total: json['total'] ?? 0,
      hasNext: json['hasNext'] ?? false,
    );
  }
}

/// Response model cho API xóa sản phẩm
class DeleteProductResponse {
  final bool success;
  final String? message;

  DeleteProductResponse({
    required this.success,
    this.message,
  });

  factory DeleteProductResponse.fromJson(Map<String, dynamic> json) {
    return DeleteProductResponse(
      success: json['success'] ?? true,
      message: json['message'],
    );
  }
}
