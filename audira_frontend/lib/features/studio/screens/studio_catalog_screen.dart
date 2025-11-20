// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/providers/auth_provider.dart';
import 'edit_song_screen.dart';
import 'edit_album_screen.dart';

/// GA01-151: Editar contenido publicado (título/descripción)
/// GA01-152: Quitar/ocultar publicación
/// GA01-153: Ver lista de publicaciones/filtros
class StudioCatalogScreen extends StatefulWidget {
  const StudioCatalogScreen({super.key});

  @override
  State<StudioCatalogScreen> createState() => _StudioCatalogScreenState();
}

class _StudioCatalogScreenState extends State<StudioCatalogScreen>
    with SingleTickerProviderStateMixin {
  final MusicService _musicService = MusicService();
  late TabController _tabController;

  List<Song> _songs = [];
  List<Album> _albums = [];
  bool _isLoading = false;
  String? _error;

  // GA01-153: Filtros
  String _filterStatus = 'all'; // all, published, hidden
  String _sortBy = 'recent'; // recent, name, plays

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCatalog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final artistId = authProvider.currentUser!.id;

      final songsResponse = await _musicService.getSongsByArtist(artistId);
      if (songsResponse.success && songsResponse.data != null) {
        _songs = songsResponse.data!;
      }

      final albumsResponse = await _musicService.getAlbumsByArtist(artistId);
      if (albumsResponse.success && albumsResponse.data != null) {
        _albums = albumsResponse.data!;
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // GA01-151: Navegar a pantalla de edición completa de canción
  Future<void> _editSong(Song song) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditSongScreen(song: song),
      ),
    );

    // Si se guardaron cambios, recargar catálogo
    if (result == true) {
      _loadCatalog();
    }
  }

  // GA01-151: Navegar a pantalla de edición completa de álbum
  Future<void> _editAlbum(Album album) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditAlbumScreen(album: album),
      ),
    );

    // Si se guardaron cambios, recargar catálogo
    if (result == true) {
      _loadCatalog();
    }
  }

  // GA01-152: Toggle publicar/ocultar canción
  Future<void> _toggleSongPublished(Song song) async {
    try {
      final response = await _musicService.publishSong(song.id, !song.published);
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(song.published
                ? 'Canción ocultada exitosamente'
                : 'Canción publicada exitosamente'),
          ),
        );
        _loadCatalog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.error}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // GA01-152: Toggle publicar/ocultar álbum
  Future<void> _toggleAlbumPublished(Album album) async {
    try {
      final response =
          await _musicService.publishAlbum(album.id, !album.published);
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(album.published
                ? 'Álbum ocultado exitosamente'
                : 'Álbum publicado exitosamente'),
          ),
        );
        _loadCatalog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.error}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteSong(int songId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Canción'),
        content:
            const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _musicService.deleteSong(songId);
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Canción eliminada exitosamente')),
          );
          _loadCatalog();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteAlbum(int albumId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Álbum'),
        content: const Text(
            '¿Estás seguro? Esto también removerá todas las canciones del álbum.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _musicService.deleteAlbum(albumId);
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Álbum eliminado exitosamente')),
          );
          _loadCatalog();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // GA01-153: Filtrar y ordenar canciones
  List<Song> get _filteredSongs {
    var filtered = _songs.where((song) {
      if (_filterStatus == 'published') return song.published;
      if (_filterStatus == 'hidden') return !song.published;
      return true;
    }).toList();

    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'plays':
        filtered.sort((a, b) => b.plays.compareTo(a.plays));
        break;
      case 'recent':
      default:
        filtered.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
    }

    return filtered;
  }

  // GA01-153: Filtrar y ordenar álbumes
  List<Album> get _filteredAlbums {
    var filtered = _albums.where((album) {
      if (_filterStatus == 'published') return album.published;
      if (_filterStatus == 'hidden') return !album.published;
      return true;
    }).toList();

    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'recent':
      default:
        filtered.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: const Text('Mi Catálogo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Canciones', icon: Icon(Icons.music_note)),
            Tab(text: 'Álbumes', icon: Icon(Icons.album)),
          ],
        ),
        actions: [
          // GA01-153: Menú de filtros
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value == 'all' ||
                    value == 'published' ||
                    value == 'hidden') {
                  _filterStatus = value;
                } else {
                  _sortBy = value;
                }
              });
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'filter_header',
                enabled: false,
                child: Text('FILTRAR POR ESTADO',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              PopupMenuItem<String>(
                value: 'all',
                child: Row(
                  children: [
                    if (_filterStatus == 'all')
                      const Icon(Icons.check, size: 20),
                    if (_filterStatus != 'all') const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    const Text('Todas'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'published',
                child: Row(
                  children: [
                    if (_filterStatus == 'published')
                      const Icon(Icons.check, size: 20),
                    if (_filterStatus != 'published') const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    const Text('Publicadas'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'hidden',
                child: Row(
                  children: [
                    if (_filterStatus == 'hidden')
                      const Icon(Icons.check, size: 20),
                    if (_filterStatus != 'hidden') const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    const Text('Ocultas'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'sort_header',
                enabled: false,
                child: Text('ORDENAR POR',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              PopupMenuItem<String>(
                value: 'recent',
                child: Row(
                  children: [
                    if (_sortBy == 'recent') const Icon(Icons.check, size: 20),
                    if (_sortBy != 'recent') const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    const Text('Más recientes'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'name',
                child: Row(
                  children: [
                    if (_sortBy == 'name') const Icon(Icons.check, size: 20),
                    if (_sortBy != 'name') const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    const Text('Nombre'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'plays',
                child: Row(
                  children: [
                    if (_sortBy == 'plays') const Icon(Icons.check, size: 20),
                    if (_sortBy != 'plays') const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    const Text('Reproducciones'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      ElevatedButton(
                        onPressed: _loadCatalog,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSongsList(),
                    _buildAlbumsList(),
                  ],
                ),
    );
  }

  Widget _buildSongsList() {
    final songs = _filteredSongs;

    if (songs.isEmpty) {
      String message = 'No hay canciones';
      if (_filterStatus == 'published') {
        message = 'No hay canciones publicadas';
      } else if (_filterStatus == 'hidden') {
        message = 'No hay canciones ocultas';
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _editSong(song),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Portada o icono
                  _buildSongCover(song),
                  const SizedBox(width: 12),
                  // Información
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                song.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!song.published)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: const Text(
                                  'OCULTO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${song.price.toStringAsFixed(2)} • ${song.durationFormatted}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${song.plays} reproducciones',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menú de opciones
                  PopupMenuButton<String>(
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: AppTheme.primaryBlue),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              song.published
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(song.published ? 'Ocultar' : 'Publicar'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editSong(song);
                      } else if (value == 'toggle') {
                        _toggleSongPublished(song);
                      } else if (value == 'delete') {
                        _deleteSong(song.id);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildAlbumsList() {
    final albums = _filteredAlbums;

    if (albums.isEmpty) {
      String message = 'No hay álbumes';
      if (_filterStatus == 'published') {
        message = 'No hay álbumes publicados';
      } else if (_filterStatus == 'hidden') {
        message = 'No hay álbumes ocultos';
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.album, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _editAlbum(album),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Portada o icono
                  _buildAlbumCover(album),
                  const SizedBox(width: 12),
                  // Información
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                album.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!album.published)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: const Text(
                                  'OCULTO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${album.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        if (album.songCount != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${album.songCount} canciones',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Menú de opciones
                  PopupMenuButton<String>(
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: AppTheme.primaryBlue),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              album.published
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(album.published ? 'Ocultar' : 'Publicar'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editAlbum(album);
                      } else if (value == 'toggle') {
                        _toggleAlbumPublished(album);
                      } else if (value == 'delete') {
                        _deleteAlbum(album.id);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.2, end: 0);
      },
    );
  }

  // Widget para mostrar portada de canción o icono de oculto
  Widget _buildSongCover(Song song) {
    if (!song.published) {
      // Si está oculto, mostrar icono visibility_off
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.visibility_off,
          size: 30,
          color: Colors.grey,
        ),
      );
    }

    // Si está publicado, mostrar portada
    if (song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          song.coverImageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.music_note,
                size: 30,
                color: AppTheme.primaryBlue,
              ),
            );
          },
        ),
      );
    }

    // Fallback: icono de música
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.music_note,
        size: 30,
        color: AppTheme.primaryBlue,
      ),
    );
  }

  // Widget para mostrar portada de álbum o icono de oculto
  Widget _buildAlbumCover(Album album) {
    if (!album.published) {
      // Si está oculto, mostrar icono visibility_off
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.visibility_off,
          size: 30,
          color: Colors.grey,
        ),
      );
    }

    // Si está publicado, mostrar portada
    if (album.coverImageUrl != null && album.coverImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          album.coverImageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.album,
                size: 30,
                color: AppTheme.primaryBlue,
              ),
            );
          },
        ),
      );
    }

    // Fallback: icono de álbum
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.album,
        size: 30,
        color: AppTheme.primaryBlue,
      ),
    );
  }
}
