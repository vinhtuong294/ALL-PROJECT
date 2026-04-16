import 'package:equatable/equatable.dart';
import '../../../../../core/models/search_response.dart';

/// State cho Search
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SearchInitial extends SearchState {
  final List<String> searchHistory;

  const SearchInitial({this.searchHistory = const []});

  @override
  List<Object?> get props => [searchHistory];
}

/// Suggesting state - đang load suggestions
class SearchSuggesting extends SearchState {
  final String query;
  const SearchSuggesting({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Suggestions loaded state
class SearchSuggestionsLoaded extends SearchState {
  final SearchData data;
  final String query;
  final List<String> searchHistory;

  const SearchSuggestionsLoaded({
    required this.data,
    required this.query,
    this.searchHistory = const [],
  });

  @override
  List<Object?> get props => [data, query, searchHistory];
}

/// Loading state
class SearchLoading extends SearchState {
  const SearchLoading();
}

/// Success state
class SearchSuccess extends SearchState {
  final SearchData data;
  final String query;

  const SearchSuccess({
    required this.data,
    required this.query,
  });

  @override
  List<Object?> get props => [data, query];
}

/// Empty state
class SearchEmpty extends SearchState {
  final String query;

  const SearchEmpty({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Error state
class SearchError extends SearchState {
  final String message;

  const SearchError({required this.message});

  @override
  List<Object?> get props => [message];
}
