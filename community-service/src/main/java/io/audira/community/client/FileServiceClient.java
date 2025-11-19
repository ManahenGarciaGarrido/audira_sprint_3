package io.audira.community.client;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@Component
@RequiredArgsConstructor
public class FileServiceClient {

    private static final Logger logger = LoggerFactory.getLogger(FileServiceClient.class);
    private final RestTemplate restTemplate;

    @Value("${file.service.url:http://file-service:9005}")
    private String fileServiceUrl;

    /**
     * Upload an image file to the file service
     * @param file the multipart file to upload
     * @return the URL of the uploaded file
     */
    public String uploadImage(MultipartFile file) throws Exception {
        String uploadUrl = fileServiceUrl + "/api/files/upload/image";

        logger.info("Uploading image {} to file service at {}", file.getOriginalFilename(), uploadUrl);

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", new MultipartFileResource(file));

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            ResponseEntity<Map> response = restTemplate.exchange(
                uploadUrl,
                HttpMethod.POST,
                requestEntity,
                Map.class
            );

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                String fileUrl = (String) response.getBody().get("fileUrl");
                logger.info("Successfully uploaded image to file service: {}", fileUrl);
                return fileUrl;
            } else {
                String errorMsg = "Failed to upload image to file service: received status " + response.getStatusCode();
                logger.error(errorMsg);
                throw new RuntimeException(errorMsg);
            }
        } catch (HttpClientErrorException e) {
            String errorMsg = "Client error uploading image to file service: " + e.getStatusCode() + " - " + e.getResponseBodyAsString();
            logger.error(errorMsg, e);
            throw new RuntimeException(errorMsg, e);
        } catch (HttpServerErrorException e) {
            String errorMsg = "Server error uploading image to file service: " + e.getStatusCode() + " - " + e.getResponseBodyAsString();
            logger.error(errorMsg, e);
            throw new RuntimeException(errorMsg, e);
        } catch (Exception e) {
            String errorMsg = "Error uploading image to file service: " + e.getMessage();
            logger.error(errorMsg, e);
            throw new RuntimeException(errorMsg, e);
        }
    }

    /**
     * Helper class to convert MultipartFile to Resource for RestTemplate
     */
    private static class MultipartFileResource extends ByteArrayResource {

        private final String filename;

        public MultipartFileResource(MultipartFile multipartFile) throws Exception {
            super(multipartFile.getBytes());
            this.filename = multipartFile.getOriginalFilename();
        }

        @Override
        public String getFilename() {
            return this.filename;
        }
    }
}
