import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/services/file_service.dart';

class FileUploadDemoScreen extends StatefulWidget {
  const FileUploadDemoScreen({super.key});

  @override
  State<FileUploadDemoScreen> createState() => _FileUploadDemoScreenState();
}

class _FileUploadDemoScreenState extends State<FileUploadDemoScreen> {
  final FileService _fileService = FileService();
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedAudioPath;
  String? _selectedImagePath;
  String? _uploadedAudioUrl;
  String? _uploadedImageUrl;
  String? _compressedFileUrl;
  bool _isUploading = false;
  bool _isCompressing = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demostración de Subida de Archivos'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección de Audio
            _buildSectionTitle('Subir Archivo de Audio'),
            _buildAudioSection(),
            const SizedBox(height: 24),

            // Sección de Imagen
            _buildSectionTitle('Subir Imagen'),
            _buildImageSection(),
            const SizedBox(height: 24),

            // Sección de Compresión
            _buildSectionTitle('Comprimir Archivos'),
            _buildCompressionSection(),
            const SizedBox(height: 24),

            // Status Message
            if (_statusMessage != null) _buildStatusMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildAudioSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAudioFile,
              icon: const Icon(Icons.audiotrack),
              label: const Text('Seleccionar Audio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.all(12),
              ),
            ),
            if (_selectedAudioPath != null) ...[
              const SizedBox(height: 12),
              Text(
                'Archivo seleccionado:\n${_selectedAudioPath!.split('/').last}',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadAudio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Subir Audio'),
              ),
            ],
            if (_uploadedAudioUrl != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(height: 8),
                    const Text('Audio subido exitosamente',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _uploadedAudioUrl!,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedImagePath != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_selectedImagePath!),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Subir Imagen'),
              ),
            ],
            if (_uploadedImageUrl != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(height: 8),
                    const Text('Imagen subida exitosamente',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _uploadedImageUrl!,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompressionSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Comprime los archivos subidos en un ZIP',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: (_uploadedAudioUrl != null || _uploadedImageUrl != null) &&
                      !_isCompressing
                  ? _compressFiles
                  : null,
              icon: const Icon(Icons.compress),
              label: const Text('Comprimir Archivos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(12),
              ),
            ),
            if (_isCompressing)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_compressedFileUrl != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.archive, color: Colors.orange),
                    const SizedBox(height: 8),
                    const Text('Archivos comprimidos exitosamente',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _compressedFileUrl!,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Text(
        _statusMessage!,
        style: const TextStyle(color: Colors.blue),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'flac', 'midi', 'mid'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAudioPath = result.files.single.path;
          _uploadedAudioUrl = null;
          _statusMessage = 'Archivo de audio seleccionado';
        });
      }
    } catch (e) {
      _showError('Error al seleccionar audio: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
          _uploadedImageUrl = null;
          _statusMessage = 'Imagen seleccionada';
        });
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _uploadAudio() async {
    if (_selectedAudioPath == null) return;

    setState(() {
      _isUploading = true;
      _statusMessage = 'Subiendo audio...';
    });

    try {
      final response = await _fileService.uploadAudioFile(_selectedAudioPath!);

      if (response.success && response.data != null) {
        setState(() {
          _uploadedAudioUrl = response.data!.fileUrl;
          _statusMessage = 'Audio subido exitosamente';
          _isUploading = false;
        });
      } else {
        _showError(response.error ?? 'Error desconocido');
        setState(() => _isUploading = false);
      }
    } catch (e) {
      _showError('Error al subir audio: $e');
      setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImagePath == null) return;

    setState(() {
      _isUploading = true;
      _statusMessage = 'Subiendo imagen...';
    });

    try {
      final response = await _fileService.uploadImageFile(_selectedImagePath!);

      if (response.success && response.data != null) {
        setState(() {
          _uploadedImageUrl = response.data!.fileUrl;
          _statusMessage = 'Imagen subida exitosamente';
          _isUploading = false;
        });
      } else {
        _showError(response.error ?? 'Error desconocido');
        setState(() => _isUploading = false);
      }
    } catch (e) {
      _showError('Error al subir imagen: $e');
      setState(() => _isUploading = false);
    }
  }

  Future<void> _compressFiles() async {
    List<String> filePaths = [];

    // Extraer las rutas relativas de los archivos subidos
    if (_uploadedAudioUrl != null) {
      final audioPath = _extractFilePath(_uploadedAudioUrl!);
      if (audioPath != null) filePaths.add(audioPath);
    }
    if (_uploadedImageUrl != null) {
      final imagePath = _extractFilePath(_uploadedImageUrl!);
      if (imagePath != null) filePaths.add(imagePath);
    }

    if (filePaths.isEmpty) {
      _showError('No hay archivos para comprimir');
      return;
    }

    setState(() {
      _isCompressing = true;
      _statusMessage = 'Comprimiendo archivos...';
    });

    try {
      final response = await _fileService.compressFiles(filePaths);

      if (response.success && response.data != null) {
        setState(() {
          _compressedFileUrl = response.data!.zipFileUrl;
          _statusMessage =
              'Archivos comprimidos. Ratio: ${response.data!.compressionRatio}';
          _isCompressing = false;
        });
      } else {
        _showError(response.error ?? 'Error desconocido');
        setState(() => _isCompressing = false);
      }
    } catch (e) {
      _showError('Error al comprimir archivos: $e');
      setState(() => _isCompressing = false);
    }
  }

  String? _extractFilePath(String url) {
    // Extrae la ruta relativa del archivo desde la URL completa
    // Ejemplo: "http://host:port/api/files/audio-files/abc.mp3" -> "audio-files/abc.mp3"
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    final fileIndex = segments.indexOf('files');
    if (fileIndex != -1 && fileIndex < segments.length - 1) {
      return segments.sublist(fileIndex + 1).join('/');
    }
    return null;
  }

  void _showError(String message) {
    setState(() {
      _statusMessage = 'Error: $message';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
