import '../api_client.dart';
import '../../../config/constants.dart';

class LibraryService {
  final ApiClient _apiClient = ApiClient();

  /// Get user's complete library organized by type
  Future<ApiResponse<UserLibrary>> getUserLibrary(int userId) async {
    final response = await _apiClient.get(
      '${AppConstants.libraryUrl}/user/$userId',
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: UserLibrary.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get all purchased items (flat list)
  Future<ApiResponse<List<PurchasedItemData>>> getAllPurchasedItems(int userId) async {
    final response = await _apiClient.get(
      '${AppConstants.libraryUrl}/user/$userId/items',
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      final items = (response.data as List)
          .map((json) => PurchasedItemData.fromJson(json))
          .toList();
      return ApiResponse(success: true, data: items);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get purchased items of a specific type
  Future<ApiResponse<List<PurchasedItemData>>> getPurchasedItemsByType(
    int userId,
    String itemType,
  ) async {
    final response = await _apiClient.get(
      '${AppConstants.libraryUrl}/user/$userId/items/$itemType',
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      final items = (response.data as List)
          .map((json) => PurchasedItemData.fromJson(json))
          .toList();
      return ApiResponse(success: true, data: items);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Check if user has purchased a specific item
  Future<ApiResponse<bool>> checkIfPurchased(
    int userId,
    String itemType,
    int itemId,
  ) async {
    final response = await _apiClient.get(
      '${AppConstants.libraryUrl}/user/$userId/check/$itemType/$itemId',
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: response.data as bool);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Clear user library (for testing)
  Future<ApiResponse<void>> clearUserLibrary(int userId) async {
    return await _apiClient.delete(
      '${AppConstants.libraryUrl}/user/$userId',
      requiresAuth: false,
    );
  }
}

/// Model for purchased item data from the API
class PurchasedItemData {
  final int id;
  final int userId;
  final String itemType;
  final int itemId;
  final int orderId;
  final int paymentId;
  final double price;
  final int quantity;
  final DateTime purchasedAt;

  PurchasedItemData({
    required this.id,
    required this.userId,
    required this.itemType,
    required this.itemId,
    required this.orderId,
    required this.paymentId,
    required this.price,
    required this.quantity,
    required this.purchasedAt,
  });

  factory PurchasedItemData.fromJson(Map<String, dynamic> json) {
    return PurchasedItemData(
      id: json['id'] as int,
      userId: json['userId'] as int,
      itemType: json['itemType'] as String,
      itemId: json['itemId'] as int,
      orderId: json['orderId'] as int,
      paymentId: json['paymentId'] as int,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      purchasedAt: DateTime.parse(json['purchasedAt'] as String),
    );
  }
}

/// Model for user library from the API
class UserLibrary {
  final int userId;
  final List<PurchasedItemData> songs;
  final List<PurchasedItemData> albums;
  final List<PurchasedItemData> merchandise;
  final int totalItems;

  UserLibrary({
    required this.userId,
    required this.songs,
    required this.albums,
    required this.merchandise,
    required this.totalItems,
  });

  factory UserLibrary.fromJson(Map<String, dynamic> json) {
    return UserLibrary(
      userId: json['userId'] as int,
      songs: (json['songs'] as List<dynamic>? ?? [])
          .map((item) => PurchasedItemData.fromJson(item as Map<String, dynamic>))
          .toList(),
      albums: (json['albums'] as List<dynamic>? ?? [])
          .map((item) => PurchasedItemData.fromJson(item as Map<String, dynamic>))
          .toList(),
      merchandise: (json['merchandise'] as List<dynamic>? ?? [])
          .map((item) => PurchasedItemData.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalItems: json['totalItems'] as int? ?? 0,
    );
  }
}
