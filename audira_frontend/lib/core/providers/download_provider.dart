// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
      print(
          'Registro de descargas guardado: ${_downloadedSongs.length} canciones');
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
        _downloadedSongs =
            downloadsList.map((json) => DownloadedSong.fromJson(json)).toList();

        print(
            'Registro de descargas cargado: ${_downloadedSongs.length} canciones');

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
              .reduce((a, b) => a.downloadedAt.isAfter(b.downloadedAt) ? a : b)
              .downloadedAt
          : null,
      'oldestDownload': _downloadedSongs.isNotEmpty
          ? _downloadedSongs
              .reduce((a, b) => a.downloadedAt.isBefore(b.downloadedAt) ? a : b)
              .downloadedAt
          : null,
    };
  }
}
