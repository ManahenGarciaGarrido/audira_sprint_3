package io.audira.community.service;

import io.audira.community.dto.*;
import io.audira.community.model.*;
import io.audira.community.repository.UserRepository;
import io.audira.community.security.JwtTokenProvider;
import io.audira.community.security.UserPrincipal;
import io.audira.community.client.FileServiceClient;
import io.audira.community.util.SocialMediaValidator;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider tokenProvider;
    private final FileServiceClient fileServiceClient;
    private static final Logger logger = LoggerFactory.getLogger(UserService.class);

    @Transactional
    public AuthResponse registerUser(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already in use");
        }
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("Username already in use");
        }

        User user;
        String encodedPassword = passwordEncoder.encode(request.getPassword());
        String uid = request.getEmail(); // TODO: Use Firebase UID

        // Create specific user type based on role
        if (request.getRole() == UserRole.ARTIST) {
            user = Artist.builder()
                    .email(request.getEmail())
                    .username(request.getUsername())
                    .password(encodedPassword)
                    .firstName(request.getFirstName())
                    .lastName(request.getLastName())
                    .role(request.getRole())
                    .uid(uid)
                    .isActive(true)
                    .isVerified(false)
                    .build();
        } else {
            user = RegularUser.builder()
                    .email(request.getEmail())
                    .username(request.getUsername())
                    .password(encodedPassword)
                    .firstName(request.getFirstName())
                    .lastName(request.getLastName())
                    .role(request.getRole())
                    .uid(uid)
                    .isActive(true)
                    .isVerified(false)
                    .build();
        }

        user = userRepository.save(user);

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );
        SecurityContextHolder.getContext().setAuthentication(authentication);
        String token = tokenProvider.generateToken(authentication);

        return AuthResponse.builder()
                .token(token)
                .user(mapToDTO(user))
                .build();
    }

    public AuthResponse loginUser(LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmailOrUsername(),
                        request.getPassword()
                )
        );

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String token = tokenProvider.generateToken(authentication);

        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        User user = userRepository.findById(userPrincipal.getId())
                .orElseThrow(() -> new RuntimeException("User not found"));

        return AuthResponse.builder()
                .token(token)
                .user(mapToDTO(user))
                .build();
    }

    public UserDTO getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
        return mapToDTO(user);
    }

    public UserDTO getUserByUsername(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found with username: " + username));
        return mapToDTO(user);
    }

    public List<UserDTO> getAllUsers() {
        return userRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public List<UserDTO> getUsersByRole(UserRole role) {
        return userRepository.findByRole(role).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public UserDTO updateProfile(Long userId, UpdateProfileRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (request.getFirstName() != null) {
            user.setFirstName(request.getFirstName());
        }
        if (request.getLastName() != null) {
            user.setLastName(request.getLastName());
        }
        if (request.getBio() != null) {
            user.setBio(request.getBio());
        }
        if (request.getProfileImageUrl() != null) {
            user.setProfileImageUrl(request.getProfileImageUrl());
        }
        if (request.getBannerImageUrl() != null) {
            user.setBannerImageUrl(request.getBannerImageUrl());
        }
        if (request.getLocation() != null) {
            user.setLocation(request.getLocation());
        }
        if (request.getWebsite() != null) {
            user.setWebsite(request.getWebsite());
        }

        // Update artist-specific fields if user is an artist
        if (user instanceof Artist) {
            Artist artist = (Artist) user;
            if (request.getArtistName() != null) {
                artist.setArtistName(request.getArtistName());
            }
            if (request.getArtistBio() != null) {
                artist.setArtistBio(request.getArtistBio());
            }
            if (request.getRecordLabel() != null) {
                artist.setRecordLabel(request.getRecordLabel());
            }
        }

        // Update social media links with validation
        // Only update if the field is not null AND not empty (to avoid overwriting with empty strings)
        if (request.getTwitterUrl() != null && !request.getTwitterUrl().trim().isEmpty()) {
            String twitterUrl = request.getTwitterUrl().trim();
            if (!SocialMediaValidator.isValidTwitterUrl(twitterUrl)) {
                throw new IllegalArgumentException("URL de Twitter/X inválida. Formato: https://twitter.com/username o https://x.com/username");
            }
            user.setTwitterUrl(twitterUrl);
        }
        if (request.getInstagramUrl() != null && !request.getInstagramUrl().trim().isEmpty()) {
            String instagramUrl = request.getInstagramUrl().trim();
            if (!SocialMediaValidator.isValidInstagramUrl(instagramUrl)) {
                throw new IllegalArgumentException("URL de Instagram inválida. Formato: https://instagram.com/username");
            }
            user.setInstagramUrl(instagramUrl);
        }
        if (request.getFacebookUrl() != null && !request.getFacebookUrl().trim().isEmpty()) {
            String facebookUrl = request.getFacebookUrl().trim();
            if (!SocialMediaValidator.isValidFacebookUrl(facebookUrl)) {
                throw new IllegalArgumentException("URL de Facebook inválida. Formato: https://facebook.com/username");
            }
            user.setFacebookUrl(facebookUrl);
        }
        if (request.getYoutubeUrl() != null && !request.getYoutubeUrl().trim().isEmpty()) {
            String youtubeUrl = request.getYoutubeUrl().trim();
            if (!SocialMediaValidator.isValidYoutubeUrl(youtubeUrl)) {
                throw new IllegalArgumentException("URL de YouTube inválida. Formato: https://youtube.com/@channel o https://youtube.com/c/channel");
            }
            user.setYoutubeUrl(youtubeUrl);
        }
        if (request.getSpotifyUrl() != null && !request.getSpotifyUrl().trim().isEmpty()) {
            String spotifyUrl = request.getSpotifyUrl().trim();
            if (!SocialMediaValidator.isValidSpotifyUrl(spotifyUrl)) {
                throw new IllegalArgumentException("URL de Spotify inválida. Formato: https://open.spotify.com/artist/...");
            }
            user.setSpotifyUrl(spotifyUrl);
        }
        if (request.getTiktokUrl() != null && !request.getTiktokUrl().trim().isEmpty()) {
            String tiktokUrl = request.getTiktokUrl().trim();
            if (!SocialMediaValidator.isValidTiktokUrl(tiktokUrl)) {
                throw new IllegalArgumentException("URL de TikTok inválida. Formato: https://tiktok.com/@username");
            }
            user.setTiktokUrl(tiktokUrl);
        }

        user = userRepository.save(user);
        return mapToDTO(user);
    }

    @Transactional
    public UserDTO updateProfile(Long userId, Map<String, Object> updates) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (updates.containsKey("firstName")) {
            user.setFirstName((String) updates.get("firstName"));
        }
        if (updates.containsKey("lastName")) {
            user.setLastName((String) updates.get("lastName"));
        }
        if (updates.containsKey("bio")) {
            user.setBio((String) updates.get("bio"));
        }
        if (updates.containsKey("profileImageUrl")) {
            user.setProfileImageUrl((String) updates.get("profileImageUrl"));
        }
        if (updates.containsKey("bannerImageUrl")) {
            user.setBannerImageUrl((String) updates.get("bannerImageUrl"));
        }
        if (updates.containsKey("location")) {
            user.setLocation((String) updates.get("location"));
        }
        if (updates.containsKey("website")) {
            user.setWebsite((String) updates.get("website"));
        }

        // Update artist-specific fields if user is an artist
        if (user instanceof Artist) {
            Artist artist = (Artist) user;
            if (updates.containsKey("artistName")) {
                artist.setArtistName((String) updates.get("artistName"));
            }
            if (updates.containsKey("artistBio")) {
                artist.setArtistBio((String) updates.get("artistBio"));
            }
            if (updates.containsKey("recordLabel")) {
                artist.setRecordLabel((String) updates.get("recordLabel"));
            }
        }

        // Update social media links with validation
        // Only update if the field exists AND is not empty (to avoid overwriting with empty strings)
        if (updates.containsKey("twitterUrl")) {
            String twitterUrl = (String) updates.get("twitterUrl");
            if (twitterUrl != null && !twitterUrl.trim().isEmpty()) {
                if (!SocialMediaValidator.isValidTwitterUrl(twitterUrl)) {
                    throw new IllegalArgumentException("URL de Twitter/X inválida. Formato: https://twitter.com/username o https://x.com/username");
                }
                user.setTwitterUrl(twitterUrl.trim());
            }
        }
        if (updates.containsKey("instagramUrl")) {
            String instagramUrl = (String) updates.get("instagramUrl");
            if (instagramUrl != null && !instagramUrl.trim().isEmpty()) {
                if (!SocialMediaValidator.isValidInstagramUrl(instagramUrl)) {
                    throw new IllegalArgumentException("URL de Instagram inválida. Formato: https://instagram.com/username");
                }
                user.setInstagramUrl(instagramUrl.trim());
            }
        }
        if (updates.containsKey("facebookUrl")) {
            String facebookUrl = (String) updates.get("facebookUrl");
            if (facebookUrl != null && !facebookUrl.trim().isEmpty()) {
                if (!SocialMediaValidator.isValidFacebookUrl(facebookUrl)) {
                    throw new IllegalArgumentException("URL de Facebook inválida. Formato: https://facebook.com/username");
                }
                user.setFacebookUrl(facebookUrl.trim());
            }
        }
        if (updates.containsKey("youtubeUrl")) {
            String youtubeUrl = (String) updates.get("youtubeUrl");
            if (youtubeUrl != null && !youtubeUrl.trim().isEmpty()) {
                if (!SocialMediaValidator.isValidYoutubeUrl(youtubeUrl)) {
                    throw new IllegalArgumentException("URL de YouTube inválida. Formato: https://youtube.com/@channel o https://youtube.com/c/channel");
                }
                user.setYoutubeUrl(youtubeUrl.trim());
            }
        }
        if (updates.containsKey("spotifyUrl")) {
            String spotifyUrl = (String) updates.get("spotifyUrl");
            if (spotifyUrl != null && !spotifyUrl.trim().isEmpty()) {
                if (!SocialMediaValidator.isValidSpotifyUrl(spotifyUrl)) {
                    throw new IllegalArgumentException("URL de Spotify inválida. Formato: https://open.spotify.com/artist/...");
                }
                user.setSpotifyUrl(spotifyUrl.trim());
            }
        }
        if (updates.containsKey("tiktokUrl")) {
            String tiktokUrl = (String) updates.get("tiktokUrl");
            if (tiktokUrl != null && !tiktokUrl.trim().isEmpty()) {
                if (!SocialMediaValidator.isValidTiktokUrl(tiktokUrl)) {
                    throw new IllegalArgumentException("URL de TikTok inválida. Formato: https://tiktok.com/@username");
                }
                user.setTiktokUrl(tiktokUrl.trim());
            }
        }

        user = userRepository.save(user);
        return mapToDTO(user);
    }

    @Transactional
    public void deleteUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        userRepository.delete(user);
    }

    @Transactional
    public UserDTO followUser(Long userId, Long targetUserId) {
        if (userId.equals(targetUserId)) {
            throw new RuntimeException("Cannot follow yourself");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new RuntimeException("Target user not found"));

        user.getFollowingIds().add(targetUserId);
        targetUser.getFollowerIds().add(userId);

        userRepository.save(user);
        userRepository.save(targetUser);

        return mapToDTO(user);
    }

    @Transactional
    public UserDTO unfollowUser(Long userId, Long targetUserId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new RuntimeException("Target user not found"));

        user.getFollowingIds().remove(targetUserId);
        targetUser.getFollowerIds().remove(userId);

        userRepository.save(user);
        userRepository.save(targetUser);

        return mapToDTO(user);
    }

    public List<UserDTO> getFollowers(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return user.getFollowerIds().stream()
                .map(this::getUserById)
                .collect(Collectors.toList());
    }

    public List<UserDTO> getFollowing(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return user.getFollowingIds().stream()
                .map(this::getUserById)
                .collect(Collectors.toList());
    }

    public List<UserDTO> getFollowedArtists(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return user.getFollowingIds().stream()
                .map(followingId -> userRepository.findById(followingId).orElse(null))
                .filter(followedUser -> followedUser != null && followedUser.getRole() == UserRole.ARTIST)
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    private UserDTO mapToDTO(User user) {
        logger.info("🔍 mapToDTO called for user: {} (id: {})", user.getUsername(), user.getId());
        logger.info("📱 User Twitter URL from entity: '{}'", user.getTwitterUrl());
        logger.info("📱 User Instagram URL from entity: '{}'", user.getInstagramUrl());

        UserDTO.UserDTOBuilder builder = UserDTO.builder()
                .id(user.getId())
                .email(user.getEmail())
                .username(user.getUsername())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .bio(user.getBio())
                .profileImageUrl(user.getProfileImageUrl())
                .bannerImageUrl(user.getBannerImageUrl())
                .location(user.getLocation())
                .website(user.getWebsite())
                .role(user.getRole())
                .isActive(user.getIsActive())
                .isVerified(user.getIsVerified())
                .followerIds(user.getFollowerIds())
                .followingIds(user.getFollowingIds())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt());

        // Add artist-specific fields if user is an artist
        if (user instanceof Artist) {
            Artist artist = (Artist) user;
            builder.artistName(artist.getArtistName())
                   .artistBio(artist.getArtistBio())
                   .recordLabel(artist.getRecordLabel())
                   .verifiedArtist(artist.getVerifiedArtist());
        }

        // Add social media links
        String twitterUrl = user.getTwitterUrl();
        String instagramUrl = user.getInstagramUrl();
        String facebookUrl = user.getFacebookUrl();
        String youtubeUrl = user.getYoutubeUrl();
        String spotifyUrl = user.getSpotifyUrl();
        String tiktokUrl = user.getTiktokUrl();

        logger.info("🐦 Adding Twitter URL to DTO: '{}'", twitterUrl);

        builder.twitterUrl(twitterUrl)
               .instagramUrl(instagramUrl)
               .facebookUrl(facebookUrl)
               .youtubeUrl(youtubeUrl)
               .spotifyUrl(spotifyUrl)
               .tiktokUrl(tiktokUrl);

        UserDTO dto = builder.build();
        logger.info("✅ DTO built - Twitter URL in DTO: '{}'", dto.getTwitterUrl());
        return dto;
    }

    @Transactional
    public User verifyEmail(Long userId) {
        // Buscar usuario
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Verificar que no esté ya verificado
        if (user.getIsVerified()) {
            throw new RuntimeException("Email already verified");
        }

        // Marcar como verificado
        user.setIsVerified(true);
        user = userRepository.save(user);


        logger.info("Email verified successfully for user: {} ({})",
                    user.getUsername(),
                    user.getEmail());

        return user;
    }

    @Transactional
    public void changePassword(Long userId, ChangePasswordRequest request) {
        // Validar que las contraseñas coincidan
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new RuntimeException("Las contraseñas no coinciden");
        }

        // Obtener el usuario
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        // Verificar que la contraseña actual sea correcta
        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
            throw new RuntimeException("La contraseña actual es incorrecta");
        }

        // Validar que la nueva contraseña sea diferente de la actual
        if (passwordEncoder.matches(request.getNewPassword(), user.getPassword())) {
            throw new RuntimeException("La nueva contraseña debe ser diferente de la actual");
        }

        // Actualizar la contraseña
        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
    }

    // Search methods for GA01-96
    public List<UserDTO> searchArtists(String query) {
        List<Artist> artists = userRepository.searchArtistsByName(query);
        return artists.stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public List<Long> searchArtistIds(String query) {
        return userRepository.searchArtistIdsByName(query);
    }

    @Transactional
    public UserDTO uploadProfileImage(Long userId, MultipartFile imageFile) {
        try {
            // Upload image to file service
            String imageUrl = fileServiceClient.uploadImage(imageFile);

            // Update user with new profile image URL
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            user.setProfileImageUrl(imageUrl);
            user = userRepository.save(user);

            logger.info("Profile image updated for user: {} ({})", user.getUsername(), user.getEmail());

            return mapToDTO(user);
        } catch (Exception e) {
            logger.error("Error uploading profile image for user {}: {}", userId, e.getMessage());
            throw new RuntimeException("Error al subir la imagen de perfil: " + e.getMessage());
        }
    }

    @Transactional
    public UserDTO uploadBannerImage(Long userId, MultipartFile imageFile) {
        try {
            // Upload image to file service
            String imageUrl = fileServiceClient.uploadImage(imageFile);

            // Update user with new banner image URL
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            user.setBannerImageUrl(imageUrl);
            user = userRepository.save(user);

            logger.info("Banner image updated for user: {} ({})", user.getUsername(), user.getEmail());

            return mapToDTO(user);
        } catch (Exception e) {
            logger.error("Error uploading banner image for user {}: {}", userId, e.getMessage());
            throw new RuntimeException("Error al subir la imagen de banner: " + e.getMessage());
        }
    }
}
