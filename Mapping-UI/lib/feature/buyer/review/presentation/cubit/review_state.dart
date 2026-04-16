part of 'review_cubit.dart';

/// Base class cho tất cả các state của Review
abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

/// State khởi tạo ban đầu
class ReviewInitial extends ReviewState {}

/// State đang tải dữ liệu đánh giá
class ReviewLoading extends ReviewState {}

/// State tải dữ liệu thành công
class ReviewLoaded extends ReviewState {
  final List<Review> reviews;
  final double averageRating;
  final Map<int, int> ratingCounts; // {5: 10, 4: 2, 3: 0, 2: 0, 1: 0}
  final int totalReviews;

  const ReviewLoaded({
    required this.reviews,
    required this.averageRating,
    required this.ratingCounts,
    required this.totalReviews,
  });

  @override
  List<Object?> get props => [reviews, averageRating, ratingCounts, totalReviews];
}

/// State đang gửi đánh giá
class ReviewSubmitting extends ReviewState {}

/// State gửi đánh giá thành công
class ReviewSubmitSuccess extends ReviewState {
  final String message;

  const ReviewSubmitSuccess({this.message = 'Đánh giá đã được gửi thành công!'});

  @override
  List<Object?> get props => [message];
}

/// State gửi đánh giá thất bại
class ReviewSubmitFailure extends ReviewState {
  final String errorMessage;

  const ReviewSubmitFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

/// State tải dữ liệu thất bại
class ReviewFailure extends ReviewState {
  final String errorMessage;

  const ReviewFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

/// State validation error khi submit review
class ReviewValidationError extends ReviewState {
  final String? reviewTextError;
  final String? ratingError;

  const ReviewValidationError({
    this.reviewTextError,
    this.ratingError,
  });

  @override
  List<Object?> get props => [reviewTextError, ratingError];
}

/// State chọn ảnh
class ReviewImagesSelected extends ReviewState {
  final List<String> imagePaths;

  const ReviewImagesSelected({required this.imagePaths});

  @override
  List<Object?> get props => [imagePaths];
}

/// Model cho Review
class Review {
  final String id;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    this.images = const [],
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      userName: json['userName'] ?? 'Anonymous',
      userAvatar: json['userAvatar'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      images: (json['images'] as List?)?.cast<String>() ?? [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
