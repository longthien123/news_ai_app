import 'package:app_news_ai/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/profile_menu_item.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<ProfileCubit>().loadProfile(authState.user.id);
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
        title: const Text(
          'Tài khoản',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // We use AuthCubit for basic info as fallback or primary source for email
          final authUser = (authState is Authenticated) ? authState.user : null;
          
          return BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, profileState) {
              // Use profile data if loaded, otherwise auth data
              String name = authUser?.name ?? 'User';
              String email = authUser?.email ?? '';
              String? photoUrl;
              
              if (profileState is ProfileLoaded) {
                if (profileState.profile.fullName != null && profileState.profile.fullName!.isNotEmpty) {
                  name = profileState.profile.fullName!;
                } else if (profileState.profile.username != null && profileState.profile.username!.isNotEmpty) {
                  name = profileState.profile.username!;
                }
                if (profileState.profile.email.isNotEmpty) {
                  email = profileState.profile.email;
                }
                photoUrl = profileState.profile.photoUrl;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : const AssetImage('assets/images/logo.png') as ImageProvider,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // View Full Profile Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfilePage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Xem chi tiết hồ sơ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Preferences Section
                    const Text(
                      'Tùy chọn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ProfileMenuItem(
                      title: 'Ngôn ngữ',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tiếng Việt',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Ionicons.chevron_forward, size: 20, color: Colors.grey),
                        ],
                      ),
                      onTap: () {},
                    ),
                    ProfileMenuItem(
                      title: 'Thông báo',
                      onTap: () {},
                      showDivider: false,
                    ),

                    const SizedBox(height: 32),

                    // Legal & Support Section
                    const Text(
                      'Pháp lý & Hỗ trợ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ProfileMenuItem(
                      title: 'Điều khoản sử dụng',
                      onTap: () {},
                    ),
                    ProfileMenuItem(
                      title: 'Trung tâm trợ giúp',
                      onTap: () {},
                    ),
                    ProfileMenuItem(
                      title: 'Phản hồi ứng dụng',
                      onTap: () {},
                      showDivider: false,
                    ),

                    const SizedBox(height: 40),

                    // Log Out Button
                    TextButton.icon(
                      onPressed: () {
                        context.read<AuthCubit>().logout();
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Ionicons.log_out_outline, color: Colors.black),
                      label: const Text(
                        'Đăng xuất',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
