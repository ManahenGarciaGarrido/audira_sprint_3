# Guía de Migración: Gestión de Descargas por Subtarea

Esta guía detalla **TODOS** los cambios necesarios para implementar las funcionalidades de descargas de música, organizados por subtarea para facilitar la migración al repositorio original de GitHub.

---
 
## 📋 Índice de Subtareas

1. [GA01-135: Botón y permisos (solo si comprado)](#ga01-135-botón-y-permisos-solo-si-comprado)
2. [GA01-136: Descarga en formato original](#ga01-136-descarga-en-formato-original)
3. [GA01-137: Registro de descargas](#ga01-137-registro-de-descargas)

---

## 📦 Dependencias Requeridas

Antes de implementar cualquier subtarea, añadir estas dependencias a `pubspec.yaml`:

```yaml
dependencies:
  # ... dependencias existentes ...

  # Permissions
  permission_handler: ^11.0.1

  # Path Provider
  path_provider: ^2.1.1
```

Luego ejecutar:
```bash
flutter pub get
```

---

## GA01-135: Botón y permisos (solo si comprado)

### 📁 Archivos a Crear/Modificar

#### 1. CREAR: `lib/core/services/download_service.dart`

**Ubicación**: `audira_frontend/lib/core/services/download_service.dart`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```dart
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';
import '../models/downloaded_song.dart';

/// Servicio para gestionar descargas de canciones
/// GA01-135: Botón y permisos (solo si comprado)
/// GA01-136: Descarga en formato original
class DownloadService {
  final Dio _dio = Dio();
  static const String _downloadSubfolder = 'Audira/Downloads';

  /// Solicitar permisos de almacenamiento
  /// GA01-135: Botón y permisos
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Para Android 13+ (API 33+) no necesitamos permisos de storage para descargas
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        // En Android 13+, las apps tienen acceso a su propia carpeta sin permisos
        return true;
      }

      // Para Android 12 y anteriores
      final status = await Permission.storage.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS no requiere permisos explícitos para el app directory
      return true;
    }
    return false;
  }

  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      // Simulamos versión 33 para desarrollo
      // En producción esto vendría de device_info_plus
      return 33;
    }
    return 0;
  }

  /// Verificar si tiene permisos de almacenamiento
  Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) return true;
      return await Permission.storage.isGranted;
    } else if (Platform.isIOS) {
      return true;
    }
    return false;
  }

  /// Obtener directorio de descargas de la app
  /// GA01-136: Descarga en formato original
  Future<Directory> getDownloadsDirectory() async {
    Directory appDocDir;

    if (Platform.isAndroid) {
      // En Android usamos el directorio externo de la app
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        throw Exception('No se pudo acceder al almacenamiento externo');
      }
      appDocDir = dir;
    } else if (Platform.isIOS) {
      // En iOS usamos el directorio de documentos
      appDocDir = await getApplicationDocumentsDirectory();
    } else {
      throw UnsupportedError('Plataforma no soportada');
    }

    // Crear subcarpeta para descargas de Audira
    final downloadsDir = Directory('${appDocDir.path}/$_downloadSubfolder');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    return downloadsDir;
  }

  /// Descargar una canción
  /// GA01-136: Descarga en formato original
  Future<DownloadedSong?> downloadSong({
    required Song song,
    required Function(double) onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      // Verificar permisos
      final hasPermission = await hasStoragePermission();
      if (!hasPermission) {
        final granted = await requestStoragePermission();
        if (!granted) {
          throw Exception('Permisos de almacenamiento denegados');
        }
      }

      // Verificar que la canción tenga URL de audio
      if (song.audioUrl == null || song.audioUrl!.isEmpty) {
        throw Exception('La canción no tiene URL de audio');
      }

      // Obtener directorio de descargas
      final downloadsDir = await getDownloadsDirectory();

      // Generar nombre de archivo seguro
      final safeFileName = _sanitizeFileName(song.name);
      final format = _getAudioFormat(song.audioUrl!);
      final fileName = '${song.id}_$safeFileName.$format';
      final filePath = '${downloadsDir.path}/$fileName';

      print('Descargando canción: ${song.name}');
      print('URL: ${song.audioUrl}');
      print('Destino: $filePath');

      // Descargar archivo
      await _dio.download(
        song.audioUrl!,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
        options: Options(
          headers: {
            'Accept': 'audio/*',
          },
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 10),
        ),
      );

      // Verificar que el archivo se descargó correctamente
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Error al guardar el archivo');
      }

      final fileSize = await file.length();
      print('Descarga completada: $fileSize bytes');

      // Crear registro de descarga
      final downloadedSong = DownloadedSong(
        songId: song.id,
        songName: song.name,
        artistName: song.artistName,
        albumName: null, // Se puede obtener del álbum si está disponible
        localFilePath: filePath,
        fileSize: fileSize,
        format: format,
        bitrate: 320, // Valor por defecto, idealmente vendría del servidor
        downloadedAt: DateTime.now(),
        coverImageUrl: song.coverImageUrl,
        duration: song.duration,
      );

      return downloadedSong;
    } catch (e) {
      print('Error al descargar canción: $e');
      rethrow;
    }
  }

  /// Eliminar una canción descargada
  Future<bool> deleteDownloadedSong(String localFilePath) async {
    try {
      final file = File(localFilePath);
      if (await file.exists()) {
        await file.delete();
        print('Archivo eliminado: $localFilePath');
        return true;
      }
      return false;
    } catch (e) {
      print('Error al eliminar archivo: $e');
      return false;
    }
  }

  /// Verificar si un archivo existe
  Future<bool> fileExists(String localFilePath) async {
    try {
      final file = File(localFilePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Obtener tamaño de archivo
  Future<int> getFileSize(String localFilePath) async {
    try {
      final file = File(localFilePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Obtener espacio disponible en el dispositivo
  Future<int> getAvailableSpace() async {
    try {
      final dir = await getDownloadsDirectory();
      final stat = await dir.stat();
      // Nota: stat no proporciona espacio disponible directamente
      // Se necesitaría un plugin adicional como disk_space
      return 1024 * 1024 * 1024; // 1 GB por defecto
    } catch (e) {
      return 0;
    }
  }

  /// Limpiar todas las descargas
  Future<bool> clearAllDownloads() async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (await downloadsDir.exists()) {
        await downloadsDir.delete(recursive: true);
        await downloadsDir.create(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      print('Error al limpiar descargas: $e');
      return false;
    }
  }

  /// Sanitizar nombre de archivo
  String _sanitizeFileName(String fileName) {
    // Eliminar caracteres no permitidos en nombres de archivo
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, fileName.length > 50 ? 50 : fileName.length);
  }

  /// Obtener formato de audio de la URL
  String _getAudioFormat(String url) {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();

    if (path.endsWith('.mp3')) return 'mp3';
    if (path.endsWith('.flac')) return 'flac';
    if (path.endsWith('.wav')) return 'wav';
    if (path.endsWith('.m4a')) return 'm4a';
    if (path.endsWith('.aac')) return 'aac';
    if (path.endsWith('.ogg')) return 'ogg';

    // Por defecto asumimos mp3
    return 'mp3';
  }
}
```

#### 2. CREAR: `lib/features/downloads/widgets/download_button.dart`

**Ubicación**: `audira_frontend/lib/features/downloads/widgets/download_button.dart`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/download_provider.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/models/song.dart';
import '../../../core/models/downloaded_song.dart';

/// Botón de descarga para canciones
/// GA01-135: Botón y permisos (solo si comprado)
class DownloadButton extends StatefulWidget {
  final Song song;
  final bool showLabel;
  final VoidCallback? onDownloadComplete;

  const DownloadButton({
    super.key,
    required this.song,
    this.showLabel = false,
    this.onDownloadComplete,
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool _isProcessing = false;

  Future<void> _handleDownload() async {
    final downloadProvider = context.read<DownloadProvider>();
    final libraryProvider = context.read<LibraryProvider>();

    // GA01-135: Verificar que la canción esté comprada
    if (!libraryProvider.isSongPurchased(widget.song.id)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes comprar esta canción para descargarla'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Verificar permisos
      final hasPermission = await downloadProvider.hasStoragePermission();
      if (!hasPermission) {
        final granted = await downloadProvider.requestStoragePermission();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Se necesitan permisos de almacenamiento'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() => _isProcessing = false);
          return;
        }
      }

      // Iniciar descarga
      final success = await downloadProvider.downloadSong(widget.song);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.song.name} descargada correctamente'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          widget.onDownloadComplete?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al descargar la canción'),
              backgroundColor: Colors.red,
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
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    final downloadProvider = context.read<DownloadProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar descarga'),
        content: Text(
          '¿Estás seguro de que quieres eliminar la descarga de "${widget.song.name}"?',
        ),
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
      setState(() => _isProcessing = true);

      final success = await downloadProvider.deleteDownload(widget.song.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Descarga eliminada'
                  : 'Error al eliminar la descarga',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final libraryProvider = context.watch<LibraryProvider>();

    final isPurchased = libraryProvider.isSongPurchased(widget.song.id);
    final status = downloadProvider.getDownloadStatus(widget.song.id);
    final progress = downloadProvider.getDownloadProgress(widget.song.id);

    // No mostrar botón si no está comprada
    if (!isPurchased) {
      return const SizedBox.shrink();
    }

    // Mostrar progreso de descarga
    if (status == DownloadStatus.downloading && progress != null) {
      return _buildDownloadProgress(progress);
    }

    // Mostrar botón según estado
    if (status == DownloadStatus.downloaded) {
      return _buildDownloadedButton();
    }

    return _buildDownloadButton();
  }

  Widget _buildDownloadButton() {
    return widget.showLabel
        ? TextButton.icon(
            onPressed: _isProcessing ? null : _handleDownload,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: const Text('Descargar'),
          )
        : IconButton(
            onPressed: _isProcessing ? null : _handleDownload,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            tooltip: 'Descargar',
          );
  }

  Widget _buildDownloadedButton() {
    return widget.showLabel
        ? TextButton.icon(
            onPressed: _isProcessing ? null : _handleDelete,
            icon: const Icon(Icons.download_done_rounded, color: Colors.green),
            label: const Text('Descargada'),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          )
        : IconButton(
            onPressed: _isProcessing ? null : _handleDelete,
            icon: const Icon(Icons.download_done_rounded, color: Colors.green),
            tooltip: 'Descargada - Toca para eliminar',
          ).animate().scale(duration: 300.ms);
  }

  Widget _buildDownloadProgress(DownloadProgress progress) {
    return SizedBox(
      width: widget.showLabel ? null : 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.progress,
            strokeWidth: 3,
          ),
          Text(
            '${(progress.progress * 100).toInt()}%',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
```

#### 3. MODIFICAR: `lib/features/music/screens/song_detail_screen.dart`

**Acción**: Añadir import y botón de descarga

**Añadir import** (después de los otros imports):

```dart
import '../../../features/downloads/widgets/download_button.dart';
```

**Buscar la sección del botón de favoritos** (alrededor de la línea 621) y **añadir después del IconButton de favoritos**:

```dart
          ),
          // Botón de descarga
          // GA01-135: Botón y permisos (solo si comprado)
          if (_song != null) DownloadButton(song: _song!),
        ],
```

---

## GA01-136: Descarga en formato original

### 📁 Archivos a Crear/Modificar

#### 1. CREAR: `lib/core/models/downloaded_song.dart`

**Ubicación**: `audira_frontend/lib/core/models/downloaded_song.dart`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```dart
import 'package:equatable/equatable.dart';

/// Modelo para representar una canción descargada
/// GA01-137: Registro de descargas
class DownloadedSong extends Equatable {
  final int songId;
  final String songName;
  final String artistName;
  final String? albumName;
  final String localFilePath;
  final int fileSize; // en bytes
  final String format; // mp3, flac, wav, etc.
  final int bitrate; // en kbps
  final DateTime downloadedAt;
  final String? coverImageUrl;
  final int duration;

  const DownloadedSong({
    required this.songId,
    required this.songName,
    required this.artistName,
    this.albumName,
    required this.localFilePath,
    required this.fileSize,
    required this.format,
    required this.bitrate,
    required this.downloadedAt,
    this.coverImageUrl,
    required this.duration,
  });

  factory DownloadedSong.fromJson(Map<String, dynamic> json) {
    return DownloadedSong(
      songId: json['songId'] as int,
      songName: json['songName'] as String,
      artistName: json['artistName'] as String,
      albumName: json['albumName'] as String?,
      localFilePath: json['localFilePath'] as String,
      fileSize: json['fileSize'] as int,
      format: json['format'] as String,
      bitrate: json['bitrate'] as int,
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      coverImageUrl: json['coverImageUrl'] as String?,
      duration: json['duration'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songId': songId,
      'songName': songName,
      'artistName': artistName,
      'albumName': albumName,
      'localFilePath': localFilePath,
      'fileSize': fileSize,
      'format': format,
      'bitrate': bitrate,
      'downloadedAt': downloadedAt.toIso8601String(),
      'coverImageUrl': coverImageUrl,
      'duration': duration,
    };
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [
        songId,
        songName,
        artistName,
        albumName,
        localFilePath,
        fileSize,
        format,
        bitrate,
        downloadedAt,
        coverImageUrl,
        duration,
      ];
}

/// Estado de descarga de una canción
enum DownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  paused,
  failed,
}

/// Progreso de descarga
class DownloadProgress extends Equatable {
  final int songId;
  final DownloadStatus status;
  final double progress; // 0.0 - 1.0
  final int downloadedBytes;
  final int totalBytes;
  final String? error;

  const DownloadProgress({
    required this.songId,
    required this.status,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.error,
  });

  DownloadProgress copyWith({
    int? songId,
    DownloadStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    String? error,
  }) {
    return DownloadProgress(
      songId: songId ?? this.songId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        songId,
        status,
        progress,
        downloadedBytes,
        totalBytes,
        error,
      ];
}
```

#### 2. CREAR: `lib/core/providers/download_provider.dart`

**Ubicación**: `audira_frontend/lib/core/providers/download_provider.dart`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```dart
// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/song.dart';
import '../models/downloaded_song.dart';
import '../services/download_service.dart';

/// Provider para gestionar descargas de canciones
/// GA01-135: Botón y permisos (solo si comprado)
/// GA01-136: Descarga en formato original
/// GA01-137: Registro de descargas
class DownloadProvider with ChangeNotifier {
  final DownloadService _downloadService = DownloadService();

  // Registro de canciones descargadas
  // GA01-137: Registro de descargas
  List<DownloadedSong> _downloadedSongs = [];

  // Progreso de descargas activas
  final Map<int, DownloadProgress> _downloadProgress = {};

  // Tokens de cancelación para descargas activas
  final Map<int, CancelToken> _cancelTokens = {};

  // Getters
  List<DownloadedSong> get downloadedSongs => _downloadedSongs;
  Map<int, DownloadProgress> get downloadProgress => _downloadProgress;

  bool get isDownloading => _downloadProgress.values
      .any((p) => p.status == DownloadStatus.downloading);

  int get totalDownloads => _downloadedSongs.length;

  int get totalDownloadSize =>
      _downloadedSongs.fold(0, (sum, song) => sum + song.fileSize);

  /// Inicializar provider y cargar registro de descargas
  Future<void> initialize() async {
    await _loadDownloadRegistry();
  }

  /// Verificar si una canción está descargada
  bool isSongDownloaded(int songId) {
    return _downloadedSongs.any((song) => song.songId == songId);
  }

  /// Obtener canción descargada por ID
  DownloadedSong? getDownloadedSong(int songId) {
    try {
      return _downloadedSongs.firstWhere((song) => song.songId == songId);
    } catch (e) {
      return null;
    }
  }

  /// Obtener progreso de descarga de una canción
  DownloadProgress? getDownloadProgress(int songId) {
    return _downloadProgress[songId];
  }

  /// Obtener estado de descarga de una canción
  DownloadStatus getDownloadStatus(int songId) {
    if (isSongDownloaded(songId)) {
      return DownloadStatus.downloaded;
    }
    return _downloadProgress[songId]?.status ?? DownloadStatus.notDownloaded;
  }

  /// Solicitar permisos de almacenamiento
  /// GA01-135: Botón y permisos
  Future<bool> requestStoragePermission() async {
    return await _downloadService.requestStoragePermission();
  }

  /// Verificar permisos de almacenamiento
  Future<bool> hasStoragePermission() async {
    return await _downloadService.hasStoragePermission();
  }

  /// Descargar una canción
  /// GA01-136: Descarga en formato original
  Future<bool> downloadSong(Song song) async {
    try {
      // Verificar si ya está descargada
      if (isSongDownloaded(song.id)) {
        print('La canción ya está descargada');
        return false;
      }

      // Verificar si ya se está descargando
      if (_downloadProgress[song.id]?.status == DownloadStatus.downloading) {
        print('La canción ya se está descargando');
        return false;
      }

      // Crear token de cancelación
      final cancelToken = CancelToken();
      _cancelTokens[song.id] = cancelToken;

      // Inicializar progreso
      _downloadProgress[song.id] = DownloadProgress(
        songId: song.id,
        status: DownloadStatus.downloading,
        progress: 0.0,
      );
      notifyListeners();

      // Descargar canción
      final downloadedSong = await _downloadService.downloadSong(
        song: song,
        cancelToken: cancelToken,
        onProgress: (progress) {
          _downloadProgress[song.id] = _downloadProgress[song.id]!.copyWith(
            progress: progress,
            status: DownloadStatus.downloading,
          );
          notifyListeners();
        },
      );

      if (downloadedSong != null) {
        // Verificar que el archivo existe
        final exists = await _downloadService.fileExists(
          downloadedSong.localFilePath,
        );

        if (exists) {
          // Agregar a registro de descargas
          _downloadedSongs.add(downloadedSong);

          // Guardar registro
          await _saveDownloadRegistry();

          // Actualizar progreso
          _downloadProgress[song.id] = DownloadProgress(
            songId: song.id,
            status: DownloadStatus.downloaded,
            progress: 1.0,
            totalBytes: downloadedSong.fileSize,
            downloadedBytes: downloadedSong.fileSize,
          );

          // Limpiar token de cancelación
          _cancelTokens.remove(song.id);

          notifyListeners();
          print('Canción descargada exitosamente: ${song.name}');
          return true;
        } else {
          throw Exception('El archivo descargado no existe');
        }
      }

      return false;
    } catch (e) {
      print('Error al descargar canción: $e');

      // Actualizar progreso con error
      _downloadProgress[song.id] = DownloadProgress(
        songId: song.id,
        status: DownloadStatus.failed,
        error: e.toString(),
      );

      // Limpiar token de cancelación
      _cancelTokens.remove(song.id);

      notifyListeners();
      return false;
    }
  }

  /// Cancelar descarga
  Future<void> cancelDownload(int songId) async {
    final cancelToken = _cancelTokens[songId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Descarga cancelada por el usuario');
      _cancelTokens.remove(songId);
    }

    _downloadProgress[songId] = DownloadProgress(
      songId: songId,
      status: DownloadStatus.notDownloaded,
    );

    notifyListeners();
  }

  /// Eliminar canción descargada
  Future<bool> deleteDownload(int songId) async {
    try {
      final downloadedSong = getDownloadedSong(songId);
      if (downloadedSong == null) return false;

      // Eliminar archivo físico
      final deleted = await _downloadService.deleteDownloadedSong(
        downloadedSong.localFilePath,
      );

      if (deleted) {
        // Eliminar del registro
        _downloadedSongs.removeWhere((song) => song.songId == songId);

        // Eliminar progreso
        _downloadProgress.remove(songId);

        // Guardar registro actualizado
        await _saveDownloadRegistry();

        notifyListeners();
        print('Descarga eliminada: ${downloadedSong.songName}');
        return true;
      }

      return false;
    } catch (e) {
      print('Error al eliminar descarga: $e');
      return false;
    }
  }

  /// Limpiar todas las descargas
  Future<bool> clearAllDownloads() async {
    try {
      // Eliminar todos los archivos
      final success = await _downloadService.clearAllDownloads();

      if (success) {
        // Limpiar registro
        _downloadedSongs.clear();
        _downloadProgress.clear();
        _cancelTokens.clear();

        // Guardar registro vacío
        await _saveDownloadRegistry();

        notifyListeners();
        print('Todas las descargas han sido eliminadas');
        return true;
      }

      return false;
    } catch (e) {
      print('Error al limpiar descargas: $e');
      return false;
    }
  }

  /// Obtener canciones descargadas ordenadas por fecha
  List<DownloadedSong> getDownloadedSongsSorted({
    bool newestFirst = true,
  }) {
    final sorted = List<DownloadedSong>.from(_downloadedSongs);
    sorted.sort((a, b) {
      if (newestFirst) {
        return b.downloadedAt.compareTo(a.downloadedAt);
      } else {
        return a.downloadedAt.compareTo(b.downloadedAt);
      }
    });
    return sorted;
  }

  /// Buscar canciones descargadas
  List<DownloadedSong> searchDownloadedSongs(String query) {
    if (query.isEmpty) return _downloadedSongs;

    final lowerQuery = query.toLowerCase();
    return _downloadedSongs.where((song) {
      return song.songName.toLowerCase().contains(lowerQuery) ||
          song.artistName.toLowerCase().contains(lowerQuery) ||
          (song.albumName?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Verificar integridad de descargas
  /// Elimina registros de archivos que ya no existen
  Future<int> verifyDownloads() async {
    int removedCount = 0;

    for (final song in List<DownloadedSong>.from(_downloadedSongs)) {
      final exists = await _downloadService.fileExists(song.localFilePath);
      if (!exists) {
        _downloadedSongs.removeWhere((s) => s.songId == song.songId);
        removedCount++;
      }
    }

    if (removedCount > 0) {
      await _saveDownloadRegistry();
      notifyListeners();
      print('Se eliminaron $removedCount registros de archivos inexistentes');
    }

    return removedCount;
  }

  /// Guardar registro de descargas en SharedPreferences
  /// GA01-137: Registro de descargas
  Future<void> _saveDownloadRegistry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = jsonEncode(
        _downloadedSongs.map((s) => s.toJson()).toList(),
      );
      await prefs.setString('downloaded_songs', downloadsJson);
      print('Registro de descargas guardado: ${_downloadedSongs.length} canciones');
    } catch (e) {
      print('Error al guardar registro de descargas: $e');
    }
  }

  /// Cargar registro de descargas desde SharedPreferences
  /// GA01-137: Registro de descargas
  Future<void> _loadDownloadRegistry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = prefs.getString('downloaded_songs');

      if (downloadsJson != null) {
        final downloadsList = jsonDecode(downloadsJson) as List;
        _downloadedSongs = downloadsList
            .map((json) => DownloadedSong.fromJson(json))
            .toList();

        print('Registro de descargas cargado: ${_downloadedSongs.length} canciones');

        // Verificar integridad de archivos
        await verifyDownloads();
      }
    } catch (e) {
      print('Error al cargar registro de descargas: $e');
    }
  }

  /// Obtener estadísticas de descargas
  Map<String, dynamic> getDownloadStats() {
    final totalSize = totalDownloadSize;
    final totalSizeMB = (totalSize / (1024 * 1024)).toStringAsFixed(2);

    final formats = <String, int>{};
    for (final song in _downloadedSongs) {
      formats[song.format] = (formats[song.format] ?? 0) + 1;
    }

    return {
      'totalDownloads': totalDownloads,
      'totalSize': totalSize,
      'totalSizeMB': totalSizeMB,
      'formats': formats,
      'newestDownload': _downloadedSongs.isNotEmpty
          ? _downloadedSongs
              .reduce((a, b) =>
                  a.downloadedAt.isAfter(b.downloadedAt) ? a : b)
              .downloadedAt
          : null,
      'oldestDownload': _downloadedSongs.isNotEmpty
          ? _downloadedSongs
              .reduce((a, b) =>
                  a.downloadedAt.isBefore(b.downloadedAt) ? a : b)
              .downloadedAt
          : null,
    };
  }
}
```

#### 3. MODIFICAR: `lib/main.dart`

**Añadir import**:

```dart
import 'core/providers/download_provider.dart';
```

**Añadir provider** (en la lista de providers, línea ~32):

```dart
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
```

**Actualizar método `_checkAuthenticationChange`** para inicializar el DownloadProvider:

Buscar:
```dart
  void _checkAuthenticationChange() {
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
```

Reemplazar con:
```dart
  void _checkAuthenticationChange() {
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
```

Y actualizar la sección que carga los datos:
```dart
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await cartProvider.loadCart(currentUserId);
          await libraryProvider.loadLibrary(currentUserId);
          await downloadProvider.initialize();
        });
```

---

## GA01-137: Registro de descargas

### 📁 Archivos a Crear/Modificar

#### 1. CREAR: `lib/features/downloads/screens/downloads_screen.dart`

**Ubicación**: `audira_frontend/lib/features/downloads/screens/downloads_screen.dart`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/providers/download_provider.dart';
import '../../../core/providers/audio_provider.dart';
import '../../../core/models/downloaded_song.dart';
import '../../../core/models/song.dart';
import '../../../config/theme.dart';

/// Pantalla de descargas
/// GA01-137: Registro de descargas
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  Future<void> _clearAllDownloads() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todas las descargas'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todas las descargas? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final downloadProvider = context.read<DownloadProvider>();
      final success = await downloadProvider.clearAllDownloads();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Todas las descargas eliminadas'
                  : 'Error al eliminar descargas',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showDownloadStats() {
    final downloadProvider = context.read<DownloadProvider>();
    final stats = downloadProvider.getDownloadStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas de Descargas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total de descargas:', '${stats['totalDownloads']}'),
            _buildStatRow('Espacio utilizado:', '${stats['totalSizeMB']} MB'),
            const SizedBox(height: 16),
            if (stats['formats'] != null && (stats['formats'] as Map).isNotEmpty)
              ...[
                const Text(
                  'Formatos:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...((stats['formats'] as Map<String, int>).entries.map(
                  (e) => _buildStatRow('  ${e.key.toUpperCase()}:', '${e.value}'),
                )),
              ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();

    final downloadedSongs = _searchQuery.isEmpty
        ? downloadProvider.getDownloadedSongsSorted()
        : downloadProvider.searchDownloadedSongs(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar descargas...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              )
            : const Text('Descargas'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          if (downloadedSongs.isNotEmpty && !_isSearching)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'stats') {
                  _showDownloadStats();
                } else if (value == 'clear') {
                  _clearAllDownloads();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart),
                      SizedBox(width: 12),
                      Text('Estadísticas'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Eliminar todo', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: downloadedSongs.isEmpty
          ? _buildEmptyState()
          : _buildDownloadsList(downloadedSongs),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty
                ? Icons.download_outlined
                : Icons.search_off,
            size: 80,
            color: Colors.grey,
          ).animate().scale(duration: 300.ms),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No tienes descargas'
                : 'No se encontraron descargas',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Las canciones que descargues aparecerán aquí'
                : 'Intenta con otra búsqueda',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadsList(List<DownloadedSong> songs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final downloadedSong = songs[index];
        return _buildDownloadedSongCard(downloadedSong);
      },
    );
  }

  Widget _buildDownloadedSongCard(DownloadedSong downloadedSong) {
    final audioProvider = context.watch<AudioProvider>();
    final isPlaying = audioProvider.currentSong?.id == downloadedSong.songId &&
        audioProvider.isPlaying;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _playSong(downloadedSong),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: downloadedSong.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: downloadedSong.coverImageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[800],
                          child: const Icon(Icons.music_note, color: Colors.white54),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[800],
                          child: const Icon(Icons.music_note, color: Colors.white54),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[800],
                        child: const Icon(Icons.music_note, color: Colors.white54),
                      ),
              ),
              const SizedBox(width: 12),
              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      downloadedSong.songName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      downloadedSong.artistName,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.storage_rounded,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          downloadedSong.fileSizeFormatted,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.music_note,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          downloadedSong.format.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            timeago.format(
                              downloadedSong.downloadedAt,
                              locale: 'es',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Play button
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle : Icons.play_circle,
                  color: AppTheme.primaryBlue,
                  size: 32,
                ),
                onPressed: () => _playSong(downloadedSong),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteDownload(downloadedSong),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }

  Future<void> _playSong(DownloadedSong downloadedSong) async {
    // Convertir DownloadedSong a Song para reproducir
    final song = Song(
      id: downloadedSong.songId,
      artistId: 0, // No disponible en DownloadedSong
      artistName: downloadedSong.artistName,
      name: downloadedSong.songName,
      duration: downloadedSong.duration,
      price: 0,
      coverImageUrl: downloadedSong.coverImageUrl,
      audioUrl: downloadedSong.localFilePath, // Usar archivo local
    );

    final audioProvider = context.read<AudioProvider>();
    await audioProvider.playSong(song);
  }

  Future<void> _deleteDownload(DownloadedSong downloadedSong) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar descarga'),
        content: Text(
          '¿Estás seguro de que quieres eliminar la descarga de "${downloadedSong.songName}"?',
        ),
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
      final downloadProvider = context.read<DownloadProvider>();
      final success = await downloadProvider.deleteDownload(downloadedSong.songId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Descarga eliminada'
                  : 'Error al eliminar la descarga',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
```

#### 2. MODIFICAR: `lib/config/routes.dart`

**Añadir import**:

```dart
import '../features/downloads/screens/downloads_screen.dart';
```

**Añadir constante de ruta** (alrededor de la línea 76):

```dart
  static const String downloads = '/downloads';
```

**Añadir case en el switch** (antes del default, alrededor de la línea 230):

```dart
      case downloads:
        return MaterialPageRoute(builder: (_) => const DownloadsScreen());
```

#### 3. MODIFICAR: `lib/features/library/screens/library_screen.dart`

**Añadir imports**:

```dart
import '../../../core/providers/download_provider.dart';
import '../../../config/routes.dart';
```

**Cambiar TabController length** de 4 a 5 (línea ~27):

```dart
    _tabController = TabController(length: 5, vsync: this);
```

**Añadir tab de Descargas** (en el TabBar, línea ~91):

```dart
                  tabs: const [
                    Tab(text: 'Canciones'),
                    Tab(text: 'Álbumes'),
                    Tab(text: 'Playlists'),
                    Tab(text: 'Favoritos'),
                    Tab(text: 'Descargas'),  // AÑADIR ESTA LÍNEA
                  ],
```

**Añadir TabView de Descargas** (después del tab de Favoritos, línea ~182):

```dart
                    // Favorites
                    _buildFavoritesTab(libraryProvider),

                    // Downloads
                    // GA01-137: Registro de descargas
                    _buildDownloadsTab(context),  // AÑADIR ESTA LÍNEA
                  ],
```

**Añadir método `_buildDownloadsTab`** (antes del método `_buildEmptyState`, alrededor de línea 463):

```dart
  Widget _buildDownloadsTab(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, child) {
        final downloads = downloadProvider.downloadedSongs;

        if (downloads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.download_outlined,
                  size: 80,
                  color: AppTheme.textGrey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No tienes descargas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Las canciones que descargues aparecerán aquí',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.downloads);
                  },
                  icon: const Icon(Icons.explore),
                  label: const Text('Explorar música'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${downloads.length} canciones descargadas',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 14,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.downloads);
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Ver todas'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: downloads.length > 5 ? 5 : downloads.length,
                itemBuilder: (context, index) {
                  final download = downloads[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: AppTheme.surfaceBlack,
                    child: ListTile(
                      leading: download.coverImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                download.coverImageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 50,
                                  height: 50,
                                  color: AppTheme.darkBlue,
                                  child: const Icon(Icons.music_note,
                                      color: Colors.white),
                                ),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.darkBlue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.music_note,
                                  color: Colors.white),
                            ),
                      title: Text(
                        download.songName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            download.artistName,
                            style: const TextStyle(color: AppTheme.textGrey),
                          ),
                          const SizedBox(width: 8),
                          const Text('•', style: TextStyle(color: AppTheme.textGrey)),
                          const SizedBox(width: 8),
                          Text(
                            download.fileSizeFormatted,
                            style: const TextStyle(color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.download_done,
                            color: Colors.green[400],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: AppTheme.textGrey,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.downloads);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
```

---

## ✅ Checklist de Verificación

### GA01-135: Botón y permisos (solo si comprado)

- [ ] `lib/core/services/download_service.dart` creado
- [ ] `lib/features/downloads/widgets/download_button.dart` creado
- [ ] Import añadido en `song_detail_screen.dart`
- [ ] DownloadButton integrado en `song_detail_screen.dart`
- [ ] Permisos de almacenamiento funcionan correctamente
- [ ] Botón solo aparece para canciones compradas
- [ ] Descarga se inicia correctamente

### GA01-136: Descarga en formato original

- [ ] `lib/core/models/downloaded_song.dart` creado
- [ ] `lib/core/providers/download_provider.dart` creado
- [ ] DownloadProvider añadido a `main.dart`
- [ ] DownloadProvider se inicializa en login
- [ ] Archivos se descargan en formato original
- [ ] Progreso de descarga se muestra correctamente
- [ ] Archivos se guardan en directorio correcto

### GA01-137: Registro de descargas

- [ ] `lib/features/downloads/screens/downloads_screen.dart` creado
- [ ] Ruta añadida en `routes.dart`
- [ ] Tab de Descargas añadido en `library_screen.dart`
- [ ] Método `_buildDownloadsTab` añadido
- [ ] Registro se guarda en SharedPreferences
- [ ] Registro se carga al iniciar app
- [ ] Lista de descargas se muestra correctamente
- [ ] Búsqueda de descargas funciona
- [ ] Estadísticas se muestran correctamente
- [ ] Eliminar descarga funciona correctamente

---

## 📝 Notas Técnicas

### Orden Recomendado de Implementación

1. **Primero**: Actualizar `pubspec.yaml` y ejecutar `flutter pub get`
2. **Segundo**: Implementar GA01-136 (modelos y servicios base)
3. **Tercero**: Implementar GA01-135 (botón y permisos)
4. **Cuarto**: Implementar GA01-137 (pantalla de registro)

### Dependencias Entre Subtareas

- **GA01-135** depende de **GA01-136** (necesita los modelos y servicios)
- **GA01-137** depende de **GA01-136** (necesita los modelos)

### Arquitectura de Permisos

- Android 13+ (API 33+): No requiere permisos explícitos para el directorio de la app
- Android 12 y anteriores: Requiere permiso `WRITE_EXTERNAL_STORAGE`
- iOS: No requiere permisos explícitos para el directorio de documentos

### Formato de Audio

El servicio detecta automáticamente el formato basándose en la extensión de la URL:
- Soporta: mp3, flac, wav, m4a, aac, ogg
- Por defecto: mp3

### Almacenamiento

- **Android**: `/storage/emulated/0/Android/data/com.audira.app/files/Audira/Downloads/`
- **iOS**: `<App Documents Directory>/Audira/Downloads/`

### Persistencia

- Registro de descargas se guarda en `SharedPreferences`
- Clave: `downloaded_songs`
- Formato: JSON array

---

## 🚀 Comandos de Migración

### Commit Messages Sugeridos

```bash
# GA01-135
git add .
git commit -m "feat: Implementar botón de descarga y gestión de permisos (GA01-135)

- Añadir DownloadService con gestión de permisos
- Crear DownloadButton widget con verificación de compra
- Integrar botón en SongDetailScreen
- Soportar Android 13+ y versiones anteriores"

# GA01-136
git add .
git commit -m "feat: Implementar descarga de canciones en formato original (GA01-136)

- Crear modelo DownloadedSong con metadatos
- Implementar DownloadProvider para gestión de estado
- Añadir progreso de descarga en tiempo real
- Detectar formato de audio automáticamente
- Integrar con providers existentes"

# GA01-137
git add .
git commit -m "feat: Implementar registro y visualización de descargas (GA01-137)

- Crear DownloadsScreen con búsqueda y filtros
- Añadir tab de Descargas en LibraryScreen
- Implementar persistencia con SharedPreferences
- Añadir estadísticas de descargas
- Verificar integridad de archivos al inicio"
```

---

## 🔧 Testing

### Casos de Prueba GA01-135

1. Intentar descargar canción no comprada → Debe mostrar error
2. Descargar canción comprada → Debe solicitar permisos si es necesario
3. Denegar permisos → Debe mostrar mensaje apropiado
4. Descargar canción ya descargada → No debe descargar de nuevo

### Casos de Prueba GA01-136

1. Descargar canción MP3 → Debe guardar con extensión .mp3
2. Cancelar descarga en progreso → Debe detener descarga
3. Verificar archivo después de descarga → Debe existir en disco
4. Progreso de descarga → Debe actualizar de 0% a 100%

### Casos de Prueba GA01-137

1. Ver lista de descargas → Debe mostrar todas las canciones
2. Buscar descarga por nombre → Debe filtrar correctamente
3. Eliminar descarga → Debe eliminar archivo y registro
4. Ver estadísticas → Debe mostrar totales correctos
5. Reiniciar app → Descargas deben persistir

---

## ❗ Problemas Conocidos y Soluciones

### Problema: Archivos huérfanos

**Síntoma**: Archivos descargados no aparecen en la lista

**Solución**: El método `verifyDownloads()` se ejecuta automáticamente al iniciar para limpiar registros huérfanos

### Problema: Permisos en Android 13+

**Síntoma**: Error de permisos en Android 13+

**Solución**: El código ya maneja Android 13+ correctamente sin solicitar permisos

### Problema: Descarga no inicia

**Síntoma**: Botón de descarga no hace nada

**Solución**: Verificar que:
1. La canción tenga `audioUrl`
2. El usuario esté autenticado
3. La canción esté comprada
4. Hay permisos de almacenamiento

---

## 📞 Contacto y Soporte

Para preguntas sobre esta guía de migración, consultar la documentación del proyecto o contactar al equipo de desarrollo.
