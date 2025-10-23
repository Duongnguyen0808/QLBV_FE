// lib/app/presentation/features/medical_record/pages/medical_history_page.dart

// ignore_for_file: prefer_const_constructors

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
          'Bệnh án ',
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
                _buildDetailRow('Chẩn đoán', record.diagnosis,
                    isImportant: true),
                _buildDetailRow('Triệu chứng', record.symptoms),
                _buildDetailRow('Dấu hiệu sinh tồn', record.vitalSigns),
                _buildDetailRow('Kết quả xét nghiệm', record.testResults),
                _buildDetailRow('Đơn thuốc', record.prescription,
                    isMultiLine: true),
                _buildDetailRow('Ghi chú', record.notes),
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
      {bool isMultiLine = false, bool isImportant = false}) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isImportant ? AppColors.red : AppColors.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: const TextStyle(fontSize: 14.5),
            ),
          ),
          if (!isMultiLine) const SizedBox(height: 8),
        ],
      ),
    );
  }
}
