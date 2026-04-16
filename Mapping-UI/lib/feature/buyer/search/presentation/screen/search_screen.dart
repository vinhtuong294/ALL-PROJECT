import 'package:dngo/core/widgets/buyer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';
import 'search_result_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchCubit()..loadHistory(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm món ăn, nguyên liệu, gian hàng...',
            hintStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Color(0xFF8E8E93),
            ),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF8E8E93)),
                    onPressed: () {
                      _searchController.clear();
                      context.read<SearchCubit>().clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Color(0xFF1C1C1E),
          ),
          onChanged: (value) {
            setState(() {});
            context.read<SearchCubit>().suggest(value);
          },
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchResultScreen(searchQuery: value),
                ),
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF00B40F)),
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchResultScreen(searchQuery: _searchController.text),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state is SearchSuggesting) {
            return _buildLoadingView();
          }
          if (state is SearchSuggestionsLoaded) {
            return _buildSuggestionsView(context, state);
          }
          if (state is SearchInitial && state.searchHistory.isNotEmpty) {
            return _buildHistoryView(context, state.searchHistory);
          }
          return _buildInitialView();
        },
      ),
    );
  }

  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tìm kiếm món ăn, nguyên liệu\nhoặc gian hàng',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Roboto', fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const BuyerLoading(
              message: 'Đang tải...',
            );
  }

  Widget _buildSuggestionsView(BuildContext context, SearchSuggestionsLoaded state) {
    final data = state.data;
    return ListView(
      children: [
        // Món ăn suggestions
        if (data.dishes.isNotEmpty) ...[
          _buildSectionHeader('Món ăn'),
          ...data.dishes.take(5).map((item) => _buildSuggestionItem(
            icon: Icons.restaurant,
            imageUrl: item.image,
            title: item.name,
            subtitle: item.type,
            onTap: () => _navigateToResult(item.name),
          )),
        ],
        // Nguyên liệu suggestions
        if (data.ingredients.isNotEmpty) ...[
          _buildSectionHeader('Nguyên liệu'),
          ...data.ingredients.take(5).map((item) => _buildSuggestionItem(
            icon: Icons.eco,
            imageUrl: item.image,
            title: item.name,
            subtitle: item.type,
            onTap: () => _navigateToResult(item.name),
          )),
        ],
        // Gian hàng suggestions
        if (data.stalls.isNotEmpty) ...[
          _buildSectionHeader('Gian hàng'),
          ...data.stalls.take(5).map((item) => _buildSuggestionItem(
            icon: Icons.store,
            imageUrl: item.image,
            title: item.name,
            subtitle: item.type,
            onTap: () => _navigateToResult(item.name),
          )),
        ],
        // Xem tất cả kết quả
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _navigateToResult(state.query),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B40F),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Xem tất cả kết quả cho "${state.query}"',
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8E8E93),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem({
    required IconData icon,
    String? imageUrl,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(icon, color: const Color(0xFF00B40F), size: 20),
                )
              : Icon(icon, color: const Color(0xFF00B40F), size: 20),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'Roboto', fontSize: 15, color: Color(0xFF1C1C1E)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Color(0xFF8E8E93)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: const Icon(Icons.north_west, size: 16, color: Color(0xFF8E8E93)),
      onTap: onTap,
    );
  }

  void _navigateToResult(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchResultScreen(searchQuery: query)),
    );
  }

  Widget _buildHistoryView(BuildContext context, List<String> history) {
    return ListView(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tìm kiếm gần đây',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              TextButton(
                onPressed: () {
                  context.read<SearchCubit>().clearHistory();
                },
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Color(0xFF008EDB),
                  ),
                ),
              ),
            ],
          ),
        ),
        // History items
        ...history.map((query) => ListTile(
              leading: const Icon(
                Icons.history,
                color: Color(0xFF8E8E93),
              ),
              title: Text(
                query,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Color(0xFF8E8E93),
                  size: 20,
                ),
                onPressed: () {
                  context.read<SearchCubit>().removeHistoryItem(query);
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchResultScreen(searchQuery: query),
                  ),
                );
              },
            )),
      ],
    );
  }
}
