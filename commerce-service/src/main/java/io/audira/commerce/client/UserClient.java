package io.audira.commerce.client;

import io.audira.commerce.dto.UserDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

@Component
@RequiredArgsConstructor
@Slf4j
public class UserClient {

    private final RestTemplate restTemplate;

    @Value("${services.user.url:http://172.16.0.4:9001/api/users}")
    private String userServiceUrl;

    public UserDTO getUserById(Long userId) {
        String url = userServiceUrl + "/" + userId;

        try {
            log.info("=== Fetching user information for userId: {} from URL: {} ===", userId, url);
            UserDTO user = restTemplate.getForObject(url, UserDTO.class);

            if (user == null) {
                log.error("Received null response from user service for userId: {}", userId);
                throw new RuntimeException("User service returned null for userId: " + userId);
            }

            log.info("User information retrieved successfully: id={}, email={}, name={} {}",
                    user.getId(), user.getEmail(), user.getFirstName(), user.getLastName());
            return user;

        } catch (HttpClientErrorException e) {
            log.error("HTTP error fetching user information for userId: {}. Status: {}, Response: {}",
                    userId, e.getStatusCode(), e.getResponseBodyAsString(), e);
            throw new RuntimeException("Failed to fetch user information for userId: " + userId +
                    ". HTTP Status: " + e.getStatusCode(), e);

        } catch (ResourceAccessException e) {
            log.error("Connection error accessing user service at {} for userId: {}. " +
                    "Please verify that community-service is running on the correct port.",
                    url, userId, e);
            throw new RuntimeException("Cannot connect to user service at " + url +
                    ". Please ensure community-service is running.", e);

        } catch (Exception e) {
            log.error("Unexpected error fetching user information for userId: {} from URL: {}",
                    userId, url, e);
            throw new RuntimeException("Unexpected error fetching user information for userId: " + userId, e);
        }
    }
}
