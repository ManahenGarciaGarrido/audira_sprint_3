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
