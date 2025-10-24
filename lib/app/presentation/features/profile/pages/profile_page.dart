// lib/app/presentation/features/profile/pages/profile_page.dart

// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, prefer_const_constructors, unused_import, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_cubit.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_state.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:dio/dio.dart';
import 'package:hospital_booking_app/app/data/models/user_model.dart';
import 'package:hospital_booking_app/app/presentation/features/profile/bloc/profile_cubit.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Số điện thoại CSKH cố định
  static const String _cskhPhoneNumber = '0345745181';

  Future<void> _changePasswordApi(String current, String newPass) async {
    final dio = sl<Dio>();
    final requestData = {
      'currentPassword': current,
      'newPassword': newPass,
      'confirmationPassword': newPass,
    };

    try {
      await dio.put(
        '/api/users/me/change-password',
        data: requestData,
      );
    } on DioException catch (e) {
      String errorMessage = e.response?.data is String
          ? e.response!.data
          : e.response?.data['message'] ?? 'Lỗi đổi mật khẩu không xác định.';
      throw Exception(errorMessage);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<ProfileCubit>().state is ProfileInitial) {
        context.read<ProfileCubit>().fetchMyProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoadFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi tải hồ sơ: ${state.message}'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }

        if (state is ProfileLoadSuccess) {
          return RefreshIndicator(
            onRefresh: () => context.read<ProfileCubit>().fetchMyProfile(),
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(), // Cho phép kéo xuống để refresh
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(state.user.fullName, state.user.email),
                  const SizedBox(height: 20),
                  _buildInfoCard(state.user),
                  const SizedBox(height: 30),

                  // MỤC ĐỔI MẬT KHẨU
                  _buildActionButton(
                    icon: Icons.lock_outline,
                    title: 'Đổi Mật Khẩu',
                    color: AppColors.secondaryColor,
                    onTap: () => _showChangePasswordDialog(context),
                  ),

                  const SizedBox(height: 15),

                  // THÊM MỤC CSKH MỚI
                  _buildActionButton(
                    icon: Icons.support_agent,
                    title: 'Chăm sóc Khách hàng (CSKH)',
                    subtitle: 'Hotline: $_cskhPhoneNumber',
                    color: AppColors.primaryColor,
                    onTap: () => _showCskhInfo(context),
                  ),

                  const SizedBox(height: 15),
                  _buildLogoutButton(context),
                ],
              ),
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Không thể tải dữ liệu hồ sơ.'),
              ElevatedButton(
                onPressed: () => context.read<ProfileCubit>().fetchMyProfile(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- HÀM MỚI: HIỂN THỊ THÔNG BÁO CSKH ---
  void _showCskhInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bộ phận CSKH'),
        content: Text(
            'Vui lòng gọi đến số hotline để được hỗ trợ:\n\nHotline: $_cskhPhoneNumber'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
          // Trong thực tế sẽ dùng url_launcher để gọi
          // TextButton(
          //   onPressed: () {
          //     // Logic gọi điện thoại
          //     Navigator.of(ctx).pop();
          //   },
          //   child: const Text('Gọi ngay'),
          // ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String fullName, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryColor,
            child: Text(
              fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 24, color: AppColors.white),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor),
              ),
              Text(
                email,
                style: TextStyle(fontSize: 14, color: AppColors.hintColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(UserModel user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cá nhân',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor),
            ),
            const Divider(height: 20, thickness: 1),
            _buildInfoRow(Icons.phone, 'Số điện thoại', user.phoneNumber),
            _buildInfoRow(Icons.email, 'Email Đăng nhập', user.email),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 22),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(color: AppColors.hintColor, fontSize: 14)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String title,
      String? subtitle, // THÊM SUBTITLE
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Icon(icon, color: color, size: 26),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style:
                    TextStyle(color: AppColors.hintColor)) // HIỂN THỊ SUBTITLE
            : null,
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 18, color: AppColors.hintColor),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.read<AuthCubit>().signOut(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        child: const Text(
          'Đăng xuất',
          style: TextStyle(
              fontSize: 18,
              color: AppColors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Center(
            child: Text('Đổi Mật Khẩu',
                style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold)),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPasswordField(
                      currentPasswordController, 'Mật khẩu hiện tại'),
                  _buildPasswordField(
                      newPasswordController, 'Mật khẩu mới (ít nhất 6 ký tự)',
                      minLength: 6),
                  _buildPasswordField(
                      confirmPasswordController, 'Xác nhận mật khẩu mới',
                      isConfirm: true,
                      newPassController: newPasswordController),
                ],
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy',
                  style: TextStyle(color: AppColors.hintColor)),
            ),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (authContext, authState) {
                final bool isLoading = authState is AuthLoading;

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isLoading
                      ? null
                      : () => _submitChangePassword(
                            context: ctx,
                            formKey: formKey,
                            currentPass: currentPasswordController.text,
                            newPass: newPasswordController.text,
                          ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white))
                        : const Text('Xác nhận',
                            style: TextStyle(color: AppColors.white)),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label,
      {int minLength = 0,
      bool isConfirm = false,
      TextEditingController? newPassController}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        style: const TextStyle(color: AppColors.textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.hintColor),
          filled: true,
          fillColor: AppColors.lightGray,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.red),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Trường này là bắt buộc.';
          }
          if (minLength > 0 && value.length < minLength) {
            return 'Mật khẩu phải có ít nhất $minLength ký tự.';
          }
          if (isConfirm &&
              newPassController != null &&
              value != newPassController.text) {
            return 'Mật khẩu xác nhận không khớp.';
          }
          return null;
        },
      ),
    );
  }

  // LOGIC XỬ LÝ GỌI API ĐỔI MẬT KHẨU
  void _submitChangePassword({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required String currentPass,
    required String newPass,
  }) async {
    if (formKey.currentState!.validate()) {
      final authCubit = context.read<AuthCubit>();

      // Bắt đầu trạng thái loading cho nút
      final originalState = authCubit.state;
      authCubit.emit(AuthLoading()); // Bắt đầu Loading

      try {
        await _changePasswordApi(currentPass, newPass);

        // Thành công: Đóng dialog và hiển thị thông báo
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.'),
            backgroundColor: AppColors.green,
          ),
        );

        // Tự động đăng xuất người dùng
        await authCubit.signOut();
      } catch (e) {
        // Thất bại:
        // 1. Dừng loading bằng cách trả về trạng thái trước đó
        authCubit.emit(originalState);

        // 2. Hiển thị lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Lỗi: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }
}
