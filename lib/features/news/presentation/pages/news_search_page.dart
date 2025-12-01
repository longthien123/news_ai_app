import 'package:app_news_ai/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ionicons/ionicons.dart';
import '../../data/datasources/remote/news_remote_source.dart';
import '../../data/repositories/news_repo_impl.dart';
import '../../domain/usecases/get_news_usecase.dart';
import '../cubit/search_news_cubit.dart';
import '../widgets/news_home_widgets.dart';

class NewsSearchPage extends StatelessWidget {
  const NewsSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final remoteSource = NewsRemoteSourceImpl(
          firestore: FirebaseFirestore.instance,
        );
        final repository = NewsRepositoryImpl(remoteSource: remoteSource);
        final useCase = GetNewsUseCase(repository);
        return SearchNewsCubit(getNewsUseCase: useCase);
      },
      child: const NewsSearchView(),
    );
  }
}

class NewsSearchView extends StatefulWidget {
  const NewsSearchView({super.key});

  @override
  State<NewsSearchView> createState() => _NewsSearchViewState();
}

class _NewsSearchViewState extends State<NewsSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto focus vào ô tìm kiếm khi mở trang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      context.read<SearchNewsCubit>().searchNews(query.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Ionicons.chevron_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm tin tức...',
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Ionicons.search_outline,
                color: Colors.grey[600],
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Ionicons.close_circle,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        context.read<SearchNewsCubit>().clearSearch();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
            onSubmitted: _performSearch,
            textInputAction: TextInputAction.search,
          ),
        ),
      ),
      body: BlocBuilder<SearchNewsCubit, SearchNewsState>(
        builder: (context, state) {
          if (state is SearchNewsInitial) {
            return _buildSearchSuggestions();
          }

          if (state is SearchNewsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is SearchNewsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (state is SearchNewsLoaded) {
            if (state.results.isEmpty) {
              return _buildNoResults();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Tìm thấy ${state.results.length} kết quả',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.results.length,
                    itemBuilder: (context, index) {
                      final news = state.results[index];
                      return RecommendationCard(news: news);
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final suggestions = [
      'Công nghệ',
      'Thể thao',
      'Kinh tế',
      'Giải trí',
      'Sức khỏe',
      'Du lịch',
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gợi ý tìm kiếm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = suggestion;
                  _performSearch(suggestion);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Ionicons.search_outline,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        suggestion,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }


  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.search_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Không tìm thấy kết quả',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thử tìm kiếm với từ khóa khác',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
