import 'package:app_news_ai/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ionicons/ionicons.dart';
import '../../data/datasources/remote/news_remote_source.dart';
import '../../data/repositories/news_repo_impl.dart';
import '../../domain/usecases/get_news_usecase.dart';
import '../cubit/news_cubit.dart';
import '../widgets/news_home_widgets.dart';

/// [NEW FEATURE] Màn hình gợi ý tin tức bằng AI
/// Sử dụng Gemini API để phân tích sở thích user và gợi ý tin phù hợp
class AIRecommendationPage extends StatelessWidget {
  const AIRecommendationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final remoteSource = NewsRemoteSourceImpl(
          firestore: FirebaseFirestore.instance,
        );
        final repository = NewsRepositoryImpl(remoteSource: remoteSource);
        final useCase = GetNewsUseCase(repository);
        // Load tin gợi ý AI
        return NewsCubit(getNewsUseCase: useCase)..loadNews(category: 'Gợi ý cho bạn');
      },
      child: const AIRecommendationView(),
    );
  }
}

class AIRecommendationView extends StatelessWidget {
  const AIRecommendationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Header giống Thư viện
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 27, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Ionicons.chevron_back,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  const Text(
                    'Gợi ý cho bạn',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  const Text(
                    'Tin tức được chọn riêng dựa trên sở thích của bạn',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Search bar (giống Thư viện)
            Padding(
              padding: const EdgeInsets.fromLTRB(27, 16, 27, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm trong những bài viết gợi ý...',
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Ionicons.search_outline,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    suffixIcon: BlocBuilder<NewsCubit, NewsState>(
                      builder: (context, state) {
                        return IconButton(
                          icon: Icon(
                            Ionicons.refresh_outline,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          onPressed: () {
                            context.read<NewsCubit>().refreshNews();
                          },
                        );
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    // TODO: Implement search functionality if needed
                  },
                ),
              ),
            ),

            // News list
            Expanded(
              child: BlocBuilder<NewsCubit, NewsState>(
                builder: (context, state) {
                  // Loading state
                  if (state is NewsLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Đang phân tích sở thích của bạn...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Error state
                  if (state is NewsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Ionicons.alert_circle_outline,
                            size: 80,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không thể tải gợi ý',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              state.message,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              context.read<NewsCubit>().refreshNews();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Thử lại',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Success state
                  if (state is NewsLoaded) {
                    final recommendations = state.recommendedNews;

                    // Empty state
                    if (recommendations.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Ionicons.sparkles_outline,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có gợi ý',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy đọc thêm tin tức để AI hiểu sở thích của bạn',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // List of recommended news
                    return RefreshIndicator(
                      onRefresh: () async {
                        await context.read<NewsCubit>().refreshNews();
                      },
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(27, 0, 27, 16),
                        itemCount: recommendations.length,
                        itemBuilder: (context, index) {
                          final news = recommendations[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: RecommendationCard(news: news),
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
