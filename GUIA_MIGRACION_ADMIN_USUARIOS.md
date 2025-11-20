# Guía de Migración: Gestión de Usuarios Admin por Subtarea

Esta guía detalla **TODOS** los cambios necesarios para implementar la gestión de usuarios en el panel de administración, organizados por subtarea para facilitar la migración al repositorio original de GitHub.

---

## 📋 Índice de Subtareas

1. [GA01-164: Buscar/editar usuario (roles, estado)](#ga01-164-buscareditar-usuario-roles-estado)
2. [GA01-165: Suspender/reactivar cuentas](#ga01-165-suspenderreactivar-cuentas)

---

## 📦 Información General

### Contexto
El panel de administración ya tiene la UI básica implementada pero **sin funcionalidad real**. Esta guía implementa los endpoints del backend y conecta el frontend para gestionar usuarios completamente.

### Arquitectura de Roles
- **USER**: Usuario regular
- **ARTIST**: Artista con capacidades de estudio
- **ADMIN**: Administrador con acceso al panel admin

### Sistema de Permisos
- Los endpoints de admin requieren autenticación JWT
- Protección con `@PreAuthorize("hasRole('ADMIN')")`
- SecurityConfig ya tiene `@EnableMethodSecurity` habilitado

---

## GA01-164: Buscar/editar usuario (roles, estado)

### 📁 Archivos a Crear/Modificar (Backend)

#### 1. CREAR: `ChangeRoleRequest.java`

**Ubicación**: `community-service/src/main/java/io/audira/community/dto/ChangeRoleRequest.java`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```java
package io.audira.community.dto;

import io.audira.community.model.UserRole;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for changing user role
 * GA01-164: Buscar/editar usuario (roles, estado)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChangeRoleRequest {

    @NotNull(message = "Role is required")
    private UserRole role;
}
```

#### 2. CREAR: `AdminController.java`

**Ubicación**: `community-service/src/main/java/io/audira/community/controller/AdminController.java`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```java
package io.audira.community.controller;

import io.audira.community.dto.ChangeRoleRequest;
import io.audira.community.dto.ChangeStatusRequest;
import io.audira.community.dto.UserDTO;
import io.audira.community.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Admin Controller for user management operations
 * GA01-164: Buscar/editar usuario (roles, estado)
 * GA01-165: Suspender/reactivar cuentas
 */
@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")  // All endpoints require ADMIN role
public class AdminController {

    private final UserService userService;

    /**
     * Get all users (admin view)
     * GA01-164: Buscar/editar usuario
     */
    @GetMapping
    public ResponseEntity<List<UserDTO>> getAllUsersAdmin() {
        List<UserDTO> users = userService.getAllUsers();
        return ResponseEntity.ok(users);
    }

    /**
     * Get user by ID (admin view)
     * GA01-164: Buscar/editar usuario
     */
    @GetMapping("/{userId}")
    public ResponseEntity<UserDTO> getUserByIdAdmin(@PathVariable Long userId) {
        UserDTO user = userService.getUserById(userId);
        return ResponseEntity.ok(user);
    }

    /**
     * Change user role
     * GA01-164: Buscar/editar usuario (roles, estado)
     *
     * @param userId User ID to change role
     * @param request ChangeRoleRequest containing new role
     * @return Updated user DTO
     */
    @PutMapping("/{userId}/role")
    public ResponseEntity<UserDTO> changeUserRole(
            @PathVariable Long userId,
            @Valid @RequestBody ChangeRoleRequest request
    ) {
        UserDTO updatedUser = userService.changeUserRole(userId, request.getRole());
        return ResponseEntity.ok(updatedUser);
    }

    /**
     * Change user active status (suspend/activate account)
     * GA01-165: Suspender/reactivar cuentas
     *
     * @param userId User ID to change status
     * @param request ChangeStatusRequest containing new active status
     * @return Updated user DTO
     */
    @PutMapping("/{userId}/status")
    public ResponseEntity<UserDTO> changeUserStatus(
            @PathVariable Long userId,
            @Valid @RequestBody ChangeStatusRequest request
    ) {
        UserDTO updatedUser = userService.changeUserStatus(userId, request.getIsActive());
        return ResponseEntity.ok(updatedUser);
    }

    /**
     * Suspend user account (shortcut for setting isActive = false)
     * GA01-165: Suspender/reactivar cuentas
     */
    @PutMapping("/{userId}/suspend")
    public ResponseEntity<UserDTO> suspendUser(@PathVariable Long userId) {
        UserDTO updatedUser = userService.changeUserStatus(userId, false);
        return ResponseEntity.ok(updatedUser);
    }

    /**
     * Activate user account (shortcut for setting isActive = true)
     * GA01-165: Suspender/reactivar cuentas
     */
    @PutMapping("/{userId}/activate")
    public ResponseEntity<UserDTO> activateUser(@PathVariable Long userId) {
        UserDTO updatedUser = userService.changeUserStatus(userId, true);
        return ResponseEntity.ok(updatedUser);
    }

    /**
     * Get user statistics
     * GA01-164: Buscar/editar usuario
     */
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getUserStatistics() {
        Map<String, Object> stats = userService.getUserStatistics();
        return ResponseEntity.ok(stats);
    }

    /**
     * Search users by query (username, email, name)
     * GA01-164: Buscar/editar usuario
     */
    @GetMapping("/search")
    public ResponseEntity<List<UserDTO>> searchUsers(@RequestParam String query) {
        List<UserDTO> users = userService.searchUsers(query);
        return ResponseEntity.ok(users);
    }

    /**
     * Get users by role
     * GA01-164: Buscar/editar usuario
     */
    @GetMapping("/by-role/{role}")
    public ResponseEntity<List<UserDTO>> getUsersByRole(@PathVariable String role) {
        List<UserDTO> users = userService.getUsersByRole(role);
        return ResponseEntity.ok(users);
    }

    /**
     * Verify user email (admin action)
     * GA01-164: Buscar/editar usuario
     */
    @PutMapping("/{userId}/verify")
    public ResponseEntity<UserDTO> verifyUserEmail(@PathVariable Long userId) {
        UserDTO updatedUser = userService.adminVerifyUser(userId);
        return ResponseEntity.ok(updatedUser);
    }
}
```

#### 3. MODIFICAR: `UserService.java`

**Ubicación**: `community-service/src/main/java/io/audira/community/service/UserService.java`

**Acción**: Añadir métodos al final de la clase (antes del cierre `}`)

**Buscar** (alrededor de línea 556):
```java
            throw new RuntimeException("Error al subir la imagen de banner: " + e.getMessage());
        }
    }
}
```

**Reemplazar con**:
```java
            throw new RuntimeException("Error al subir la imagen de banner: " + e.getMessage());
        }
    }

    // Admin-specific methods for user management
    // GA01-164: Buscar/editar usuario (roles, estado)
    // GA01-165: Suspender/reactivar cuentas

    /**
     * Change user role (Admin operation)
     * GA01-164: Buscar/editar usuario (roles, estado)
     */
    @Transactional
    public UserDTO changeUserRole(Long userId, UserRole newRole) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Check if role is actually changing
        if (user.getRole() == newRole) {
            return mapToDTO(user);
        }

        // Get current role for logging
        UserRole oldRole = user.getRole();

        // Delete old user entity
        userRepository.delete(user);
        userRepository.flush();

        // Create new user entity based on new role
        User newUser;
        if (newRole == UserRole.ARTIST) {
            newUser = Artist.builder()
                    .id(user.getId())
                    .email(user.getEmail())
                    .username(user.getUsername())
                    .password(user.getPassword())
                    .firstName(user.getFirstName())
                    .lastName(user.getLastName())
                    .role(newRole)
                    .uid(user.getUid())
                    .bio(user.getBio())
                    .profileImageUrl(user.getProfileImageUrl())
                    .bannerImageUrl(user.getBannerImageUrl())
                    .location(user.getLocation())
                    .website(user.getWebsite())
                    .twitterUrl(user.getTwitterUrl())
                    .instagramUrl(user.getInstagramUrl())
                    .facebookUrl(user.getFacebookUrl())
                    .youtubeUrl(user.getYoutubeUrl())
                    .spotifyUrl(user.getSpotifyUrl())
                    .tiktokUrl(user.getTiktokUrl())
                    .isActive(user.getIsActive())
                    .isVerified(user.getIsVerified())
                    .followerIds(user.getFollowerIds())
                    .followingIds(user.getFollowingIds())
                    .createdAt(user.getCreatedAt())
                    .build();
        } else {
            newUser = RegularUser.builder()
                    .id(user.getId())
                    .email(user.getEmail())
                    .username(user.getUsername())
                    .password(user.getPassword())
                    .firstName(user.getFirstName())
                    .lastName(user.getLastName())
                    .role(newRole)
                    .uid(user.getUid())
                    .bio(user.getBio())
                    .profileImageUrl(user.getProfileImageUrl())
                    .bannerImageUrl(user.getBannerImageUrl())
                    .location(user.getLocation())
                    .website(user.getWebsite())
                    .twitterUrl(user.getTwitterUrl())
                    .instagramUrl(user.getInstagramUrl())
                    .facebookUrl(user.getFacebookUrl())
                    .youtubeUrl(user.getYoutubeUrl())
                    .spotifyUrl(user.getSpotifyUrl())
                    .tiktokUrl(user.getTiktokUrl())
                    .isActive(user.getIsActive())
                    .isVerified(user.getIsVerified())
                    .followerIds(user.getFollowerIds())
                    .followingIds(user.getFollowingIds())
                    .createdAt(user.getCreatedAt())
                    .build();
        }

        newUser = userRepository.save(newUser);

        logger.info("User role changed: {} ({}) - {} -> {}",
                    user.getUsername(), user.getEmail(), oldRole, newRole);

        return mapToDTO(newUser);
    }

    /**
     * Change user active status (Admin operation)
     * GA01-165: Suspender/reactivar cuentas
     */
    @Transactional
    public UserDTO changeUserStatus(Long userId, Boolean isActive) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setIsActive(isActive);
        user = userRepository.save(user);

        String action = isActive ? "activated" : "suspended";
        logger.info("User account {}: {} ({})", action, user.getUsername(), user.getEmail());

        return mapToDTO(user);
    }

    /**
     * Get user statistics for admin dashboard
     * GA01-164: Buscar/editar usuario
     */
    public Map<String, Object> getUserStatistics() {
        List<User> allUsers = userRepository.findAll();

        long totalUsers = allUsers.size();
        long activeUsers = allUsers.stream().filter(User::getIsActive).count();
        long inactiveUsers = totalUsers - activeUsers;
        long verifiedUsers = allUsers.stream().filter(User::getIsVerified).count();

        long regularUsers = allUsers.stream()
                .filter(u -> u.getRole() == UserRole.USER)
                .count();
        long artists = allUsers.stream()
                .filter(u -> u.getRole() == UserRole.ARTIST)
                .count();
        long admins = allUsers.stream()
                .filter(u -> u.getRole() == UserRole.ADMIN)
                .count();

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalUsers", totalUsers);
        stats.put("activeUsers", activeUsers);
        stats.put("inactiveUsers", inactiveUsers);
        stats.put("verifiedUsers", verifiedUsers);
        stats.put("unverifiedUsers", totalUsers - verifiedUsers);
        stats.put("regularUsers", regularUsers);
        stats.put("artists", artists);
        stats.put("admins", admins);

        return stats;
    }

    /**
     * Search users by query (username, email, or name)
     * GA01-164: Buscar/editar usuario
     */
    public List<UserDTO> searchUsers(String query) {
        String lowerQuery = query.toLowerCase();
        List<User> allUsers = userRepository.findAll();

        return allUsers.stream()
                .filter(user ->
                    user.getUsername().toLowerCase().contains(lowerQuery) ||
                    user.getEmail().toLowerCase().contains(lowerQuery) ||
                    user.getFirstName().toLowerCase().contains(lowerQuery) ||
                    user.getLastName().toLowerCase().contains(lowerQuery))
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Admin verify user email
     * GA01-164: Buscar/editar usuario
     */
    @Transactional
    public UserDTO adminVerifyUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setIsVerified(true);
        user = userRepository.save(user);

        logger.info("User verified by admin: {} ({})", user.getUsername(), user.getEmail());

        return mapToDTO(user);
    }
}
```

---

### 📁 Archivos a Crear/Modificar (Frontend)

#### 4. CREAR: `admin_service.dart`

**Ubicación**: `audira_frontend/lib/core/api/services/admin_service.dart`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/constants.dart';
import '../../models/api_response.dart';
import '../../models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for admin user management operations
/// GA01-164: Buscar/editar usuario (roles, estado)
/// GA01-165: Suspender/reactivar cuentas
class AdminService {
  final String baseUrl = ApiConstants.baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Get authorization header with JWT token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get all users (admin endpoint)
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<List<User>>> getAllUsersAdmin() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final users = data.map((json) => User.fromJson(json)).toList();
        return ApiResponse.success(users);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error loading users: $e');
    }
  }

  /// Get user by ID (admin endpoint)
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<User>> getUserByIdAdmin(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        return ApiResponse.success(user);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error loading user: $e');
    }
  }

  /// Change user role
  /// GA01-164: Buscar/editar usuario (roles, estado)
  Future<ApiResponse<User>> changeUserRole(int userId, String newRole) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/role'),
        headers: headers,
        body: json.encode({'role': newRole}),
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        return ApiResponse.success(user);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error changing user role: $e');
    }
  }

  /// Change user active status
  /// GA01-165: Suspender/reactivar cuentas
  Future<ApiResponse<User>> changeUserStatus(int userId, bool isActive) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/status'),
        headers: headers,
        body: json.encode({'isActive': isActive}),
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        return ApiResponse.success(user);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error changing user status: $e');
    }
  }

  /// Suspend user account (shortcut)
  /// GA01-165: Suspender/reactivar cuentas
  Future<ApiResponse<User>> suspendUser(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/suspend'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        return ApiResponse.success(user);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error suspending user: $e');
    }
  }

  /// Activate user account (shortcut)
  /// GA01-165: Suspender/reactivar cuentas
  Future<ApiResponse<User>> activateUser(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/activate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        return ApiResponse.success(user);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error activating user: $e');
    }
  }

  /// Get user statistics
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<Map<String, dynamic>>> getUserStatistics() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final stats = json.decode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(stats);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error loading statistics: $e');
    }
  }

  /// Search users
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<List<User>>> searchUsers(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users/search?query=$query'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final users = data.map((json) => User.fromJson(json)).toList();
        return ApiResponse.success(users);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error searching users: $e');
    }
  }

  /// Get users by role
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<List<User>>> getUsersByRole(String role) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users/by-role/$role'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final users = data.map((json) => User.fromJson(json)).toList();
        return ApiResponse.success(users);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error loading users by role: $e');
    }
  }

  /// Verify user email (admin action)
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<User>> verifyUserEmail(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/verify'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        return ApiResponse.success(user);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error verifying user: $e');
    }
  }

  /// Extract error message from response
  String _extractError(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      if (data is Map && data.containsKey('error')) {
        return data['error'];
      }
      return 'Error: ${response.statusCode}';
    } catch (e) {
      return 'Error: ${response.statusCode} - ${response.body}';
    }
  }
}
```

#### 5. MODIFICAR: `admin_users_screen.dart`

**Ubicación**: `audira_frontend/lib/features/admin/screens/admin_users_screen.dart`

**Cambios necesarios**:

1. **Cambiar import** (línea 3):

**De**:
```dart
import 'package:audira_frontend/core/api/auth_service.dart';
```

**A**:
```dart
import 'package:audira_frontend/core/api/services/admin_service.dart';
```

2. **Cambiar servicio** (línea 17):

**De**:
```dart
  final AuthService _authService = AuthService();
```

**A**:
```dart
  final AdminService _adminService = AdminService();
```

3. **Actualizar método `_loadUsers`** (línea 38-60):

**Buscar**:
```dart
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _authService.getAllUsers();
      if (response.success && response.data != null) {
        setState(() {
          _users = response.data!;
          _applyFilters();
        });
      } else {
        setState(() => _error = response.error ?? 'Failed to load users');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }
```

**Reemplazar con**:
```dart
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // GA01-164: Using admin endpoint for user management
      final response = await _adminService.getAllUsersAdmin();
      if (response.success && response.data != null) {
        setState(() {
          _users = response.data!;
          _applyFilters();
        });
      } else {
        setState(() => _error = response.error ?? 'Failed to load users');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }
```

4. **Actualizar método `_changeUserRole`** (línea 84-109):

**Buscar**:
```dart
  Future<void> _changeUserRole(User user) async {
    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['USER', 'ARTIST', 'ADMIN'].map((role) {
            return RadioListTile<String>(
              title: Text(role),
              value: role,
              groupValue: user.role,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
      ),
    );

    if (selectedRole != null && selectedRole != user.role) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User role changed to $selectedRole')),
      );
      _loadUsers();
    }
  }
```

**Reemplazar con**:
```dart
  Future<void> _changeUserRole(User user) async {
    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['USER', 'ARTIST', 'ADMIN'].map((role) {
            return RadioListTile<String>(
              title: Text(role),
              value: role,
              groupValue: user.role,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
      ),
    );

    if (selectedRole != null && selectedRole != user.role) {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // GA01-164: Change user role via admin endpoint
        final response = await _adminService.changeUserRole(
          user.id,
          selectedRole,
        );

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User role changed to $selectedRole'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
```

5. **Actualizar método `_toggleUserStatus`** (línea 111-140):

**Buscar**:
```dart
  Future<void> _toggleUserStatus(User user) async {
    final action = user.isActive ? 'deactivate' : 'activate';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.toUpperCase()} User'),
        content: Text('Are you sure you want to $action this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.red : Colors.green,
            ),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ${action}d successfully')),
      );
      _loadUsers();
    }
  }
```

**Reemplazar con**:
```dart
  Future<void> _toggleUserStatus(User user) async {
    final action = user.isActive ? 'suspend' : 'activate';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.toUpperCase()} User'),
        content: Text(
          user.isActive
              ? 'Are you sure you want to suspend this user? They will not be able to access the platform.'
              : 'Are you sure you want to activate this user? They will regain access to the platform.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.red : Colors.green,
            ),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // GA01-165: Change user status via admin endpoint
        final response = await _adminService.changeUserStatus(
          user.id,
          !user.isActive,
        );

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User ${action}d successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
```

---

## GA01-165: Suspender/reactivar cuentas

### 📁 Archivos a Crear/Modificar

#### 1. CREAR: `ChangeStatusRequest.java`

**Ubicación**: `community-service/src/main/java/io/audira/community/dto/ChangeStatusRequest.java`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```java
package io.audira.community.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for changing user active status
 * GA01-165: Suspender/reactivar cuentas
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChangeStatusRequest {

    @NotNull(message = "Active status is required")
    private Boolean isActive;
}
```

**Nota**: Los endpoints de suspender/reactivar ya están incluidos en el `AdminController.java` creado en GA01-164:
- `PUT /api/admin/users/{userId}/status` - Cambiar estado (genérico)
- `PUT /api/admin/users/{userId}/suspend` - Atajo para suspender
- `PUT /api/admin/users/{userId}/activate` - Atajo para activar

Y el método `changeUserStatus()` ya está incluido en `UserService.java` (ver GA01-164).

---

## ✅ Checklist de Verificación

### GA01-164: Buscar/editar usuario (roles, estado)

**Backend:**
- [ ] `ChangeRoleRequest.java` creado
- [ ] `AdminController.java` creado
- [ ] Métodos añadidos en `UserService.java`:
  - [ ] `changeUserRole()`
  - [ ] `getUserStatistics()`
  - [ ] `searchUsers()`
  - [ ] `adminVerifyUser()`
- [ ] Endpoints protegidos con `@PreAuthorize("hasRole('ADMIN')")`
- [ ] `@EnableMethodSecurity` habilitado en SecurityConfig (ya existe)

**Frontend:**
- [ ] `admin_service.dart` creado
- [ ] Import cambiado en `admin_users_screen.dart`
- [ ] Servicio cambiado a `AdminService`
- [ ] Método `_loadUsers()` actualizado
- [ ] Método `_changeUserRole()` actualizado
- [ ] Loading states implementados
- [ ] Error handling implementado

**Funcionalidad:**
- [ ] Listar usuarios funciona
- [ ] Buscar usuarios funciona
- [ ] Filtrar por rol funciona
- [ ] Cambiar rol de usuario funciona
- [ ] Se ve loading indicator al cambiar rol
- [ ] Se muestra mensaje de éxito/error
- [ ] Lista se recarga después de cambio

### GA01-165: Suspender/reactivar cuentas

**Backend:**
- [ ] `ChangeStatusRequest.java` creado
- [ ] Métodos añadidos en `UserService.java`:
  - [ ] `changeUserStatus()`
- [ ] Endpoints en `AdminController.java`:
  - [ ] `PUT /api/admin/users/{userId}/status`
  - [ ] `PUT /api/admin/users/{userId}/suspend`
  - [ ] `PUT /api/admin/users/{userId}/activate`

**Frontend:**
- [ ] Métodos en `admin_service.dart`:
  - [ ] `changeUserStatus()`
  - [ ] `suspendUser()` (atajo)
  - [ ] `activateUser()` (atajo)
- [ ] Método `_toggleUserStatus()` actualizado en `admin_users_screen.dart`
- [ ] Diálogo de confirmación con contexto claro
- [ ] Loading indicator implementado
- [ ] Error handling implementado

**Funcionalidad:**
- [ ] Suspender usuario funciona
- [ ] Activar usuario funciona
- [ ] Se ve loading indicator al cambiar estado
- [ ] Diálogo muestra información clara (suspender vs activar)
- [ ] Se muestra mensaje de éxito/error
- [ ] Lista se recarga después de cambio
- [ ] Estado se persiste en base de datos

---

## 📝 Notas Técnicas

### Arquitectura de Cambio de Rol

El cambio de rol requiere **recrear la entidad de usuario** debido a la jerarquía polimórfica:
- `User` (abstract)
  - `RegularUser` (USER y ADMIN roles)
  - `Artist` (ARTIST role)

**Proceso:**
1. Cargar usuario actual
2. Eliminar entidad actual (`delete` + `flush`)
3. Crear nueva entidad del tipo correspondiente
4. Copiar todos los datos
5. Guardar nueva entidad

### Sistema de Permisos

- **@PreAuthorize("hasRole('ADMIN')")**: Requiere rol ADMIN para acceder
- **SecurityConfig**: Ya tiene `@EnableMethodSecurity` habilitado
- **JWT**: Token se envía en header `Authorization: Bearer {token}`

### Endpoints Admin

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/admin/users` | Listar todos los usuarios |
| GET | `/api/admin/users/{userId}` | Obtener usuario por ID |
| PUT | `/api/admin/users/{userId}/role` | Cambiar rol |
| PUT | `/api/admin/users/{userId}/status` | Cambiar estado activo |
| PUT | `/api/admin/users/{userId}/suspend` | Suspender cuenta |
| PUT | `/api/admin/users/{userId}/activate` | Activar cuenta |
| GET | `/api/admin/users/stats` | Estadísticas |
| GET | `/api/admin/users/search?query=X` | Buscar usuarios |
| GET | `/api/admin/users/by-role/{role}` | Filtrar por rol |
| PUT | `/api/admin/users/{userId}/verify` | Verificar email |

### Estado de Usuario

- **isActive**: `true` = cuenta activa, `false` = cuenta suspendida
- **isVerified**: `true` = email verificado, `false` = pendiente verificación

### Filtros Frontend

La pantalla ya tiene implementados:
- Búsqueda por username, email, firstName, lastName
- Filtro por rol (ALL, USER, ARTIST, ADMIN)
- Combinación de búsqueda + filtro

---

## 🚀 Comandos de Migración

### Commit Messages Sugeridos

```bash
# GA01-164
git add .
git commit -m "feat: Implementar búsqueda y edición de usuarios admin (GA01-164)

- Crear AdminController con endpoints protegidos por rol
- Añadir endpoint para cambiar rol de usuario
- Implementar cambio polimórfico de entidad User/Artist
- Crear AdminService en frontend
- Actualizar admin_users_screen para usar endpoints reales
- Añadir estadísticas de usuarios
- Implementar búsqueda multi-campo"

# GA01-165
git add .
git commit -m "feat: Implementar suspensión y activación de cuentas (GA01-165)

- Añadir endpoints para cambiar estado de usuario
- Crear atajos suspend y activate
- Actualizar diálogos de confirmación
- Añadir loading states
- Implementar feedback visual completo
- Persistir estado en base de datos"

# O commit combinado
git add .
git commit -m "feat: Implementar gestión de usuarios en panel admin (GA01-164, GA01-165)

GA01-164: Buscar/editar usuario (roles, estado)
- AdminController con @PreAuthorize('ADMIN')
- Cambio de rol con recreación de entidad
- AdminService en frontend
- Búsqueda y filtros completos

GA01-165: Suspender/reactivar cuentas
- Endpoints de cambio de estado
- Diálogos con contexto claro
- Loading y error handling

Archivos backend:
- AdminController.java (nuevo)
- ChangeRoleRequest.java (nuevo)
- ChangeStatusRequest.java (nuevo)
- UserService.java (métodos añadidos)

Archivos frontend:
- admin_service.dart (nuevo)
- admin_users_screen.dart (actualizado)"
```

---

## 🔧 Testing

### Casos de Prueba GA01-164

1. **Cambiar rol USER → ARTIST**
   - ✓ Usuario debe poder acceder a Studio
   - ✓ Debe mantenerse toda la información del usuario
   - ✓ Followers/following deben mantenerse

2. **Cambiar rol ARTIST → USER**
   - ✓ Usuario ya no debe ver Studio
   - ✓ Datos de artista (artistName, etc.) se pierden
   - ✓ Relaciones sociales se mantienen

3. **Cambiar rol a ADMIN**
   - ✓ Usuario debe ver panel admin
   - ✓ Todos los permisos de admin habilitados

4. **Búsqueda de usuarios**
   - ✓ Por username: "john" → encuentra "john_doe"
   - ✓ Por email: "gmail" → encuentra todos con gmail
   - ✓ Por nombre: "John" → encuentra firstName o lastName

5. **Filtros**
   - ✓ Filtro USER → solo usuarios regulares
   - ✓ Filtro ARTIST → solo artistas
   - ✓ Filtro ADMIN → solo admins
   - ✓ Combinación filtro + búsqueda funciona

### Casos de Prueba GA01-165

1. **Suspender usuario activo**
   - ✓ isActive cambia a false
   - ✓ Usuario no puede hacer login
   - ✓ Sesión actual se mantiene (hasta logout)
   - ✓ Se muestra estado en lista de usuarios

2. **Activar usuario suspendido**
   - ✓ isActive cambia a true
   - ✓ Usuario puede hacer login nuevamente
   - ✓ Todos los datos se mantienen

3. **Intentar suspender a sí mismo**
   - ⚠️ Debería haber validación (no implementado aún)

4. **Suspender último admin**
   - ⚠️ Debería haber validación (no implementado aún)

---

## ❗ Problemas Conocidos y Soluciones

### Problema: No se puede login después de cambiar rol

**Síntoma**: Usuario no puede iniciar sesión después de cambio de rol

**Causa**: Token JWT contiene rol antiguo

**Solución**: Usuario debe cerrar sesión y volver a iniciar sesión para obtener nuevo token

### Problema: Error "Forbidden" al llamar endpoints admin

**Síntoma**: HTTP 403 Forbidden al intentar cambiar rol/estado

**Causa**: Usuario no tiene rol ADMIN o token no es válido

**Solución**: Verificar:
1. Usuario tiene role='ADMIN' en BD
2. Token JWT es válido y contiene rol ADMIN
3. Header Authorization está presente

### Problema: Datos de artista se pierden al cambiar de ARTIST a USER

**Síntoma**: artistName, artistBio, etc. desaparecen

**Causa**: RegularUser no tiene esos campos

**Solución**: Esto es **comportamiento esperado**. Los datos específicos de Artist no se mantienen al cambiar a USER. Documentar claramente en la UI.

### Problema: Cambio de rol muy lento

**Síntoma**: Loading dialog se muestra por varios segundos

**Causa**: Delete + flush + create + save son operaciones pesadas

**Solución**: Esto es **normal** para cambios de tipo de entidad. Optimizaciones posibles:
- Usar índices en BD
- Batch operations si hay múltiples cambios
- Consider caching

---

## 📞 Mejoras Futuras

1. **Validaciones adicionales**:
   - No permitir suspender último admin
   - No permitir auto-suspensión
   - Requerir confirmación adicional para cambios críticos

2. **Audit log**:
   - Registrar quién hizo qué cambio
   - Timestamp de cambios
   - Historial de cambios de rol

3. **Notificaciones**:
   - Email al usuario cuando cambia su rol
   - Email al usuario cuando se suspende su cuenta
   - Notificaciones in-app

4. **Bulk operations**:
   - Cambiar rol de múltiples usuarios
   - Suspender múltiples usuarios
   - Exportar lista de usuarios

5. **Filtros avanzados**:
   - Por fecha de registro
   - Por verificación de email
   - Por último login
   - Por actividad

6. **Paginación**:
   - Para listas grandes de usuarios
   - Server-side pagination
   - Lazy loading

---

## 🎯 Orden Recomendado de Implementación

1. **Primero**: Backend completo (DTOs + Controller + Service)
2. **Segundo**: AdminService en frontend
3. **Tercero**: Actualizar admin_users_screen
4. **Cuarto**: Testing completo

### Dependencias
- **GA01-165** depende de **GA01-164** (usa mismo controller y estructura)
- Ambas subtareas pueden implementarse en un solo commit

---

## 📚 Referencias

- User Model: `community-service/src/main/java/io/audira/community/model/User.java`
- User Service: `community-service/src/main/java/io/audira/community/service/UserService.java`
- Security Config: `community-service/src/main/java/io/audira/community/config/SecurityConfig.java`
- Admin Users Screen: `audira_frontend/lib/features/admin/screens/admin_users_screen.dart`

---

Para preguntas sobre esta guía de migración, consultar la documentación del proyecto o contactar al equipo de desarrollo.
