import 'package:flutter/material.dart';
import '../../../../main.dart'; // Sửa path từ ../../../main.dart
import '../../../auth/presentation/cubit/auth_cubit.dart'; // Sửa path từ ../../auth/presentation/cubit/auth_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'news_home_page.dart';

/// Wrapper cho NewsHomePage để auto-trigger notifications
class SmartNewsHomePage extends StatefulWidget {
  const SmartNewsHomePage({super.key});

  @override
  State<SmartNewsHomePage> createState() => _SmartNewsHomePageState();
}

class _SmartNewsHomePageState extends State<SmartNewsHomePage> {
  bool _hasTriggeredOnce = false;

  @override
  void initState() {
    super.initState();
    _triggerUserActivity();
  }

  void _triggerUserActivity() {
    // Trigger sau khi widget build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasTriggeredOnce) {
        final authState = context.read<AuthCubit>().state;
        if (authState is Authenticated) {
          triggerUserOpenedApp(authState.user.id);
          _hasTriggeredOnce = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const NewsHomePage();
  }
}