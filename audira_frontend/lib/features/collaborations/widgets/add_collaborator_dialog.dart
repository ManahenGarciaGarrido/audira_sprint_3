// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/api/services/collaboration_service.dart';

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
  final _artistIdController = TextEditingController();
  final _roleController = TextEditingController();
  final CollaborationService _collaborationService = CollaborationService();

  String _entityType = 'song'; // 'song' or 'album'
  int? _selectedEntityId;
  bool _isLoading = false;

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
    _artistIdController.dispose();
    _roleController.dispose();
    super.dispose();
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

    setState(() => _isLoading = true);

    try {
      final artistId = int.parse(_artistIdController.text);
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

              // Artist ID
              const Text(
                'ID del artista',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _artistIdController,
                decoration: const InputDecoration(
                  hintText: 'Ingresa el ID del artista',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.backgroundBlack,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el ID del artista';
                  }
                  if (int.tryParse(value) == null) {
                    return 'ID inválido';
                  }
                  return null;
                },
              ),
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
