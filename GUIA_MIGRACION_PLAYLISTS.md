# Guía de Migración: Gestión de Playlists por Subtarea

Esta guía detalla **TODOS** los cambios necesarios para implementar las funcionalidades de playlists, organizados por subtarea para facilitar la migración al repositorio original de GitHub.

---

## 📋 Índice de Subtareas

1. [GA01-113: Crear lista con nombre](#ga01-113-crear-lista-con-nombre)
2. [GA01-114: Añadir / eliminar canciones](#ga01-114-añadir--eliminar-canciones)
3. [GA01-115: Editar nombre / eliminar lista](#ga01-115-editar-nombre--eliminar-lista)
4. [GA01-116: Ver todas mis listas](#ga01-116-ver-todas-mis-listas)

---

## GA01-113: Crear lista con nombre

### 📁 Archivos a Modificar/Crear
 
#### 1. MODIFICAR: `lib/features/playlist/screens/create_playlist_screen.dart`

**Ubicación**: `audira_frontend/lib/features/playlist/screens/create_playlist_screen.dart`

**Acción**: Reemplazar completamente el contenido del archivo

**Contenido completo**:

```dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/song.dart';
import '../../../core/models/playlist.dart';
import '../../../core/api/services/playlist_service.dart';
import '../../../config/theme.dart';

/// Pantalla para crear o editar playlists
/// GA01-113: Crear lista con nombre
class CreatePlaylistScreen extends StatefulWidget {
  final int? playlistId; // null = crear nueva

  const CreatePlaylistScreen({super.key, this.playlistId});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final PlaylistService _playlistService = PlaylistService();

  bool _isPublic = false;
  bool _isLoading = false;
  bool _isLoadingData = false;
  bool _showPreview = false;

  Playlist? _originalPlaylist;
  List<Song> _selectedSongs = [];

  @override
  void initState() {
    super.initState();
    if (widget.playlistId != null) {
      _loadPlaylistData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Cargar datos de la playlist si estamos editando
  Future<void> _loadPlaylistData() async {
    setState(() => _isLoadingData = true);

    try {
      final response =
          await _playlistService.getPlaylistWithSongs(widget.playlistId!);
      if (response.success && response.data != null) {
        _originalPlaylist = response.data?['playlist'];
        _selectedSongs = response.data?['songs'] ?? [];

        _nameController.text = _originalPlaylist!.name;
        _descriptionController.text = _originalPlaylist!.description ?? '';
        _isPublic = _originalPlaylist!.isPublic;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar playlist: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  /// Guardar o actualizar playlist
  Future<void> _savePlaylist() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final libraryProvider = context.read<LibraryProvider>();

      if (!authProvider.isAuthenticated) {
        throw Exception('Debes iniciar sesión para crear playlists');
      }

      if (widget.playlistId == null) {
        // CREAR NUEVA PLAYLIST
        final playlist = await libraryProvider.createPlaylist(
          userId: authProvider.currentUser!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isPublic: _isPublic,
        );

        if (playlist != null) {
          // Añadir canciones seleccionadas
          for (final song in _selectedSongs) {
            await libraryProvider.addSongToPlaylist(playlist.id, song.id);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Playlist "${playlist.name}" creada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          throw Exception('No se pudo crear la playlist');
        }
      } else {
        // EDITAR (se implementa en GA01-115)
        throw UnimplementedError('Edición disponible en GA01-115');
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _togglePreview() {
    setState(() => _showPreview = !_showPreview);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.playlistId == null ? 'Crear Playlist' : 'Editar Playlist',
        ),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.preview),
            onPressed: _togglePreview,
            tooltip: _showPreview ? 'Editar' : 'Vista previa',
          ),
        ],
      ),
      body: _showPreview ? _buildPreview() : _buildForm(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Playlist name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la Playlist',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.playlist_play),
                filled: true,
                fillColor: AppTheme.surfaceBlack,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un nombre';
                }
                if (value.trim().length < 3) {
                  return 'El nombre debe tener al menos 3 caracteres';
                }
                return null;
              },
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppTheme.surfaceBlack,
              ),
              maxLines: 3,
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 16),

            // Public/Private toggle
            Card(
              color: AppTheme.surfaceBlack,
              child: SwitchListTile(
                title: const Text('Playlist pública'),
                subtitle: const Text(
                    'Otros usuarios pueden ver y escuchar esta playlist'),
                value: _isPublic,
                onChanged: (value) {
                  setState(() => _isPublic = value);
                },
                activeColor: AppTheme.primaryBlue,
                secondary: Icon(
                  _isPublic ? Icons.public : Icons.lock,
                  color: _isPublic ? AppTheme.primaryBlue : AppTheme.textGrey,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Info message
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 64,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Añadir canciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Podrás añadir canciones después de crear la playlist',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.playlist_play,
                      size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  _nameController.text.trim().isEmpty
                      ? 'Sin nombre'
                      : _nameController.text.trim(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_descriptionController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _descriptionController.text.trim(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isPublic ? Icons.public : Icons.lock,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isPublic ? 'Pública' : 'Privada',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.9, 0.9)),

          const SizedBox(height: 24),

          const Text(
            'Vista Previa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Así es como se verá tu playlist',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlack,
        border: Border(
          top: BorderSide(color: AppTheme.textGrey.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePlaylist,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.playlistId == null
                            ? 'Crear Playlist'
                            : 'Guardar Cambios',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Cambios principales**:
- ✅ Formulario completo con validación para nombre (mínimo 3 caracteres)
- ✅ Campo de descripción opcional
- ✅ Toggle público/privado con icono dinámico
- ✅ Vista previa de la playlist
- ✅ Botón de cancelar y crear
- ✅ Feedback visual con SnackBars
- ✅ Animaciones con flutter_animate

---

#### 2. NO MODIFICAR (por ahora): `lib/config/routes.dart`

**Nota**: La ruta `/playlist/create` ya existe y funciona correctamente. No requiere cambios para GA01-113.

---

### ✅ Verificación GA01-113

Después de aplicar estos cambios, el usuario debe poder:
1. ✅ Navegar a crear playlist desde la biblioteca
2. ✅ Ingresar nombre de playlist (validado)
3. ✅ Ingresar descripción opcional
4. ✅ Seleccionar si es pública o privada
5. ✅ Ver vista previa de la playlist
6. ✅ Guardar la playlist con éxito
7. ✅ Ver mensaje de confirmación

---

## GA01-114: Añadir / eliminar canciones

### 📁 Archivos a Modificar/Crear

#### 1. CREAR: `lib/features/playlist/screens/song_selector_screen.dart`

**Ubicación**: `audira_frontend/lib/features/playlist/screens/song_selector_screen.dart`

**Acción**: Crear nuevo archivo

**Contenido completo**: (Ver archivo en el repositorio - 400+ líneas)

<details>
<summary>📄 Contenido completo de song_selector_screen.dart (Click para expandir)</summary>

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../core/models/song.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/providers/audio_provider.dart';
import '../../../core/providers/auth_provider.dart';

/// Pantalla para seleccionar canciones para añadir a una playlist
/// GA01-114: Añadir canciones a playlist
class SongSelectorScreen extends StatefulWidget {
  final List<int> currentSongIds; // Canciones ya en la playlist
  final String playlistName;

  const SongSelectorScreen({
    super.key,
    this.currentSongIds = const [],
    required this.playlistName,
  });

  @override
  State<SongSelectorScreen> createState() => _SongSelectorScreenState();
}

class _SongSelectorScreenState extends State<SongSelectorScreen> {
  final MusicService _musicService = MusicService();
  final TextEditingController _searchController = TextEditingController();

  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  final Set<int> _selectedSongIds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _musicService.getAllSongs();
      if (response.success && response.data != null) {
        // Filtrar canciones que NO están en la playlist
        _allSongs = response.data!
            .where((song) => !widget.currentSongIds.contains(song.id))
            .toList();
        _filteredSongs = _allSongs;
      } else {
        _error = response.error ?? 'Failed to load songs';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterSongs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSongs = _allSongs;
      } else {
        _filteredSongs = _allSongs.where((song) {
          return song.name.toLowerCase().contains(query.toLowerCase()) ||
              song.artistName.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleSongSelection(int songId) {
    setState(() {
      if (_selectedSongIds.contains(songId)) {
        _selectedSongIds.remove(songId);
      } else {
        _selectedSongIds.add(songId);
      }
    });
  }

  void _confirmSelection() {
    // Obtener las canciones seleccionadas
    final selectedSongs = _filteredSongs
        .where((song) => _selectedSongIds.contains(song.id))
        .toList();
    Navigator.pop(context, selectedSongs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Añadir canciones'),
            Text(
              'a "${widget.playlistName}"',
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
            ),
          ],
        ),
        actions: [
          if (_selectedSongIds.isNotEmpty)
            TextButton(
              onPressed: _confirmSelection,
              child: Text(
                'Añadir (${_selectedSongIds.length})',
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSongs,
              decoration: InputDecoration(
                hintText: 'Buscar canciones...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterSongs('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),

          // Selected count chip
          if (_selectedSongIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedSongIds.length} canción${_selectedSongIds.length == 1 ? "" : "es"} seleccionada${_selectedSongIds.length == 1 ? "" : "s"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedSongIds.clear());
                    },
                    child: const Text(
                      'Limpiar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.5, end: 0),

          // Songs list
          Expanded(
            child: _buildSongsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllSongs,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_filteredSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isEmpty
                  ? Icons.music_note
                  : Icons.search_off,
              size: 64,
              color: AppTheme.textGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay canciones disponibles'
                  : 'No se encontraron canciones',
              style: const TextStyle(fontSize: 18, color: AppTheme.textGrey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSongs.length,
      itemBuilder: (context, index) {
        final song = _filteredSongs[index];
        final isSelected = _selectedSongIds.contains(song.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : null,
          child: ListTile(
            leading: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.coverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: song.coverImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const Icon(Icons.music_note),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.music_note),
                          )
                        : Container(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                            child: const Icon(Icons.music_note),
                          ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            title: Text(
              song.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryBlue : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.artistName),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      song.durationFormatted,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.attach_money,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    Text(
                      song.price.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                  },
                  tooltip: 'Vista previa',
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSongSelection(song.id),
                  activeColor: AppTheme.primaryBlue,
                ),
              ],
            ),
            onTap: () => _toggleSongSelection(song.id),
          ),
        ).animate(delay: (index * 30).ms).fadeIn().slideX(begin: -0.1);
      },
    );
  }
}
```

</details>

**Funcionalidades**:
- ✅ Búsqueda y filtrado de canciones en tiempo real
- ✅ Selección múltiple con checkboxes
- ✅ Contador visual de canciones seleccionadas
- ✅ Vista previa de audio
- ✅ Filtrado automático (no muestra canciones ya en la playlist)
- ✅ Animaciones fluidas

---

#### 2. MODIFICAR: `lib/features/playlist/screens/create_playlist_screen.dart`

**Acción**: Añadir el import y el método para seleccionar canciones

**Import a añadir** (al principio del archivo):
```dart
import 'song_selector_screen.dart';
```

**Método a añadir** (después del método `_togglePreview()`):
```dart
/// Abrir pantalla de selección de canciones
Future<void> _addSongsToPlaylist() async {
  final currentSongIds = _selectedSongs.map((s) => s.id).toList();
  final playlistName = _nameController.text.trim().isEmpty
      ? 'Nueva Playlist'
      : _nameController.text.trim();

  final List<Song>? selectedSongs = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SongSelectorScreen(
        currentSongIds: currentSongIds,
        playlistName: playlistName,
      ),
    ),
  );

  if (selectedSongs != null && selectedSongs.isNotEmpty) {
    // Si estamos creando, añadir a la lista temporal
    setState(() {
      _selectedSongs.addAll(selectedSongs);
    });
  }
}

/// Eliminar canción de la playlist
Future<void> _removeSong(Song song) async {
  setState(() {
    _selectedSongs.remove(song);
  });
}
```

**Reemplazar en `_buildForm()`** la sección de "Info message" por:
```dart
// Songs section header
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Canciones',
          style:
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          '${_selectedSongs.length} ${_selectedSongs.length == 1 ? "canción" : "canciones"}',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
      ],
    ),
    ElevatedButton.icon(
      onPressed: _isLoading ? null : _addSongsToPlaylist,
      icon: const Icon(Icons.add),
      label: const Text('Añadir'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryBlue,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
      ),
    ),
  ],
).animate().fadeIn(delay: 300.ms, duration: 300.ms),

const SizedBox(height: 16),

// Selected songs list
if (_selectedSongs.isEmpty)
  Center(
    child: Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.music_note,
              size: 64,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay canciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca "Añadir" para seleccionar canciones',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  ).animate().fadeIn(delay: 400.ms)
else
  ..._selectedSongs.asMap().entries.map((entry) {
    final index = entry.key;
    final song = entry.value;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.surfaceBlack,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryBlue,
          child: Text(
            '${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(song.name),
        subtitle: Text(
          '${song.artistName} • ${song.durationFormatted}',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => _removeSong(song),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: -0.1);
  }),
```

**Actualizar en `_buildPreview()`** para mostrar canciones:
```dart
// Songs preview (añadir después del texto "Así es como se verá tu playlist")
const SizedBox(height: 24),

if (_selectedSongs.isEmpty)
  Center(
    child: Column(
      children: [
        const Icon(Icons.music_note,
            size: 64, color: AppTheme.textGrey),
        const SizedBox(height: 16),
        Text(
          'No hay canciones en esta playlist',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ],
    ),
  )
else
  ..._selectedSongs.asMap().entries.map((entry) {
    final index = entry.key;
    final song = entry.value;
    return Card(
      color: AppTheme.surfaceBlack,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryBlue,
          child: Text('${index + 1}'),
        ),
        title: Text(song.name),
        subtitle: Text(
          '${song.artistName} • ${song.durationFormatted}',
        ),
        trailing: const Icon(Icons.play_arrow),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: -0.2);
  }),
```

---

#### 3. MODIFICAR: `lib/features/playlist/screens/playlist_detail_screen.dart`

**Acción**: Añadir funcionalidad para añadir y eliminar canciones

**Imports a añadir**:
```dart
import '../../../core/providers/library_provider.dart';
import 'song_selector_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
```

**Métodos a añadir** (después de `_loadPlaylist()`):
```dart
/// Añadir canciones a la playlist
Future<void> _addSongsToPlaylist() async {
  if (_playlist == null) return;

  final currentSongIds = _songs.map((s) => s.id).toList();

  final List<Song>? selectedSongs = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SongSelectorScreen(
        currentSongIds: currentSongIds,
        playlistName: _playlist!.name,
      ),
    ),
  );

  if (selectedSongs != null && selectedSongs.isNotEmpty) {
    setState(() => _isLoading = true);
    try {
      final libraryProvider = context.read<LibraryProvider>();
      for (final song in selectedSongs) {
        await libraryProvider.addSongToPlaylist(widget.playlistId, song.id);
      }
      // Recargar playlist
      await _loadPlaylist();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${selectedSongs.length} canción${selectedSongs.length == 1 ? "" : "es"} añadida${selectedSongs.length == 1 ? "" : "s"}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
```

**Reemplazar el método existente** `_removeSongFromPlaylist()` por:
```dart
/// Eliminar canción de la playlist
Future<void> _removeSongFromPlaylist(Song song) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.surfaceBlack,
      title: const Text('Eliminar canción'),
      content: Text('¿Eliminar "${song.name}" de esta playlist?'),
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
      await _playlistService.removeSongFromPlaylist(
          widget.playlistId, song.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Canción eliminada'),
          backgroundColor: Colors.green,
        ),
      );
      _loadPlaylist();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Modificar el ListView.builder de canciones** en `build()` para añadir botón de eliminar:
```dart
trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: const Icon(Icons.play_circle_outline),
      onPressed: () {
        audioProvider.playSong(song);
      },
      tooltip: 'Reproducir',
    ),
    if (isOwner)
      IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppTheme.surfaceBlack,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Ver detalles'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      '/song',
                      arguments: song.id,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red),
                  title: const Text(
                    'Eliminar de playlist',
                    style: TextStyle(
                        color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeSongFromPlaylist(song);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
  ],
),
```

**Añadir botón FAB** para añadir canciones (antes del cierre de Scaffold):
```dart
floatingActionButton: isOwner && _songs.isNotEmpty
    ? FloatingActionButton.extended(
        onPressed: _addSongsToPlaylist,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('Añadir canciones'),
      ).animate().fadeIn(delay: 500.ms).scale()
    : null,
```

---

### ✅ Verificación GA01-114

Después de aplicar estos cambios, el usuario debe poder:
1. ✅ Abrir pantalla de selección de canciones desde crear/editar playlist
2. ✅ Buscar y filtrar canciones en tiempo real
3. ✅ Seleccionar múltiples canciones
4. ✅ Ver contador de canciones seleccionadas
5. ✅ Reproducir vista previa de canciones
6. ✅ Añadir canciones a la playlist
7. ✅ Eliminar canciones con confirmación
8. ✅ Ver actualización instantánea de la lista

---

## GA01-115: Editar nombre / eliminar lista

### 📁 Archivos a Modificar

#### 1. MODIFICAR: `lib/features/playlist/screens/create_playlist_screen.dart`

**Acción**: Actualizar el método `_savePlaylist()` para soportar edición

**Reemplazar** el bloque del `else` en `_savePlaylist()`:

```dart
} else {
  // EDITAR PLAYLIST EXISTENTE
  await libraryProvider.updatePlaylist(
    playlistId: widget.playlistId!,
    name: _nameController.text.trim(),
    description: _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim(),
    isPublic: _isPublic,
  );

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playlist actualizada exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true);
  }
}
```

**Añadir método** para eliminar playlist (después de `_savePlaylist()`):
```dart
/// Eliminar playlist
Future<void> _deletePlaylist() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.surfaceBlack,
      title: Row(
        children: const [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 12),
          Text('Eliminar Playlist'),
        ],
      ),
      content: Text(
        '¿Estás seguro de que deseas eliminar "${_nameController.text}"?\n\nEsta acción no se puede deshacer.',
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  if (confirmed == true && widget.playlistId != null) {
    setState(() => _isLoading = true);

    try {
      final libraryProvider = context.read<LibraryProvider>();
      await libraryProvider.deletePlaylist(widget.playlistId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playlist eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
```

**Modificar AppBar** en `build()` para añadir botón de eliminar:
```dart
appBar: AppBar(
  title: Text(
    widget.playlistId == null ? 'Crear Playlist' : 'Editar Playlist',
  ),
  actions: [
    if (widget.playlistId != null)
      IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: _deletePlaylist,
        tooltip: 'Eliminar playlist',
      ),
    IconButton(
      icon: Icon(_showPreview ? Icons.edit : Icons.preview),
      onPressed: _togglePreview,
      tooltip: _showPreview ? 'Editar' : 'Vista previa',
    ),
  ],
),
```

**Actualizar método** `_addSongsToPlaylist()` para soportar edición:
```dart
Future<void> _addSongsToPlaylist() async {
  final currentSongIds = _selectedSongs.map((s) => s.id).toList();
  final playlistName = _nameController.text.trim().isEmpty
      ? 'Nueva Playlist'
      : _nameController.text.trim();

  final List<Song>? selectedSongs = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SongSelectorScreen(
        currentSongIds: currentSongIds,
        playlistName: playlistName,
      ),
    ),
  );

  if (selectedSongs != null && selectedSongs.isNotEmpty) {
    // Si estamos editando, añadir directamente al backend
    if (widget.playlistId != null) {
      setState(() => _isLoading = true);
      try {
        final libraryProvider = context.read<LibraryProvider>();
        for (final song in selectedSongs) {
          await libraryProvider.addSongToPlaylist(widget.playlistId!, song.id);
        }
        // Recargar datos
        await _loadPlaylistData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${selectedSongs.length} canción${selectedSongs.length == 1 ? "" : "es"} añadida${selectedSongs.length == 1 ? "" : "s"}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      // Si estamos creando, añadir a la lista temporal
      setState(() {
        _selectedSongs.addAll(selectedSongs);
      });
    }
  }
}
```

**Actualizar método** `_removeSong()` para soportar edición:
```dart
Future<void> _removeSong(Song song) async {
  // Si estamos editando, eliminar del backend
  if (widget.playlistId != null) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar canción'),
        content: Text('¿Eliminar "${song.name}" de esta playlist?'),
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
      setState(() => _isLoading = true);
      try {
        final libraryProvider = context.read<LibraryProvider>();
        await libraryProvider.removeSongFromPlaylist(
            widget.playlistId!, song.id);
        // Recargar datos
        await _loadPlaylistData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Canción eliminada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  } else {
    // Si estamos creando, eliminar de la lista temporal
    setState(() {
      _selectedSongs.remove(song);
    });
  }
}
```

---

#### 2. MODIFICAR: `lib/features/playlist/screens/playlist_detail_screen.dart`

**Acción**: Añadir menú de opciones y botón de eliminar

**Añadir método** para mostrar opciones (después de `_removeSongFromPlaylist()`):
```dart
/// Eliminar playlist completa
Future<void> _deletePlaylist() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.surfaceBlack,
      title: Row(
        children: const [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 12),
          Text('Eliminar Playlist'),
        ],
      ),
      content: Text(
        '¿Estás seguro de que deseas eliminar "${_playlist!.name}"?\n\nEsta acción no se puede deshacer.',
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      final libraryProvider = context.read<LibraryProvider>();
      await libraryProvider.deletePlaylist(widget.playlistId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playlist eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
}

/// Mostrar opciones de la playlist
void _showPlaylistOptions() {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surfaceBlack,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.edit, color: AppTheme.primaryBlue),
          title: const Text('Editar playlist'),
          onTap: () async {
            Navigator.pop(context);
            final result = await Navigator.pushNamed(
              context,
              '/playlist/edit',
              arguments: widget.playlistId,
            );
            if (result == true) {
              _loadPlaylist();
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.add, color: AppTheme.primaryBlue),
          title: const Text('Añadir canciones'),
          onTap: () {
            Navigator.pop(context);
            _addSongsToPlaylist();
          },
        ),
        ListTile(
          leading: const Icon(Icons.share, color: AppTheme.primaryBlue),
          title: const Text('Compartir'),
          onTap: () async {
            Navigator.pop(context);
            final shareText =
                '🎵 Mira mi playlist "${_playlist!.name}" en Audira!\n\n'
                '${_songs.length} canciones\n'
                '${_playlist!.description ?? ""}\n\n'
                '¡Escúchala ahora!';

            await Share.share(
              shareText,
              subject: 'Mira esta playlist en Audira',
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text('Eliminar playlist',
              style: TextStyle(color: Colors.red)),
          onTap: () {
            Navigator.pop(context);
            _deletePlaylist();
          },
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}
```

**Modificar AppBar** para añadir menú de opciones:
```dart
appBar: AppBar(
  title: Text(_playlist!.name),
  actions: [
    if (isOwner)
      IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: _showPlaylistOptions,
        tooltip: 'Opciones',
      ),
    if (!isOwner)
      IconButton(
        icon: const Icon(Icons.share),
        onPressed: () async {
          final shareText =
              '🎵 Mira esta playlist "${_playlist!.name}" en Audira!\n\n'
              '${_songs.length} canciones\n'
              '${_playlist!.description ?? ""}\n\n'
              '¡Escúchala ahora!';

          await Share.share(
            shareText,
            subject: 'Mira esta playlist en Audira',
          );
        },
      ),
  ],
),
```

---

#### 3. MODIFICAR: `lib/config/routes.dart`

**Acción**: Actualizar la ruta de edición para soportar ID como argumento

**Reemplazar** el caso `editPlaylist`:
```dart
case editPlaylist:
  // Soportar el ID como argumento
  final playlistId = settings.arguments as int?;
  if (playlistId != null) {
    return MaterialPageRoute(
      builder: (_) => CreatePlaylistScreen(playlistId: playlistId),
    );
  }
  // Si no hay ID, crear nueva playlist
  return MaterialPageRoute(builder: (_) => const CreatePlaylistScreen());
```

---

### ✅ Verificación GA01-115

Después de aplicar estos cambios, el usuario debe poder:
1. ✅ Editar nombre, descripción y privacidad de playlist existente
2. ✅ Ver cambios reflejados inmediatamente
3. ✅ Eliminar playlist con confirmación de seguridad
4. ✅ Ver advertencia sobre acción irreversible
5. ✅ Acceder al menú de opciones desde detalle de playlist
6. ✅ Solo el owner puede editar/eliminar
7. ✅ Redirigir correctamente después de eliminar

---

## GA01-116: Ver todas mis listas

### 📁 Archivos a Modificar

#### 1. MODIFICAR: `lib/features/library/screens/library_screen.dart`

**Acción**: Mejorar la vista de playlists con FAB y diseño mejorado

**Modificar** el método `initState()`:
```dart
@override
void initState() {
  super.initState();
  _tabController = TabController(length: 4, vsync: this);
  // Listen to tab changes to update FAB visibility
  _tabController.addListener(() {
    if (mounted) {
      setState(() {});
    }
  });
  // Schedule loading after the first frame to avoid setState during build
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadPlaylists();
    _loadLibrary();
  });
}
```

**Modificar** el método `build()` para añadir FAB:
```dart
@override
Widget build(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  return Scaffold(
    appBar: AppBar(
      title: const Text('Mi Biblioteca'),
      centerTitle: true,
    ),
    body: Consumer<LibraryProvider>(
      builder: (context, libraryProvider, child) {
        return Column(
          children: [
            Material(
              color: AppTheme.surfaceBlack,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.primaryBlue,
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.textGrey,
                tabs: const [
                  Tab(text: 'Canciones'),
                  Tab(text: 'Álbumes'),
                  Tab(text: 'Playlists'),
                  Tab(text: 'Favoritos'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Songs
                  _buildSongsTab(libraryProvider),

                  // Albums
                  _buildAlbumsTab(libraryProvider),

                  // Playlists
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _playlists.isEmpty
                          ? _buildEmptyPlaylistsState(context)
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _playlists.length,
                              itemBuilder: (context, index) {
                                final playlist = _playlists[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: AppTheme.surfaceBlack,
                                  child: ListTile(
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.playlist_play, color: Colors.white),
                                    ),
                                    title: Text(
                                      playlist.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Icon(
                                          playlist.isPublic ? Icons.public : Icons.lock,
                                          size: 12,
                                          color: AppTheme.textGrey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${playlist.songCount} ${playlist.songCount == 1 ? "canción" : "canciones"}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppTheme.textGrey,
                                              ),
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                      color: AppTheme.textGrey,
                                    ),
                                    onTap: () async {
                                      final result = await Navigator.pushNamed(
                                        context,
                                        '/playlist',
                                        arguments: playlist.id,
                                      );
                                      if (result == true) {
                                        _loadPlaylists();
                                      }
                                    },
                                  ),
                                );
                              },
                            ),

                  // Favorites
                  _buildFavoritesTab(libraryProvider),
                ],
              ),
            ),
          ],
        );
      },
    ),
    floatingActionButton: _tabController.index == 2 && authProvider.isAuthenticated
        ? FloatingActionButton.extended(
            onPressed: () async {
              final result =
                  await Navigator.pushNamed(context, '/playlist/create');
              if (result == true) {
                _loadPlaylists();
              }
            },
            backgroundColor: AppTheme.primaryBlue,
            icon: const Icon(Icons.add),
            label: const Text('Nueva Playlist'),
          )
        : null,
  );
}
```

**Añadir método** `_buildEmptyPlaylistsState()` (después de `_buildEmptyState()`):
```dart
Widget _buildEmptyPlaylistsState(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.playlist_play,
            size: 80,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'No hay playlists',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Crea tu primera playlist y organiza\ntu música favorita',
          style: TextStyle(
            color: AppTheme.textGrey,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (authProvider.isAuthenticated)
          ElevatedButton.icon(
            onPressed: () async {
              final result =
                  await Navigator.pushNamed(context, '/playlist/create');
              if (result == true) {
                _loadPlaylists();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear Playlist'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    ),
  );
}
```

---

### ✅ Verificación GA01-116

Después de aplicar estos cambios, el usuario debe poder:
1. ✅ Ver todas sus playlists en la pestaña de biblioteca
2. ✅ Ver diseño mejorado con gradientes azules
3. ✅ Ver información completa: nombre, cantidad, privacidad
4. ✅ FAB visible solo en pestaña de Playlists
5. ✅ Crear playlist rápidamente desde FAB
6. ✅ Estado vacío atractivo con CTA
7. ✅ Actualización automática al volver de editar
8. ✅ Navegación fluida entre pantallas

---

## 📦 Resumen de Archivos por Subtarea

### GA01-113
- `lib/features/playlist/screens/create_playlist_screen.dart` (MODIFICAR)

### GA01-114
- `lib/features/playlist/screens/song_selector_screen.dart` (CREAR)
- `lib/features/playlist/screens/create_playlist_screen.dart` (MODIFICAR)
- `lib/features/playlist/screens/playlist_detail_screen.dart` (MODIFICAR)

### GA01-115
- `lib/features/playlist/screens/create_playlist_screen.dart` (MODIFICAR)
- `lib/features/playlist/screens/playlist_detail_screen.dart` (MODIFICAR)
- `lib/config/routes.dart` (MODIFICAR)

### GA01-116
- `lib/features/library/screens/library_screen.dart` (MODIFICAR)

---

## 🚀 Orden de Implementación Recomendado

1. **Primero**: Implementar GA01-113 (crear playlist básica)
2. **Segundo**: Implementar GA01-114 (añadir/eliminar canciones)
3. **Tercero**: Implementar GA01-115 (editar/eliminar playlist)
4. **Cuarto**: Implementar GA01-116 (vista mejorada de playlists)

---

## ⚠️ Dependencias y Notas Importantes

### Dependencias de Packages (ya instaladas):
- `flutter_animate: ^4.5.0`
- `cached_network_image: ^3.3.1`
- `share_plus: ^10.1.2`
- `provider: ^6.1.1`

### Modelos Requeridos:
- `Playlist` - Ya existe
- `Song` - Ya existe
- `PlaylistService` - Ya existe
- `LibraryProvider` - Ya existe con métodos necesarios

### Rutas Existentes:
- `/playlist/create` - Ya existe
- `/playlist` - Ya existe (detalle)
- `/playlist/edit` - Se añade en GA01-115

---

## ✅ Checklist de Migración

Por cada subtarea, verificar:

- [ ] Código copiado exactamente como se indica
- [ ] Imports añadidos correctamente
- [ ] Métodos reemplazados/añadidos en orden correcto
- [ ] No hay errores de compilación
- [ ] Navegación funciona correctamente
- [ ] Feedback visual aparece correctamente
- [ ] Animaciones se ejecutan suavemente

---

## 📝 Mensajes de Commit Sugeridos

### GA01-113:
```
feat(playlists): Implementar creación de playlists con nombre (GA01-113)

- Formulario completo con validación
- Campo de descripción opcional
- Toggle público/privado
- Vista previa de playlist
- Feedback visual con SnackBars
```

### GA01-114:
```
feat(playlists): Implementar añadir/eliminar canciones (GA01-114)

- Nueva pantalla de selección de canciones
- Búsqueda y filtrado en tiempo real
- Selección múltiple
- Vista previa de audio
- Confirmación de eliminación
```

### GA01-115:
```
feat(playlists): Implementar editar y eliminar playlists (GA01-115)

- Edición completa de playlists
- Botón de eliminar con confirmación
- Menú de opciones en detalle
- Actualización de rutas
- Validación de permisos
```

### GA01-116:
```
feat(playlists): Mejorar vista de todas las playlists (GA01-116)

- FAB para crear playlists rápidamente
- Diseño mejorado con gradientes
- Estado vacío atractivo
- Actualización automática
- Navegación fluida
```

---

## 🎯 Resultado Final

Al completar todas las subtareas, tendrás:
- ✅ Sistema completo de gestión de playlists
- ✅ Crear, editar, eliminar playlists
- ✅ Añadir/eliminar canciones
- ✅ Vista mejorada de todas las playlists
- ✅ Diseño consistente y profesional
- ✅ UX intuitiva y fluida

---

**Fecha de creación**: 2025-11-19
**Autor**: Claude (Anthropic)
**Proyecto**: Audira - Sprint 3
