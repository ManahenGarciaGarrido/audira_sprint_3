import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String? uid;
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? profileImageUrl;
  final String? bannerImageUrl;
  final String? location;
  final String? website;
  final String role;
  final bool isActive;
  final bool isVerified;
  final List<int> followerIds;
  final List<int> followingIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Artist-specific fields
  final String? artistName;
  final String? artistBio;
  final String? recordLabel;
  final bool? verifiedArtist;

  // Social media links
  final String? twitterUrl;
  final String? instagramUrl;
  final String? facebookUrl;
  final String? youtubeUrl;
  final String? spotifyUrl;
  final String? tiktokUrl;

  const User({
    required this.id,
    this.uid,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.bio,
    this.profileImageUrl,
    this.bannerImageUrl,
    this.location,
    this.website,
    required this.role,
    this.isActive = true,
    this.isVerified = false,
    this.followerIds = const [],
    this.followingIds = const [],
    this.createdAt,
    this.updatedAt,
    this.artistName,
    this.artistBio,
    this.recordLabel,
    this.verifiedArtist,
    this.twitterUrl,
    this.instagramUrl,
    this.facebookUrl,
    this.youtubeUrl,
    this.spotifyUrl,
    this.tiktokUrl,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      uid: json['uid'] as String?,
      email: json['email'] as String,
      username: json['username'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      bio: json['bio'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      bannerImageUrl: json['bannerImageUrl'] as String?,
      location: json['location'] as String?,
      website: json['website'] as String?,
      role: json['role'] as String,
      isActive: json['isActive'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
      followerIds: (json['followerIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      followingIds: (json['followingIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      artistName: json['artistName'] as String?,
      artistBio: json['artistBio'] as String?,
      recordLabel: json['recordLabel'] as String?,
      verifiedArtist: json['verifiedArtist'] as bool?,
      twitterUrl: json['twitterUrl'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      facebookUrl: json['facebookUrl'] as String?,
      youtubeUrl: json['youtubeUrl'] as String?,
      spotifyUrl: json['spotifyUrl'] as String?,
      tiktokUrl: json['tiktokUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'bannerImageUrl': bannerImageUrl,
      'location': location,
      'website': website,
      'role': role,
      'isActive': isActive,
      'isVerified': isVerified,
      'followerIds': followerIds,
      'followingIds': followingIds,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'artistName': artistName,
      'artistBio': artistBio,
      'recordLabel': recordLabel,
      'verifiedArtist': verifiedArtist,
      'twitterUrl': twitterUrl,
      'instagramUrl': instagramUrl,
      'facebookUrl': facebookUrl,
      'youtubeUrl': youtubeUrl,
      'spotifyUrl': spotifyUrl,
      'tiktokUrl': tiktokUrl,
    };
  }

  User copyWith({
    int? id,
    String? uid,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? bio,
    String? profileImageUrl,
    String? bannerImageUrl,
    String? location,
    String? website,
    String? role,
    bool? isActive,
    bool? isVerified,
    List<int>? followerIds,
    List<int>? followingIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? artistName,
    String? artistBio,
    String? recordLabel,
    bool? verifiedArtist,
    String? twitterUrl,
    String? instagramUrl,
    String? facebookUrl,
    String? youtubeUrl,
    String? spotifyUrl,
    String? tiktokUrl,
  }) {
    return User(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      location: location ?? this.location,
      website: website ?? this.website,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      followerIds: followerIds ?? this.followerIds,
      followingIds: followingIds ?? this.followingIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      artistName: artistName ?? this.artistName,
      artistBio: artistBio ?? this.artistBio,
      recordLabel: recordLabel ?? this.recordLabel,
      verifiedArtist: verifiedArtist ?? this.verifiedArtist,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      spotifyUrl: spotifyUrl ?? this.spotifyUrl,
      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        uid,
        email,
        username,
        firstName,
        lastName,
        bio,
        profileImageUrl,
        bannerImageUrl,
        location,
        website,
        role,
        isActive,
        isVerified,
        followerIds,
        followingIds,
        createdAt,
        updatedAt,
        artistName,
        artistBio,
        recordLabel,
        verifiedArtist,
        twitterUrl,
        instagramUrl,
        facebookUrl,
        youtubeUrl,
        spotifyUrl,
        tiktokUrl,
      ];

  bool get isArtist => role == 'ARTIST';

  String get displayName {
    if (isArtist && artistName != null && artistName!.isNotEmpty) {
      return artistName!;
    }
    return fullName;
  }
}
