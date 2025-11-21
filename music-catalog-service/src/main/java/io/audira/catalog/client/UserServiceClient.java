package io.audira.catalog.client;

import io.audira.catalog.dto.UserDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

/**
 * REST client for communication with Community Service (User management)
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class UserServiceClient {

    private final RestTemplate restTemplate;

    @Value("${services.user.url:http://172.16.0.4:9001/api/users}")
    private String userServiceUrl;

    /**
     * Get user/artist information by ID
     *
     * @param userId User ID
     * @return UserDTO with user information
     */
    public UserDTO getUserById(Long userId) {
        String url = userServiceUrl + "/" + userId;

        try {
            log.debug("Fetching user information for userId: {} from URL: {}", userId, url);
            UserDTO user = restTemplate.getForObject(url, UserDTO.class);

            if (user == null) {
                log.warn("Received null response from user service for userId: {}", userId);
                return createFallbackUser(userId);
            }

            log.debug("User information retrieved successfully: id={}, username={}",
                    user.getId(), user.getUsername());
            return user;

        } catch (HttpClientErrorException e) {
            log.warn("HTTP error fetching user for userId: {}. Status: {}",
                    userId, e.getStatusCode());
            return createFallbackUser(userId);

        } catch (ResourceAccessException e) {
            log.warn("Connection error accessing user service at {} for userId: {}",
                    url, userId);
            return createFallbackUser(userId);

        } catch (Exception e) {
            log.error("Unexpected error fetching user for userId: {}", userId, e);
            return createFallbackUser(userId);
        }
    }

    /**
     * Create a fallback user when the service is unavailable
     */
    private UserDTO createFallbackUser(Long userId) {
        return UserDTO.builder()
                .id(userId)
                .username("User #" + userId)
                .artistName("Artist #" + userId)
                .build();
    }
}
