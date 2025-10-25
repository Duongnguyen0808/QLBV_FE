// lib/app/presentation/features/booking/pages/booking_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/data/models/specialty_model.dart';
import 'package:hospital_booking_app/app/data/models/user_model.dart';
import 'package:hospital_booking_app/app/data/models/doctor_search_result_model.dart';
import 'package:hospital_booking_app/app/presentation/features/booking/bloc/booking_cubit.dart';
import 'package:hospital_booking_app/app/presentation/features/booking/pages/doctor_list_page.dart';
import 'package:hospital_booking_app/app/presentation/features/booking/pages/specialty_list_page.dart';
import 'package:hospital_booking_app/app/domain/repositories/data/data_repository.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/pages/appointment_detail_page.dart'; // THÊM IMPORT NÀY
import 'package:hospital_booking_app/app/data/models/user_review_store.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  // Helper function: Logic lọc bác sĩ theo chuyên khoa và điều hướng
  void _navigateAndFilterDoctors(
      BuildContext context, int specialtyId, String specialtyName) async {
    final dataRepo = sl<DataRepository>(); // Lấy DataRepository instance

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đang tải bác sĩ cho khoa $specialtyName...')),
      );
    }

    try {
      // Gọi API tìm kiếm bác sĩ với filter specialtyId
      final filteredDoctors =
          await dataRepo.searchDoctors(specialtyId: specialtyId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // Điều hướng tới trang danh sách bác sĩ với kết quả đã lọc
        Navigator.of(context).push(MaterialPageRoute(
          builder: (c) => DoctorListPage(doctors: filteredDoctors),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải bác sĩ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingCubit>(
      create: (context) => sl<BookingCubit>()..fetchInitialData(),
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: BlocBuilder<BookingCubit, BookingState>(
          builder: (context, state) {
            if (state is BookingLoading) {
              return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryColor));
            }
            if (state is BookingLoadFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lỗi tải dữ liệu: ${state.message}'),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<BookingCubit>().fetchInitialData(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }
            if (state is BookingLoadSuccess) {
              return _buildBookingContent(context, state.userProfile,
                  state.specialties, state.recommendedDoctors);
            }
            return const Center(child: Text('Chưa có dữ liệu.'));
          },
        ),
      ),
    );
  }

  Widget _buildBookingContent(
    BuildContext context,
    UserModel userProfile,
    List<SpecialtyModel> specialties,
    List<DoctorSearchResultModel> recommendedDoctors,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(userProfile),
          const SizedBox(height: 25),
          _buildSearchBar(context),
          const SizedBox(height: 30),
          _buildSectionTitle(
              title: 'Chuyên khoa',
              onSeeAll: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (c) => SpecialtyListPage(specialties: specialties),
                ));
              }),
          const SizedBox(height: 10),
          _buildCategories(context, specialties),
          const SizedBox(height: 30),
          _buildSectionTitle(
            title: 'Bác sĩ nổi bật',
            onSeeAll: () async {
              final cubit = context.read<BookingCubit>();
              try {
                final allDoctors = await cubit.fetchAllDoctors();
                if (context.mounted) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (c) => DoctorListPage(doctors: allDoctors),
                  ));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi tải danh sách bác sĩ: $e')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 10),
          _buildDoctorsList(recommendedDoctors),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chào bạn trở lại,',
              style: TextStyle(color: AppColors.hintColor, fontSize: 14),
            ),
            Text(
              user.fullName,
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none,
              color: AppColors.primaryColor, size: 28),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm Bác sĩ, Chuyên khoa...',
          hintStyle: TextStyle(color: AppColors.hintColor),
          prefixIcon: const Icon(Icons.search, color: AppColors.hintColor),
          suffixIcon: const Icon(Icons.mic, color: AppColors.primaryColor),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onTap: () async {
          final cubit = sl<BookingCubit>();
          try {
            final allDoctors = await cubit.fetchAllDoctors();
            if (context.mounted) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (c) => DoctorListPage(doctors: allDoctors),
              ));
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi tải danh sách bác sĩ: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(
      {required String title, required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text(
            'Xem tất cả',
            style: TextStyle(
                color: AppColors.secondaryColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildCategories(
      BuildContext context, List<SpecialtyModel> specialties) {
    final displaySpecialties = specialties.take(4).toList();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displaySpecialties.length,
        itemBuilder: (context, index) {
          final specialty = displaySpecialties[index];
          return Padding(
            padding: const EdgeInsets.only(right: 15.0),
            // SỬA: Truyền toàn bộ SpecialtyModel và context
            child: _buildCategoryCard(context, specialty),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, SpecialtyModel specialty) {
    return GestureDetector(
      // Bọc bằng GestureDetector
      onTap: () {
        // Gọi hàm lọc bác sĩ khi nhấn vào thẻ chuyên khoa
        _navigateAndFilterDoctors(context, specialty.id, specialty.name);
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.secondaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_hospital_outlined,
                color: AppColors.primaryColor, size: 35),
            const SizedBox(height: 5),
            Text(
              specialty.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsList(List<DoctorSearchResultModel> doctors) {
    if (doctors.isEmpty) {
      return const Center(child: Text('Chưa có bác sĩ nổi bật.'));
    }
    return Column(
      children: doctors.map((doc) => _buildDoctorCard(doc)).toList(),
    );
  }

  Widget _buildDoctorCard(DoctorSearchResultModel doc) {
    return Builder(builder: (context) {
      return Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.hintColor.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                doc.avatarUrl ?? 'assets/images/doctor.png',
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                  Text(
                    doc.specialtyName,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<Map<String, int>>(
                    valueListenable:
                        UserReviewStore.instance.lastRatingsByDoctorName,
                    builder: (context, ratings, _) {
                      final key = UserReviewStore.normalizeName(doc.fullName);
                      final r = ratings[key];
                      if (r != null) {
                        return Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < r ? Icons.star : Icons.star_border,
                                color: AppColors.orange,
                                size: 18,
                              ),
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: const [
                          Icon(Icons.star, color: AppColors.orange, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Chưa có đánh giá',
                            style: TextStyle(
                                color: AppColors.hintColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // SỬA: Điều hướng tới AppointmentDetailPage khi nhấn nút Đặt lịch
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (c) => AppointmentDetailPage(doctor: doc),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Đặt lịch',
                  style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      );
    });
  }
}
