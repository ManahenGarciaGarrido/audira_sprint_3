import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/order_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../checkout/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final OrderService _orderService = OrderService();
  bool _isCreatingOrder = false;

  @override
  void initState() {
    super.initState();
    // Schedule cart loading after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCart();
    });
  }

  Future<void> _loadCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await cartProvider.loadCart(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppTheme.textGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'Tu carrito está vacío',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega productos para comenzar',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textGrey,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cartProvider.cartItemDetails.length,
            itemBuilder: (context, index) {
              final itemDetail = cartProvider.cartItemDetails[index];
              final item = itemDetail.cartItem;

              return Card(
                key: ValueKey('cart-item-${item.id}-${item.itemType}-${item.itemId}'),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: itemDetail.itemImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: itemDetail.itemImageUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 80,
                                  height: 80,
                                  color: AppTheme.surfaceBlack,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 80,
                                  height: 80,
                                  color: AppTheme.surfaceBlack,
                                  child: Icon(
                                    item.itemType == 'SONG'
                                        ? Icons.music_note
                                        : Icons.album,
                                    size: 40,
                                    color: AppTheme.textGrey,
                                  ),
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: AppTheme.surfaceBlack,
                                child: Icon(
                                  item.itemType == 'SONG'
                                      ? Icons.music_note
                                      : Icons.album,
                                  size: 40,
                                  color: AppTheme.textGrey,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      // Product Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemDetail.itemName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              itemDetail.itemArtist,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (itemDetail.itemDuration != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                itemDetail.itemDuration!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              '\$${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Delete Button Only
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: AppTheme.errorRed,
                        iconSize: 24,
                        tooltip: 'Eliminar del carrito',
                        onPressed: () {
                          if (authProvider.currentUser != null) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Eliminar producto'),
                                content: Text(
                                  '¿Deseas eliminar "${itemDetail.itemName}" del carrito?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      // Save messenger and navigator before popping
                                      final messenger = ScaffoldMessenger.of(context);
                                      final navigator = Navigator.of(context);
                                      final itemName = itemDetail.itemName;

                                      // Close dialog first
                                      navigator.pop();

                                      // Execute removal
                                      final success = await cartProvider.removeItem(
                                        authProvider.currentUser!.id,
                                        item.id!,
                                      );

                                      // Show feedback
                                      if (success) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text('$itemName eliminado del carrito'),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      } else {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Error al eliminar del carrito'),
                                            backgroundColor: Colors.red,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Eliminar',
                                      style: TextStyle(color: AppTheme.errorRed),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceBlack,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Subtotal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '\$${cartProvider.subtotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tax
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'IVA (21%)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  Text(
                    '\$${cartProvider.taxAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: AppTheme.textSecondary.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    '\$${cartProvider.totalWithTax.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryBlue,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isCreatingOrder
                      ? null
                      : () => _proceedToCheckout(cartProvider, authProvider),
                  child: _isCreatingOrder
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Proceder al pago'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _proceedToCheckout(
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) async {
    if (!authProvider.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para comprar'),
        ),
      );
      return;
    }

    if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
        ),
      );
      return;
    }

    setState(() {
      _isCreatingOrder = true;
    });

    try {
      // Prepare order items
      final orderItems = cartProvider.cart!.items.map((item) {
        return {
          'itemType': item.itemType,
          'itemId': item.itemId,
          'quantity': item.quantity,
          'price': item.price,
        };
      }).toList();

      // Create order
      final response = await _orderService.createOrder(
        userId: authProvider.currentUser!.id,
        shippingAddress: 'Digital delivery', // For digital products
        items: orderItems,
      );

      setState(() {
        _isCreatingOrder = false;
      });

      if (response.success && response.data != null) {
        // Navigate to checkout screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CheckoutScreen(order: response.data!),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Error al crear la orden'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isCreatingOrder = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
