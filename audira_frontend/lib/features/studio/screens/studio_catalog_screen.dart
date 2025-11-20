// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/providers/auth_provider.dart';

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

  // GA01-151: Editar canción
  Future<void> _editSong(Song song) async {
    final titleController = TextEditingController(text: song.name);
    final descController = TextEditingController(text: song.description ?? '');
    final priceController = TextEditingController(text: song.price.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Canción'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final response = await _musicService.updateSong(song.id, {
          'title': titleController.text,
          'description': descController.text,
          'price': double.parse(priceController.text),
        });

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Canción actualizada exitosamente')),
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

    titleController.dispose();
    descController.dispose();
    priceController.dispose();
  }

  // GA01-151: Editar álbum
  Future<void> _editAlbum(Album album) async {
    final titleController = TextEditingController(text: album.name);
    final descController = TextEditingController(text: album.description ?? '');
    final priceController = TextEditingController(text: album.price.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Álbum'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final response = await _musicService.updateAlbum(album.id, {
          'title': titleController.text,
          'description': descController.text,
          'price': double.parse(priceController.text),
        });

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Álbum actualizado exitosamente')),
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

    titleController.dispose();
    descController.dispose();
    priceController.dispose();
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
      appBar: AppBar(
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
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter_header',
                enabled: false,
                child: Text('FILTRAR POR ESTADO',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              PopupMenuItem(
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
              PopupMenuItem(
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
              PopupMenuItem(
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
              const PopupMenuItem(
                value: 'sort_header',
                enabled: false,
                child: Text('ORDENAR POR',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              PopupMenuItem(
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
              PopupMenuItem(
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
              PopupMenuItem(
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
      return Center(child: Text(message));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  song.published ? AppTheme.primaryBlue : Colors.grey,
              child: Icon(
                song.published ? Icons.music_note : Icons.visibility_off,
                color: Colors.white,
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(song.name)),
                if (!song.published)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'OCULTO',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
                '\$${song.price.toStringAsFixed(2)} • ${song.durationFormatted} • ${song.plays} plays'),
            trailing: PopupMenuButton<String>(
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
          ),
        ).animate().fadeIn(delay: (index * 50).ms);
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
      return Center(child: Text(message));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  album.published ? AppTheme.primaryBlue : Colors.grey,
              child: Icon(
                album.published ? Icons.album : Icons.visibility_off,
                color: Colors.white,
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(album.name)),
                if (!album.published)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'OCULTO',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
              ],
            ),
            subtitle: Text('\$${album.price.toStringAsFixed(2)}'),
            trailing: PopupMenuButton<String>(
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
          ),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }
}
