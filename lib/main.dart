import 'package:app_news_ai/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// Import news files
import 'features/admin/data/datasources/local/news_local_source.dart';
import 'features/admin/data/datasources/remote/news_remote_source.dart';
import 'features/admin/data/repositories/news_repo_impl.dart';
import 'features/admin/domain/usecases/news/add_news_usecase.dart';
import 'features/admin/domain/usecases/news/get_news_detail_usecase.dart';
import 'features/admin/domain/usecases/news/get_news_usecase.dart';
import 'features/admin/presentation/cubit/news_cubit.dart';
import 'features/admin/presentation/pages/add_news_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();

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
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/forgot-password': (context) => const ForgotPasswordPage(),
          '/home': (context) => const NewsHomePage(),
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is Authenticated) {
          return const NewsHomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
