import 'package:app_news_ai/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/utils/timeago_setup.dart';

// Import auth files
import 'features/auth/data/datasources/local/user_local_source.dart';
import 'features/auth/data/datasources/remote/user_remote_source.dart';
import 'features/auth/data/repositories/user_repo_impl.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/update_profile_usecase.dart';
import 'features/auth/domain/usecases/google_signin_usecase.dart';
import 'features/auth/domain/usecases/forgot_password_usecase.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/email_verification_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/news/presentation/pages/news_home_page.dart';
import 'features/splash/splash_screen.dart';

// Import news files
import 'features/admin/data/datasources/local/news_local_source.dart';
import 'features/admin/data/datasources/remote/news_remote_source.dart';
import 'features/admin/data/repositories/news_repo_impl.dart';
import 'features/admin/domain/usecases/news/add_news_usecase.dart';
import 'features/admin/domain/usecases/news/get_news_detail_usecase.dart';
import 'features/admin/domain/usecases/news/get_news_usecase.dart';
import 'features/admin/presentation/cubit/news_cubit.dart';
import 'features/admin/presentation/pages/add_news_page.dart';
import 'features/admin/presentation/pages/admin_dashboard_page.dart';
import 'features/admin/data/datasources/remote/rss_news_service.dart';

import 'features/profile/data/datasources/profile_remote_datasource.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/usecases/get_profile_usecase.dart';
import 'features/profile/domain/usecases/update_profile_usecase.dart';
import 'features/profile/domain/usecases/upload_avatar_usecase.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';

// Import notification files
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'features/notification/data/datasources/notification_datasource.dart';
import 'features/notification/data/datasources/user_behavior_datasource.dart';
import 'features/notification/data/repositories/notification_repository_impl.dart';
import 'features/notification/data/repositories/user_behavior_repository_impl.dart';
import 'features/notification/data/services/gemini_recommendation_service.dart';
import 'features/notification/domain/usecases/get_notifications_usecase.dart';
import 'features/notification/domain/usecases/get_smart_notif_usecase.dart';
import 'features/notification/domain/usecases/analyze_user_behavior_usecase.dart';
import 'features/notification/domain/usecases/create_smart_notification_usecase.dart';
import 'features/notification/presentation/cubit/notification_cubit.dart';
import 'features/notification/presentation/pages/notifications_page.dart';
import 'features/notification/presentation/pages/notification_settings_page.dart';
import 'features/notification/presentation/pages/notification_demo_page.dart';
import 'features/notification/presentation/pages/notification_test_page.dart';

// Handle FCM background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📨 Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set FCM background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();

  // Setup timeago Vietnamese locale
  setupTimeagoLocale();

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    // Setup Auth dependencies
    final userRemoteSource = UserRemoteSourceImpl();
    final userLocalSource = UserLocalSourceImpl(prefs: prefs);
    final userRepository = UserRepoImpl(
      remote: userRemoteSource,
      local: userLocalSource,
    );

    final loginUsecase = LoginUsecase(userRepository);
    final registerUsecase = RegisterUsecase(userRepository);
    final updateProfileUsecase = UpdateProfileUsecase(userRepository);
    final googleSignInUsecase = GoogleSignInUsecase(userRepository);
    final forgotPasswordUsecase = ForgotPasswordUsecase(userRepository);

    // Setup News dependencies
    final newsRemoteSource = NewsRemoteSourceImpl();
    final newsLocalSource = NewsLocalSourceImpl(prefs: prefs);
    final newsRepository = NewsRepoImpl(
      remote: newsRemoteSource,
      local: newsLocalSource,
    );

    final addNewsUsecase = AddNewsUsecase(newsRepository);
    final getNewsDetailUsecase = GetNewsDetailUsecase(newsRepository);
    final getNewsUsecase = GetNewsUsecase(newsRepository);
    // ✅ THÊM: Setup RSS service
    final rssNewsService = RssNewsService();

    // Setup Profile dependencies
    final profileRemoteSource = ProfileRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
    );
    final profileRepository = ProfileRepositoryImpl(
      remoteDataSource: profileRemoteSource,
    );
    final getProfileUsecase = GetProfileUseCase(profileRepository);
    final updateUserProfileUsecase = UpdateProfileUseCase(profileRepository);
    final uploadAvatarUsecase = UploadAvatarUseCase(profileRepository);

    // Setup Notification dependencies
    final notificationDataSource = NotificationDataSource(
      firestore: FirebaseFirestore.instance,
      messaging: FirebaseMessaging.instance,
      localNotifications: FlutterLocalNotificationsPlugin(),
    );
    final behaviorDataSource = UserBehaviorDataSource(
      firestore: FirebaseFirestore.instance,
    );
    final geminiService = GeminiRecommendationService();

    final notificationRepository = NotificationRepositoryImpl(
      dataSource: notificationDataSource,
    );
    final behaviorRepository = UserBehaviorRepositoryImpl(
      dataSource: behaviorDataSource,
      aiService: geminiService,
    );

    final getNotificationsUseCase = GetNotificationsUseCase(
      notificationRepository,
    );
    final getSmartNotificationsUseCase = GetSmartNotificationsUseCase(
      notificationRepository: notificationRepository,
      behaviorRepository: behaviorRepository,
    );
    final analyzeUserBehaviorUseCase = AnalyzeUserBehaviorUseCase(
      behaviorRepository,
    );
    final createSmartNotificationUseCase = CreateSmartNotificationUseCase(
      notificationRepository: notificationRepository,
      behaviorRepository: behaviorRepository,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(
            loginUsecase: loginUsecase,
            registerUsecase: registerUsecase,
            updateProfileUsecase: updateProfileUsecase,
            googleSignInUsecase: googleSignInUsecase,
            forgotPasswordUsecase: forgotPasswordUsecase,
            repository: userRepository,
          )..checkAuth(),
        ),
        BlocProvider(
          create: (context) => NewsCubit(
            addNewsUsecase: addNewsUsecase,
            getNewsDetailUsecase: getNewsDetailUsecase,
            getNewsUsecase: getNewsUsecase,
            rssNewsService: rssNewsService, // ✅ THÊM parameter
          ),
        ),
        BlocProvider(
          create: (context) => ProfileCubit(
            getProfileUseCase: getProfileUsecase,
            updateProfileUseCase: updateUserProfileUsecase,
            uploadAvatarUseCase: uploadAvatarUsecase,
          ),
        ),
        BlocProvider(
          create: (context) => NotificationCubit(
            getNotificationsUseCase: getNotificationsUseCase,
            getSmartNotificationsUseCase: getSmartNotificationsUseCase,
            analyzeUserBehaviorUseCase: analyzeUserBehaviorUseCase,
            createSmartNotificationUseCase: createSmartNotificationUseCase,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'News App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/forgot-password': (context) => const ForgotPasswordPage(),
          '/home': (context) => const NewsHomePage(),
          '/admin': (context) => const AdminDashboardPage(),
          '/admin/add-news': (context) => const AddNewsPage(),
          '/notifications': (context) => const NotificationsPage(),
          '/notification-settings': (context) =>
              const NotificationSettingsPage(),
          '/notification-demo': (context) => const NotificationDemoPage(),
          '/notification-test': (context) => const NotificationTestPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/email-verification') {
            final email = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => EmailVerificationPage(email: email),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  // ✅ Danh sách email admin
  static const List<String> adminEmails = ['longthienl80@gmail.com'];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is Authenticated) {
          // ✅ Kiểm tra email để route đúng
          final email = state.user.email ?? '';

          if (adminEmails.contains(email)) {
            // Admin → vào trang admin
            return const AdminDashboardPage();
          } else {
            // User → vào trang home
            return const NewsHomePage();
          }
        } else {
          // Chưa đăng nhập → login
          return const LoginPage();
        }
      },
    );
  }
}
