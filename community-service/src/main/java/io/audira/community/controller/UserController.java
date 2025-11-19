package io.audira.community.controller;

import io.audira.community.dto.ChangePasswordRequest;
import io.audira.community.dto.UpdateProfileRequest;
import io.audira.community.dto.UserDTO;
import io.audira.community.security.UserPrincipal;
import io.audira.community.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    // Endpoint: GET /api/users/profile (probado en el script)
    @GetMapping("/profile")
    public ResponseEntity<UserDTO> getCurrentUserProfile(@AuthenticationPrincipal UserPrincipal currentUser) {
        UserDTO userProfile = userService.getUserById(currentUser.getId());
        return ResponseEntity.ok(userProfile);
    }

    // Endpoint: PUT /api/users/profile (probado en el script)
    @PutMapping("/profile")
    public ResponseEntity<UserDTO> updateCurrentUserProfile(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @Valid @RequestBody UpdateProfileRequest updateRequest
    ) {
        UserDTO updatedProfile = userService.updateProfile(currentUser.getId(), updateRequest);
        return ResponseEntity.ok(updatedProfile);
    }

    // Endpoint: GET /api/users/{id} (probado en el script)
    @GetMapping("/{id}")
    public ResponseEntity<UserDTO> getUserProfileById(@PathVariable("id") Long userId) {
        UserDTO userProfile = userService.getUserById(userId);
        return ResponseEntity.ok(userProfile);
    }

    // Endpoint: GET /api/users (probado en el script)
    @GetMapping
    public ResponseEntity<List<UserDTO>> getAllUsers() {
        List<UserDTO> users = userService.getAllUsers();
        return ResponseEntity.ok(users);
    }

    // Endpoint: GET /api/users/{userId}/followers
    @GetMapping("/{userId}/followers")
    public ResponseEntity<List<UserDTO>> getUserFollowers(@PathVariable("userId") Long userId) {
        List<UserDTO> followers = userService.getFollowers(userId);
        return ResponseEntity.ok(followers);
    }

    // Endpoint: GET /api/users/{userId}/following
    @GetMapping("/{userId}/following")
    public ResponseEntity<List<UserDTO>> getUserFollowing(@PathVariable("userId") Long userId) {
        List<UserDTO> following = userService.getFollowing(userId);
        return ResponseEntity.ok(following);
    }

    // Endpoint: GET /api/users/{userId}/following/artists
    @GetMapping("/{userId}/following/artists")
    public ResponseEntity<List<UserDTO>> getFollowedArtists(@PathVariable("userId") Long userId) {
        List<UserDTO> followedArtists = userService.getFollowedArtists(userId);
        return ResponseEntity.ok(followedArtists);
    }

    // Endpoint: POST /api/users/{userId}/follow/{targetUserId}
    @PostMapping("/{userId}/follow/{targetUserId}")
    public ResponseEntity<UserDTO> followUser(
            @PathVariable("userId") Long userId,
            @PathVariable("targetUserId") Long targetUserId) {
        UserDTO updatedUser = userService.followUser(userId, targetUserId);
        return ResponseEntity.ok(updatedUser);
    }

    // Endpoint: DELETE /api/users/{userId}/follow/{targetUserId}
    @DeleteMapping("/{userId}/follow/{targetUserId}")
    public ResponseEntity<UserDTO> unfollowUser(
            @PathVariable("userId") Long userId,
            @PathVariable("targetUserId") Long targetUserId) {
        UserDTO updatedUser = userService.unfollowUser(userId, targetUserId);
        return ResponseEntity.ok(updatedUser);
    }

    // Endpoint: POST /api/users/change-password
    @PostMapping("/change-password")
    public ResponseEntity<?> changePassword(
            @RequestParam("userId") Long userId,
            @Valid @RequestBody ChangePasswordRequest request) {
        try {
            userService.changePassword(userId, request);
            return ResponseEntity.ok().body(
                java.util.Map.of("message", "Contraseña actualizada exitosamente")
            );
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(
                java.util.Map.of("error", e.getMessage())
            );
        }
    }

    // Endpoint: GET /api/users/search/artists - for GA01-96
    @GetMapping("/search/artists")
    public ResponseEntity<List<UserDTO>> searchArtists(@RequestParam("query") String query) {
        List<UserDTO> artists = userService.searchArtists(query);
        return ResponseEntity.ok(artists);
    }

    // Endpoint: GET /api/users/search/artist-ids - for GA01-96 (internal use by music-catalog-service)
    @GetMapping("/search/artist-ids")
    public ResponseEntity<List<Long>> searchArtistIds(@RequestParam("query") String query) {
        List<Long> artistIds = userService.searchArtistIds(query);
        return ResponseEntity.ok(artistIds);
    }

    // Endpoint: POST /api/users/profile/image - Upload profile image
    @PostMapping("/profile/image")
    public ResponseEntity<?> uploadProfileImage(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "userId", required = false) Long userId) {
        try {
            // Use authenticated user's ID if userId is not provided
            Long targetUserId = (userId != null) ? userId : currentUser.getId();

            // Validate that the file is not empty
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body(
                    Map.of("error", "El archivo está vacío")
                );
            }

            // Validate file size (max 5MB)
            if (file.getSize() > 5 * 1024 * 1024) {
                return ResponseEntity.badRequest().body(
                    Map.of("error", "El archivo no debe superar los 5MB")
                );
            }

            // Validate that the file is an image
            String contentType = file.getContentType();
            String fileName = file.getOriginalFilename();

            boolean validContentType = contentType != null && (
                    contentType.equals("image/jpeg") ||
                    contentType.equals("image/jpg") ||
                    contentType.equals("image/png") ||
                    contentType.equals("image/gif") ||
                    contentType.equals("image/webp") ||
                    contentType.equals("application/octet-stream")
            );

            boolean validExtension = false;
            if (fileName != null && fileName.contains(".")) {
                String extension = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
                validExtension = extension.equals("jpg") ||
                               extension.equals("jpeg") ||
                               extension.equals("png") ||
                               extension.equals("gif") ||
                               extension.equals("webp");
            }

            if (!validContentType && !validExtension) {
                return ResponseEntity.badRequest().body(
                    Map.of("error", "El archivo debe ser una imagen (JPEG, PNG, GIF, WEBP)")
                );
            }

            // Upload the profile image
            UserDTO updatedUser = userService.uploadProfileImage(targetUserId, file);

            // Return response in the format expected by the frontend
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Foto de perfil actualizada exitosamente");
            response.put("user", updatedUser);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                Map.of("error", "Error al subir la imagen de perfil: " + e.getMessage())
            );
        }
    }

    // Endpoint: POST /api/users/profile/banner - Upload banner image
    @PostMapping("/profile/banner")
    public ResponseEntity<?> uploadBannerImage(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "userId", required = false) Long userId) {
        try {
            // Use authenticated user's ID if userId is not provided
            Long targetUserId = (userId != null) ? userId : currentUser.getId();

            // Validate that the file is not empty
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body(
                    Map.of("error", "El archivo está vacío")
                );
            }

            // Validate file size (max 10MB for banners)
            if (file.getSize() > 10 * 1024 * 1024) {
                return ResponseEntity.badRequest().body(
                    Map.of("error", "El archivo no debe superar los 10MB")
                );
            }

            // Validate that the file is an image
            String contentType = file.getContentType();
            String fileName = file.getOriginalFilename();

            boolean validContentType = contentType != null && (
                    contentType.equals("image/jpeg") ||
                    contentType.equals("image/jpg") ||
                    contentType.equals("image/png") ||
                    contentType.equals("image/gif") ||
                    contentType.equals("image/webp") ||
                    contentType.equals("application/octet-stream")
            );

            boolean validExtension = false;
            if (fileName != null && fileName.contains(".")) {
                String extension = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
                validExtension = extension.equals("jpg") ||
                               extension.equals("jpeg") ||
                               extension.equals("png") ||
                               extension.equals("gif") ||
                               extension.equals("webp");
            }

            if (!validContentType && !validExtension) {
                return ResponseEntity.badRequest().body(
                    Map.of("error", "El archivo debe ser una imagen (JPEG, PNG, GIF, WEBP)")
                );
            }

            // Upload the banner image
            UserDTO updatedUser = userService.uploadBannerImage(targetUserId, file);

            // Return response in the format expected by the frontend
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Banner actualizado exitosamente");
            response.put("user", updatedUser);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                Map.of("error", "Error al subir el banner: " + e.getMessage())
            );
        }
    }
}