import '../api_client.dart';
import '../../../config/constants.dart';
import '../../models/receipt.dart';

class ReceiptService {
  final ApiClient _apiClient = ApiClient();

  /// Get receipt by payment ID
  Future<ApiResponse<Receipt>> getReceiptByPaymentId(int paymentId) async {
    final response = await _apiClient.get(
      '${AppConstants.receiptsUrl}/payment/$paymentId',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: Receipt.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al parsear recibo: $e',
        );
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get receipt by transaction ID
  Future<ApiResponse<Receipt>> getReceiptByTransactionId(
      String transactionId) async {
    final response = await _apiClient.get(
      '${AppConstants.receiptsUrl}/transaction/$transactionId',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: Receipt.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al parsear recibo: $e',
        );
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Generate receipt for a payment
  Future<ApiResponse<Receipt>> generateReceipt(int paymentId) async {
    final response = await _apiClient.post(
      '${AppConstants.receiptsUrl}/generate/$paymentId',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: Receipt.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al generar recibo: $e',
        );
      }
    }
    return ApiResponse(success: false, error: response.error);
  }
}
