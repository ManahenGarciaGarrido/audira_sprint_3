import 'user.dart';

class Artist extends User {
  const Artist({
    required super.id,
    super.uid,
    required super.email,
    required super.username,
    super.firstName,
    super.lastName,
    super.bio,
    super.profileImageUrl,
    super.bannerImageUrl,
    super.location,
    super.website,
    required super.role,
    super.isActive,
    super.isVerified,
    super.followerIds,
    super.followingIds,
    super.createdAt,
    super.updatedAt,
    super.artistName,
    bool verifiedArtist = false,
    super.artistBio,
    super.recordLabel,
    super.twitterUrl,
    super.instagramUrl,
    super.facebookUrl,
    super.youtubeUrl,
    super.spotifyUrl,
    super.tiktokUrl,
  }) : super(verifiedArtist: verifiedArtist);

  @override
  bool get verifiedArtist => super.verifiedArtist ?? false;

  @override
  String get displayName => artistName ?? fullName;

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
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
      verifiedArtist: json['verifiedArtist'] as bool? ?? false,
      artistBio: json['artistBio'] as String?,
      recordLabel: json['recordLabel'] as String?,
      twitterUrl: json['twitterUrl'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      facebookUrl: json['facebookUrl'] as String?,
      youtubeUrl: json['youtubeUrl'] as String?,
      spotifyUrl: json['spotifyUrl'] as String?,
      tiktokUrl: json['tiktokUrl'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['artistName'] = artistName;
    data['verifiedArtist'] = verifiedArtist;
    data['artistBio'] = artistBio;
    data['recordLabel'] = recordLabel;
    return data;
  }

  @override
  Artist copyWith({
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
    bool? verifiedArtist,
    String? artistBio,
    String? recordLabel,
    String? facebookUrl,
    String? instagramUrl,
    String? spotifyUrl,
    String? tiktokUrl,
    String? twitterUrl,
    String? youtubeUrl,
  }) {
    return Artist(
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
      verifiedArtist: verifiedArtist ?? this.verifiedArtist,
      artistBio: artistBio ?? this.artistBio,
      recordLabel: recordLabel ?? this.recordLabel,
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
        ...super.props,
        artistName,
        verifiedArtist,
        artistBio,
        recordLabel,
      ];
}
