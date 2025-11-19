import 'package:audira_frontend/core/providers/auth_provider.dart';
import 'package:audira_frontend/core/providers/cart_provider.dart';
import 'package:audira_frontend/core/providers/library_provider.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/album.dart';

class AlbumCard extends StatelessWidget {
  final Album album;

  const AlbumCard({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/album', arguments: album.id);
      },
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: AppTheme.cardBlack,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: album.coverImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: album.coverImageUrl!,
                          width: 180,
                          height: 140,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 180,
                            height: 140,
                            color: AppTheme.surfaceBlack,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 180,
                            height: 140,
                            color: AppTheme.surfaceBlack,
                            child: const Icon(Icons.album, size: 48),
                          ),
                        )
                      : Container(
                          width: 180,
                          height: 140,
                          color: AppTheme.surfaceBlack,
                          child: const Icon(Icons.album, size: 48),
                        ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Consumer<LibraryProvider>(
                    builder: (context, libraryProvider, child) {
                      final isPurchased = libraryProvider.isAlbumPurchased(album.id);

                      if (isPurchased) {
                        // Mostrar badge de producto Comprado
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Comprado',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Mostrar botón de añadir al carrito
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final currentContext = context;
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final cartProvider = Provider.of<CartProvider>(context, listen: false);

                            if (!authProvider.isAuthenticated) {
                              if (!currentContext.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Inicia sesión para añadir al carrito'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            final success = await cartProvider.addToCart(
                              userId: authProvider.currentUser!.id,
                              itemType: 'ALBUM',
                              itemId: album.id,
                              price: album.discountedPrice,
                              quantity: 1,
                            );

                            if (!currentContext.mounted) return;

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${album.name} añadido al carrito'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${album.name} ya está en el carrito'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${album.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.textGrey,
                              decoration: TextDecoration.lineThrough,
                            ),
                      ),
                      Text(
                        '\$${album.discountedPrice.toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.primaryBlue,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
