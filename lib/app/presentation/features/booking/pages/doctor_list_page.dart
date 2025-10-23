// lib/app/presentation/features/booking/pages/doctor_list_page.dart

import 'package:flutter/material.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/data/models/doctor_search_result_model.dart';
import 'package:hospital_booking_app/app/domain/repositories/data/data_repository.dart';
import 'package:hospital_booking_app/app/presentation/features/booking/pages/appointment_detail_page.dart';

// CHUYỂN TỪ StatelessWidget SANG StatefulWidget
class DoctorListPage extends StatefulWidget {
  final List<DoctorSearchResultModel> doctors;
  const DoctorListPage({super.key, required this.doctors});

  @override
  State<DoctorListPage> createState() => _DoctorListPageState();
}

class _DoctorListPageState extends State<DoctorListPage> {
  // DANH SÁCH HIỂN THỊ (thay đổi khi tìm kiếm)
  List<DoctorSearchResultModel> _filteredDoctors = [];
  final TextEditingController _searchController = TextEditingController();
  final DataRepository _dataRepo = sl<DataRepository>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo danh sách hiển thị bằng danh sách ban đầu
    _filteredDoctors = widget.doctors;
    // Bắt đầu nghe sự kiện thay đổi của ô tìm kiếm để kích hoạt tìm kiếm
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // LOGIC XỬ LÝ KHI Ô TÌM KIẾM THAY ĐỔI
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      // Nếu rỗng, hiển thị lại toàn bộ danh sách ban đầu
      setState(() {
        _filteredDoctors = widget.doctors;
        _isLoading = false;
      });
    } else {
      // Nếu có query, gọi API tìm kiếm
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API tìm kiếm theo tên
      final results = await _dataRepo.searchDoctors(name: query);

      if (mounted) {
        setState(() {
          _filteredDoctors = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _filteredDoctors = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Lỗi tìm kiếm: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Tất Cả Bác Sĩ',
            style: TextStyle(color: AppColors.primaryColor)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildSearchBar(),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor))
          : _filteredDoctors.isEmpty
              ? const Center(
                  child: Text('Không tìm thấy bác sĩ nào trùng khớp.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _filteredDoctors.length,
                  itemBuilder: (context, index) {
                    return _buildDoctorCard(context, _filteredDoctors[index]);
                  },
                ),
    );
  }

  Widget _buildSearchBar() {
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
        controller: _searchController, // <-- SỬ DỤNG CONTROLLER
        decoration: InputDecoration(
          hintText: 'Tìm kiếm Bác sĩ theo tên...',
          hintStyle: TextStyle(color: AppColors.hintColor),
          prefixIcon: const Icon(Icons.search, color: AppColors.hintColor),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        // Đã loại bỏ onChanged và thay bằng listener trên controller
        onSubmitted: (query) =>
            _performSearch(query), // Tìm kiếm khi nhấn Enter
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, DoctorSearchResultModel doc) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.orange, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${doc.rating}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // FIX: Điều hướng đến trang chi tiết chọn lịch
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AppointmentDetailPage(doctor: doc),
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Đặt lịch với bác sĩ này',
                        style: TextStyle(color: AppColors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
