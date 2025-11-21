package io.audira.catalog.client;

import io.audira.catalog.dto.OrderDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;

/**
 * REST client for communication with Commerce Service
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class CommerceServiceClient {

    private final RestTemplate restTemplate;

    @Value("${services.commerce.url:http://172.16.0.4:8083}")
    private String commerceServiceUrl;

    /**
     * Get all orders for a user
     *
     * @param userId User ID
     * @return List of orders
     */
    public List<OrderDTO> getUserOrders(Long userId) {
        String url = String.format("%s/api/orders/user/%d", commerceServiceUrl, userId);

        try {
            log.debug("Fetching orders for user {} from URL: {}", userId, url);

            ResponseEntity<List<OrderDTO>> response = restTemplate.exchange(
                url,
                HttpMethod.GET,
                null,
                new ParameterizedTypeReference<List<OrderDTO>>() {}
            );

            List<OrderDTO> orders = response.getBody();
            if (orders == null) {
                log.warn("Received null response from commerce service for user {}", userId);
                return new ArrayList<>();
            }

            log.debug("Orders retrieved successfully for user {}: {} orders", userId, orders.size());
            return orders;

        } catch (HttpClientErrorException e) {
            log.warn("HTTP error fetching orders for user {}. Status: {}", userId, e.getStatusCode());
            return new ArrayList<>();

        } catch (ResourceAccessException e) {
            log.warn("Connection error accessing commerce service at {} for user {}", url, userId);
            return new ArrayList<>();

        } catch (Exception e) {
            log.error("Unexpected error fetching orders for user {}", userId, e);
            return new ArrayList<>();
        }
    }

    /**
     * Get all orders
     *
     * @return List of all orders
     */
    public List<OrderDTO> getAllOrders() {
        String url = String.format("%s/api/orders", commerceServiceUrl);

        try {
            log.debug("Fetching all orders from URL: {}", url);

            ResponseEntity<List<OrderDTO>> response = restTemplate.exchange(
                url,
                HttpMethod.GET,
                null,
                new ParameterizedTypeReference<List<OrderDTO>>() {}
            );

            List<OrderDTO> orders = response.getBody();
            if (orders == null) {
                log.warn("Received null response from commerce service for all orders");
                return new ArrayList<>();
            }

            log.debug("All orders retrieved successfully: {} orders", orders.size());
            return orders;

        } catch (HttpClientErrorException e) {
            log.warn("HTTP error fetching all orders. Status: {}", e.getStatusCode());
            return new ArrayList<>();

        } catch (ResourceAccessException e) {
            log.warn("Connection error accessing commerce service at {}", url);
            return new ArrayList<>();

        } catch (Exception e) {
            log.error("Unexpected error fetching all orders", e);
            return new ArrayList<>();
        }
    }
}
