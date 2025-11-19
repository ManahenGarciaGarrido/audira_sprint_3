// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/api/services/file_service.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';

class UploadAlbumScreen extends StatefulWidget {
  const UploadAlbumScreen({super.key});

  @override
  State<UploadAlbumScreen> createState() => _UploadAlbumScreenState();
}

class _UploadAlbumScreenState extends State<UploadAlbumScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '19.99');
  final _releaseDateController = TextEditingController();

  bool _showPreview = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _coverImagePath;
  List<Song> _selectedSongs = [];
  Album? _createdAlbum;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _releaseDateController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _coverImagePath = image.path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imagen seleccionada: ${image.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _selectSongs() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    try {
      final musicService = MusicService();
      final response = await musicService.getSongsByArtist(
        authProvider.currentUser!.id,
      );

      if (!response.success || response.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No se pudieron cargar las canciones')),
          );
        }
        return;
      }

      final songs = response.data!;
      if (!mounted) return;

      final selectedSongs = await showDialog<List<Song>>(
        context: context,
        builder: (context) => _SongSelectionDialog(
          songs: songs,
          alreadySelected: _selectedSongs,
        ),
      );

      if (selectedSongs != null) {
        setState(() => _selectedSongs = selectedSongs);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _uploadAlbum() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor agrega al menos una canción')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final musicService = MusicService();
      final fileService = FileService();

      // Paso 1: Subir la imagen de portada si existe
      String? coverImageUrl;
      if (_coverImagePath != null) {
        setState(() => _uploadProgress = 0.2);

        final imageUploadResponse = await fileService.uploadImageFile(
          _coverImagePath!,
          onProgress: (sent, total) {
            setState(() {
              _uploadProgress = 0.2 + (sent / total) * 0.3;
            });
          },
        );

        if (!imageUploadResponse.success) {
          throw Exception(
              'Error al subir imagen: ${imageUploadResponse.error}');
        }

        coverImageUrl = imageUploadResponse.data!.fileUrl;
      }

      // Paso 2: Crear el álbum con la URL de la imagen
      setState(() => _uploadProgress = 0.6);

      final albumData = {
        'title': _titleController.text,
        'artistId': authProvider.currentUser!.id,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'coverImageUrl': coverImageUrl,
        'genreIds': [],
        'releaseDate': _releaseDateController.text.isNotEmpty
            ? _releaseDateController.text
            : null,
        'discountPercentage': 15.0,
        'songIds': _selectedSongs.map((s) => s.id).toList(),
      };

      final createResponse = await musicService.createAlbum(albumData);

      if (!createResponse.success || createResponse.data == null) {
        throw Exception('Error al crear el álbum');
      }

      setState(() {
        _createdAlbum = createResponse.data!;
        _uploadProgress = 1.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Álbum creado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );

        // Mostrar diálogo para publicar
        _showPublishDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear álbum: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _showPublishDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Publicar álbum?'),
        content: const Text(
          '¿Deseas publicar el álbum ahora para que esté visible para los usuarios?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Publicar después'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Publicar ahora'),
          ),
        ],
      ),
    );

    if (result == true && _createdAlbum != null) {
      await _publishAlbum(true);
    } else {
      // Volver a la pantalla anterior
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _publishAlbum(bool publish) async {
    if (_createdAlbum == null) return;

    try {
      final musicService = MusicService();
      final response = await musicService.publishAlbum(
        _createdAlbum!.id,
        publish,
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                publish
                    ? '¡Álbum publicado exitosamente!'
                    : 'Álbum despublicado',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Volver a la pantalla anterior después de publicar
          if (publish) {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al publicar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Álbum'),
        actions: [
          if (_createdAlbum == null)
            IconButton(
              icon: Icon(_showPreview ? Icons.edit : Icons.preview),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() => _showPreview = !_showPreview);
                }
              },
            ),
        ],
      ),
      body: _showPreview ? _buildPreview() : _buildForm(),
      bottomNavigationBar: _isUploading
          ? Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Subiendo... ${(_uploadProgress * 100).toInt()}%'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _uploadProgress),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección: Portada del álbum
            Card(
              child: InkWell(
                onTap: _pickCoverImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBlack,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _coverImagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_coverImagePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 60,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toca para seleccionar portada',
                              style: TextStyle(color: AppTheme.textGrey),
                            ),
                          ],
                        ),
                ),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 24),

            // Información del álbum
            Text(
              'Información del Álbum',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título del Álbum *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.album),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ).animate().fadeIn(delay: 50.ms),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _releaseDateController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Lanzamiento',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        _releaseDateController.text =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 24),

            // Sección: Canciones
            Text(
              'Canciones del Álbum',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.music_note, color: AppTheme.primaryBlue),
                title: Text(_selectedSongs.isEmpty
                    ? 'Agregar Canciones'
                    : '${_selectedSongs.length} canciones seleccionadas'),
                trailing: const Icon(Icons.add),
                onTap: _selectSongs,
              ),
            ).animate().fadeIn(delay: 200.ms),

            if (_selectedSongs.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._selectedSongs.asMap().entries.map((entry) {
                final index = entry.key;
                final song = entry.value;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(song.name),
                    subtitle: Text(song.durationFormatted),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() => _selectedSongs.removeAt(index));
                      },
                    ),
                  ),
                ).animate().fadeIn(delay: (250 + index * 50).ms);
              }),
            ],

            const SizedBox(height: 24),

            // Botón de crear álbum
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadAlbum,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Crear Álbum'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).scale(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portada
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlack,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: _coverImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_coverImagePath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.album,
                      size: 100,
                      color: AppTheme.primaryBlue,
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Información del álbum
          Center(
            child: Text(
              _titleController.text.isEmpty
                  ? 'Título del Álbum'
                  : _titleController.text,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),

          if (_descriptionController.text.isNotEmpty) ...[
            Center(
              child: Text(
                _descriptionController.text,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Precio
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.attach_money,
                    color: AppTheme.primaryBlue, size: 32),
                Text(
                  _priceController.text,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Precio con descuento
          Center(
            child: Text(
              'Precio con descuento: \$${(double.parse(_priceController.text) * 0.85).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Lista de canciones
          const Divider(),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lista de Canciones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_selectedSongs.length} canciones',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_selectedSongs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No hay canciones seleccionadas',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              ),
            )
          else
            ..._selectedSongs.asMap().entries.map((entry) {
              final index = entry.key;
              final song = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text('${index + 1}'),
                ),
                title: Text(song.name),
                subtitle: Text(song.durationFormatted),
                trailing: Icon(
                  Icons.play_circle_outline,
                  color: AppTheme.primaryBlue,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SongSelectionDialog extends StatefulWidget {
  final List<Song> songs;
  final List<Song> alreadySelected;

  const _SongSelectionDialog({
    required this.songs,
    this.alreadySelected = const [],
  });

  @override
  State<_SongSelectionDialog> createState() => _SongSelectionDialogState();
}

class _SongSelectionDialogState extends State<_SongSelectionDialog> {
  late Set<int> _selectedIndices;

  @override
  void initState() {
    super.initState();
    _selectedIndices = {};

    // Preseleccionar canciones ya seleccionadas
    for (var selectedSong in widget.alreadySelected) {
      final index = widget.songs.indexWhere((s) => s.id == selectedSong.id);
      if (index != -1) {
        _selectedIndices.add(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Canciones'),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.songs.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No tienes canciones disponibles.\nSube canciones primero.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.songs.length,
                itemBuilder: (context, index) {
                  final song = widget.songs[index];
                  final isSelected = _selectedIndices.contains(index);

                  return CheckboxListTile(
                    title: Text(song.name),
                    subtitle: Text(song.durationFormatted),
                    value: isSelected,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIndices.add(index);
                        } else {
                          _selectedIndices.remove(index);
                        }
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: widget.songs.isEmpty
              ? null
              : () {
                  final selectedSongs = _selectedIndices
                      .map((index) => widget.songs[index])
                      .toList();
                  Navigator.pop(context, selectedSongs);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
          ),
          child: Text('Seleccionar (${_selectedIndices.length})'),
        ),
      ],
    );
  }
}
