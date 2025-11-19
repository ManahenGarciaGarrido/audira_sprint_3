class AppConstants {
  // API Configuration
  static const String apiGatewayUrl = 'http://68.221.240.178:8080';

  // Auth endpoints
  static const String authRegisterUrl = '/api/auth/register';
  static const String authLoginUrl = '/api/auth/login';

  // User endpoints
  static const String userProfileUrl = '/api/users/profile';
  static const String userByIdUrl = '/api/users';

  static const String allUsersUrl = '/api/users';

  // Song endpoints
  static const String songsUrl = '/api/songs';

  // Album endpoints
  static const String albumsUrl = '/api/albums';

  // Genre endpoints
  static const String genresUrl = '/api/genres';

  // Playlist endpoints
  static const String playlistsUrl = '/api/playlists';

  // Cart endpoints
  static const String cartUrl = '/api/cart';

  // Order endpoints
  static const String ordersUrl = '/api/orders';

  // Library endpoints
  static const String libraryUrl = '/api/library';

  // Playback endpoints
  static const String playbackUrl = '/api/playback';

  // Queue endpoints
  static const String queueUrl = '/api/queue';

  // History endpoints
  static const String historyUrl = '/api/history';

  // Rating endpoints
  static const String ratingsUrl = '/api/ratings';

  // Comment endpoints
  static const String commentsUrl = '/api/comments';

  // FAQ endpoints
  static const String faqsUrl = '/api/faqs';

  // Contact endpoints
  static const String contactUrl = '/api/contact';

  // Notification endpoints
  static const String notificationsUrl = '/api/notifications';

  // Artist Metrics endpoints
  static const String artistMetricsUrl = '/api/metrics/artists';

  // Collaboration endpoints
  static const String collaborationsUrl = '/api/collaborations';

  // Discovery endpoints
  static const String discoveryUrl = '/api/discovery';

  // Product endpoints
  static const String productsUrl = '/api/products';

  // Payment endpoints
  static const String paymentsUrl = '/api/payments';
  static const String receiptsUrl = '/api/receipts';

  // App Configuration
  static const String appName = 'Audira';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String userDataKey = 'user_data';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Audio
  static const int demoSongDuration = 10; // seconds

  // Cart
  static const String guestCartKey = 'guest_cart';

  // Roles
  static const String roleGuest = 'GUEST';
  static const String roleUser = 'USER';
  static const String roleArtist = 'ARTIST';
  static const String roleAdmin = 'ADMIN';

  // Item Types
  static const String itemTypeSong = 'SONG';
  static const String itemTypeAlbum = 'ALBUM';
  static const String itemTypeArtist = 'ARTIST';
  static const String itemTypePlaylist = 'PLAYLIST';

  // Entity Types
  static const String entityTypeSong = 'SONG';
  static const String entityTypeAlbum = 'ALBUM';
  static const String entityTypeArtist = 'ARTIST';
  static const String entityTypePlaylist = 'PLAYLIST';

  // Order Status
  static const String orderStatusPending = 'PENDING';
  static const String orderStatusProcessing = 'PROCESSING';
  static const String orderStatusShipped = 'SHIPPED';
  static const String orderStatusDelivered = 'DELIVERED';
  static const String orderStatusCancelled = 'CANCELLED';

  // Payment Status
  static const String paymentStatusPending = 'PENDING';
  static const String paymentStatusProcessing = 'PROCESSING';
  static const String paymentStatusCompleted = 'COMPLETED';
  static const String paymentStatusFailed = 'FAILED';
  static const String paymentStatusRefunded = 'REFUNDED';

  // Payment Methods
  static const String paymentMethodCreditCard = 'CREDIT_CARD';
  static const String paymentMethodDebitCard = 'DEBIT_CARD';
  static const String paymentMethodPaypal = 'PAYPAL';
  static const String paymentMethodBankTransfer = 'BANK_TRANSFER';

  // FAQ Categories
  static const String faqCategoryAccount = 'ACCOUNT';
  static const String faqCategoryBilling = 'BILLING';
  static const String faqCategoryTechnical = 'TECHNICAL';
  static const String faqCategoryArtists = 'ARTISTS';
  static const String faqCategoryContent = 'CONTENT';
  static const String faqCategoryPrivacy = 'PRIVACY';
  static const String faqCategoryGeneral = 'GENERAL';

  // Notification Types
  static const String notificationTypeInfo = 'INFO';
  static const String notificationTypeWarning = 'WARNING';
  static const String notificationTypeError = 'ERROR';
  static const String notificationTypeSuccess = 'SUCCESS';

  // Repeat Modes
  static const String repeatModeOff = 'OFF';
  static const String repeatModeOne = 'ONE';
  static const String repeatModeAll = 'ALL';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxUsernameLength = 30;
  static const int minUsernameLength = 3;

  // Error Messages
  static const String errorNetworkMessage =
      'Error de conexión. Verifica tu internet.';
  static const String errorUnauthorizedMessage =
      'No autorizado. Inicia sesión nuevamente.';
  static const String errorServerMessage =
      'Error del servidor. Intenta más tarde.';
  static const String errorUnknownMessage =
      'Error desconocido. Intenta nuevamente.';
}
