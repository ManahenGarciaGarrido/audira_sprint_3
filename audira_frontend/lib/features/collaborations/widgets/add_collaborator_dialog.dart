// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/models/user.dart';
import '../../../core/api/services/collaboration_service.dart';
import '../../../core/api/services/user_service.dart';

/// Dialog for inviting collaborators to songs or albums
/// GA01-154: Añadir colaboradores
class AddCollaboratorDialog extends StatefulWidget {
  final List<Song> songs;
  final List<Album> albums;

  const AddCollaboratorDialog({
    super.key,
    required this.songs,
    required this.albums,
  });

  @override
  State<AddCollaboratorDialog> createState() => _AddCollaboratorDialogState();
}

class _AddCollaboratorDialogState extends State<AddCollaboratorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _roleController = TextEditingController();
  final CollaborationService _collaborationService = CollaborationService();
  final UserService _userService = UserService();

  String _entityType = 'song'; // 'song' or 'album'
  int? _selectedEntityId;
  User? _selectedArtist;
  bool _isLoading = false;
  bool _isSearching = false;
  List<User> _searchResults = [];

  final List<String> _suggestedRoles = [
    'Artista destacado',
    'Productor',
    'Compositor',
    'Vocalista',
    'Instrumentista',
    'Mezclador',
    'Masterizador',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _searchArtists(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final response = await _userService.searchArtists(query);
      if (response.success && response.data != null) {
        setState(() {
          _searchResults = response.data!;
        });
      } else {
        setState(() => _searchResults = []);
      }
    } catch (e) {
      setState(() => _searchResults = []);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _inviteCollaborator() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEntityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una canción o álbum'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedArtist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un artista'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final artistId = _selectedArtist!.id;
      final role = _roleController.text.trim();

      final response = _entityType == 'song'
          ? await _collaborationService.inviteCollaboratorToSong(
              songId: _selectedEntityId!,
              artistId: artistId,
              role: role,
            )
          : await _collaborationService.inviteCollaboratorToAlbum(
              albumId: _selectedEntityId!,
              artistId: artistId,
              role: role,
            );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Colaborador invitado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        throw Exception(response.error ?? 'Error desconocido');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceBlack,
      title: const Row(
        children: [
          Icon(Icons.person_add, color: AppTheme.primaryBlue),
          SizedBox(width: 12),
          Text('Invitar Colaborador'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Entity type selection
              const Text(
                'Tipo de contenido',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'song',
                    label: Text('Canción'),
                    icon: Icon(Icons.music_note),
                  ),
                  ButtonSegment(
                    value: 'album',
                    label: Text('Álbum'),
                    icon: Icon(Icons.album),
                  ),
                ],
                selected: {_entityType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _entityType = newSelection.first;
                    _selectedEntityId = null; // Reset selection
                  });
                },
              ),
              const SizedBox(height: 16),

              // Entity selection
              Text(
                _entityType == 'song'
                    ? 'Seleccionar canción'
                    : 'Seleccionar álbum',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (_entityType == 'song')
                _buildSongDropdown()
              else
                _buildAlbumDropdown(),

              const SizedBox(height: 16),

              // Artist Search with Autocomplete
              const Text(
                'Buscar artista',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildArtistAutocomplete(),

              const SizedBox(height: 16),

              // Role
              const Text(
                'Rol del colaborador',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Productor, Compositor, etc.',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.backgroundBlack,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el rol';
                  }
                  if (value.trim().length < 2) {
                    return 'El rol debe tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Role suggestions
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _suggestedRoles.map((role) {
                  return ActionChip(
                    label: Text(
                      role,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      _roleController.text = role;
                    },
                    backgroundColor: AppTheme.surfaceBlack,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _inviteCollaborator,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
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
              : const Text('Invitar'),
        ),
      ],
    );
  }

  Widget _buildArtistAutocomplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Escribe el nombre del artista',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _selectedArtist != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _selectedArtist = null;
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: AppTheme.backgroundBlack,
          ),
          onChanged: (value) {
            _searchArtists(value);
            // Clear selection if user is typing
            if (_selectedArtist != null) {
              setState(() => _selectedArtist = null);
            }
          },
          validator: (value) {
            if (_selectedArtist == null) {
              return 'Por favor selecciona un artista de la lista';
            }
            return null;
          },
        ),

        // Selected artist display
        if (_selectedArtist != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text(
                    _selectedArtist!.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedArtist!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '@${_selectedArtist!.username} • ID: ${_selectedArtist!.id}',
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          ),
        ],

        // Search results dropdown
        if (_searchResults.isNotEmpty && _selectedArtist == null) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppTheme.backgroundBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.textGrey.withValues(alpha: 0.3),
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final artist = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue,
                    child: Text(
                      artist.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  title: Text(artist.name),
                  subtitle: Text(
                    '@${artist.username}',
                    style: const TextStyle(color: AppTheme.textGrey),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    setState(() {
                      _selectedArtist = artist;
                      _searchController.text = artist.name;
                      _searchResults = [];
                    });
                  },
                );
              },
            ),
          ),
        ],

        // Helper text
        if (_searchResults.isEmpty &&
            _searchController.text.isNotEmpty &&
            !_isSearching &&
            _selectedArtist == null) ...[
          const SizedBox(height: 8),
          Text(
            _searchController.text.length < 2
                ? 'Escribe al menos 2 caracteres para buscar'
                : 'No se encontraron artistas',
            style: const TextStyle(
              color: AppTheme.textGrey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSongDropdown() {
    if (widget.songs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.textGrey.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.textGrey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No tienes canciones publicadas',
                style: TextStyle(color: AppTheme.textGrey),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedEntityId,
      decoration: const InputDecoration(
        hintText: 'Selecciona una canción',
        prefixIcon: Icon(Icons.music_note),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: AppTheme.backgroundBlack,
      ),
      items: widget.songs.map((song) {
        return DropdownMenuItem(
          value: song.id,
          child: Text(
            song.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedEntityId = value);
      },
      validator: (value) {
        if (value == null) {
          return 'Por favor selecciona una canción';
        }
        return null;
      },
    );
  }

  Widget _buildAlbumDropdown() {
    if (widget.albums.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.textGrey.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.textGrey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No tienes álbumes publicados',
                style: TextStyle(color: AppTheme.textGrey),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedEntityId,
      decoration: const InputDecoration(
        hintText: 'Selecciona un álbum',
        prefixIcon: Icon(Icons.album),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: AppTheme.backgroundBlack,
      ),
      items: widget.albums.map((album) {
        return DropdownMenuItem(
          value: album.id,
          child: Text(
            album.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedEntityId = value);
      },
      validator: (value) {
        if (value == null) {
          return 'Por favor selecciona un álbum';
        }
        return null;
      },
    );
  }
}
