// lib/app/data/models/payment_models.dart

import 'package:equatable/equatable.dart';

// Request Model (Dùng để gọi /api/payments/create-request)
class PaymentRequestModel extends Equatable {
  final int appointmentId;
  final String paymentMethod; // VD: VNPAY, MOMO, VIETQR

  const PaymentRequestModel({
    required this.appointmentId,
    this.paymentMethod = 'VIETQR',
  });

  Map<String, dynamic> toJson() => {
        'appointmentId': appointmentId,
        'paymentMethod': paymentMethod,
      };

  @override
  List<Object> get props => [appointmentId, paymentMethod];
}

// Response Model (Dùng để nhận kết quả từ /api/payments/create-request)
class PaymentResponseModel extends Equatable {
  final String paymentUrl;
  final int transactionId;
  final int amount;

  const PaymentResponseModel({
    required this.paymentUrl,
    required this.transactionId,
    required this.amount,
  });

  factory PaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentResponseModel(
      paymentUrl: json['paymentUrl'] as String,
      // Backend trả về Long, Flutter dùng int (dart int supports 64-bit)
      transactionId: (json['transactionId'] as num).toInt(),
      amount: (json['amount'] as num).toInt(),
    );
  }

  @override
  List<Object> get props => [paymentUrl, transactionId, amount];
}

// Model cho API kiểm tra trạng thái
class TransactionStatusResponseModel extends Equatable {
  final String status; // PENDING, SUCCESS, FAILED
  const TransactionStatusResponseModel({required this.status});

  factory TransactionStatusResponseModel.fromJson(Map<String, dynamic> json) {
    return TransactionStatusResponseModel(
      status: json['status'] as String,
    );
  }

  @override
  List<Object> get props => [status];
}
