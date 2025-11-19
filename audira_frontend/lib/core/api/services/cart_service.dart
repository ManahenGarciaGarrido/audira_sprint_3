import '../api_client.dart';
import '../../../config/constants.dart';
import '../../models/cart_item.dart';

class CartService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<Cart>> getCart(int userId) async {
    final response = await _apiClient.get('${AppConstants.cartUrl}/$userId', requiresAuth: false);
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Cart.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<Cart>> addToCart({
    required int userId,
    required String itemType,
    required int itemId,
    required double price,
    int quantity = 1,
  }) async {
    final response = await _apiClient.post(
      '${AppConstants.cartUrl}/$userId/items',
      queryParameters: {
        'itemType': itemType,
        'itemId': itemId.toString(),
        'quantity': quantity.toString(),
        'price': price.toString(),
      },
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Cart.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<Cart>> updateCartItem({
    required int userId,
    required int itemId,
    required int quantity,
  }) async {
    final response = await _apiClient.put(
      '${AppConstants.cartUrl}/$userId/items/$itemId',
      queryParameters: {'quantity': quantity.toString()},
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Cart.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<Cart>> removeFromCart(int userId, int itemId) async {
    final response = await _apiClient.delete(
      '${AppConstants.cartUrl}/$userId/items/$itemId',
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Cart.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<void>> clearCart(int userId) async {
    return await _apiClient.delete(
      '${AppConstants.cartUrl}/$userId',
      requiresAuth: false,
    );
  }

  Future<ApiResponse<int>> getCartCount(int userId) async {
    final response = await _apiClient.get(
      '${AppConstants.cartUrl}/$userId/count',
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: response.data as int);
    }
    return ApiResponse(success: false, error: response.error);
  }
}
