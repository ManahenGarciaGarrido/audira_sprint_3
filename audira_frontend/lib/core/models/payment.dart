import 'package:equatable/equatable.dart';

enum PaymentMethod {
  creditCard('CREDIT_CARD'),
  debitCard('DEBIT_CARD'),
  stripe('STRIPE'),
  paypal('PAYPAL'),
  bankTransfer('BANK_TRANSFER');

  final String value;
  const PaymentMethod(this.value);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentMethod.creditCard,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.creditCard:
        return 'Tarjeta de Crédito';
      case PaymentMethod.debitCard:
        return 'Tarjeta de Débito';
      case PaymentMethod.stripe:
        return 'Stripe';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.bankTransfer:
        return 'Transferencia Bancaria';
    }
  }
}

enum PaymentStatus {
  pending('PENDING'),
  processing('PROCESSING'),
  completed('COMPLETED'),
  failed('FAILED'),
  refunded('REFUNDED'),
  cancelled('CANCELLED');

  final String value;
  const PaymentStatus(this.value);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pendiente';
      case PaymentStatus.processing:
        return 'Procesando';
      case PaymentStatus.completed:
        return 'Completado';
      case PaymentStatus.failed:
        return 'Fallido';
      case PaymentStatus.refunded:
        return 'Reembolsado';
      case PaymentStatus.cancelled:
        return 'Cancelado';
    }
  }
}

class Payment extends Equatable {
  final int id;
  final String transactionId;
  final int orderId;
  final int userId;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final double amount;
  final String? errorMessage;
  final int retryCount;
  final String? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  const Payment({
    required this.id,
    required this.transactionId,
    required this.orderId,
    required this.userId,
    required this.paymentMethod,
    required this.status,
    required this.amount,
    this.errorMessage,
    this.retryCount = 0,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int,
      transactionId: json['transactionId'] as String,
      orderId: json['orderId'] as int,
      userId: json['userId'] as int,
      paymentMethod: PaymentMethod.fromString(json['paymentMethod'] as String),
      status: PaymentStatus.fromString(json['status'] as String),
      amount: (json['amount'] as num).toDouble(),
      errorMessage: json['errorMessage'] as String?,
      retryCount: json['retryCount'] as int? ?? 0,
      metadata: json['metadata'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'orderId': orderId,
      'userId': userId,
      'paymentMethod': paymentMethod.value,
      'status': status.value,
      'amount': amount,
      'errorMessage': errorMessage,
      'retryCount': retryCount,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        transactionId,
        orderId,
        userId,
        paymentMethod,
        status,
        amount,
        errorMessage,
        retryCount,
        metadata,
        createdAt,
        updatedAt,
        completedAt,
      ];
}

class PaymentResponse extends Equatable {
  final bool success;
  final String? transactionId;
  final PaymentStatus? status;
  final String message;
  final Payment? payment;

  const PaymentResponse({
    required this.success,
    this.transactionId,
    this.status,
    required this.message,
    this.payment,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] as bool,
      transactionId: json['transactionId'] as String?,
      status: json['status'] != null
          ? PaymentStatus.fromString(json['status'] as String)
          : null,
      message: json['message'] as String,
      payment: json['payment'] != null
          ? Payment.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [success, transactionId, status, message, payment];
}
