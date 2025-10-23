// lib/app/presentation/features/medical_record/pages/medical_history_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/data/models/medical_record_model.dart';
import 'package:hospital_booking_app/app/presentation/features/medical_record/bloc/medical_record_cubit.dart';
import 'package:intl/intl.dart';

class MedicalHistoryPage extends StatelessWidget {
  const MedicalHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Gọi API load lại khi mở trang (đã được gọi trong constructor cubit, giữ lại RefreshIndicator)

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
        if (state is MedicalRecordLoading || state is MedicalRecordInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }

        final records = state is MedicalRecordLoadSuccess
            ? state.records
            : <MedicalRecordModel>[];

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Bạn chưa có lịch sử khám bệnh nào.',
                    style: TextStyle(fontSize: 16, color: AppColors.hintColor)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () =>
                      context.read<MedicalRecordCubit>().fetchMedicalRecords(),
                  child: const Text('Tải lại'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              context.read<MedicalRecordCubit>().fetchMedicalRecords(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: records.length,
            itemBuilder: (context, index) {
              return _buildRecordCard(records[index]);
            },
          ),
        );
      },
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
