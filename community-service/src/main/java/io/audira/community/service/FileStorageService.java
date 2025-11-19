package io.audira.community.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@Service
public class FileStorageService {

    private final Path fileStorageLocation;

    public FileStorageService(@Value("${file.upload-dir:uploads}") String uploadDir) {
        this.fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.fileStorageLocation);
        } catch (Exception ex) {
            throw new RuntimeException("No se pudo crear el directorio de subida de archivos.", ex);
        }
    }

    public String storeFile(MultipartFile file, String subDirectory) {
        // Normalizar nombre del archivo
        String originalFileName = StringUtils.cleanPath(file.getOriginalFilename());

        try {
            // Verificar que el archivo no esté vacío
            if (file.isEmpty()) {
                throw new RuntimeException("El archivo está vacío: " + originalFileName);
            }

            // Verificar que el nombre del archivo no contenga caracteres inválidos
            if (originalFileName.contains("..")) {
                throw new RuntimeException("El nombre del archivo contiene una secuencia de ruta inválida: " + originalFileName);
            }

            // Generar un nombre único para el archivo
            String fileExtension = "";
            int dotIndex = originalFileName.lastIndexOf('.');
            if (dotIndex > 0) {
                fileExtension = originalFileName.substring(dotIndex);
            }
            String fileName = UUID.randomUUID().toString() + fileExtension;

            // Crear subdirectorio si es necesario
            Path targetLocation = this.fileStorageLocation.resolve(subDirectory);
            Files.createDirectories(targetLocation);

            // Copiar archivo a la ubicación de destino
            Path destinationFile = targetLocation.resolve(fileName);
            Files.copy(file.getInputStream(), destinationFile, StandardCopyOption.REPLACE_EXISTING);

            return subDirectory + "/" + fileName;
        } catch (IOException ex) {
            throw new RuntimeException("No se pudo almacenar el archivo " + originalFileName + ". Por favor, intente nuevamente.", ex);
        }
    }

    public void deleteFile(String filePath) {
        try {
            Path file = this.fileStorageLocation.resolve(filePath).normalize();
            Files.deleteIfExists(file);
        } catch (IOException ex) {
            throw new RuntimeException("No se pudo eliminar el archivo: " + filePath, ex);
        }
    }

    public boolean isValidImageFile(MultipartFile file) {
        String contentType = file.getContentType();
        String fileName = file.getOriginalFilename();

        // Verificar por content-type
        boolean validContentType = contentType != null && (
                contentType.equals("image/jpeg") ||
                contentType.equals("image/jpg") ||
                contentType.equals("image/png") ||
                contentType.equals("image/gif") ||
                contentType.equals("image/webp") ||
                contentType.equals("application/octet-stream") // Permitir este tipo genérico
        );

        // Verificar por extensión del archivo como fallback
        boolean validExtension = false;
        if (fileName != null) {
            String extension = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
            validExtension = extension.equals("jpg") ||
                           extension.equals("jpeg") ||
                           extension.equals("png") ||
                           extension.equals("gif") ||
                           extension.equals("webp");
        }

        // Aceptar si el content-type O la extensión son válidos
        return validContentType || validExtension;
    }

    public boolean isValidAudioFile (MultipartFile file) {
        String contentType = file.getContentType();
        String fileName = file.getOriginalFilename();

        // Verificar por content-type
        boolean validContentType = contentType != null && (
                contentType.equals("audio/mpeg") ||       // .mp3
                contentType.equals("audio/mp3") ||        // Variante para .mp3
                contentType.equals("audio/wav") ||        // .wav
                contentType.equals("audio/wave") ||       // Variante común
                contentType.equals("audio/x-wav") ||      // Variante común para .wav
                contentType.equals("audio/flac") ||       // .flac
                contentType.equals("audio/x-flac") ||     // Variante común para .flac
                contentType.equals("audio/midi") ||       // .midi
                contentType.equals("audio/x-midi") ||     // Variante común para .midi
                contentType.equals("audio/ogg") ||        // .ogg
                contentType.equals("audio/aac") ||        // .aac
                contentType.equals("application/octet-stream") // Tipo genérico permitido
        );

        // Verificar por extensión del archivo como fallback
        boolean validExtension = false;
        if (fileName != null) {
            String extension = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
            validExtension = extension.equals("mp3") ||
                            extension.equals("wav") ||
                            extension.equals("flac") ||
                            extension.equals("midi") ||
                            extension.equals("mid") ||
                            extension.equals("ogg") ||
                            extension.equals("aac");
        }

        return validContentType || validExtension;
    }
}