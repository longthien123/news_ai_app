import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import auth files
import 'features/auth/data/datasources/local/user_local_source.dart';
import 'features/auth/data/datasources/remote/user_remote_source.dart';
import 'features/auth/data/repositories/user_repo_impl.dart';
//import 'features/auth/domain/repositories/user_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/update_profile_usecase.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    // Setup dependencies
    final userRemoteSource = UserRemoteSourceImpl();
    final userLocalSource = UserLocalSourceImpl(prefs: prefs);
    final userRepository = UserRepoImpl(
      remote: userRemoteSource,
      local: userLocalSource,
    );
    
    final loginUsecase = LoginUsecase(userRepository);
    final registerUsecase = RegisterUsecase(userRepository);
    final updateProfileUsecase = UpdateProfileUsecase(userRepository);

    return BlocProvider(
      create: (context) => AuthCubit(
        loginUsecase: loginUsecase,
        registerUsecase: registerUsecase,
        updateProfileUsecase: updateProfileUsecase,
        repository: userRepository,
      )..checkAuth(), // Check if user is already logged in
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
          '/home': (context) => const MyHomePage(title: 'Home Page'),
        },
      ),
    );
  }
}

// Wrapper to check authentication status
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is Authenticated) {
          return const MyHomePage(title: 'Home Page');
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

// Home Page (sau khi đăng nhập thành công)
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chào mừng!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Email: ${state.user.email}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (state.user.name != null)
                    Text(
                      'Tên: ${state.user.name}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthCubit>().logout();
                    },
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Không có thông tin user'));
        },
      ),
    );
  }
}