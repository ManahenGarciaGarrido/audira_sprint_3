import 'package:equatable/equatable.dart';

class Album extends Equatable {
  final int id;
  final int artistId;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? category;
  final String? coverImageUrl;
  final List<int> genreIds;
  final DateTime? releaseDate;
  final double discountPercentage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool published;
  final int? songCount;

  const Album({
    required this.id,
    required this.artistId,
    required this.name,
    this.description,
    required this.price,
    this.stock = 0,
    this.category,
    this.coverImageUrl,
    this.genreIds = const [],
    this.releaseDate,
    this.discountPercentage = 15.0,
    this.createdAt,
    this.updatedAt,
    this.published = false,
    this.songCount,
  });

  double get discountedPrice {
    return price * (1 - discountPercentage / 100);
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as int,
      artistId: json['artistId'] as int,
      name: json['title'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int? ?? 0,
      category: json['category'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      genreIds:
          (json['genreIds'] as List<dynamic>?)?.map((e) => e as int).toList() ??
              [],
      releaseDate: json['releaseDate'] != null
          ? DateTime.parse(json['releaseDate'] as String)
          : null,
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 15.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      published: json['published'] as bool? ?? false,
      songCount: json['songCount'] as int?, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'artistId': artistId,
      'title': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'coverImageUrl': coverImageUrl,
      'genreIds': genreIds,
      'releaseDate': releaseDate?.toIso8601String().split('T')[0],
      'discountPercentage': discountPercentage,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'published': published,
      'songCount': songCount
    };
  }

  Album copyWith({
    int? id,
    int? artistId,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? category,
    List<String>? imageUrls,
    List<int>? genreIds,
    DateTime? releaseDate,
    double? discountPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? published,
    int? songCount,
  }) {
    return Album(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      coverImageUrl: coverImageUrl ?? coverImageUrl,
      genreIds: genreIds ?? this.genreIds,
      releaseDate: releaseDate ?? this.releaseDate,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      published: published ?? this.published,
      songCount: songCount ?? this.songCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        artistId,
        name,
        description,
        price,
        stock,
        category,
        coverImageUrl,
        genreIds,
        releaseDate,
        discountPercentage,
        createdAt,
        updatedAt,
        published,
        songCount,
      ];
}
