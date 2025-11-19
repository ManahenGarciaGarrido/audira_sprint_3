class SocialMediaValidator {
  // Validación de URL de Twitter/X
  static bool isValidTwitterUrl(String url) {
    if (url.isEmpty) return true; // Permitir vacío
    final regex = RegExp(
      r'^https?://(www\.)?(twitter\.com|x\.com)/[a-zA-Z0-9_]{1,15}(\?.*)?$',
      caseSensitive: false,
    );
    return regex.hasMatch(url);
  }

  // Validación de URL de Instagram
  static bool isValidInstagramUrl(String url) {
    if (url.isEmpty) return true;
    final regex = RegExp(
      r'^https?://(www\.)?instagram\.com/[a-zA-Z0-9_.]{1,30}/?(\?.*)?$',
      caseSensitive: false,
    );
    return regex.hasMatch(url);
  }

  // Validación de URL de Facebook
  static bool isValidFacebookUrl(String url) {
    if (url.isEmpty) return true;
    final regex = RegExp(
      r'^https?://(www\.)?facebook\.com/[a-zA-Z0-9.]{1,50}/?(\?.*)?$',
      caseSensitive: false,
    );
    return regex.hasMatch(url);
  }

  // Validación de URL de YouTube
  static bool isValidYoutubeUrl(String url) {
    if (url.isEmpty) return true;
    final regex = RegExp(
      r'^https?://(www\.)?youtube\.com/(c/|@|channel/|user/)?[a-zA-Z0-9_-]{1,100}/?(\?.*)?$',
      caseSensitive: false,
    );
    return regex.hasMatch(url);
  }

  // Validación de URL de Spotify
  static bool isValidSpotifyUrl(String url) {
    if (url.isEmpty) return true;
    final regex = RegExp(
      r'^https?://open\.spotify\.com/artist/[a-zA-Z0-9]{22}(\?.*)?$',
      caseSensitive: false,
    );
    return regex.hasMatch(url);
  }

  // Validación de URL de TikTok
  static bool isValidTiktokUrl(String url) {
    if (url.isEmpty) return true;
    final regex = RegExp(
      r'^https?://(www\.)?tiktok\.com/@[a-zA-Z0-9_.]{1,24}/?(\?.*)?$',
      caseSensitive: false,
    );
    return regex.hasMatch(url);
  }

  // Extraer nombre de usuario de Twitter/X
  static String? extractTwitterUsername(String url) {
    final regex = RegExp(
      r'https?://(www\.)?(twitter\.com|x\.com)/([a-zA-Z0-9_]{1,15})',
      caseSensitive: false,
    );
    final match = regex.firstMatch(url);
    return match?.group(3);
  }

  // Extraer nombre de usuario de Instagram
  static String? extractInstagramUsername(String url) {
    final regex = RegExp(
      r'https?://(www\.)?instagram\.com/([a-zA-Z0-9_.]{1,30})',
      caseSensitive: false,
    );
    final match = regex.firstMatch(url);
    return match?.group(2);
  }

  // Extraer nombre de usuario de Facebook
  static String? extractFacebookUsername(String url) {
    final regex = RegExp(
      r'https?://(www\.)?facebook\.com/([a-zA-Z0-9.]{1,50})',
      caseSensitive: false,
    );
    final match = regex.firstMatch(url);
    return match?.group(2);
  }

  // Extraer identificador de YouTube
  static String? extractYoutubeId(String url) {
    final regex = RegExp(
      r'https?://(www\.)?youtube\.com/(?:c/|@|channel/|user/)?([a-zA-Z0-9_-]{1,100})',
      caseSensitive: false,
    );
    final match = regex.firstMatch(url);
    return match?.group(2);
  }

  // Extraer ID de artista de Spotify
  static String? extractSpotifyArtistId(String url) {
    final regex = RegExp(
      r'https?://open\.spotify\.com/artist/([a-zA-Z0-9]{22})',
      caseSensitive: false,
    );
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  // Extraer nombre de usuario de TikTok
  static String? extractTiktokUsername(String url) {
    final regex = RegExp(
      r'https?://(www\.)?tiktok\.com/@([a-zA-Z0-9_.]{1,24})',
      caseSensitive: false,
    );
    final match = regex.firstMatch(url);
    return match?.group(2);
  }

  // Validación genérica por plataforma
  static bool validateByPlatform(String url, String platform) {
    switch (platform.toLowerCase()) {
      case 'twitter':
      case 'x':
        return isValidTwitterUrl(url);
      case 'instagram':
        return isValidInstagramUrl(url);
      case 'facebook':
        return isValidFacebookUrl(url);
      case 'youtube':
        return isValidYoutubeUrl(url);
      case 'spotify':
        return isValidSpotifyUrl(url);
      case 'tiktok':
        return isValidTiktokUrl(url);
      default:
        return false;
    }
  }

  // Extracción genérica por plataforma
  static String? extractUsername(String url, String platform) {
    switch (platform.toLowerCase()) {
      case 'twitter':
      case 'x':
        return extractTwitterUsername(url);
      case 'instagram':
        return extractInstagramUsername(url);
      case 'facebook':
        return extractFacebookUsername(url);
      case 'youtube':
        return extractYoutubeId(url);
      case 'spotify':
        return extractSpotifyArtistId(url);
      case 'tiktok':
        return extractTiktokUsername(url);
      default:
        return null;
    }
  }
}

// Estado de validación de red social
class SocialMediaValidationState {
  final bool isValid;
  final String? username;
  final String? errorMessage;

  const SocialMediaValidationState({
    required this.isValid,
    this.username,
    this.errorMessage,
  });

  factory SocialMediaValidationState.initial() {
    return const SocialMediaValidationState(isValid: true);
  }

  factory SocialMediaValidationState.valid(String username) {
    return SocialMediaValidationState(isValid: true, username: username);
  }

  factory SocialMediaValidationState.invalid(String message) {
    return SocialMediaValidationState(
      isValid: false,
      errorMessage: message,
    );
  }

  factory SocialMediaValidationState.empty() {
    return const SocialMediaValidationState(isValid: true);
  }
}
