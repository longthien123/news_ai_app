import 'package:app_news_ai/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../widgets/app_bottom_nav_bar.dart';
import '../../../notification/presentation/widgets/notification_dropdown.dart';
import '../../../notification/presentation/cubit/notification_cubit.dart';
import '../../../notification/domain/entities/user_preference.dart';
import '../../../notification/data/services/auto_notification_service.dart';
import '../../../notification/data/services/gemini_recommendation_service.dart';
import '../../../notification/data/datasources/notification_datasource.dart';
import '../../data/datasources/remote/news_remote_source.dart';
import '../../data/repositories/news_repo_impl.dart';
import '../../domain/usecases/get_news_usecase.dart';
import '../cubit/news_cubit.dart';
import '../widgets/news_home_widgets.dart';

import 'news_saved.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class NewsHomePage extends StatelessWidget {
  const NewsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final remoteSource = NewsRemoteSourceImpl(
          firestore: FirebaseFirestore.instance,
        );
        final repository = NewsRepositoryImpl(remoteSource: remoteSource);
        final useCase = GetNewsUseCase(repository);
        return NewsCubit(getNewsUseCase: useCase)..loadNews(category: 'Thời sự');
      },
      child: const NewsHomeView(),
    );
  }
}

class NewsHomeView extends StatefulWidget {
  const NewsHomeView({super.key});

  @override
  State<NewsHomeView> createState() => _NewsHomeViewState();
}

class _NewsHomeViewState extends State<NewsHomeView> {
  int _currentPage = 0;
  int _selectedCategoryIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final List<String> _categories = [
    'Thời sự',
    'Thế giới',
    'Thể thao',
    'Sức khỏe',
    'Giải trí',
    'Giáo dục',
    'Đời sống',
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _autoCheckNewNotifications();
  }

  void _loadNotifications() async {
    final user = await FirebaseAuth.instance.authStateChanges().first;
    if (user != null && mounted) {
      context.read<NotificationCubit>().loadNotifications(user.uid);
    }
  }

  void _autoCheckNewNotifications() async {
    final user = await FirebaseAuth.instance.authStateChanges().first;
    if (user == null || !mounted) return;

    // Create auto notification service
    final autoService = AutoNotificationService(
      firestore: FirebaseFirestore.instance,
      notificationDataSource: NotificationDataSource(
        firestore: FirebaseFirestore.instance,
        messaging: FirebaseMessaging.instance,
        localNotifications: FlutterLocalNotificationsPlugin(),
      ),
      geminiService: GeminiRecommendationService(),
    );

    // Lấy user preferences
    final prefDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('preferences')
        .doc('userPreference')
        .get();

    // Kiểm tra số bài đã đọc
    final readingSessionsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('readingSessions')
        .get();
    
    final hasReadingHistory = readingSessionsSnapshot.docs.length >= 5;

    if (!prefDoc.exists && !hasReadingHistory) {
      print('⚠️ User chưa có preferences và chưa đọc đủ bài - skip auto notification');
      return;
    }

    UserPreference userPref;
    if (!prefDoc.exists) {
      // Có reading history nhưng chưa chạy "Phân tích ngay"
      print('ℹ️ User có ${readingSessionsSnapshot.docs.length} bài đã đọc - dùng default tạm');
      userPref = UserPreference(
        userId: user.uid,
        favoriteCategories: ['Thời sự', 'Công nghệ'], // Chỉ 2 categories phổ biến
        keywords: [],
        activeHours: {},
        dailyNotificationLimit: 5,
      );
    } else {
      // Parse existing preference
      final prefData = prefDoc.data()!;
      userPref = UserPreference(
        userId: user.uid,
        favoriteCategories: List<String>.from(prefData['favoriteCategories'] ?? ['Thời sự']),
        keywords: List<String>.from(prefData['keywords'] ?? []),
        activeHours: Map<int, int>.from(prefData['activeHours'] ?? {}),
        dailyNotificationLimit: prefData['dailyNotificationLimit'] ?? 5,
      );
    }

    // Check tin mới (chạy background)
    autoService.checkAndCreateNotifications(user.uid, userPref);
    
    // Check breaking news
    autoService.checkBreakingNews(user.uid);

    // Reload notifications after auto check
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.read<NotificationCubit>().loadNotifications(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(27, 15, 27, 0),
            child: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
                    leading: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Ionicons.menu_outline, color: Colors.black, size: 20),
                onSelected: (value) {
                  if (value == 'demo') {
                    Navigator.pushNamed(context, '/notification-demo');
                  } else if (value == 'test') {
                    Navigator.pushNamed(context, '/notification-test');
                  } else if (value == 'settings') {
                    Navigator.pushNamed(context, '/notification-settings');
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'demo',
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active, size: 20),
                        SizedBox(width: 8),
                        Text('Demo Thông báo'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'test',
                    child: Row(
                      children: [
                        Icon(Icons.bug_report, size: 20),
                        SizedBox(width: 8),
                        Text('Test AI (Debug)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 20),
                        SizedBox(width: 8),
                        Text('Cài đặt thông báo'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
                    ),
                    actions: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Ionicons.search_outline, color: Colors.black, size: 20),
                  onPressed: () {},
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(5),
              child: NotificationDropdown(),
            ),
                    ],
            ),
          ),
          Expanded(
            child: BlocBuilder<NewsCubit, NewsState>(
              builder: (context, state) {
          if (state is NewsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NewsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<NewsCubit>().refreshNews(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is NewsLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<NewsCubit>().refreshNews(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breaking News Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(27, 20, 27, 17),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tin mới nhất',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Xem tất cả',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Breaking News Carousel
                    if (state.breakingNews.isNotEmpty)
                      Column(
                        children: [
                          SizedBox(
                            height: 270,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: state.breakingNews.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final news = state.breakingNews[index];
                                return AnimatedBuilder(
                                  animation: _pageController,
                                  builder: (context, child) {
                                    double value = 1.0;
                                    if (_pageController.position.haveDimensions) {
                                      value = _pageController.page! - index;
                                      value = (1 - (value.abs() * 0.25)).clamp(0.75, 1.0);
                                    }
                                    return Center(
                                      child: SizedBox(
                                        height: Curves.easeOut.transform(value) * 270,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: BreakingNewsCard(news: news),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Page indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              state.breakingNews.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentPage == index ? 32 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentPage == index ? AppColors.primary : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 30),

                    // Category Tabs Section
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedCategoryIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryIndex = index;
                                });
                                // Filter news by category
                                context.read<NewsCubit>().filterByCategory(_categories[index]);
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _categories[index],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.black : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (isSelected)
                                    Container(
                                      height: 3,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // News List by Category
                    if (state.recommendedNews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có tin tức trong mục này',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.recommendedNews.length,
                        itemBuilder: (context, index) {
                          final news = state.recommendedNews[index];
                          return RecommendationCard(news: news);
                        },
                      ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          }

          return const SizedBox();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 2) {
            // Navigate to Library/Saved News page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SavedNewsPage(),
              ),
            );
          } else if (index == 3) {
            // Navigate to Profile page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfilePage(),
              ),
            );
          }
          // TODO: Handle other navigation items
        },
      ),
    );
  }
}
