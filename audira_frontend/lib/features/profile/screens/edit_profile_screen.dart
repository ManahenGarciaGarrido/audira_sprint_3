// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:async';
import 'package:audira_frontend/core/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/auth_service.dart';
import '../../../config/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/social_media_validator.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  late TextEditingController _artistNameController;
  late TextEditingController _artistBioController;
  late TextEditingController _recordLabelController;
  late TextEditingController _twitterController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;
  late TextEditingController _youtubeController;
  late TextEditingController _spotifyController;
  late TextEditingController _tiktokController;

  bool _isLoading = false;
  bool _hasChanges = false;
  File? _selectedImage;
  bool _isUploadingImage = false;
  File? _selectedBanner;
  bool _isUploadingBanner = false;
  final ImagePicker _picker = ImagePicker();

  // Estados de validación de redes sociales
  SocialMediaValidationState _twitterValidation =
      SocialMediaValidationState.initial();
  SocialMediaValidationState _instagramValidation =
      SocialMediaValidationState.initial();
  SocialMediaValidationState _facebookValidation =
      SocialMediaValidationState.initial();
  SocialMediaValidationState _youtubeValidation =
      SocialMediaValidationState.initial();
  SocialMediaValidationState _spotifyValidation =
      SocialMediaValidationState.initial();
  SocialMediaValidationState _tiktokValidation =
      SocialMediaValidationState.initial();

  // Timers para debounce de validación
  Timer? _twitterDebounce;
  Timer? _instagramDebounce;
  Timer? _facebookDebounce;
  Timer? _youtubeDebounce;
  Timer? _spotifyDebounce;
  Timer? _tiktokDebounce;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _locationController = TextEditingController(text: user?.location ?? '');
    _websiteController = TextEditingController(text: user?.website ?? '');
    _artistNameController = TextEditingController(text: user?.artistName ?? '');
    _artistBioController = TextEditingController(text: user?.artistBio ?? '');
    _recordLabelController =
        TextEditingController(text: user?.recordLabel ?? '');
    _twitterController = TextEditingController(text: user?.twitterUrl ?? '');
    _instagramController =
        TextEditingController(text: user?.instagramUrl ?? '');
    _facebookController = TextEditingController(text: user?.facebookUrl ?? '');
    _youtubeController = TextEditingController(text: user?.youtubeUrl ?? '');
    _spotifyController = TextEditingController(text: user?.spotifyUrl ?? '');
    _tiktokController = TextEditingController(text: user?.tiktokUrl ?? '');

    _firstNameController.addListener(() => setState(() => _hasChanges = true));
    _lastNameController.addListener(() => setState(() => _hasChanges = true));
    _bioController.addListener(() => setState(() => _hasChanges = true));
    _locationController.addListener(() => setState(() => _hasChanges = true));
    _websiteController.addListener(() => setState(() => _hasChanges = true));
    _artistNameController.addListener(() => setState(() => _hasChanges = true));
    _artistBioController.addListener(() => setState(() => _hasChanges = true));
    _recordLabelController
        .addListener(() => setState(() => _hasChanges = true));
    _twitterController.addListener(() => setState(() => _hasChanges = true));
    _instagramController.addListener(() => setState(() => _hasChanges = true));
    _facebookController.addListener(() => setState(() => _hasChanges = true));
    _youtubeController.addListener(() => setState(() => _hasChanges = true));
    _spotifyController.addListener(() => setState(() => _hasChanges = true));
    _tiktokController.addListener(() => setState(() => _hasChanges = true));

    // Validar URLs existentes al cargar
    if (user?.twitterUrl != null && user!.twitterUrl!.isNotEmpty) {
      _validateTwitter(user.twitterUrl!);
    }
    if (user?.instagramUrl != null && user!.instagramUrl!.isNotEmpty) {
      _validateInstagram(user.instagramUrl!);
    }
    if (user?.facebookUrl != null && user!.facebookUrl!.isNotEmpty) {
      _validateFacebook(user.facebookUrl!);
    }
    if (user?.youtubeUrl != null && user!.youtubeUrl!.isNotEmpty) {
      _validateYoutube(user.youtubeUrl!);
    }
    if (user?.spotifyUrl != null && user!.spotifyUrl!.isNotEmpty) {
      _validateSpotify(user.spotifyUrl!);
    }
    if (user?.tiktokUrl != null && user!.tiktokUrl!.isNotEmpty) {
      _validateTiktok(user.tiktokUrl!);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _artistNameController.dispose();
    _artistBioController.dispose();
    _recordLabelController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _youtubeController.dispose();
    _spotifyController.dispose();
    _tiktokController.dispose();
    _twitterDebounce?.cancel();
    _instagramDebounce?.cancel();
    _facebookDebounce?.cancel();
    _youtubeDebounce?.cancel();
    _spotifyDebounce?.cancel();
    _tiktokDebounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(EditProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar controladores si el usuario cambia
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _updateControllersFromUser(user);
    }
  }

  void _updateControllersFromUser(User user) {
    _firstNameController.text = user.firstName ?? '';
    _lastNameController.text = user.lastName ?? '';
    _bioController.text = user.bio ?? '';
    _locationController.text = user.location ?? '';
    _websiteController.text = user.website ?? '';
    _artistNameController.text = user.artistName ?? '';
    _artistBioController.text = user.artistBio ?? '';
    _recordLabelController.text = user.recordLabel ?? '';
    _twitterController.text = user.twitterUrl ?? '';
    _instagramController.text = user.instagramUrl ?? '';
    _facebookController.text = user.facebookUrl ?? '';
    _youtubeController.text = user.youtubeUrl ?? '';
    _spotifyController.text = user.spotifyUrl ?? '';
    _tiktokController.text = user.tiktokUrl ?? '';

    // Validar URLs existentes
    if (user.twitterUrl != null && user.twitterUrl!.isNotEmpty) {
      _validateTwitter(user.twitterUrl!);
    }
    if (user.instagramUrl != null && user.instagramUrl!.isNotEmpty) {
      _validateInstagram(user.instagramUrl!);
    }
    if (user.facebookUrl != null && user.facebookUrl!.isNotEmpty) {
      _validateFacebook(user.facebookUrl!);
    }
    if (user.youtubeUrl != null && user.youtubeUrl!.isNotEmpty) {
      _validateYoutube(user.youtubeUrl!);
    }
    if (user.spotifyUrl != null && user.spotifyUrl!.isNotEmpty) {
      _validateSpotify(user.spotifyUrl!);
    }
    if (user.tiktokUrl != null && user.tiktokUrl!.isNotEmpty) {
      _validateTiktok(user.tiktokUrl!);
    }
  }

  void _validateTwitter(String url) {
    setState(() {
      if (url.isEmpty) {
        _twitterValidation = SocialMediaValidationState.empty();
      } else if (SocialMediaValidator.isValidTwitterUrl(url)) {
        final username = SocialMediaValidator.extractTwitterUsername(url);
        if (username != null) {
          _twitterValidation = SocialMediaValidationState.valid(username);
        } else {
          _twitterValidation = SocialMediaValidationState.invalid(
              'No se pudo extraer el nombre de usuario');
        }
      } else {
        _twitterValidation = SocialMediaValidationState.invalid(
            'URL de Twitter/X no válida. Formato: https://twitter.com/usuario');
      }
    });
  }

  void _validateInstagram(String url) {
    setState(() {
      if (url.isEmpty) {
        _instagramValidation = SocialMediaValidationState.empty();
      } else if (SocialMediaValidator.isValidInstagramUrl(url)) {
        final username = SocialMediaValidator.extractInstagramUsername(url);
        if (username != null) {
          _instagramValidation = SocialMediaValidationState.valid(username);
        } else {
          _instagramValidation = SocialMediaValidationState.invalid(
              'No se pudo extraer el nombre de usuario');
        }
      } else {
        _instagramValidation = SocialMediaValidationState.invalid(
            'URL de Instagram no válida. Formato: https://instagram.com/usuario');
      }
    });
  }

  void _validateFacebook(String url) {
    setState(() {
      if (url.isEmpty) {
        _facebookValidation = SocialMediaValidationState.empty();
      } else if (SocialMediaValidator.isValidFacebookUrl(url)) {
        final username = SocialMediaValidator.extractFacebookUsername(url);
        if (username != null) {
          _facebookValidation = SocialMediaValidationState.valid(username);
        } else {
          _facebookValidation = SocialMediaValidationState.invalid(
              'No se pudo extraer el nombre de usuario');
        }
      } else {
        _facebookValidation = SocialMediaValidationState.invalid(
            'URL de Facebook no válida. Formato: https://facebook.com/usuario');
      }
    });
  }

  void _validateYoutube(String url) {
    setState(() {
      if (url.isEmpty) {
        _youtubeValidation = SocialMediaValidationState.empty();
      } else if (SocialMediaValidator.isValidYoutubeUrl(url)) {
        final username = SocialMediaValidator.extractYoutubeId(url);
        if (username != null) {
          _youtubeValidation = SocialMediaValidationState.valid(username);
        } else {
          _youtubeValidation = SocialMediaValidationState.invalid(
              'No se pudo extraer el identificador');
        }
      } else {
        _youtubeValidation = SocialMediaValidationState.invalid(
            'URL de YouTube no válida. Formato: https://youtube.com/@canal');
      }
    });
  }

  void _validateSpotify(String url) {
    setState(() {
      if (url.isEmpty) {
        _spotifyValidation = SocialMediaValidationState.empty();
      } else if (SocialMediaValidator.isValidSpotifyUrl(url)) {
        final artistId = SocialMediaValidator.extractSpotifyArtistId(url);
        if (artistId != null) {
          _spotifyValidation = SocialMediaValidationState.valid(artistId);
        } else {
          _spotifyValidation = SocialMediaValidationState.invalid(
              'No se pudo extraer el ID del artista');
        }
      } else {
        _spotifyValidation = SocialMediaValidationState.invalid(
            'URL de Spotify no válida. Formato: https://open.spotify.com/artist/ID');
      }
    });
  }

  void _validateTiktok(String url) {
    setState(() {
      if (url.isEmpty) {
        _tiktokValidation = SocialMediaValidationState.empty();
      } else if (SocialMediaValidator.isValidTiktokUrl(url)) {
        final username = SocialMediaValidator.extractTiktokUsername(url);
        if (username != null) {
          _tiktokValidation = SocialMediaValidationState.valid(username);
        } else {
          _tiktokValidation = SocialMediaValidationState.invalid(
              'No se pudo extraer el nombre de usuario');
        }
      } else {
        _tiktokValidation = SocialMediaValidationState.invalid(
            'URL de TikTok no válida. Formato: https://tiktok.com/@usuario');
      }
    });
  }

  void _onTwitterChanged(String value) {
    _twitterDebounce?.cancel();
    _twitterDebounce = Timer(const Duration(milliseconds: 500), () {
      _validateTwitter(value);
    });
  }

  void _onInstagramChanged(String value) {
    _instagramDebounce?.cancel();
    _instagramDebounce = Timer(const Duration(milliseconds: 500), () {
      _validateInstagram(value);
    });
  }

  void _onFacebookChanged(String value) {
    _facebookDebounce?.cancel();
    _facebookDebounce = Timer(const Duration(milliseconds: 500), () {
      _validateFacebook(value);
    });
  }

  void _onYoutubeChanged(String value) {
    _youtubeDebounce?.cancel();
    _youtubeDebounce = Timer(const Duration(milliseconds: 500), () {
      _validateYoutube(value);
    });
  }

  void _onSpotifyChanged(String value) {
    _spotifyDebounce?.cancel();
    _spotifyDebounce = Timer(const Duration(milliseconds: 500), () {
      _validateSpotify(value);
    });
  }

  void _onTiktokChanged(String value) {
    _tiktokDebounce?.cancel();
    _tiktokDebounce = Timer(const Duration(milliseconds: 500), () {
      _validateTiktok(value);
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que todas las URLs de redes sociales sean válidas antes de guardar
    if (!_twitterValidation.isValid &&
        _twitterController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Por favor, corrige la URL de Twitter antes de guardar')),
      );
      return;
    }
    if (!_instagramValidation.isValid &&
        _instagramController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Por favor, corrige la URL de Instagram antes de guardar')),
      );
      return;
    }
    if (!_facebookValidation.isValid &&
        _facebookController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Por favor, corrige la URL de Facebook antes de guardar')),
      );
      return;
    }
    if (!_youtubeValidation.isValid &&
        _youtubeController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Por favor, corrige la URL de YouTube antes de guardar')),
      );
      return;
    }
    if (!_spotifyValidation.isValid &&
        _spotifyController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Por favor, corrige la URL de Spotify antes de guardar')),
      );
      return;
    }
    if (!_tiktokValidation.isValid &&
        _tiktokController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Por favor, corrige la URL de TikTok antes de guardar')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final user = context.read<AuthProvider>().currentUser;
      final updates = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'website': _websiteController.text.trim(),
      };

      // Add artist-specific fields if user is an artist
      if (user?.isArtist == true) {
        updates['artistName'] = _artistNameController.text.trim();
        updates['artistBio'] = _artistBioController.text.trim();
        updates['recordLabel'] = _recordLabelController.text.trim();
      }

      // Add social media links - solo si no están vacías
      final twitterUrl = _twitterController.text.trim();
      final instagramUrl = _instagramController.text.trim();
      final facebookUrl = _facebookController.text.trim();
      final youtubeUrl = _youtubeController.text.trim();
      final spotifyUrl = _spotifyController.text.trim();
      final tiktokUrl = _tiktokController.text.trim();

      if (twitterUrl.isNotEmpty) {
        updates['twitterUrl'] = twitterUrl;
      }
      if (instagramUrl.isNotEmpty) {
        updates['instagramUrl'] = instagramUrl;
      }
      if (facebookUrl.isNotEmpty) {
        updates['facebookUrl'] = facebookUrl;
      }
      if (youtubeUrl.isNotEmpty) {
        updates['youtubeUrl'] = youtubeUrl;
      }
      if (spotifyUrl.isNotEmpty) {
        updates['spotifyUrl'] = spotifyUrl;
      }
      if (tiktokUrl.isNotEmpty) {
        updates['tiktokUrl'] = tiktokUrl;
      }

      debugPrint('🔵 Enviando actualizaciones: $updates');

      final ApiResponse<User> response =
          await authService.updateProfile(updates);

      debugPrint(
          '🟢 Response recibido - success: ${response.success}, data: ${response.data != null}');

      if (response.success && response.data != null) {
        final updatedUser = response.data!;
        debugPrint('🟡 Usuario actualizado recibido:');
        debugPrint('  - Twitter: ${updatedUser.twitterUrl}');
        debugPrint('  - Instagram: ${updatedUser.instagramUrl}');
        debugPrint('  - Facebook: ${updatedUser.facebookUrl}');
        debugPrint('  - YouTube: ${updatedUser.youtubeUrl}');
        debugPrint('  - Spotify: ${updatedUser.spotifyUrl}');
        debugPrint('  - TikTok: ${updatedUser.tiktokUrl}');

        if (mounted) {
          // Actualizar el provider DIRECTAMENTE con los datos del response
          // Esto evita hacer otra llamada al backend y problemas de sincronización
          final authProvider = context.read<AuthProvider>();
          authProvider.updateUser(updatedUser);

          debugPrint('🟣 Usuario actualizado en provider');

          // Usar los datos del response para actualizar los controladores
          _updateControllersFromUser(updatedUser);

          debugPrint('🟢 Controladores actualizados');
          debugPrint('  - Twitter controller: ${_twitterController.text}');
          debugPrint('  - Instagram controller: ${_instagramController.text}');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() => _hasChanges = false);
        }
      } else {
        debugPrint('🔴 Error en response: ${response.error}');
        throw Exception(response.error ?? 'Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        throw Exception('Usuario no identificado');
      }

      final authService = AuthService();
      final response =
          await authService.uploadProfileImage(_selectedImage!, userId);

      if (response.success) {
        await authProvider.refreshProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil actualizada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response.error ?? 'Error al subir imagen');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _pickBanner() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedBanner = File(pickedFile.path);
        });
        await _uploadBanner();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar banner: $e')),
        );
      }
    }
  }

  Future<void> _uploadBanner() async {
    if (_selectedBanner == null) return;

    setState(() => _isUploadingBanner = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        throw Exception('Usuario no identificado');
      }

      final authService = AuthService();
      final response =
          await authService.uploadBannerImage(_selectedBanner!, userId);

      if (response.success) {
        await authProvider.refreshProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Banner actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response.error ?? 'Error al subir banner');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingBanner = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use watch to listen to AuthProvider changes
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Header with Stack (Banner + Profile Picture)
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner Background
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient:
                        _selectedBanner == null && user?.bannerImageUrl == null
                            ? LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue.withValues(alpha: 0.8),
                                  AppTheme.primaryBlue.withValues(alpha: 0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                    image: _selectedBanner != null
                        ? DecorationImage(
                            image: FileImage(_selectedBanner!),
                            fit: BoxFit.cover,
                          )
                        : (user?.bannerImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(user!.bannerImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: -0.2),

                // Upload Banner Indicator
                if (_isUploadingBanner)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Change Banner Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingBanner ? null : _pickBanner,
                    icon: const Icon(Icons.photo_camera, size: 18),
                    label: const Text('Change Banner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                // Profile Picture - Positioned overlapping the banner
                Positioned(
                  bottom: -50,
                  left: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppTheme.primaryBlue,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (user?.profileImageUrl != null
                                  ? NetworkImage(user!.profileImageUrl!)
                                  : null) as ImageProvider?,
                          child: (_selectedImage == null &&
                                  user?.profileImageUrl == null)
                              ? const Icon(Icons.person,
                                  size: 60, color: Colors.white)
                              : null,
                        ),
                        if (_isUploadingImage)
                          Positioned.fill(
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.black54,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 250.ms).scale(delay: 250.ms),
                ),
              ],
            ),

            // Space for overlapping avatar
            const SizedBox(height: 60),

            // User Info Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'User',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 4),
                  Text(
                    '@${user?.username ?? 'username'}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                  ).animate().fadeIn(delay: 350.ms),
                  const SizedBox(height: 16),
                  // Change Profile Image Button - Completely separated from Stack
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _pickImage,
                    icon: const Icon(Icons.photo_camera, size: 18),
                    label: const Text('Change Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      return null;
                    },
                  ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.2),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.2),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.2),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ).animate(delay: 400.ms).fadeIn().slideX(begin: -0.2),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Website',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                  ).animate(delay: 500.ms).fadeIn().slideX(begin: -0.2),
                  const SizedBox(height: 16),

                  // Artist-specific fields
                  if (context.read<AuthProvider>().currentUser?.isArtist ==
                      true) ...[
                    const Divider(height: 32),
                    Text(
                      'Artist Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                    ).animate(delay: 600.ms).fadeIn(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _artistNameController,
                      decoration: const InputDecoration(
                        labelText: 'Artist Name / Stage Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.stars),
                        hintText: 'Your professional artist name',
                      ),
                    ).animate(delay: 700.ms).fadeIn().slideX(begin: -0.2),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _artistBioController,
                      decoration: const InputDecoration(
                        labelText: 'Artist Bio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.music_note),
                        alignLabelWithHint: true,
                        hintText: 'Tell your fans about your music',
                      ),
                      maxLines: 4,
                    ).animate(delay: 800.ms).fadeIn().slideX(begin: -0.2),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _recordLabelController,
                      decoration: const InputDecoration(
                        labelText: 'Record Label',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.album),
                        hintText: 'Independent or label name',
                      ),
                    ).animate(delay: 900.ms).fadeIn().slideX(begin: -0.2),
                    const SizedBox(height: 16),
                  ],

                  const Divider(height: 32),
                  Text(
                    'Social Media Links',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate(delay: 1000.ms).fadeIn(),
                  const SizedBox(height: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _twitterController,
                        decoration: const InputDecoration(
                          labelText: 'Twitter/X',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.alternate_email),
                          hintText: 'https://twitter.com/username',
                        ),
                        keyboardType: TextInputType.url,
                        onChanged: _onTwitterChanged,
                      ),
                      _buildValidationFeedback(_twitterValidation),
                    ],
                  ).animate(delay: 1100.ms).fadeIn().slideX(begin: -0.2),
                  const SizedBox(height: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _instagramController,
                        decoration: const InputDecoration(
                          labelText: 'Instagram',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.camera_alt),
                          hintText: 'https://instagram.com/username',
                        ),
                        keyboardType: TextInputType.url,
                        onChanged: _onInstagramChanged,
                      ),
                      _buildValidationFeedback(_instagramValidation),
                    ],
                  ).animate(delay: 1200.ms).fadeIn().slideX(begin: -0.2),
                  const SizedBox(height: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _facebookController,
                        decoration: const InputDecoration(
                          labelText: 'Facebook',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.facebook),
                          hintText: 'https://facebook.com/username',
                        ),
                        keyboardType: TextInputType.url,
                        onChanged: _onFacebookChanged,
                      ),
                      _buildValidationFeedback(_facebookValidation),
                    ],
                  ).animate(delay: 1300.ms).fadeIn().slideX(begin: -0.2),
                  const SizedBox(height: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _youtubeController,
                        decoration: const InputDecoration(
                          labelText: 'YouTube',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.play_circle_outline),
                          hintText: 'https://youtube.com/c/channel',
                        ),
                        keyboardType: TextInputType.url,
                        onChanged: _onYoutubeChanged,
                      ),
                      _buildValidationFeedback(_youtubeValidation),
                    ],
                  ).animate(delay: 1400.ms).fadeIn().slideX(begin: -0.2),
                  const SizedBox(height: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _spotifyController,
                        decoration: const InputDecoration(
                          labelText: 'Spotify',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.music_note_outlined),
                          hintText: 'https://open.spotify.com/artist/...',
                        ),
                        keyboardType: TextInputType.url,
                        onChanged: _onSpotifyChanged,
                      ),
                      _buildValidationFeedback(_spotifyValidation),
                    ],
                  ).animate(delay: 1500.ms).fadeIn().slideX(begin: -0.2),
                  const SizedBox(height: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _tiktokController,
                        decoration: const InputDecoration(
                          labelText: 'TikTok',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.video_library_outlined),
                          hintText: 'https://tiktok.com/@username',
                        ),
                        keyboardType: TextInputType.url,
                        onChanged: _onTiktokChanged,
                      ),
                      _buildValidationFeedback(_tiktokValidation),
                    ],
                  ).animate(delay: 1600.ms).fadeIn().slideX(begin: -0.2),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _hasChanges && !_isLoading ? _saveChanges : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Changes',
                            style: TextStyle(fontSize: 16)),
                  )
                      .animate(delay: 600.ms)
                      .fadeIn()
                      .scale(begin: const Offset(0.9, 0.9)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildValidationFeedback(SocialMediaValidationState state) {
    if (state.username != null && state.isValid) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, left: 12),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Usuario encontrado: @${state.username}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (!state.isValid && state.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, left: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                state.errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
