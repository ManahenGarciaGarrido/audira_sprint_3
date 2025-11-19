import '../api_client.dart';
import '../../../config/constants.dart';
import '../../models/order.dart';

class OrderService {
  final ApiClient _apiClient = ApiClient();

  /// Get all orders for a specific user
  Future<ApiResponse<List<Order>>> getOrdersByUserId(int userId) async {
    final response = await _apiClient.get(
      '${AppConstants.ordersUrl}/user/$userId',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> ordersJson = response.data as List<dynamic>;
        final orders = ordersJson
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: orders);
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al parsear órdenes: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get a specific order by ID
  Future<ApiResponse<Order>> getOrderById(int orderId) async {
    final response = await _apiClient.get(
      '${AppConstants.ordersUrl}/$orderId',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: Order.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al parsear orden: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get order by order number
  Future<ApiResponse<Order>> getOrderByOrderNumber(String orderNumber) async {
    final response = await _apiClient.get(
      '${AppConstants.ordersUrl}/order-number/$orderNumber',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: Order.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al parsear orden: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get orders by user ID and status
  Future<ApiResponse<List<Order>>> getOrdersByUserIdAndStatus(
    int userId,
    String status,
  ) async {
    final response = await _apiClient.get(
      '${AppConstants.ordersUrl}/user/$userId/status/$status',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> ordersJson = response.data as List<dynamic>;
        final orders = ordersJson
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: orders);
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al parsear órdenes: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Create a new order
  Future<ApiResponse<Order>> createOrder({
    required int userId,
    required String shippingAddress,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _apiClient.post(
      AppConstants.ordersUrl,
      body: {
        'userId': userId,
        'shippingAddress': shippingAddress,
        'items': items,
      },
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: Order.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al crear orden: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Update order status
  Future<ApiResponse<Order>> updateOrderStatus(
    int orderId,
    String status,
  ) async {
    final response = await _apiClient.put(
      '${AppConstants.ordersUrl}/$orderId/status',
      body: {'status': status},
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: Order.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al actualizar orden: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Cancel an order
  Future<ApiResponse<Order>> cancelOrder(int orderId) async {
    final response = await _apiClient.post(
      '${AppConstants.ordersUrl}/$orderId/cancel',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: Order.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al cancelar orden: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Delete an order
  Future<ApiResponse<void>> deleteOrder(int orderId) async {
    return await _apiClient.delete(
      '${AppConstants.ordersUrl}/$orderId',
      requiresAuth: false,
    );
  }

  /// Get all orders (admin)
  Future<ApiResponse<List<Order>>> getAllOrders() async {
    final response = await _apiClient.get(
      AppConstants.ordersUrl,
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> ordersJson = response.data as List<dynamic>;
        final orders = ordersJson
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: orders);
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al parsear órdenes: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }
}
