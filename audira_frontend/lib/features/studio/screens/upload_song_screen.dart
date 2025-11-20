// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/api/services/file_service.dart';
import '../../../core/models/genre.dart';

class UploadSongScreen extends StatefulWidget {
  const UploadSongScreen({super.key});

  @override
  State<UploadSongScreen> createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _priceController = TextEditingController(text: '9.99');
  final _durationController = TextEditingController();
  final _categoryController = TextEditingController();
  final MusicService _musicService = MusicService();
  final FileService _fileService = FileService();

  bool _showPreview = false;
  bool _isUploading = false;
  bool _isLoadingGenres = true;
  bool _publishNow = true; // Publicar inmediatamente por defecto
  double _uploadProgress = 0.0;
  String? _audioFileName;
  String? _audioFilePath;
  String? _imageFileName;
  String? _imageFilePath;
  int? _audioFileSizeBytes;
  String? _audioFileExtension;
  List<Genre> _availableGenres = [];
  final List<int> _selectedGenreIds = [];

  // Colaboradores
  final List<Map<String, String>> _collaborators = [];
  final _collaboratorNameController = TextEditingController();
  final _collaboratorRoleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _lyricsController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _categoryController.dispose();

    _collaboratorNameController.dispose();
    _collaboratorRoleController.dispose();
    super.dispose();
  }

  Future<void> _loadGenres() async {
    setState(() => _isLoadingGenres = true);
    try {
      final response = await _musicService.getAllGenres();
      if (response.success && response.data != null) {
        setState(() {
          _availableGenres = response.data!;
          _isLoadingGenres = false;
        });
      } else {
        setState(() => _isLoadingGenres = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error al cargar géneros: ${response.error}')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoadingGenres = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar géneros: $e')),
        );
      }
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final extension = file.extension?.toLowerCase();

        // Validar extensión
        if (extension == null ||
            !['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'].contains(extension)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Formato de audio no válido. Use MP3, WAV, FLAC, AAC, M4A u OGG')),
          );
          return;
        }

        // Validar tamaño (máximo 100MB)
        if (file.size > 100 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('El archivo es demasiado grande. Máximo 100MB')),
          );
          return;
        }

        // Validar que tengamos el path del archivo
        if (file.path == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No se pudo obtener la ruta del archivo')),
          );
          return;
        }

        setState(() {
          _audioFileName = file.name;
          _audioFilePath = file.path;
          _audioFileSizeBytes = file.size;
          _audioFileExtension = extension;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Audio seleccionado: ${file.name} (${_formatFileSize(file.size)})'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar audio: $e')),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickImageFile() async {
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
          _imageFileName = image.name;
          _imageFilePath = image.path;
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

  Future<void> _uploadSong() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar archivo de audio
    if (_audioFileName == null || _audioFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un archivo de audio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar géneros seleccionados
    if (_selectedGenreIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un género'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Paso 1: Subir archivo de audio (30% del progreso)
      setState(() => _uploadProgress = 0.1);
      final audioUploadResponse = await _fileService.uploadAudioFile(
        _audioFilePath!,
        onProgress: (sent, total) {
          setState(() {
            _uploadProgress = 0.1 + (sent / total) * 0.3;
          });
        },
      );

      if (!audioUploadResponse.success) {
        throw Exception('Error al subir audio: ${audioUploadResponse.error}');
      }

      final audioUrl = audioUploadResponse.data!.fileUrl;

      // Paso 2: Subir imagen de portada si existe (20% del progreso)
      setState(() => _uploadProgress = 0.4);
      String? coverImageUrl;
      if (_imageFilePath != null) {
        final imageUploadResponse = await _fileService.uploadImageFile(
          _imageFilePath!,
          onProgress: (sent, total) {
            setState(() {
              _uploadProgress = 0.4 + (sent / total) * 0.2;
            });
          },
        );

        if (!imageUploadResponse.success) {
          throw Exception(
              'Error al subir imagen: ${imageUploadResponse.error}');
        }

        coverImageUrl = imageUploadResponse.data!.fileUrl;
      }

      // Paso 3: Obtener artistId del usuario autenticado
      setState(() => _uploadProgress = 0.6);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final artistId = authProvider.currentUser?.id;

      if (artistId == null) {
        throw Exception(
            'No se pudo obtener el ID del artista. Inicia sesión nuevamente.');
      }

      // Paso 4: Preparar datos de la canción
      setState(() => _uploadProgress = 0.7);
      final songData = {
        'title': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'artistId': artistId,
        'price': double.parse(_priceController.text),
        'duration': int.parse(_durationController.text),
        'audioUrl': audioUrl,
        'coverImageUrl': coverImageUrl,
        'lyrics': _lyricsController.text.trim().isEmpty
            ? null
            : _lyricsController.text.trim(),
        'category': _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        'genreIds': _selectedGenreIds,
        'published': _publishNow, // Incluir estado de publicación
        'plays': 0,
        'productType': 'SONG',
        'collaborators': _collaborators,
      };

      // Paso 5: Crear la canción en el backend
      setState(() => _uploadProgress = 0.8);
      final createSongResponse = await _musicService.createSong(songData);

      if (!createSongResponse.success) {
        throw Exception('Error al crear canción: ${createSongResponse.error}');
      }

      setState(() => _uploadProgress = 1.0);

      // Éxito!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Canción subida exitosamente!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Pequeña espera para que el usuario vea el mensaje
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context);
      }
    } catch (e) {
      // Error
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir canción: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _addCollaborator() {
    if (_collaboratorNameController.text.trim().isEmpty ||
        _collaboratorRoleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa el nombre y rol del colaborador'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _collaborators.add({
        'name': _collaboratorNameController.text.trim(),
        'role': _collaboratorRoleController.text.trim(),
      });
      _collaboratorNameController.clear();
      _collaboratorRoleController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Colaborador añadido'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _removeCollaborator(int index) {
    setState(() {
      _collaborators.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Canción'),
        actions: [
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
                  Text('Subiendo canción... ${(_uploadProgress * 100).toInt()}%'),
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
            // Audio File - Enhanced
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.audiotrack, color: AppTheme.primaryBlue),
                title: Text(_audioFileName ?? 'Seleccionar Archivo de Audio *'),
                subtitle: _audioFileName != null && _audioFileSizeBytes != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Formato: ${_audioFileExtension?.toUpperCase() ?? 'N/A'}'),
                          Text(
                              'Tamaño: ${_formatFileSize(_audioFileSizeBytes!)}'),
                        ],
                      )
                    : const Text('MP3, WAV, FLAC, AAC, M4A, OGG (Máx 100MB)'),
                trailing: Icon(
                  _audioFileName != null
                      ? Icons.check_circle
                      : Icons.upload_file,
                  color: _audioFileName != null ? Colors.green : null,
                ),
                onTap: _pickAudioFile,
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 16),

            // Cover Image
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.image, color: AppTheme.primaryBlue),
                    title: Text(_imageFileName ?? 'Seleccionar Portada'),
                    subtitle: const Text('JPG, PNG (Opcional)'),
                    trailing: Icon(
                      _imageFileName != null
                          ? Icons.check_circle
                          : Icons.upload_file,
                      color: _imageFileName != null ? Colors.green : null,
                    ),
                    onTap: _pickImageFile,
                  ),
                  if (_imageFilePath != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_imageFilePath!),
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 50.ms),
            const SizedBox(height: 24),

            // Song Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Song Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.music_note),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter song name';
                }
                return null;
              },
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                helperText: 'Describe tu canción (estilo, mood, historia)',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa una descripción';
                }
                return null;
              },
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 16),

            // Géneros - Selección Múltiple
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category,
                            color: AppTheme.primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Géneros *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingGenres)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_availableGenres.isEmpty)
                      const Text(
                        'No hay géneros disponibles',
                        style: TextStyle(color: AppTheme.textGrey),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableGenres.map((genre) {
                          final isSelected =
                              _selectedGenreIds.contains(genre.id);
                          return FilterChip(
                            label: Text(genre.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedGenreIds.add(genre.id);
                                } else {
                                  _selectedGenreIds.remove(genre.id);
                                }
                              });
                            },
                            selectedColor:
                                AppTheme.primaryBlue.withValues(alpha: 0.3),
                            checkmarkColor: AppTheme.primaryBlue,
                            backgroundColor: AppTheme.surfaceBlack,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          );
                        }).toList(),
                      ),
                    if (_selectedGenreIds.isEmpty && !_isLoadingGenres)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Selecciona al menos un género',
                          style:
                              TextStyle(color: AppTheme.textGrey, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 175.ms),
            const SizedBox(height: 16),

            // Categoría/Metadata
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Categoría (Opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
                helperText: 'Ej: Single, Álbum, EP, Remix, Cover',
              ),
              maxLines: 1,
            ).animate().fadeIn(delay: 185.ms),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people,
                            color: AppTheme.primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Colaboradores (Opcional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _collaboratorNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _collaboratorRoleController,
                            decoration: const InputDecoration(
                              labelText: 'Rol',
                              border: OutlineInputBorder(),
                              isDense: true,
                              helperText: 'Ej: feat, productor',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addCollaborator,
                          icon: const Icon(Icons.add_circle,
                              color: AppTheme.primaryBlue),
                          tooltip: 'Añadir colaborador',
                        ),
                      ],
                    ),
                    if (_collaborators.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      ...List.generate(_collaborators.length, (index) {
                        final collab = _collaborators[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.person,
                                  size: 16, color: AppTheme.textGrey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${collab['name']} - ${collab['role']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeCollaborator(index),
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 190.ms),
            const SizedBox(height: 16),

            // Lyrics (Optional)
            TextFormField(
              controller: _lyricsController,
              decoration: const InputDecoration(
                labelText: 'Lyrics (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lyrics),
              ),
              maxLines: 5,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),

            // Price and Duration
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (sec) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 24),

            // Publicar inmediatamente
            Card(
              child: SwitchListTile(
                title: const Text(
                  '¿Publicar inmediatamente?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _publishNow
                      ? 'La canción será visible para todos los usuarios'
                      : 'La canción quedará oculta hasta que la publiques manualmente',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                value: _publishNow,
                onChanged: (value) {
                  setState(() {
                    _publishNow = value;
                  });
                },
                activeThumbColor: AppTheme.primaryBlue,
                secondary: Icon(
                  _publishNow ? Icons.visibility : Icons.visibility_off,
                  color: _publishNow ? AppTheme.primaryBlue : Colors.grey,
                ),
              ),
            ).animate().fadeIn(delay: 275.ms),
            const SizedBox(height: 24),

            // Upload Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadSong,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Upload Song'),
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
    final selectedGenres = _availableGenres
        .where((genre) => _selectedGenreIds.contains(genre.id))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image Preview
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlack,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _imageFilePath != null
                    ? Image.file(
                        File(_imageFilePath!),
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(Icons.music_note,
                            size: 100, color: AppTheme.primaryBlue),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Song Details
          Text(
            _nameController.text.isEmpty ? 'Song Name' : _nameController.text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _descriptionController.text.isEmpty
                ? 'Description'
                : _descriptionController.text,
            style: const TextStyle(color: AppTheme.textGrey),
          ),
          const SizedBox(height: 16),

          // Genres
          if (selectedGenres.isNotEmpty) ...[
            const Text(
              'Géneros',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedGenres.map((genre) {
                return Chip(
                  label: Text(genre.name),
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  labelStyle: const TextStyle(color: Colors.white),
                  avatar: const Icon(Icons.music_note,
                      color: AppTheme.primaryBlue, size: 16),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Category
          if (_categoryController.text.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.label, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  _categoryController.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Collaborators
          if (_collaborators.isNotEmpty) ...[
            const Text(
              'Colaboradores',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              color: AppTheme.surfaceBlack,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _collaborators.map((collab) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person,
                              color: AppTheme.primaryBlue, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            collab['name']!,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha:0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              collab['role']!,
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Audio File Info
          if (_audioFileName != null) ...[
            Card(
              color: AppTheme.surfaceBlack,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.audiotrack, color: AppTheme.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _audioFileName!,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_audioFileSizeBytes != null)
                            Text(
                              '${_audioFileExtension?.toUpperCase()} • ${_formatFileSize(_audioFileSizeBytes!)}',
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Price
          Row(
            children: [
              const Icon(Icons.attach_money, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                '\$${_priceController.text}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Duration
          if (_durationController.text.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.timer, color: AppTheme.textGrey),
                const SizedBox(width: 8),
                Text('${_durationController.text}s'),
              ],
            ),
          const SizedBox(height: 24),

          // Lyrics
          if (_lyricsController.text.isNotEmpty) ...[
            const Text(
              'Letra',
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
                _lyricsController.text,
                style:
                    const TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
