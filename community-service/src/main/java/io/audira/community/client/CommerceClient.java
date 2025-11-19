package io.audira.community.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.HttpClientErrorException;

/**
 * Cliente REST para comunicación con Commerce Service
 * Verifica si un usuario ha comprado un producto antes de permitir valorarlo
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class CommerceClient {

    private final RestTemplate restTemplate;

    @Value("${services.commerce.url:http://172.16.0.4:8083}")
    private String commerceServiceUrl;

    /**
     * Verifica si un usuario ha comprado un producto específico
     *
     * @param userId ID del usuario
     * @param itemType Tipo de producto (SONG, ALBUM)
     * @param itemId ID del producto
     * @return true si el usuario ha comprado el producto, false en caso contrario
     */
    public boolean hasPurchasedItem(Long userId, String itemType, Long itemId) {
        try {
            String url = String.format(
                "%s/api/library/user/%d/check/%s/%d",
                commerceServiceUrl,
                userId,
                itemType.toUpperCase(),
                itemId
            );

            log.debug("Checking if user {} has purchased {} {}", userId, itemType, itemId);

            Boolean result = restTemplate.getForObject(url, Boolean.class);

            log.debug("Purchase check result for user {} on {} {}: {}",
                userId, itemType, itemId, result);

            return Boolean.TRUE.equals(result);

        } catch (HttpClientErrorException.NotFound e) {
            log.warn("Purchase not found for user {} on {} {}", userId, itemType, itemId);
            return false;
        } catch (Exception e) {
            log.error("Error checking purchase for user {} on {} {}: {}",
                userId, itemType, itemId, e.getMessage());
            // En caso de error de comunicación, permitimos la valoración
            // (fail-open para evitar bloquear funcionalidad por problemas de red)
            return true;
        }
    }
}
