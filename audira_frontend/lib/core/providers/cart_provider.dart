import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../api/services/cart_service.dart';
import '../api/services/music_service.dart';
import '../../config/constants.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  final MusicService _musicService = MusicService();

  Cart? _cart;
  bool _isLoading = false;
  bool _isLoadingInProgress = false;
  List<CartItemDetail> _cartItemDetails = [];

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  int get itemCount => _cart?.itemCount ?? 0;
  double get totalAmount => _cart?.totalAmount ?? 0.0;
  List<CartItemDetail> get cartItemDetails => _cartItemDetails;

  // Tax calculations (IVA 21%)
  static const double taxRate = 0.21;

  double get subtotal {
    if (_cart == null || _cart!.items.isEmpty) return 0.0;
    return _cart!.items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get taxAmount {
    return subtotal * taxRate;
  }

  double get totalWithTax {
    return subtotal + taxAmount;
  }

  Future<void> loadCart(int userId) async {
    // Prevent concurrent loads
    if (_isLoadingInProgress) {
      debugPrint('Cart load already in progress, skipping duplicate call');
      return;
    }

    _isLoadingInProgress = true;
    _isLoading = true;
    notifyListeners();

    try {
      // Try to load from local storage first
      await _loadCartFromLocal(userId);

      // Then sync with server
      final response = await _cartService.getCart(userId);
      if (response.success && response.data != null) {
        _cart = response.data;
        await _loadCartItemDetails();
        await _saveCartToLocal(userId);
      }
    } finally {
      _isLoading = false;
      _isLoadingInProgress = false;
      notifyListeners();
    }
  }

  Future<void> _loadCartItemDetails() async {
    if (_cart == null || _cart!.items.isEmpty) {
      _cartItemDetails = [];
      return;
    }

    _cartItemDetails = [];
    for (var item in _cart!.items) {
      Song? song;
      Album? album;

      if (item.itemType == 'SONG') {
        final songResponse = await _musicService.getSongById(item.itemId);
        if (songResponse.success && songResponse.data != null) {
          song = songResponse.data;
        }
      } else if (item.itemType == 'ALBUM') {
        final albumResponse = await _musicService.getAlbumById(item.itemId);
        if (albumResponse.success && albumResponse.data != null) {
          album = albumResponse.data;
        }
      }

      _cartItemDetails.add(CartItemDetail(
        cartItem: item,
        song: song,
        album: album,
      ));
    }
  }

  // Save cart to local storage
  Future<void> _saveCartToLocal(int userId) async {
    if (_cart == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(_cart!.toJson());
      await prefs.setString('${AppConstants.guestCartKey}_$userId', cartJson);
    } catch (e) {
      debugPrint('Error saving cart to local storage: $e');
    }
  }

  // Load cart from local storage
  Future<void> _loadCartFromLocal(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('${AppConstants.guestCartKey}_$userId');

      if (cartJson != null) {
        final cartData = jsonDecode(cartJson) as Map<String, dynamic>;
        _cart = Cart.fromJson(cartData);
        await _loadCartItemDetails();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cart from local storage: $e');
    }
  }

  // Clear local storage
  Future<void> _clearCartFromLocal(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${AppConstants.guestCartKey}_$userId');
    } catch (e) {
      debugPrint('Error clearing cart from local storage: $e');
    }
  }

  Future<bool> addToCart({
    required int userId,
    required String itemType,
    required int itemId,
    required double price,
    int quantity = 1,
  }) async {
    try {
      debugPrint('CartProvider.addToCart called - userId: $userId, itemType: $itemType, itemId: $itemId, price: $price');

      // Check if the item already exists in the cart (prevent duplicates for digital products)
      if (_cart != null) {
        final existingItem = _cart!.items.firstWhere(
          (item) => item.itemType == itemType && item.itemId == itemId,
          orElse: () => const CartItem(itemType: '', itemId: -1, price: 0),
        );

        if (existingItem.itemId != -1) {
          debugPrint('Item already exists in cart - not adding duplicate');
          return false; // Item already in cart, don't add duplicate
        }
      }

      // Set loading state to prevent UI flickering
      _isLoading = true;
      notifyListeners();

      // For digital products, always set quantity to 1
      final response = await _cartService.addToCart(
        userId: userId,
        itemType: itemType,
        itemId: itemId,
        price: price,
        quantity: 1, // Always 1 for digital products
      );

      debugPrint('CartService.addToCart response - success: ${response.success}, error: ${response.error}, statusCode: ${response.statusCode}');

      if (response.success && response.data != null) {
        _cart = response.data;
        debugPrint('Cart updated - items count: ${_cart!.items.length}');

        await _loadCartItemDetails();
        debugPrint('Cart item details loaded - count: ${_cartItemDetails.length}');

        await _saveCartToLocal(userId);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      debugPrint('addToCart failed - success: ${response.success}, data null: ${response.data == null}');
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error in addToCart: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuantity(int userId, int itemId, int quantity) async {
    final response = await _cartService.updateCartItem(
      userId: userId,
      itemId: itemId,
      quantity: quantity,
    );

    if (response.success && response.data != null) {
      _cart = response.data;
      await _loadCartItemDetails();
      await _saveCartToLocal(userId);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> removeItem(int userId, int itemId) async {
    debugPrint('CartProvider.removeItem called - userId: $userId, itemId: $itemId');

    final response = await _cartService.removeFromCart(userId, itemId);

    debugPrint('CartService.removeFromCart response - success: ${response.success}, error: ${response.error}');

    if (response.success && response.data != null) {
      _cart = response.data;
      debugPrint('Cart updated after removal - items count: ${_cart!.items.length}');

      await _loadCartItemDetails();
      await _saveCartToLocal(userId);
      notifyListeners();
      return true;
    }

    debugPrint('removeItem failed - success: ${response.success}, data null: ${response.data == null}');
    return false;
  }

  Future<void> clearCart(int userId) async {
    debugPrint('=== CartProvider.clearCart called for userId: $userId ===');

    try {
      final response = await _cartService.clearCart(userId);
      debugPrint('CartService.clearCart response - success: ${response.success}');

      // Clear local state regardless of server response
      _cart = null;
      _cartItemDetails = [];
      await _clearCartFromLocal(userId);
      notifyListeners();

      debugPrint('=== Cart cleared successfully ===');
    } catch (e) {
      debugPrint('=== Error clearing cart: $e ===');
      // Still clear local state even if server fails
      _cart = null;
      _cartItemDetails = [];
      await _clearCartFromLocal(userId);
      notifyListeners();
    }
  }
}
