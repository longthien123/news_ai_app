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
      backgroundColor: Colors.grey[50],
      // Header với icon AI gradient
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Ionicons.chevron_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Icon AI gradient
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Ionicons.sparkles, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Gợi ý cho bạn',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Nút refresh để tải lại gợi ý
          IconButton(
            icon: const Icon(Ionicons.refresh_outline, color: Colors.black87),
            onPressed: () {
              context.read<NewsCubit>().refreshNews();
            },
          ),
        ],
      ),
      body: BlocBuilder<NewsCubit, NewsState>(
        builder: (context, state) {
          // Loading state
          if (state is NewsLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang phân tích sở thích của bạn...', style: TextStyle(color: Colors.grey)),
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
                  const Icon(Ionicons.alert_circle_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Không thể tải gợi ý',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.message,
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.read<NewsCubit>().refreshNews(),
                    icon: const Icon(Ionicons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
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
                    const Icon(Ionicons.newspaper_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có gợi ý',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Hãy đọc thêm tin tức để AI hiểu sở thích của bạn',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        textAlign: TextAlign.center,
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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
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
    );
  }
}
