package io.audira.fileservice.controller;

import io.audira.fileservice.service.FileStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/files/upload")
@RequiredArgsConstructor
public class FileUploadController {

    private final FileStorageService fileStorageService;

    @Value("${file.base-url:http://172.16.0.4:9005}")
    private String baseUrl;

    @PostMapping("/audio")
    public ResponseEntity<?> uploadAudioFile(
            @RequestParam("file") MultipartFile file) {

        try {
            // Log para debugging
            System.out.println("Recibido archivo de audio: " + file.getOriginalFilename());
            System.out.println("Content-Type: " + file.getContentType());
            System.out.println("Tamaño: " + file.getSize() + " bytes");

            // Validar que sea un archivo de audio
            if (!fileStorageService.isValidAudioFile(file)) {
                return ResponseEntity.badRequest().body(
                    createErrorResponse("El archivo debe ser de audio (MP3, WAV, FLAC, MIDI)")
                );
            }

            // Validar tamaño (máximo 100MB para archivos de audio)
            if (file.getSize() > 100 * 1024 * 1024) {
                return ResponseEntity.badRequest().body(
                    createErrorResponse("El archivo no debe superar los 100MB")
                );
            }

            // Guardar el archivo
            String filePath = fileStorageService.storeFile(file, "audio-files");
            String fileUrl = baseUrl + "/api/files/" + filePath;

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Archivo de audio subido exitosamente");
            response.put("fileUrl", fileUrl);
            response.put("filePath", filePath);
            response.put("fileName", file.getOriginalFilename());
            response.put("fileSize", file.getSize());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                createErrorResponse("Error al subir el archivo de audio: " + e.getMessage())
            );
        }
    }

    @PostMapping("/image")
    public ResponseEntity<?> uploadImageFile(
            @RequestParam("file") MultipartFile file) {

        try {
            // Log para debugging
            System.out.println("Recibido archivo de imagen: " + file.getOriginalFilename());
            System.out.println("Content-Type: " + file.getContentType());
            System.out.println("Tamaño: " + file.getSize() + " bytes");

            // Validar que sea una imagen
            if (!fileStorageService.isValidImageFile(file)) {
                return ResponseEntity.badRequest().body(
                    createErrorResponse("El archivo debe ser una imagen (JPG, PNG, WEBP)")
                );
            }

            // Validar tamaño (máximo 10MB)
            if (file.getSize() > 10 * 1024 * 1024) {
                return ResponseEntity.badRequest().body(
                    createErrorResponse("El archivo no debe superar los 10MB")
                );
            }

            // Guardar el archivo
            String filePath = fileStorageService.storeFile(file, "images");
            String fileUrl = baseUrl + "/api/files/" + filePath;

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Imagen subida exitosamente");
            response.put("fileUrl", fileUrl);
            response.put("filePath", filePath);
            response.put("fileName", file.getOriginalFilename());
            response.put("fileSize", file.getSize());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                createErrorResponse("Error al subir la imagen: " + e.getMessage())
            );
        }
    }

    private Map<String, String> createErrorResponse(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }
}
