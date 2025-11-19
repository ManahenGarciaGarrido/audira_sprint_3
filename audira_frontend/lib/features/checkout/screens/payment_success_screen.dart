import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/payment.dart';
import '../../../core/models/order.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../receipt/screens/receipt_screen.dart';
import '../../home/screens/main_layout.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final Payment payment;
  final Order order;

  const PaymentSuccessScreen({
    super.key,
    required this.payment,
    required this.order,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  final MusicService _musicService = MusicService();
  bool _isAddingToLibrary = true;
  final List<Song> _purchasedSongs = [];
  final List<Album> _purchasedAlbums = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePaymentSuccess();
  }

  Future<void> _initializePaymentSuccess() async {
    // Add content to library and clear cart
    await _addPurchasedContentToLibrary();
  }

  Future<void> _addPurchasedContentToLibrary() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      debugPrint('=== PaymentSuccessScreen: Starting library sync ===');
      debugPrint('User ID: ${authProvider.currentUser?.id}');
      debugPrint('Order ID: ${widget.order.id}');
      debugPrint('Payment ID: ${widget.payment.id}');

      // Fetch all purchased items details for display
      for (final item in widget.order.items) {
        if (item.itemType == 'SONG') {
          final response = await _musicService.getSongById(item.itemId);
          if (response.success && response.data != null) {
            _purchasedSongs.add(response.data!);
          }
        } else if (item.itemType == 'ALBUM') {
          final response = await _musicService.getAlbumById(item.itemId);
          if (response.success && response.data != null) {
            _purchasedAlbums.add(response.data!);
          }
        }
      }

      // The backend has already added items to the library when payment was completed
      // Just reload the library to sync with the server
      if (authProvider.currentUser != null) {
        debugPrint('=== Calling libraryProvider.loadLibrary() ===');
        await libraryProvider.loadLibrary(authProvider.currentUser!.id);
        debugPrint('=== Library loaded successfully ===');
        debugPrint('Songs in library: ${libraryProvider.purchasedSongs.length}');
        debugPrint('Albums in library: ${libraryProvider.purchasedAlbums.length}');
      } else {
        debugPrint('ERROR: No current user found!');
      }

      // Clear cart
      if (authProvider.currentUser != null) {
        debugPrint('=== Clearing cart for user ${authProvider.currentUser!.id} ===');
        debugPrint('Cart before clear - items: ${cartProvider.cart?.items.length ?? 0}');

        // Clear cart on server and locally
        await cartProvider.clearCart(authProvider.currentUser!.id);
        debugPrint('Cart cleared, now reloading from server to verify...');

        // Force reload from server to ensure cart is empty
        await cartProvider.loadCart(authProvider.currentUser!.id);
        debugPrint('Cart after clear and reload - items: ${cartProvider.cart?.items.length ?? 0}');
        debugPrint('=== Cart clearing completed ===');
      } else {
        debugPrint('ERROR: Cannot clear cart - no current user');
      }

      setState(() {
        _isAddingToLibrary = false;
      });

      debugPrint('=== PaymentSuccessScreen: Library sync completed ===');
    } catch (e, stackTrace) {
      debugPrint('=== ERROR in _addPurchasedContentToLibrary ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');

      setState(() {
        _isAddingToLibrary = false;
        _errorMessage = 'Error al sincronizar la biblioteca: $e';
      });

      // Show error and navigate to home
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('¡Compra exitosa!'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isAddingToLibrary
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Agregando contenido a tu biblioteca...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Success icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Success message
                  const Text(
                    '¡Pago completado!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gracias por tu compra',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Payment details card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalles del pago',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'ID de transacción:',
                            widget.payment.transactionId,
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Número de orden:',
                            widget.order.orderNumber,
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Monto:',
                            '\$${widget.payment.amount.toStringAsFixed(2)}',
                            valueColor: AppTheme.primaryBlue,
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Método de pago:',
                            widget.payment.paymentMethod.displayName,
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Fecha:',
                            _formatDate(widget.payment.completedAt ?? widget.payment.createdAt),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Purchased content
                  if (_purchasedSongs.isNotEmpty || _purchasedAlbums.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.library_music,
                                  color: AppTheme.primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Contenido disponible',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'El siguiente contenido ha sido agregado a tu biblioteca:',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            if (_purchasedSongs.isNotEmpty) ...[
                              const Text(
                                'Canciones:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ..._purchasedSongs.map((song) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.music_note, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(song.name),
                                        ),
                                      ],
                                    ),
                                  )),
                              const SizedBox(height: 16),
                            ],
                            if (_purchasedAlbums.isNotEmpty) ...[
                              const Text(
                                'Álbumes:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ..._purchasedAlbums.map((album) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.album, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(album.name),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Error message if any
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ReceiptScreen(payment: widget.payment),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt),
                      label: const Text('Ver recibo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to MainLayout (will start at Home tab)
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const MainLayout(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Ir al inicio'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
