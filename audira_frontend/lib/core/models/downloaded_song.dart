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
