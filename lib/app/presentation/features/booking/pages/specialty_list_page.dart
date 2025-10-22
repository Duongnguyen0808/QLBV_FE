import 'package:flutter/material.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart'; // THÊM IMPORT
import 'package:hospital_booking_app/app/data/models/specialty_model.dart';
import 'package:hospital_booking_app/app/domain/repositories/data/data_repository.dart'; // THÊM IMPORT
import 'package:hospital_booking_app/app/presentation/features/booking/pages/doctor_list_page.dart'; // THÊM IMPORT

class SpecialtyListPage extends StatelessWidget {
  final List<SpecialtyModel> specialties;

  const SpecialtyListPage({super.key, required this.specialties});

  // HÀM MỚI: Xử lý việc lọc bác sĩ và điều hướng
  void _navigateAndFilterDoctors(
      BuildContext context, int specialtyId, String specialtyName) async {
    final dataRepo = sl<DataRepository>(); // Lấy DataRepository instance

    // Hiển thị loading/thông báo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đang tải bác sĩ cho khoa $specialtyName...')),
    );

    try {
      // 1. Gọi API tìm kiếm bác sĩ với filter specialtyId
      final filteredDoctors =
          await dataRepo.searchDoctors(specialtyId: specialtyId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (filteredDoctors.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Không tìm thấy bác sĩ nào thuộc chuyên khoa này.')),
          );
          return;
        }
        // 2. Điều hướng tới trang danh sách bác sĩ với kết quả đã lọc
        Navigator.of(context).push(MaterialPageRoute(
          builder: (c) => DoctorListPage(doctors: filteredDoctors),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải bác sĩ: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Tất Cả Chuyên Khoa',
            style: TextStyle(color: AppColors.primaryColor)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: specialties.isEmpty
          ? const Center(child: Text('Không tìm thấy chuyên khoa nào.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: specialties.length,
              itemBuilder: (context, index) {
                return _buildSpecialtyCard(context, specialties[index]);
              },
            ),
    );
  }

  Widget _buildSpecialtyCard(BuildContext context, SpecialtyModel specialty) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: const Icon(Icons.local_hospital,
            color: AppColors.primaryColor, size: 40),
        title: Text(
          specialty.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        subtitle: const Text(
          'Chọn để xem danh sách bác sĩ',
          style: TextStyle(color: AppColors.hintColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _navigateAndFilterDoctors(context, specialty.id, specialty.name);
        },
      ),
    );
  }
}
