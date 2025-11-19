// ignore_for_file: use_build_context_synchronously

import 'package:audira_frontend/config/theme.dart';
import 'package:audira_frontend/core/api/services/music_service.dart';
import 'package:audira_frontend/core/models/album.dart';
import 'package:audira_frontend/core/models/artist.dart';
import 'package:audira_frontend/core/models/rating.dart';
import 'package:audira_frontend/core/models/rating_stats.dart';
import 'package:audira_frontend/core/models/song.dart';
import 'package:audira_frontend/core/providers/audio_provider.dart';
import 'package:audira_frontend/core/providers/auth_provider.dart';
import 'package:audira_frontend/core/providers/cart_provider.dart';
import 'package:audira_frontend/core/providers/library_provider.dart';
import 'package:audira_frontend/features/common/widgets/app_bottom_navigation_bar.dart';
import 'package:audira_frontend/features/common/widgets/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/api/services/rating_service.dart';
import '../../../core/api/services/library_service.dart';
import '../../../features/rating/widgets/rating_dialog.dart';
import '../../../features/rating/widgets/rating_list.dart';

class AlbumDetailScreen extends StatefulWidget {
  final int albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen>
    with SingleTickerProviderStateMixin {
  final MusicService _musicService = MusicService();
  final RatingService _ratingService = RatingService();
  final LibraryService _libraryService = LibraryService();

  Album? _album;
  Artist? _artist;
  List<Song> _songs = [];
  RatingStats? _ratingStats;
  List<Rating> _ratingsWithComments = [];
  Rating? _myRating;

  bool _isLoading = true;
  bool _isLoadingRatings = true;
  String? _error;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Solo Info y Ratings
    _loadAlbumDetails();
    _loadRatingsAndComments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAlbumDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load album
      final albumResponse = await _musicService.getAlbumById(widget.albumId);
      if (albumResponse.success && albumResponse.data != null) {
        _album = albumResponse.data;

        // Load artist
        final artistResponse =
            await _musicService.getArtistById(_album!.artistId);
        if (artistResponse.success) {
          _artist = artistResponse.data;
        }

        // Load songs in album
        final songsResponse =
            await _musicService.getSongsByAlbum(widget.albumId);
        if (songsResponse.success && songsResponse.data != null) {
          _songs = songsResponse.data!;
          // Sort by track number if available
          _songs.sort(
              (a, b) => (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0));
        }
      } else {
        _error = albumResponse.error ?? 'Failed to load album';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRatingsAndComments() async {
    setState(() {
      _isLoadingRatings = true;
    });

    try {
      // Cargar estadísticas (no requiere autenticación)
      final statsResponse = await _ratingService.getEntityRatingStats(
        entityType: 'ALBUM',
        entityId: widget.albumId,
      );
      if (statsResponse.success) {
        _ratingStats = statsResponse.data;
      }

      // Cargar valoraciones con comentarios (no requiere autenticación)
      final ratingsResponse = await _ratingService.getEntityRatingsWithComments(
        entityType: 'ALBUM',
        entityId: widget.albumId,
      );
      if (ratingsResponse.success && ratingsResponse.data != null) {
        _ratingsWithComments = ratingsResponse.data!;
      }

      // Obtener mi valoración SOLO si estoy autenticado
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        final myRatingResponse = await _ratingService.getMyEntityRating(
          entityType: 'ALBUM',
          entityId: widget.albumId,
        );
        if (myRatingResponse.success && myRatingResponse.data != null) {
          _myRating = myRatingResponse.data;
        }
      } else {
        // Usuario no autenticado (invitado)
        _myRating = null;
      }
    } catch (e) {
      debugPrint('Error loading ratings/comments: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingRatings = false);
      }
    }
  }

  /// Mostrar diálogo para crear o editar valoración (con comentario incluido)
  /// Verifica que el usuario haya comprado el álbum antes de permitir valorar
  Future<void> _showRatingDialog() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      // Usuario invitado - mostrar alerta para iniciar sesión
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Inicie Sesión'),
            content: const Text(
              'Debe iniciar sesión para valorar productos y acceder a todas las funcionalidades de la plataforma.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Redirigir a pantalla de login
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Iniciar Sesión'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Si ya tiene una valoración, puede editarla sin verificar compra
    if (_myRating == null) {
      // Verificar si ha comprado el álbum
      final purchaseResponse = await _libraryService.checkIfPurchased(
        authProvider.currentUser!.id,
        'ALBUM',
        widget.albumId,
      );

      if (!purchaseResponse.success || !(purchaseResponse.data ?? false)) {
        // No ha comprado el álbum
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Compra requerida'),
              content: const Text(
                'Debes comprar este álbum antes de poder valorarlo. '
                '¿Deseas agregarlo al carrito?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _addToCart();
                  },
                  child: const Text('Agregar al carrito'),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    final result = await showRatingDialog(
      context,
      entityType: 'ALBUM',
      entityId: widget.albumId,
      existingRating: _myRating,
      entityName: _album?.name,
    );

    if (result == true) {
      _loadRatingsAndComments();
    }
  }

  Future<void> _addToCart() async {
    if (_album == null) return;

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      // Usuario invitado - mostrar alerta para iniciar sesión
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Inicie Sesión'),
            content: const Text(
              'Debe iniciar sesión para agregar productos al carrito y realizar compras.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Iniciar Sesión'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final cartProvider = context.read<CartProvider>();
    try {
      final success = await cartProvider.addToCart(
        userId: authProvider.currentUser!.id,
        itemType: 'ALBUM',
        itemId: _album!.id,
        price: _album!.price,
        quantity: 1,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_album!.name} añadido al carrito'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_album!.name} ya está en el carrito'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _album == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Album not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_album!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final textToCopy = 'Check out "${_album!.name}" album on Audira!';
              Clipboard.setData(ClipboardData(text: textToCopy));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Album link copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAlbumHeader(),
                  _buildActionButtons(),
                  _buildTabs(),
                ],
              ),
            ),
          ),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigationBar(
        selectedIndex: null,
      ),
    );
  }

  Widget _buildAlbumHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Hero(
            tag: 'album-${_album!.id}',
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _album!.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _album!.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.album, size: 48),
                      )
                    : const Icon(Icons.album, size: 48),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Album info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // CORREGIDO: El campo se llama 'name', no 'title'
                  _album!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_artist != null)
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/artist',
                        arguments: _artist!.id,
                      );
                    },
                    child: Text(
                      _artist!.artistName ?? _artist!.username,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (_album!.releaseDate != null)
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _album!.releaseDate.toString().split(' ')[0],
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.music_note,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${_songs.length} songs',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_money,
                        size: 16, color: AppTheme.textSecondary),
                    Text(
                      '\$${_album!.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                if (_ratingStats != null &&
                    _ratingStats!.averageRating > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < _ratingStats!.averageRating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_ratingStats!.averageRating.toStringAsFixed(1)} (${_ratingStats!.totalRatings})',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildActionButtons() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isFavorite = libraryProvider.isAlbumFavorite(_album!.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (_album != null && _songs.isNotEmpty) {
                  audioProvider.playSong(
                    _songs[0],
                    isUserAuthenticated: authProvider.isAuthenticated,
                  );

                  Navigator.pushNamed(context, '/playback');
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(authProvider.isAuthenticated
                  ? 'Reproducir álbum'
                  : 'Vista previa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: libraryProvider.isAlbumPurchased(_album!.id)
                ? ElevatedButton.icon(
                    onPressed: null, // Botón deshabilitado
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Producto Comprado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.green.withValues(alpha: 0.7),
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _addToCart,
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              if (!authProvider.isAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please login to add favorites'),
                  ),
                );
                return;
              }
              try {
                await libraryProvider.toggleAlbumFavorite(
                  authProvider.currentUser!.id,
                  _album!,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isFavorite
                        ? 'Removed from favorites'
                        : 'Added to favorites'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            color: isFavorite ? Colors.red : AppTheme.primaryBlue,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: 'Songs'),
            Tab(text: 'Ratings'),
          ],
        ),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSongsTab(),
              _buildRatingsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSongsTab() {
    if (_songs.isEmpty) {
      return const Center(child: Text('No songs in this album'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue,
              child: Text(
                song.trackNumber?.toString() ?? (index + 1).toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(song.name),
            subtitle: Text(song.durationFormatted),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_circle_outline),
                  onPressed: () {
                    final audioProvider = context.read<AudioProvider>();
                    final authProvider = context.read<AuthProvider>();
                    audioProvider.playSong(
                      song,
                      isUserAuthenticated: authProvider.isAuthenticated,
                    );

                    Navigator.pushNamed(context, '/playback');
                    if (!authProvider.isAuthenticated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Vista previa de 10 segundos'),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'Registrarse',
                            textColor: AppTheme.primaryBlue,
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                          ),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/song',
                      arguments: song.id,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRatingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón para crear o editar mi valoración
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _showRatingDialog,
              icon: Icon(_myRating != null ? Icons.edit : Icons.star),
              label: Text(_myRating != null ? 'Editar mi valoración' : 'Valorar este álbum'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),
          ),

          const Divider(),

          // Lista de valoraciones y comentarios unificados
          if (_isLoadingRatings)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            RatingList(
              ratings: _ratingsWithComments,
              currentUserId: context.read<AuthProvider>().currentUser?.id,
              onRatingChanged: _loadRatingsAndComments,
            ),
        ],
      ),
    );
  }

}
