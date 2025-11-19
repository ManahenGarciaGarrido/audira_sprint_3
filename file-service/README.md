# 📁 File Service - Microservicio de Gestión de Archivos

Microservicio dedicado exclusivamente a la gestión de archivos de audio e imágenes para la plataforma Audira.

## 🎯 Propósito

Este servicio maneja:
- ✅ Subida de archivos de audio (.mp3, .wav, .flac, .midi)
- ✅ Subida de archivos de imagen (.jpg, .png, .webp)
- ✅ Streaming de audio con HTTP Range Requests
- ✅ Compresión de archivos en formato ZIP
- ✅ Servicio de archivos con content-type apropiado

## 🏗️ Arquitectura

### Puerto
- **9005**: Puerto del servicio

### Dependencias
- Spring Boot 3.2.0
- Spring Cloud Netflix Eureka Client
- Spring Boot Actuator
- Lombok

### Volumen
- `/uploads`: Volumen Docker persistente compartido
  - `audio-files/`: Archivos MP3, WAV, FLAC, MIDI
  - `images/`: Imágenes JPG, PNG, WEBP
  - `compressed/`: Archivos ZIP

## 🔌 Endpoints

### Subida de Archivos

```
POST /api/files/upload/audio
Content-Type: multipart/form-data
Body: file (MultipartFile)
Max Size: 50MB

Response:
{
  "message": "Archivo de audio subido exitosamente",
  "fileUrl": "http://172.16.0.4:9005/api/files/audio-files/abc-123.mp3",
  "filePath": "audio-files/abc-123.mp3",
  "fileName": "cancion.mp3",
  "fileSize": 5242880
}
```

```
POST /api/files/upload/image
Content-Type: multipart/form-data
Body: file (MultipartFile)
Max Size: 10MB

Response:
{
  "message": "Imagen subida exitosamente",
  "fileUrl": "http://172.16.0.4:9005/api/files/images/def-456.jpg",
  "filePath": "images/def-456.jpg",
  "fileName": "cover.jpg",
  "fileSize": 1048576
}
```

### Servir Archivos

```
GET /api/files/{subDirectory}/{fileName}
Headers:
  Range: bytes=0-1023 (opcional, para streaming)

Response:
- 200 OK: Archivo completo
- 206 Partial Content: Chunk de archivo (streaming)
- 404 Not Found: Archivo no existe
```

### Compresión

```
POST /api/files/compress
Content-Type: application/json
Body:
{
  "filePaths": [
    "audio-files/abc-123.mp3",
    "images/def-456.jpg"
  ]
}

Response:
{
  "message": "Archivos comprimidos exitosamente",
  "zipFileUrl": "http://172.16.0.4:9005/api/files/compressed/xyz-789.zip",
  "zipFilePath": "compressed/xyz-789.zip",
  "filesCompressed": 2,
  "originalSize": 7340032,
  "compressedSize": 6815744,
  "compressionRatio": "7.14%"
}
```

```
POST /api/files/compress/single
Content-Type: application/json
Body:
{
  "filePath": "audio-files/abc-123.mp3"
}

Response: (similar al anterior)
```

## 🚀 Ejecución

### Con Docker Compose

```bash
cd audira_v2
docker-compose up file-service
```

### Standalone (desarrollo)

```bash
cd file-service
mvn spring-boot:run
```

## 🔧 Configuración

### application.yml

```yaml
server:
  port: 9005

spring:
  servlet:
    multipart:
      max-file-size: 50MB
      max-request-size: 50MB

file:
  upload-dir: /uploads
  base-url: http://172.16.0.4:9005
```

### Variables de Entorno

```bash
EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://discovery-server:8761/eureka/
```

## 📊 Health Check

```bash
curl http://172.16.0.4:9005/actuator/health
```

## 🎵 Streaming de Audio

El servicio soporta HTTP Range Requests para streaming eficiente:

```bash
# Reproducir desde el byte 1000
curl -H "Range: bytes=1000-" http://172.16.0.4:9005/api/files/audio-files/song.mp3

# Response: 206 Partial Content
# Headers:
#   Content-Range: bytes 1000-5242879/5242880
#   Accept-Ranges: bytes
```

## 🗜️ Características de Compresión

- ✅ Compresión ZIP estándar
- ✅ Cálculo automático de ratio de compresión
- ✅ Soporte para múltiples archivos
- ✅ Nombres únicos con UUID
- ✅ Estadísticas detalladas

## 🔒 Seguridad

- ✅ Validación de tipo de archivo (extensión + MIME type)
- ✅ Límites de tamaño configurables
- ✅ Protección contra path traversal
- ✅ Nombres de archivo únicos (UUID)
- ✅ Sanitización de nombres de archivo

## 📈 Escalabilidad

Este servicio puede:
- Escalarse horizontalmente de forma independiente
- Compartir el volumen entre instancias
- Ser desplegado en múltiples regiones
- Integrar con almacenamiento en la nube (S3, Cloudinary)

## 🔗 Integración con API Gateway

El API Gateway enruta `/api/files/**` a este servicio:

```
http://172.16.0.4:8080/api/files/upload/audio
  → file-service:9005/api/files/upload/audio
```

## 📝 Logs

```bash
# Ver logs del contenedor
docker logs audira_v2-file-service-1 -f

# Nivel de logs configurado en INFO
# Para debugging, cambiar a DEBUG en application.yml
```

## 🆚 Separación de Responsabilidades

| Funcionalidad | Servicio |
|---------------|----------|
| Subida genérica de audio/imagen | file-service |
| Streaming de audio | file-service |
| Compresión de archivos | file-service |
| Subida de foto de perfil | community-service |
| Subida de banner de usuario | community-service |

## 🎯 Ventajas del Microservicio Separado

1. **Escalabilidad**: Escalar solo cuando hay mucha carga de archivos
2. **Mantenimiento**: Cambios no afectan otros servicios
3. **Recursos**: Asignar más CPU/RAM solo a este servicio
4. **Deploy**: Desplegar updates sin afectar otras funcionalidades
5. **Monitoreo**: Métricas específicas de uso de archivos
6. **Cache**: Implementar CDN solo para este servicio

## 📚 Próximas Mejoras

- [ ] Integración con S3/CloudFront
- [ ] Thumbnails automáticos para imágenes
- [ ] Transcoding de audio
- [ ] Metadata extraction
- [ ] Caché con Redis
- [ ] Antivirus scanning
- [ ] Watermarking

---

**Puerto**: 9005
**Registro en Eureka**: file-service
**Health**: http://172.16.0.4:9005/actuator/health
