// lib/app/presentation/features/medical_record/pages/medical_history_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/data/models/medical_record_model.dart';
import 'package:hospital_booking_app/app/presentation/features/medical_record/bloc/medical_record_cubit.dart';
import 'package:intl/intl.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_cubit.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_state.dart';

class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({super.key});

  @override
  State<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _currentRole = 'PATIENT'; // Khởi tạo vai trò

  @override
  void initState() {
    super.initState();
    // Lấy vai trò hiện tại
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _currentRole = authState.role;
    }

    // Nếu là Bác sĩ, không tự động gọi API (vì API /me/records là của Patient)
    if (_currentRole == 'PATIENT') {
      context.read<MedicalRecordCubit>().fetchMedicalRecords();
    }

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // LOGIC TÌM KIẾM: debounce nhẹ nhàng để gọi API/Logic filter trong repo
  void _onSearchChanged() {
    if (_currentRole == 'PATIENT') {
      context.read<MedicalRecordCubit>().fetchMedicalRecords(
            query: _searchController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRole == 'DOCTOR' || _currentRole == 'ADMIN') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history_edu,
                  color: AppColors.primaryColor, size: 50),
              const SizedBox(height: 10),
              const Text('Chức năng "Bệnh Án Đã Khám"',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                'Mobile App hiện không hỗ trợ tính năng xem và tìm kiếm bệnh án mà Bác sĩ đã tạo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textColor),
              ),
              const SizedBox(height: 5),
              Text(
                'Vui lòng sử dụng trang "Bệnh nhân của tôi" trên giao diện Web Admin để tra cứu lịch sử khám.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.red, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              // Thông báo lỗi cũ (chỉ để giải thích)
              Text('Lỗi API: Forbidden',
                  style: TextStyle(
                      color: AppColors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    // === Dành cho Bệnh nhân ===
    return BlocConsumer<MedicalRecordCubit, MedicalRecordState>(
      listener: (context, state) {
        if (state is MedicalRecordLoadFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi tải lịch sử khám: ${state.message}'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final records = state is MedicalRecordLoadSuccess
            ? state.records
            : <MedicalRecordModel>[];

        return Column(
          children: [
            // Ô TÌM KIẾM
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo Bác sĩ, Chẩn đoán...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.hintColor),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primaryColor, width: 1.5),
                  ),
                ),
              ),
            ),

            // DANH SÁCH BỆNH ÁN
            Expanded(
              child: _buildBodyContent(context, state, records),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBodyContent(BuildContext context, MedicalRecordState state,
      List<MedicalRecordModel> records) {
    if (state is MedicalRecordLoading || state is MedicalRecordInitial) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor));
    }

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                _searchController.text.isNotEmpty
                    ? 'Không tìm thấy kết quả nào trùng khớp.'
                    : 'Bạn chưa có lịch sử khám bệnh nào.',
                style:
                    const TextStyle(fontSize: 16, color: AppColors.hintColor)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                context.read<MedicalRecordCubit>().fetchMedicalRecords();
              },
              child: const Text('Tải lại/Bỏ tìm kiếm'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        _searchController.clear();
        return context.read<MedicalRecordCubit>().fetchMedicalRecords();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: records.length,
        itemBuilder: (context, index) {
          return _buildRecordCard(records[index]);
        },
      ),
    );
  }

  Widget _buildRecordCard(MedicalRecordModel record) {
    final dateTime = DateTime.parse(record.appointmentDate).toLocal();
    final formattedDate = DateFormat('HH:mm - dd/MM/yyyy').format(dateTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        // Dùng ExpansionTile để mở ra xem chi tiết
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          'Bệnh án #${record.id}',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
              fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Bác sĩ: ${record.doctorName} (${record.specialtyName})',
              style: TextStyle(fontSize: 14, color: AppColors.textColor),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppColors.hintColor),
                const SizedBox(width: 5),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 14, color: AppColors.hintColor),
                ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CHẨN ĐOÁN: Quan trọng
                _buildDetailRow('Chẩn đoán', record.diagnosis,
                    isHighlight: true, isImportant: true),
                // TRIỆU CHỨNG: Bình thường
                _buildDetailRow('Triệu chứng', record.symptoms),
                // DẤU HIỆU SINH TỒN: Bình thường
                _buildDetailRow('Dấu hiệu sinh tồn', record.vitalSigns),
                // KẾT QUẢ XÉT NGHIỆM: Bình thường
                _buildDetailRow('Kết quả xét nghiệm', record.testResults),
                // ĐƠN THUỐC: Nổi bật và MultiLine
                _buildDetailRow('Đơn thuốc', record.prescription,
                    isMultiLine: true, isHighlight: true),
                // GHI CHÚ: Nổi bật
                _buildDetailRow('Ghi chú', record.notes, isHighlight: true),
                if (record.reexaminationDate != null &&
                    record.reexaminationDate!.isNotEmpty)
                  _buildDetailRow('Tái khám', record.reexaminationDate!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String content,
      {bool isMultiLine = false,
      bool isImportant = false,
      bool isHighlight = false}) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.bold,
              color: isImportant
                  ? AppColors.red
                  : (isHighlight
                      ? AppColors.primaryColor
                      : AppColors.textColor),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlight
                  ? AppColors.primaryColor.withOpacity(0.08)
                  : AppColors.lightGray, // Nền nhẹ
              borderRadius: BorderRadius.circular(8),
              border: isHighlight
                  ? Border.all(color: AppColors.primaryColor.withOpacity(0.3))
                  : null, // Viền nhẹ
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: isHighlight ? FontWeight.w500 : FontWeight.normal,
                color: isHighlight
                    ? AppColors.textColor.withOpacity(0.9)
                    : AppColors.textColor,
              ),
            ),
          ),
          if (!isMultiLine) const SizedBox(height: 8),
        ],
      ),
    );
  }
}
