import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../core/models/album.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/library_provider.dart';

class AlbumListItem extends StatelessWidget {
  final Album album;
  final void Function()? onTap;

  const AlbumListItem({
    super.key,
    required this.album,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: album.coverImageUrl != null
              ? CachedNetworkImage(
                  imageUrl: album.coverImageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    color: AppTheme.surfaceBlack,
                    child: const Icon(Icons.album, size: 24),
                  ),
                )
              : Container(
                  width: 50,
                  height: 50,
                  color: AppTheme.surfaceBlack,
                  child: const Icon(Icons.album, size: 24),
                ),
        ),
        title: Text(album.name),
        subtitle: Text(
          '\$${album.discountedPrice.toStringAsFixed(2)} (${album.discountPercentage}% OFF)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        ),
        trailing: Consumer<LibraryProvider>(
          builder: (context, libraryProvider, child) {
            final isPurchased = libraryProvider.isAlbumPurchased(album.id);

            if (isPurchased) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Adquirido',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }

            return IconButton(
              icon: const Icon(Icons.add_shopping_cart_outlined),
              color: AppTheme.primaryBlue,
              onPressed: () async {
                if (authProvider.currentUser != null) {
                  final success = await cartProvider.addToCart(
                    userId: authProvider.currentUser!.id,
                    itemType: AppConstants.itemTypeAlbum,
                    itemId: album.id,
                    price: album.discountedPrice,
                    quantity: 1,
                  );
                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${album.name} agregado al carrito'),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${album.name} ya está en el carrito'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Inicia sesión para agregar al carrito'),
                    ),
                  );
                }
              },
            );
          },
        ),
        onTap: onTap ??
            () {
              Navigator.pushNamed(context, '/album', arguments: album.id);
            },
      ),
    );
  }
}
