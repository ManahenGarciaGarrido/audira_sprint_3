import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../../../config/constants.dart';
import '../../models/payment.dart';

class PaymentService {
  final ApiClient _apiClient = ApiClient();

  /// Process a payment
  Future<ApiResponse<PaymentResponse>> processPayment({
    required int orderId,
    required int userId,
    required PaymentMethod paymentMethod,
    required double amount,
    Map<String, String>? paymentDetails,
  }) async {
    debugPrint('PaymentService.processPayment - orderId: $orderId, userId: $userId, method: ${paymentMethod.value}');

    final response = await _apiClient.post(
      '${AppConstants.paymentsUrl}/process',
      body: {
        'orderId': orderId,
        'userId': userId,
        'paymentMethod': paymentMethod.value,
        'amount': amount,
        if (paymentDetails != null) 'paymentDetails': paymentDetails,
      },
      requiresAuth: false,
    );

    debugPrint('PaymentService - API response - success: ${response.success}, statusCode: ${response.statusCode}');
    debugPrint('PaymentService - API response data: ${response.data}');

    if (response.success && response.data != null) {
      try {
        debugPrint('Parsing PaymentResponse from JSON...');
        final paymentResponse = PaymentResponse.fromJson(response.data as Map<String, dynamic>);
        debugPrint('PaymentResponse parsed - success: ${paymentResponse.success}, payment: ${paymentResponse.payment?.id}');

        return ApiResponse(
          success: true,
          data: paymentResponse,
        );
      } catch (e, stackTrace) {
        debugPrint('Error parsing PaymentResponse: $e');
        debugPrint('Stack trace: $stackTrace');
        return ApiResponse(
          success: false,
          error: 'Error al procesar respuesta de pago: $e',
        );
      }
    }
    debugPrint('PaymentService - returning error: ${response.error}');
    return ApiResponse(success: false, error: response.error);
  }

  /// Retry a failed payment
  Future<ApiResponse<PaymentResponse>> retryPayment(int paymentId) async {
    final response = await _apiClient.post(
      '${AppConstants.paymentsUrl}/$paymentId/retry',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: PaymentResponse.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al reintentar pago: $e',
        );
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get payments by user ID
  Future<ApiResponse<List<Payment>>> getPaymentsByUserId(int userId) async {
    final response = await _apiClient.get(
      '${AppConstants.paymentsUrl}/user/$userId',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> paymentsJson = response.data as List<dynamic>;
        final payments = paymentsJson
            .map((json) => Payment.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: payments);
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al parsear pagos: $e',
        );
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get payments by order ID
  Future<ApiResponse<List<Payment>>> getPaymentsByOrderId(int orderId) async {
    final response = await _apiClient.get(
      '${AppConstants.paymentsUrl}/order/$orderId',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> paymentsJson = response.data as List<dynamic>;
        final payments = paymentsJson
            .map((json) => Payment.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: payments);
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al parsear pagos: $e',
        );
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get payment by transaction ID
  Future<ApiResponse<Payment>> getPaymentByTransactionId(
      String transactionId) async {
    final response = await _apiClient.get(
      '${AppConstants.paymentsUrl}/transaction/$transactionId',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: Payment.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al parsear pago: $e',
        );
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get payment by ID
  Future<ApiResponse<Payment>> getPaymentById(int paymentId) async {
    final response = await _apiClient.get(
      '${AppConstants.paymentsUrl}/$paymentId',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: Payment.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al parsear pago: $e',
        );
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Refund a payment
  Future<ApiResponse<PaymentResponse>> refundPayment(int paymentId) async {
    final response = await _apiClient.post(
      '${AppConstants.paymentsUrl}/$paymentId/refund',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: PaymentResponse.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al procesar reembolso: $e',
        );
      }
    }
    return ApiResponse(success: false, error: response.error);
  }
}
