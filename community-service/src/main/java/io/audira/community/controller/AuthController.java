package io.audira.community.controller;

import io.audira.community.dto.AuthResponse;
import io.audira.community.dto.LoginRequest;
import io.audira.community.dto.RegisterRequest;
import io.audira.community.model.User;
import io.audira.community.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@CrossOrigin(origins = "*", maxAge = 3600)
public class AuthController {

    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);
    private final UserService userService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        logger.info("Register request received for email: {}", request.getEmail());
        try {
            AuthResponse response = userService.registerUser(request);
            logger.info("User registered successfully: {}", request.getEmail());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Error during registration: {}", e.getMessage(), e);
            throw e;
        }
    }
    @PostMapping("/verify-email/{userId}")
    public ResponseEntity<Map<String, Object>> verifyEmail(@PathVariable Long userId) {
        logger.info("Email verification request received for userId: {}", userId);

        try {
            User user = userService.verifyEmail(userId);

            Map<String, Object> response = new HashMap<>();
            response.put("user", user);
            response.put("message", "Email verified successfully!");

            logger.info("Email verified successfully for userId: {}", userId);
            return ResponseEntity.ok(response);

        } catch (RuntimeException e) {
            logger.error("Error verifying email for userId {}: {}", userId, e.getMessage());
            throw e;
        }
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        logger.info("Login request received for: {}", request.getEmailOrUsername());
        try {
            AuthResponse response = userService.loginUser(request);
            logger.info("User logged in successfully: {}", request.getEmailOrUsername());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Error during login: {}", e.getMessage(), e);
            throw e;
        }
    }
}