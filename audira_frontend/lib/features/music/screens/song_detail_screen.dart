// ignore_for_file: use_build_context_synchronously

import 'package:audira_frontend/config/theme.dart';
import 'package:audira_frontend/core/api/services/music_service.dart';
import 'package:audira_frontend/core/models/album.dart';
import 'package:audira_frontend/core/models/artist.dart';
import 'package:audira_frontend/core/models/collaborator.dart';
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

class SongDetailScreen extends StatefulWidget {
  final int songId;

  const SongDetailScreen({super.key, required this.songId});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen>
    with SingleTickerProviderStateMixin {
  final MusicService _musicService = MusicService();
  final RatingService _ratingService = RatingService();
  final LibraryService _libraryService = LibraryService();

  Song? _song;
  Album? _album;
  Artist? _artist;
  List<Collaborator> _collaborators = [];
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
    _loadSongDetails();
    _loadRatingsAndComments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSongDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final songResponse = await _musicService.getSongById(widget.songId);
      if (songResponse.success && songResponse.data != null) {
        _song = songResponse.data;

        if (_song!.albumId != null) {
          final albumResponse =
              await _musicService.getAlbumById(_song!.albumId!);
          if (albumResponse.success) {
            _album = albumResponse.data;
          }
        }

        final artistResponse =
            await _musicService.getArtistById(_song!.artistId);
        if (artistResponse.success) {
          _artist = artistResponse.data;
        }

        final collabResponse =
            await _musicService.getCollaboratorsBySongId(widget.songId);
        if (collabResponse.success && collabResponse.data != null) {
          _collaborators = collabResponse.data!;
        }
      } else {
        _error = songResponse.error ?? 'Failed to load song';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRatingsAndComments() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRatings = true;
    });

    try {
      // Cargar estadísticas (no requiere autenticación)
      final statsResponse = await _ratingService.getEntityRatingStats(
        entityType: 'SONG',
        entityId: widget.songId,
      );
      if (statsResponse.success) {
        _ratingStats = statsResponse.data;
      }

      // Cargar valoraciones con comentarios (no requiere autenticación)
      final ratingsResponse = await _ratingService.getEntityRatingsWithComments(
        entityType: 'SONG',
        entityId: widget.songId,
      );
      if (ratingsResponse.success && ratingsResponse.data != null) {
        _ratingsWithComments = ratingsResponse.data!;
      }

      // Obtener mi valoración SOLO si estoy autenticado
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        final myRatingResponse = await _ratingService.getMyEntityRating(
          entityType: 'SONG',
          entityId: widget.songId,
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
  /// Verifica que el usuario haya comprado la canción antes de permitir valorar
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
      // Verificar si ha comprado la canción
      final purchaseResponse = await _libraryService.checkIfPurchased(
        authProvider.currentUser!.id,
        'SONG',
        widget.songId,
      );

      if (!purchaseResponse.success || !(purchaseResponse.data ?? false)) {
        // No ha comprado la canción
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Compra requerida'),
              content: const Text(
                'Debes comprar esta canción antes de poder valorarla. '
                '¿Deseas agregarla al carrito?',
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
      entityType: 'SONG',
      entityId: widget.songId,
      existingRating: _myRating,
      entityName: _song?.name,
    );

    if (result == true) {
      _loadRatingsAndComments();
    }
  }

  Future<void> _addToCart() async {
    if (_song == null) return;

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
        itemType: 'SONG',
        itemId: _song!.id,
        price: _song!.price,
        quantity: 1,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_song!.name} añadido al carrito'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_song!.name} ya está en el carrito'),
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

    if (_error != null || _song == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Song not found'),
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
        title: Text(_song!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final textToCopy = 'Check out "${_song!.name}" on Audira!';
              Clipboard.setData(ClipboardData(text: textToCopy));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Song link copied to clipboard')),
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
                  _buildSongHeader(),
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

  Widget _buildSongHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'song-${_song!.id}',
            child: Container(
              width: 120,
              height: 120,
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
                child: _song!.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _song!.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.music_note, size: 48),
                      )
                    : const Icon(Icons.music_note, size: 48),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _song!.name,
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
                if (_album != null)
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/album',
                        arguments: _album!.id,
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.album, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _album!.name,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _song!.durationFormatted,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.attach_money,
                        size: 16, color: AppTheme.textSecondary),
                    Text(
                      '\$${_song!.price.toStringAsFixed(2)}',
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
                          '${_ratingStats!.averageRating.toStringAsFixed(1)} (${_ratingStats!.totalRatings} ratings)',
                          style: TextStyle(color: AppTheme.textSecondary),
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
    final isFavorite = libraryProvider.isSongFavorite(_song!.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (_song != null) {
                  audioProvider.playSong(
                    _song!,
                    isUserAuthenticated: authProvider.isAuthenticated,
                  );

                  Navigator.pushNamed(context, '/playback');
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(
                  authProvider.isAuthenticated ? 'Reproducir' : 'Vista previa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: libraryProvider.isSongPurchased(_song!.id)
                ? ElevatedButton.icon(
                    onPressed: null, // Botón deshabilitado
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Comprado'),
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
                await libraryProvider.toggleSongFavorite(
                  authProvider.currentUser!.id,
                  _song!,
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
            Tab(text: 'Details'),
            Tab(text: 'Ratings'),
          ],
        ),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsTab(),
              _buildRatingsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_song!.description != null && _song!.description!.isNotEmpty) ...[
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_song!.description!),
            const SizedBox(height: 16),
          ],
          if (_collaborators.isNotEmpty) ...[
            const Text(
              'Collaborators',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._collaborators.map((collab) => ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text('Artist ID: ${collab.artistId}'),
                  subtitle: Text(collab.role),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/artist',
                      arguments: collab.artistId,
                    );
                  },
                )),
            const SizedBox(height: 16),
          ],
          if (_song!.lyrics != null && _song!.lyrics!.isNotEmpty) ...[
            const Text(
              'Lyrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlack,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _song!.lyrics!,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
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
              label: Text(_myRating != null ? 'Editar mi valoración' : 'Valorar esta canción'),
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
