import 'package:app_news_ai/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/user_profile.dart';
import '../cubit/profile_cubit.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _userNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    final authState = context.read<AuthCubit>().state;
    final profileState = context.read<ProfileCubit>().state;

    String email = '';
    String username = '';
    String fullName = '';
    DateTime? dob;

    if (authState is Authenticated) {
      email = authState.user.email;
      username = authState.user.name ?? '';
      fullName = authState.user.name ?? '';
    }

    if (profileState is ProfileLoaded) {
      if (profileState.profile.email.isNotEmpty) email = profileState.profile.email;
      if (profileState.profile.username != null) username = profileState.profile.username!;
      if (profileState.profile.fullName != null) fullName = profileState.profile.fullName!;
      dob = profileState.profile.dateOfBirth;
    }

    _emailController.text = email;
    _userNameController.text = username;
    _fullNameController.text = fullName;
    
    if (dob != null) {
      _selectedDate = dob;
      _dobController.text = DateFormat('dd/MM/yyyy').format(dob);
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (mounted) {
        final userId = context.read<AuthCubit>().state is Authenticated
            ? (context.read<AuthCubit>().state as Authenticated).user.id
            : null;
        if (userId != null) {
          context.read<ProfileCubit>().uploadAvatar(userId, pickedFile);
        }
      }
    }
  }

  void _saveProfile() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final updatedProfile = UserProfile(
      id: authState.user.id,
      email: _emailController.text,
      username: _userNameController.text.trim(),
      fullName: _fullNameController.text.trim(),
      dateOfBirth: _selectedDate,
    );

    context.read<ProfileCubit>().updateProfile(updatedProfile);
    
    // Also update display name in AuthCubit if username changed
    if (_userNameController.text.trim().isNotEmpty) {
      context.read<AuthCubit>().updateProfile(name: _userNameController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context);
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Ionicons.chevron_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Chỉnh sửa hồ sơ',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            String? photoUrl;
            if (state is ProfileLoaded) {
              photoUrl = state.profile.photoUrl;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : const AssetImage('assets/images/logo.png') as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Ionicons.camera_outline, size: 20, color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Fields
                  _buildTextField(
                    label: 'Tên tài khoản',
                    controller: _userNameController,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Họ và tên',
                    controller: _fullNameController,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Email',
                    controller: _emailController,
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: _buildTextField(
                        label: 'Ngày sinh',
                        controller: _dobController,
                        suffixIcon: const Icon(Ionicons.calendar_outline, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Change Password
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Đổi mật khẩu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          Icon(Ionicons.chevron_forward, size: 20, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Save Button
                   SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
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
                        'Lưu thay đổi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
