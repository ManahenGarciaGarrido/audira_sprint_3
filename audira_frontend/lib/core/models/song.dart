import 'package:equatable/equatable.dart';

class Song extends Equatable {
  final int id;
  final int artistId;
  final String artistName;
  final int? albumId;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? category;
  final String? coverImageUrl;
  final List<int> genreIds;
  final int duration;
  final String? audioUrl;
  final String? lyrics;
  final int? trackNumber;
  final int plays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Song({
    required this.id,
    required this.artistId,
    required this.artistName,
    this.albumId,
    required this.name,
    this.description,
    required this.price,
    this.stock = 0,
    this.category,
    this.coverImageUrl,
    this.genreIds = const [],
    required this.duration,
    this.audioUrl,
    this.lyrics,
    this.trackNumber,
    this.plays = 0,
    this.createdAt,
    this.updatedAt,
  });

  String get durationFormatted {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as int,
      artistId: json['artistId'] as int,
      artistName: json['artistName'] as String? ?? 'Artista Desconocido',
      albumId: json['albumId'] as int?,
      name: json['title'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int? ?? 0,
      category: json['category'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      genreIds:
          (json['genreIds'] as List<dynamic>?)?.map((e) => e as int).toList() ??
              [],
      duration: json['duration'] as int,
      audioUrl: json['audioUrl'] as String?,
      lyrics: json['lyrics'] as String?,
      trackNumber: json['trackNumber'] as int?,
      plays: json['plays'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'artistId': artistId,
      'artistName': artistName,
      'albumId': albumId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'coverImageUrl': coverImageUrl,
      'genreIds': genreIds,
      'duration': duration,
      'audioUrl': audioUrl,
      'lyrics': lyrics,
      'trackNumber': trackNumber,
      'plays': plays,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Song copyWith({
    int? id,
    int? artistId,
    String? artistName,
    int? albumId,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? category,
    String? coverImageUrl,
    List<int>? genreIds,
    int? duration,
    String? audioUrl,
    String? lyrics,
    int? trackNumber,
    int? plays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Song(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
      albumId: albumId ?? this.albumId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      genreIds: genreIds ?? this.genreIds,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      lyrics: lyrics ?? this.lyrics,
      trackNumber: trackNumber ?? this.trackNumber,
      plays: plays ?? this.plays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        artistId,
        artistName,
        albumId,
        name,
        description,
        price,
        stock,
        category,
        coverImageUrl,
        genreIds,
        duration,
        audioUrl,
        lyrics,
        trackNumber,
        plays,
        createdAt,
        updatedAt,
      ];
}
