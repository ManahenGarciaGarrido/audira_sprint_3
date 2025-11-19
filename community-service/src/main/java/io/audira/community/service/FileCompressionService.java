package io.audira.community.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.UUID;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

@Service
public class FileCompressionService {

    @Value("${file.upload-dir:uploads}")
    private String uploadDir;

    /**
     * Comprime una lista de archivos en un archivo ZIP
     * @param filePaths Lista de rutas relativas de archivos (ej: "audio-files/abc.mp3")
     * @return Ruta del archivo ZIP generado
     */
    public String compressFiles(List<String> filePaths) throws IOException {
        Path fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();

        // Crear directorio para archivos comprimidos
        Path compressedDir = fileStorageLocation.resolve("compressed");
        Files.createDirectories(compressedDir);

        // Generar nombre único para el archivo ZIP
        String zipFileName = UUID.randomUUID().toString() + ".zip";
        Path zipFilePath = compressedDir.resolve(zipFileName);

        try (FileOutputStream fos = new FileOutputStream(zipFilePath.toFile());
             ZipOutputStream zos = new ZipOutputStream(fos)) {

            for (String filePath : filePaths) {
                Path sourceFile = fileStorageLocation.resolve(filePath).normalize();

                if (!Files.exists(sourceFile)) {
                    throw new FileNotFoundException("Archivo no encontrado: " + filePath);
                }

                // Agregar archivo al ZIP
                addFileToZip(sourceFile, zos, sourceFile.getFileName().toString());
            }
        }

        return "compressed/" + zipFileName;
    }

    /**
     * Comprime un solo archivo
     * @param filePath Ruta relativa del archivo
     * @return Ruta del archivo ZIP generado
     */
    public String compressSingleFile(String filePath) throws IOException {
        Path fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        Path sourceFile = fileStorageLocation.resolve(filePath).normalize();

        if (!Files.exists(sourceFile)) {
            throw new FileNotFoundException("Archivo no encontrado: " + filePath);
        }

        // Crear directorio para archivos comprimidos
        Path compressedDir = fileStorageLocation.resolve("compressed");
        Files.createDirectories(compressedDir);

        // Generar nombre único para el archivo ZIP
        String originalFileName = sourceFile.getFileName().toString();
        String zipFileName = originalFileName.substring(0, originalFileName.lastIndexOf('.')) + "_" +
                           UUID.randomUUID().toString().substring(0, 8) + ".zip";
        Path zipFilePath = compressedDir.resolve(zipFileName);

        try (FileOutputStream fos = new FileOutputStream(zipFilePath.toFile());
             ZipOutputStream zos = new ZipOutputStream(fos)) {

            addFileToZip(sourceFile, zos, originalFileName);
        }

        return "compressed/" + zipFileName;
    }

    private void addFileToZip(Path sourceFile, ZipOutputStream zos, String entryName) throws IOException {
        ZipEntry zipEntry = new ZipEntry(entryName);
        zos.putNextEntry(zipEntry);

        try (FileInputStream fis = new FileInputStream(sourceFile.toFile())) {
            byte[] buffer = new byte[1024];
            int length;
            while ((length = fis.read(buffer)) > 0) {
                zos.write(buffer, 0, length);
            }
        }

        zos.closeEntry();
    }

    /**
     * Obtiene el tamaño de un archivo
     * @param filePath Ruta relativa del archivo
     * @return Tamaño en bytes
     */
    public long getFileSize(String filePath) throws IOException {
        Path fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        Path file = fileStorageLocation.resolve(filePath).normalize();

        if (!Files.exists(file)) {
            throw new FileNotFoundException("Archivo no encontrado: " + filePath);
        }

        return Files.size(file);
    }
}
