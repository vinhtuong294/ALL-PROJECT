import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../../../core/config/app_config.dart';

part 'review_state.dart';

/// Review Cubit quản lý logic nghiệp vụ của màn hình đánh giá
/// 
/// Chức năng chính:
/// - Tải danh sách đánh giá của gian hàng
/// - Gửi đánh giá mới
/// - Validate input
/// - Quản lý việc chọn ảnh
class ReviewCubit extends Cubit<ReviewState> {
  final ImagePicker _imagePicker = ImagePicker();
  
  // Store data
  String? _shopId;
  List<String> _selectedImages = [];
  double _currentRating = 0;
  
  ReviewCubit() : super(ReviewInitial());

  /// Khởi tạo và tải danh sách đánh giá
  Future<void> loadReviews(String shopId) async {
    _shopId = shopId;
    
    if (AppConfig.enableApiLogging) {
      AppLogger.info('🎯 [REVIEW] Bắt đầu tải đánh giá cho shop: $shopId');
    }

    try {
      emit(ReviewLoading());

      // TODO: Gọi API để lấy danh sách đánh giá
      // await _reviewRepository.getReviews(shopId);
      
      // Mock data for now
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if cubit is still open before continuing
      if (isClosed) return;
      
      final mockReviews = _generateMockReviews();
      final averageRating = _calculateAverageRating(mockReviews);
      final ratingCounts = _calculateRatingCounts(mockReviews);

      if (AppConfig.enableApiLogging) {
        AppLogger.info('✅ [REVIEW] Tải thành công ${mockReviews.length} đánh giá');
        AppLogger.info('📊 [REVIEW] Rating trung bình: $averageRating');
      }

      emit(ReviewLoaded(
        reviews: mockReviews,
        averageRating: averageRating,
        ratingCounts: ratingCounts,
        totalReviews: mockReviews.length,
      ));
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [REVIEW] Lỗi khi tải đánh giá: ${e.toString()}');
      }
      if (!isClosed) {
        emit(ReviewFailure(
          errorMessage: 'Không thể tải đánh giá: ${e.toString()}',
        ));
      }
    }
  }

  /// Validate review text
  String? validateReviewText(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'Vui lòng nhập nội dung đánh giá';
    }
    
    if (text.trim().length < 10) {
      return 'Đánh giá phải có ít nhất 10 ký tự';
    }
    
    return null;
  }

  /// Validate rating
  String? validateRating(double rating) {
    if (rating <= 0) {
      return 'Vui lòng chọn số sao đánh giá';
    }
    
    return null;
  }

  /// Gửi đánh giá mới
  Future<void> submitReview({
    required String reviewText,
    double? rating,
  }) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('🎯 [REVIEW] Bắt đầu gửi đánh giá');
      AppLogger.info('📝 [REVIEW] Nội dung: $reviewText');
      AppLogger.info('⭐ [REVIEW] Rating: ${rating ?? _currentRating}');
      AppLogger.info('📸 [REVIEW] Số ảnh: ${_selectedImages.length}');
    }

    // Validate inputs
    final reviewError = validateReviewText(reviewText);
    final ratingError = validateRating(rating ?? _currentRating);

    if (reviewError != null || ratingError != null) {
      if (AppConfig.enableApiLogging) {
        AppLogger.warning('⚠️ [REVIEW] Validation failed');
      }
      emit(ReviewValidationError(
        reviewTextError: reviewError,
        ratingError: ratingError,
      ));
      return;
    }

    try {
      emit(ReviewSubmitting());

      // TODO: Gọi API để gửi đánh giá
      // await _reviewRepository.submitReview(
      //   shopId: _shopId,
      //   rating: rating ?? _currentRating,
      //   comment: reviewText,
      //   images: _selectedImages,
      // );
      
      await Future.delayed(const Duration(seconds: 2));

      // Check if cubit is still open before continuing
      if (isClosed) return;

      if (AppConfig.enableApiLogging) {
        AppLogger.info('🎉 [REVIEW] Gửi đánh giá thành công!');
      }

      // Clear selected images and rating
      _selectedImages.clear();
      _currentRating = 0;

      emit(const ReviewSubmitSuccess(
        message: '✅ Đánh giá đã được gửi thành công!',
      ));

      // Reload reviews
      if (_shopId != null) {
        await loadReviews(_shopId!);
      }
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [REVIEW] Lỗi khi gửi đánh giá: ${e.toString()}');
      }
      if (!isClosed) {
        emit(ReviewSubmitFailure(
          errorMessage: 'Không thể gửi đánh giá: ${e.toString()}',
        ));
      }
    }
  }

  /// Chọn ảnh từ thư viện
  Future<void> pickImages() async {
    try {
      if (AppConfig.enableApiLogging) {
        AppLogger.info('📸 [REVIEW] Mở thư viện ảnh...');
      }

      final List<XFile> images = await _imagePicker.pickMultiImage();
      
      if (images.isNotEmpty) {
        _selectedImages = images.map((img) => img.path).toList();
        
        if (AppConfig.enableApiLogging) {
          AppLogger.info('✅ [REVIEW] Đã chọn ${_selectedImages.length} ảnh');
        }

        emit(ReviewImagesSelected(imagePaths: _selectedImages));
      }
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [REVIEW] Lỗi khi chọn ảnh: ${e.toString()}');
      }
    }
  }

  /// Chọn ảnh từ camera
  Future<void> pickImageFromCamera() async {
    try {
      if (AppConfig.enableApiLogging) {
        AppLogger.info('📸 [REVIEW] Mở camera...');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      
      if (image != null) {
        _selectedImages.add(image.path);
        
        if (AppConfig.enableApiLogging) {
          AppLogger.info('✅ [REVIEW] Đã chụp ảnh');
        }

        emit(ReviewImagesSelected(imagePaths: _selectedImages));
      }
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [REVIEW] Lỗi khi chụp ảnh: ${e.toString()}');
      }
    }
  }

  /// Xóa ảnh đã chọn
  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      
      if (AppConfig.enableApiLogging) {
        AppLogger.info('🗑️ [REVIEW] Đã xóa ảnh. Còn lại: ${_selectedImages.length}');
      }

      emit(ReviewImagesSelected(imagePaths: _selectedImages));
    }
  }

  /// Cập nhật rating
  void updateRating(double rating) {
    _currentRating = rating;
    
    if (AppConfig.enableApiLogging) {
      AppLogger.info('⭐ [REVIEW] Rating được cập nhật: $rating');
    }
  }

  /// Reset state về initial
  void resetState() {
    _selectedImages.clear();
    _currentRating = 0;
    emit(ReviewInitial());
  }

  /// Get selected images
  List<String> get selectedImages => _selectedImages;

  /// Get current rating
  double get currentRating => _currentRating;

  // Helper methods
  
  /// Tính rating trung bình
  double _calculateAverageRating(List<Review> reviews) {
    if (reviews.isEmpty) return 0;
    
    final total = reviews.fold<double>(
      0,
      (sum, review) => sum + review.rating,
    );
    
    return double.parse((total / reviews.length).toStringAsFixed(1));
  }

  /// Đếm số lượng đánh giá theo từng mức sao
  Map<int, int> _calculateRatingCounts(List<Review> reviews) {
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    
    for (final review in reviews) {
      final ratingInt = review.rating.round();
      if (counts.containsKey(ratingInt)) {
        counts[ratingInt] = counts[ratingInt]! + 1;
      }
    }
    
    return counts;
  }

  /// Generate mock reviews for testing
  List<Review> _generateMockReviews() {
    return [
      Review(
        id: '1',
        userName: 'Nguyễn Văn A',
        userAvatar: 'https://i.pravatar.cc/150?img=1',
        rating: 5,
        comment: 'Gian hàng rất tốt, thức ăn tươi ngon, giá cả hợp lý!',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Review(
        id: '2',
        userName: 'Trần Thị B',
        userAvatar: 'https://i.pravatar.cc/150?img=2',
        rating: 5,
        comment: 'Rất hài lòng với chất lượng sản phẩm và dịch vụ',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Review(
        id: '3',
        userName: 'Lê Văn C',
        userAvatar: 'https://i.pravatar.cc/150?img=3',
        rating: 5,
        comment: 'Tuyệt vời! Sẽ quay lại ủng hộ',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Review(
        id: '4',
        userName: 'Phạm Thị D',
        userAvatar: 'https://i.pravatar.cc/150?img=4',
        rating: 5,
        comment: 'Chất lượng tốt, giao hàng nhanh',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      Review(
        id: '5',
        userName: 'Hoàng Văn E',
        userAvatar: 'https://i.pravatar.cc/150?img=5',
        rating: 5,
        comment: 'Rất đáng để thử!',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Review(
        id: '6',
        userName: 'Võ Thị F',
        userAvatar: 'https://i.pravatar.cc/150?img=6',
        rating: 5,
        comment: 'Sản phẩm chất lượng cao',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
      Review(
        id: '7',
        userName: 'Đặng Văn G',
        userAvatar: 'https://i.pravatar.cc/150?img=7',
        rating: 5,
        comment: 'Tươi ngon, thơm, sạch sẽ',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Review(
        id: '8',
        userName: 'Bùi Thị H',
        userAvatar: 'https://i.pravatar.cc/150?img=8',
        rating: 5,
        comment: 'Rất hài lòng',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      Review(
        id: '9',
        userName: 'Đinh Văn I',
        userAvatar: 'https://i.pravatar.cc/150?img=9',
        rating: 4,
        comment: 'Khá tốt, giá hơi cao một chút',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(days: 9)),
      ),
      Review(
        id: '10',
        userName: 'Dương Thị K',
        userAvatar: 'https://i.pravatar.cc/150?img=10',
        rating: 4,
        comment: 'Tốt, sẽ quay lại',
        images: [],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }
}
