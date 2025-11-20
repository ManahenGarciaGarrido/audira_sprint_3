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
