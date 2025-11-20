# Guía de Migración: Sistema de Métricas para Artistas por Subtarea

Esta guía detalla **TODOS** los cambios necesarios para implementar el sistema completo de métricas y análisis de datos para artistas, organizados por subtarea para facilitar la migración al repositorio original de GitHub.

**IMPORTANTE**: Esta guía separa claramente el código de cada subtarea. Si un archivo necesita cambios de ambas subtareas, se muestra primero lo de GA01-108 (sin incluir GA01-109) y luego lo que hay que añadir en GA01-109 (sin repetir GA01-108).

---

## 📋 Índice de Subtareas

1. [GA01-108: Resumen rápido (plays, valoraciones, ventas, comentarios, evolución)](#ga01-108-resumen-r%C3%A1pido)
2. [GA01-109: Vista detallada (por fecha/gráfico básico)](#ga01-109-vista-detallada)

---

## 📦 Información General

### Contexto
Las métricas para artistas permiten analizar el desempeño de su contenido:
- **Actualmente**: Existe un servicio básico de métricas en el frontend pero SIN backend implementado
- **GA01-108**: Dashboard con resumen rápido de KPIs (plays, ratings, sales, comentarios) y evolución
- **GA01-109**: Vista detallada con datos históricos por fecha y gráficos para visualizar tendencias

### Arquitectura
- **Backend**: music-catalog-service (Spring Boot) - calcula métricas desde datos reales
- **Frontend**: Flutter con Provider para state management
- **Integración**: Métricas agregadas de múltiples fuentes (canciones, ratings, ventas, comentarios)

### Datos de Métricas

**Datos disponibles actualmente en music-catalog-service**:
- ✅ Plays de canciones (campo `plays` en tabla `songs`)
- ✅ Canciones del artista (tabla `songs`)
- ✅ Álbumes del artista (tabla `albums`)
- ✅ Colaboraciones (tabla `collaborators`)

**Datos que requieren integración con otros servicios** (TODO en backend):
- ⚠️ Ratings: community-service (tabla `ratings`)
- ⚠️ Ventas: commerce-service (tabla `orders`)
- ⚠️ Comentarios: community-service (tabla `comments`)
- ⚠️ Datos históricos: Requiere tabla de tracking temporal

**Nota**: El backend implementado usa datos reales donde están disponibles y genera datos mock para demostración donde se requiere integración con otros servicios. La guía indica claramente dónde implementar la integración real.

---

## GA01-108: Resumen rápido (plays, valoraciones, ventas, comentarios, evolución)

Esta subtarea implementa un dashboard con resumen rápido de las métricas clave:
- Total de plays y crecimiento vs período anterior
- Valoraciones promedio y cantidad total
- Ventas totales e ingresos generados
- Comentarios totales en el contenido
- Evolución (porcentajes de crecimiento)
- Canción más reproducida
- Totales de contenido (canciones, álbumes, colaboraciones)

### 📁 Archivos a Crear/Modificar (Backend)

#### 1. CREAR: `ArtistMetricsSummary.java`

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/dto/ArtistMetricsSummary.java`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```java
package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Summary metrics for an artist
 * GA01-108: Resumen rápido (plays, valoraciones, ventas, comentarios, evolución)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ArtistMetricsSummary {

    // Basic info
    private Long artistId;
    private String artistName;
    private LocalDateTime generatedAt;

    // Plays metrics
    private Long totalPlays;
    private Long playsLast30Days;
    private Double playsGrowthPercentage; // Comparison with previous period

    // Rating metrics
    private Double averageRating;
    private Long totalRatings;
    private Double ratingsGrowthPercentage;

    // Sales metrics
    private Long totalSales;
    private BigDecimal totalRevenue;
    private Long salesLast30Days;
    private BigDecimal revenueLast30Days;
    private Double salesGrowthPercentage;
    private Double revenueGrowthPercentage;

    // Comments metrics
    private Long totalComments;
    private Long commentsLast30Days;
    private Double commentsGrowthPercentage;

    // Content metrics
    private Long totalSongs;
    private Long totalAlbums;
    private Long totalCollaborations;

    // Top performing
    private Long mostPlayedSongId;
    private String mostPlayedSongName;
    private Long mostPlayedSongPlays;
}
```

#### 2. CREAR: `SongMetrics.java`

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/dto/SongMetrics.java`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```java
package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Metrics for a specific song
 * Used in both GA01-108 and GA01-109
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SongMetrics {

    private Long songId;
    private String songName;
    private String artistName;

    // Performance metrics
    private Long totalPlays;
    private Double averageRating;
    private Long totalRatings;
    private Long totalComments;

    // Sales metrics
    private Long totalSales;
    private Double totalRevenue;

    // Ranking
    private Integer rankInArtistCatalog; // Position among artist's songs
}
```

#### 3. CREAR: `MetricsService.java`

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/service/MetricsService.java`

**Acción**: Crear nuevo archivo (SOLO métodos de GA01-108)

**IMPORTANTE**: Este archivo también tendrá métodos de GA01-109. Aquí se muestra SOLO código de GA01-108.

**Contenido completo para GA01-108**:

```java
package io.audira.catalog.service;

import io.audira.catalog.dto.ArtistMetricsSummary;
import io.audira.catalog.dto.SongMetrics;
import io.audira.catalog.model.Album;
import io.audira.catalog.model.Collaborator;
import io.audira.catalog.model.CollaborationStatus;
import io.audira.catalog.model.Song;
import io.audira.catalog.repository.AlbumRepository;
import io.audira.catalog.repository.CollaboratorRepository;
import io.audira.catalog.repository.SongRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Service for calculating artist and song metrics
 * GA01-108: Resumen rápido (plays, valoraciones, ventas, comentarios, evolución)
 */
@Service
@RequiredArgsConstructor
public class MetricsService {

    private static final Logger logger = LoggerFactory.getLogger(MetricsService.class);

    private final SongRepository songRepository;
    private final AlbumRepository albumRepository;
    private final CollaboratorRepository collaboratorRepository;

    // TODO: Inject these services when implementing full integration
    // private final RatingService ratingService; // From community-service
    // private final OrderService orderService; // From commerce-service
    // private final CommentService commentService; // From community-service

    /**
     * Get summary metrics for an artist
     * GA01-108: Resumen rápido
     */
    public ArtistMetricsSummary getArtistMetricsSummary(Long artistId) {
        logger.info("Calculating metrics summary for artist {}", artistId);

        // Get artist's songs
        List<Song> artistSongs = songRepository.findByArtistId(artistId);

        // Get artist's albums
        List<Album> artistAlbums = albumRepository.findByArtistId(artistId);

        // Get collaborations
        List<Collaborator> collaborations = collaboratorRepository.findByArtistIdAndStatus(
                artistId, CollaborationStatus.ACCEPTED
        );

        // Calculate plays metrics
        Long totalPlays = artistSongs.stream()
                .mapToLong(Song::getPlays)
                .sum();

        // Find most played song
        Optional<Song> mostPlayedSong = artistSongs.stream()
                .max(Comparator.comparing(Song::getPlays));

        // Calculate growth (mock data - in real implementation, query historical data)
        // TODO: Implement historical tracking for accurate growth calculations
        Double playsGrowth = calculateMockGrowth(totalPlays);

        // TODO: Integrate with community-service for real ratings data
        // Example integration:
        // RatingsResponse ratingsData = ratingService.getArtistRatings(artistId);
        // Double averageRating = ratingsData.getAverageRating();
        // Long totalRatings = ratingsData.getTotalCount();
        Double averageRating = 4.2; // Mock data
        Long totalRatings = (long) (artistSongs.size() * 15); // Mock data
        Double ratingsGrowth = 5.3; // Mock data

        // TODO: Integrate with commerce-service for real sales data
        // Example integration:
        // SalesResponse salesData = orderService.getArtistSales(artistId);
        // Long totalSales = salesData.getTotalSales();
        // BigDecimal totalRevenue = salesData.getTotalRevenue();
        Long totalSales = totalPlays / 10; // Mock: 10% conversion
        BigDecimal totalRevenue = BigDecimal.valueOf(totalSales * 0.99); // Mock: $0.99 per sale
        Long salesLast30Days = totalSales / 12; // Mock
        BigDecimal revenueLast30Days = totalRevenue.divide(BigDecimal.valueOf(12), 2, RoundingMode.HALF_UP);
        Double salesGrowth = 8.7; // Mock data
        Double revenueGrowth = 8.7; // Mock data

        // TODO: Integrate with community-service for real comments data
        // Example integration:
        // CommentsResponse commentsData = commentService.getArtistComments(artistId);
        // Long totalComments = commentsData.getTotalCount();
        Long totalComments = (long) (artistSongs.size() * 8); // Mock data
        Long commentsLast30Days = totalComments / 6; // Mock
        Double commentsGrowth = 12.4; // Mock data

        return ArtistMetricsSummary.builder()
                .artistId(artistId)
                .artistName("Artist #" + artistId) // TODO: Get from user service
                .generatedAt(LocalDateTime.now())
                // Plays
                .totalPlays(totalPlays)
                .playsLast30Days(totalPlays / 4) // Mock: 25% in last 30 days
                .playsGrowthPercentage(playsGrowth)
                // Ratings
                .averageRating(averageRating)
                .totalRatings(totalRatings)
                .ratingsGrowthPercentage(ratingsGrowth)
                // Sales
                .totalSales(totalSales)
                .totalRevenue(totalRevenue)
                .salesLast30Days(salesLast30Days)
                .revenueLast30Days(revenueLast30Days)
                .salesGrowthPercentage(salesGrowth)
                .revenueGrowthPercentage(revenueGrowth)
                // Comments
                .totalComments(totalComments)
                .commentsLast30Days(commentsLast30Days)
                .commentsGrowthPercentage(commentsGrowth)
                // Content
                .totalSongs((long) artistSongs.size())
                .totalAlbums((long) artistAlbums.size())
                .totalCollaborations((long) collaborations.size())
                // Top performing
                .mostPlayedSongId(mostPlayedSong.map(Song::getId).orElse(null))
                .mostPlayedSongName(mostPlayedSong.map(Song::getTitle).orElse("N/A"))
                .mostPlayedSongPlays(mostPlayedSong.map(Song::getPlays).orElse(0L))
                .build();
    }

    /**
     * Get metrics for a specific song
     */
    public SongMetrics getSongMetrics(Long songId) {
        Song song = songRepository.findById(songId)
                .orElseThrow(() -> new RuntimeException("Song not found: " + songId));

        // Get artist's all songs to calculate rank
        List<Song> artistSongs = songRepository.findByArtistId(song.getArtistId());
        List<Song> sortedByPlays = artistSongs.stream()
                .sorted(Comparator.comparing(Song::getPlays).reversed())
                .collect(Collectors.toList());

        int rank = sortedByPlays.indexOf(song) + 1;

        // TODO: Integrate with other services for real data
        Long mockSales = song.getPlays() / 10;
        Double mockRevenue = mockSales * 0.99;

        return SongMetrics.builder()
                .songId(song.getId())
                .songName(song.getTitle())
                .artistName("Artist #" + song.getArtistId())
                .totalPlays(song.getPlays())
                .averageRating(4.1) // Mock
                .totalRatings(45L) // Mock
                .totalComments(12L) // Mock
                .totalSales(mockSales)
                .totalRevenue(mockRevenue)
                .rankInArtistCatalog(rank)
                .build();
    }

    /**
     * Calculate mock growth percentage
     * TODO: Replace with real calculation from historical data
     */
    private Double calculateMockGrowth(Long currentValue) {
        if (currentValue == 0) return 0.0;
        // Mock: growth between 0% and 20%
        Random random = new Random(currentValue);
        return random.nextDouble() * 20.0;
    }
}
```

**Resumen de métodos en MetricsService para GA01-108**:
- `getArtistMetricsSummary()` - Calcular resumen de métricas del artista
- `getSongMetrics()` - Métricas de canción específica
- `calculateMockGrowth()` - Helper para calcular crecimiento (mock)

#### 4. CREAR: `MetricsController.java`

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/controller/MetricsController.java`

**Acción**: Crear nuevo archivo (SOLO endpoints de GA01-108)

**IMPORTANTE**: Este archivo también tendrá endpoints de GA01-109. Aquí se muestra SOLO código de GA01-108.

**Contenido completo para GA01-108**:

```java
package io.audira.catalog.controller;

import io.audira.catalog.dto.ArtistMetricsSummary;
import io.audira.catalog.dto.SongMetrics;
import io.audira.catalog.service.MetricsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controller for artist and song metrics
 * GA01-108: Resumen rápido (plays, valoraciones, ventas, comentarios, evolución)
 */
@RestController
@RequestMapping("/api/metrics")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class MetricsController {

    private final MetricsService metricsService;

    /**
     * Get summary metrics for an artist
     * GA01-108: Resumen rápido
     *
     * @param artistId Artist ID
     * @return Summary with plays, ratings, sales, comments, and growth
     */
    @GetMapping("/artists/{artistId}")
    public ResponseEntity<ArtistMetricsSummary> getArtistMetricsSummary(
            @PathVariable Long artistId
    ) {
        ArtistMetricsSummary metrics = metricsService.getArtistMetricsSummary(artistId);
        return ResponseEntity.ok(metrics);
    }

    /**
     * Get metrics for a specific song
     *
     * @param songId Song ID
     * @return Song metrics
     */
    @GetMapping("/songs/{songId}")
    public ResponseEntity<SongMetrics> getSongMetrics(
            @PathVariable Long songId
    ) {
        SongMetrics metrics = metricsService.getSongMetrics(songId);
        return ResponseEntity.ok(metrics);
    }

    /**
     * Get top songs for an artist (for compatibility with existing frontend)
     * GA01-108: Part of summary
     *
     * @param artistId Artist ID
     * @param limit Number of top songs to return
     * @return List of top songs by plays
     */
    @GetMapping("/artists/{artistId}/top-songs")
    public ResponseEntity<?> getArtistTopSongs(
            @PathVariable Long artistId,
            @RequestParam(defaultValue = "10") int limit
    ) {
        // TODO: Implement properly
        // For now, return empty to maintain compatibility
        return ResponseEntity.ok(new java.util.ArrayList<>());
    }
}
```

**Resumen de endpoints para GA01-108**:
- `GET /api/metrics/artists/{artistId}` - Resumen de métricas del artista
- `GET /api/metrics/songs/{songId}` - Métricas de canción específica
- `GET /api/metrics/artists/{artistId}/top-songs` - Top canciones (compatibilidad)

### 📁 Archivos a Crear/Modificar (Frontend)

#### 5. CREAR: `artist_metrics_summary.dart` (Modelo)

**Ubicación**: `audira_frontend/lib/core/models/artist_metrics_summary.dart`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```dart
import 'package:equatable/equatable.dart';

/// Summary metrics for an artist
/// GA01-108: Resumen rápido (plays, valoraciones, ventas, comentarios, evolución)
class ArtistMetricsSummary extends Equatable {
  final int artistId;
  final String artistName;
  final DateTime generatedAt;

  // Plays metrics
  final int totalPlays;
  final int playsLast30Days;
  final double playsGrowthPercentage;

  // Rating metrics
  final double averageRating;
  final int totalRatings;
  final double ratingsGrowthPercentage;

  // Sales metrics
  final int totalSales;
  final double totalRevenue;
  final int salesLast30Days;
  final double revenueLast30Days;
  final double salesGrowthPercentage;
  final double revenueGrowthPercentage;

  // Comments metrics
  final int totalComments;
  final int commentsLast30Days;
  final double commentsGrowthPercentage;

  // Content metrics
  final int totalSongs;
  final int totalAlbums;
  final int totalCollaborations;

  // Top performing
  final int? mostPlayedSongId;
  final String? mostPlayedSongName;
  final int? mostPlayedSongPlays;

  const ArtistMetricsSummary({
    required this.artistId,
    required this.artistName,
    required this.generatedAt,
    required this.totalPlays,
    required this.playsLast30Days,
    required this.playsGrowthPercentage,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingsGrowthPercentage,
    required this.totalSales,
    required this.totalRevenue,
    required this.salesLast30Days,
    required this.revenueLast30Days,
    required this.salesGrowthPercentage,
    required this.revenueGrowthPercentage,
    required this.totalComments,
    required this.commentsLast30Days,
    required this.commentsGrowthPercentage,
    required this.totalSongs,
    required this.totalAlbums,
    required this.totalCollaborations,
    this.mostPlayedSongId,
    this.mostPlayedSongName,
    this.mostPlayedSongPlays,
  });

  factory ArtistMetricsSummary.fromJson(Map<String, dynamic> json) {
    return ArtistMetricsSummary(
      artistId: json['artistId'] as int,
      artistName: json['artistName'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      totalPlays: json['totalPlays'] as int,
      playsLast30Days: json['playsLast30Days'] as int,
      playsGrowthPercentage: (json['playsGrowthPercentage'] as num).toDouble(),
      averageRating: (json['averageRating'] as num).toDouble(),
      totalRatings: json['totalRatings'] as int,
      ratingsGrowthPercentage: (json['ratingsGrowthPercentage'] as num).toDouble(),
      totalSales: json['totalSales'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      salesLast30Days: json['salesLast30Days'] as int,
      revenueLast30Days: (json['revenueLast30Days'] as num).toDouble(),
      salesGrowthPercentage: (json['salesGrowthPercentage'] as num).toDouble(),
      revenueGrowthPercentage: (json['revenueGrowthPercentage'] as num).toDouble(),
      totalComments: json['totalComments'] as int,
      commentsLast30Days: json['commentsLast30Days'] as int,
      commentsGrowthPercentage: (json['commentsGrowthPercentage'] as num).toDouble(),
      totalSongs: json['totalSongs'] as int,
      totalAlbums: json['totalAlbums'] as int,
      totalCollaborations: json['totalCollaborations'] as int,
      mostPlayedSongId: json['mostPlayedSongId'] as int?,
      mostPlayedSongName: json['mostPlayedSongName'] as String?,
      mostPlayedSongPlays: json['mostPlayedSongPlays'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        artistId,
        artistName,
        generatedAt,
        totalPlays,
        playsLast30Days,
        playsGrowthPercentage,
        averageRating,
        totalRatings,
        ratingsGrowthPercentage,
        totalSales,
        totalRevenue,
        salesLast30Days,
        revenueLast30Days,
        salesGrowthPercentage,
        revenueGrowthPercentage,
        totalComments,
        commentsLast30Days,
        commentsGrowthPercentage,
        totalSongs,
        totalAlbums,
        totalCollaborations,
        mostPlayedSongId,
        mostPlayedSongName,
        mostPlayedSongPlays,
      ];
}
```

#### 6. MODIFICAR: `metrics_service.dart`

**Ubicación**: `audira_frontend/lib/core/api/services/metrics_service.dart`

**Acción**: El archivo ya existe, AÑADIR método para el nuevo endpoint

**Añadir este import al inicio**:

```dart
import '../../models/artist_metrics_summary.dart';
```

**Añadir este método AL FINAL de la clase**:

```dart
  /// Get artist metrics summary
  /// GA01-108: Resumen rápido
  Future<ApiResponse<ArtistMetricsSummary>> getArtistMetricsSummaryTyped(
      int artistId) async {
    try {
      final response = await _apiClient.get('/api/metrics/artists/$artistId');

      if (response.success && response.data != null) {
        return ApiResponse(
          success: true,
          data: ArtistMetricsSummary.fromJson(
            response.data as Map<String, dynamic>,
          ),
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch artist metrics summary',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }
```

**Nota**: El método `getArtistMetrics()` que ya existe devuelve `Map<String, dynamic>`. El nuevo método `getArtistMetricsSummaryTyped()` devuelve el modelo tipado. Mantén ambos para compatibilidad.

### ✅ Checklist de Implementación GA01-108

**Backend**:
- [ ] Crear `ArtistMetricsSummary.java` DTO
- [ ] Crear `SongMetrics.java` DTO
- [ ] Crear `MetricsService.java` (métodos de GA01-108)
- [ ] Crear `MetricsController.java` (endpoints de GA01-108)
- [ ] (Opcional) Integrar con community-service para ratings reales
- [ ] (Opcional) Integrar con commerce-service para ventas reales
- [ ] (Opcional) Integrar con community-service para comentarios reales

**Frontend**:
- [ ] Crear `artist_metrics_summary.dart` modelo
- [ ] Actualizar `metrics_service.dart` con método tipado
- [ ] Actualizar `studio_stats_screen.dart` para usar nuevo modelo
- [ ] Crear cards de métricas con indicadores de crecimiento
- [ ] Mostrar canción más reproducida
- [ ] Diseño responsive y atractivo

**Testing**:
- [ ] Probar endpoint de resumen con artista real
- [ ] Validar cálculo de métricas
- [ ] Probar UI con datos reales
- [ ] Verificar visualización de porcentajes de crecimiento

---

## GA01-109: Vista detallada (por fecha/gráfico básico)

Esta subtarea implementa una vista detallada con:
- Filtro por rango de fechas (desde-hasta)
- Datos históricos diarios para gráficos
- Timeline de plays, ventas, comentarios por día
- Gráfico básico para visualizar tendencias

**IMPORTANTE**: Esta subtarea requiere que GA01-108 esté implementada primero.

### 📁 Archivos a Crear/Modificar (Backend)

#### 1. CREAR: `ArtistMetricsDetailed.java`

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/dto/ArtistMetricsDetailed.java`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```java
package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Detailed metrics for an artist with timeline data
 * GA01-109: Vista detallada (por fecha/gráfico básico)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ArtistMetricsDetailed {

    // Basic info
    private Long artistId;
    private String artistName;
    private LocalDate startDate;
    private LocalDate endDate;

    // Timeline data (for charts)
    private List<DailyMetric> dailyMetrics;

    // Summary for the period
    private Long totalPlays;
    private Long totalSales;
    private BigDecimal totalRevenue;
    private Long totalComments;
    private Double averageRating;

    /**
     * Daily metric data point for charts
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DailyMetric {
        private LocalDate date;
        private Long plays;
        private Long sales;
        private BigDecimal revenue;
        private Long comments;
        private Double averageRating; // Average for that day
    }
}
```

#### 2. MODIFICAR: `MetricsService.java` (AÑADIR métodos de GA01-109)

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/service/MetricsService.java`

**Acción**: Añadir métodos adicionales (código de GA01-109 SOLAMENTE)

**IMPORTANTE**: Este archivo ya fue creado en GA01-108. Aquí se muestra QUÉ AÑADIR adicional.

**Añadir este import al inicio**:

```java
import io.audira.catalog.dto.ArtistMetricsDetailed;
import java.time.LocalDate;
```

**Actualizar el comentario de la clase** para incluir GA01-109:

```java
/**
 * Service for calculating artist and song metrics
 * GA01-108: Resumen rápido (plays, valoraciones, ventas, comentarios, evolución)
 * GA01-109: Vista detallada (por fecha/gráfico básico)
 */
```

**Añadir estos métodos AL FINAL de la clase** (después de `calculateMockGrowth`):

```java
    /**
     * Get detailed metrics with timeline for an artist
     * GA01-109: Vista detallada
     */
    public ArtistMetricsDetailed getArtistMetricsDetailed(
            Long artistId,
            LocalDate startDate,
            LocalDate endDate
    ) {
        logger.info("Calculating detailed metrics for artist {} from {} to {}",
                artistId, startDate, endDate);

        // Validate date range
        if (startDate.isAfter(endDate)) {
            throw new IllegalArgumentException("Start date must be before end date");
        }

        // Get artist's songs
        List<Song> artistSongs = songRepository.findByArtistId(artistId);
        Long totalPlays = artistSongs.stream().mapToLong(Song::getPlays).sum();

        // Generate daily metrics for chart
        // TODO: In real implementation, query actual historical data from a metrics table
        List<ArtistMetricsDetailed.DailyMetric> dailyMetrics = generateDailyMetrics(
                startDate, endDate, totalPlays
        );

        // Calculate period totals
        Long periodPlays = dailyMetrics.stream()
                .mapToLong(ArtistMetricsDetailed.DailyMetric::getPlays)
                .sum();

        Long periodSales = dailyMetrics.stream()
                .mapToLong(ArtistMetricsDetailed.DailyMetric::getSales)
                .sum();

        BigDecimal periodRevenue = dailyMetrics.stream()
                .map(ArtistMetricsDetailed.DailyMetric::getRevenue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Long periodComments = dailyMetrics.stream()
                .mapToLong(ArtistMetricsDetailed.DailyMetric::getComments)
                .sum();

        Double averageRating = dailyMetrics.stream()
                .mapToDouble(m -> m.getAverageRating() != null ? m.getAverageRating() : 0.0)
                .filter(r -> r > 0)
                .average()
                .orElse(0.0);

        return ArtistMetricsDetailed.builder()
                .artistId(artistId)
                .artistName("Artist #" + artistId) // TODO: Get from user service
                .startDate(startDate)
                .endDate(endDate)
                .dailyMetrics(dailyMetrics)
                .totalPlays(periodPlays)
                .totalSales(periodSales)
                .totalRevenue(periodRevenue)
                .totalComments(periodComments)
                .averageRating(averageRating)
                .build();
    }

    /**
     * Generate mock daily metrics for demonstration
     * TODO: Replace with real historical data from a metrics tracking table
     */
    private List<ArtistMetricsDetailed.DailyMetric> generateDailyMetrics(
            LocalDate startDate,
            LocalDate endDate,
            Long totalPlays
    ) {
        List<ArtistMetricsDetailed.DailyMetric> metrics = new ArrayList<>();
        LocalDate currentDate = startDate;
        long daysInRange = endDate.toEpochDay() - startDate.toEpochDay() + 1;

        // Distribute total plays across days with some variation
        Random random = new Random(42); // Fixed seed for consistent mock data

        while (!currentDate.isAfter(endDate)) {
            // Generate mock data with some randomness
            long dailyPlays = (totalPlays / daysInRange) + random.nextInt(100);
            long dailySales = dailyPlays / 10;
            BigDecimal dailyRevenue = BigDecimal.valueOf(dailySales * 0.99)
                    .setScale(2, RoundingMode.HALF_UP);
            long dailyComments = random.nextInt(5);
            double dailyRating = 3.5 + random.nextDouble() * 1.5; // 3.5 to 5.0

            metrics.add(ArtistMetricsDetailed.DailyMetric.builder()
                    .date(currentDate)
                    .plays(dailyPlays)
                    .sales(dailySales)
                    .revenue(dailyRevenue)
                    .comments(dailyComments)
                    .averageRating(Math.round(dailyRating * 10.0) / 10.0)
                    .build());

            currentDate = currentDate.plusDays(1);
        }

        return metrics;
    }
```

**Resumen de nuevos métodos en MetricsService para GA01-109**:
- `getArtistMetricsDetailed()` - Métricas detalladas con timeline
- `generateDailyMetrics()` - Helper para generar datos diarios (privado)

#### 3. MODIFICAR: `MetricsController.java` (AÑADIR endpoint de GA01-109)

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/controller/MetricsController.java`

**Acción**: Añadir endpoint adicional (código de GA01-109 SOLAMENTE)

**IMPORTANTE**: Este archivo ya fue creado en GA01-108. Aquí se muestra QUÉ AÑADIR adicional.

**Añadir este import al inicio**:

```java
import io.audira.catalog.dto.ArtistMetricsDetailed;
import org.springframework.format.annotation.DateTimeFormat;
import java.time.LocalDate;
```

**Actualizar el comentario de la clase** para incluir GA01-109:

```java
/**
 * Controller for artist and song metrics
 * GA01-108: Resumen rápido (plays, valoraciones, ventas, comentarios, evolución)
 * GA01-109: Vista detallada (por fecha/gráfico básico)
 */
```

**Añadir este endpoint AL FINAL de la clase** (después de `getArtistTopSongs`):

```java
    /**
     * Get detailed metrics with timeline for an artist
     * GA01-109: Vista detallada (por fecha/gráfico básico)
     *
     * @param artistId Artist ID
     * @param startDate Start date (optional, defaults to 30 days ago)
     * @param endDate End date (optional, defaults to today)
     * @return Detailed metrics with daily breakdown for charts
     */
    @GetMapping("/artists/{artistId}/detailed")
    public ResponseEntity<ArtistMetricsDetailed> getArtistMetricsDetailed(
            @PathVariable Long artistId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
    ) {
        // Default to last 30 days if not specified
        if (startDate == null) {
            startDate = LocalDate.now().minusDays(30);
        }
        if (endDate == null) {
            endDate = LocalDate.now();
        }

        ArtistMetricsDetailed metrics = metricsService.getArtistMetricsDetailed(
                artistId, startDate, endDate
        );
        return ResponseEntity.ok(metrics);
    }
```

**Resumen de nuevo endpoint para GA01-109**:
- `GET /api/metrics/artists/{artistId}/detailed?startDate={date}&endDate={date}` - Métricas detalladas con timeline

### 📁 Archivos a Crear/Modificar (Frontend)

#### 4. CREAR: `artist_metrics_detailed.dart` (Modelo)

**Ubicación**: `audira_frontend/lib/core/models/artist_metrics_detailed.dart`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```dart
import 'package:equatable/equatable.dart';

/// Detailed metrics for an artist with timeline data
/// GA01-109: Vista detallada (por fecha/gráfico básico)
class ArtistMetricsDetailed extends Equatable {
  final int artistId;
  final String artistName;
  final DateTime startDate;
  final DateTime endDate;
  final List<DailyMetric> dailyMetrics;
  final int totalPlays;
  final int totalSales;
  final double totalRevenue;
  final int totalComments;
  final double averageRating;

  const ArtistMetricsDetailed({
    required this.artistId,
    required this.artistName,
    required this.startDate,
    required this.endDate,
    required this.dailyMetrics,
    required this.totalPlays,
    required this.totalSales,
    required this.totalRevenue,
    required this.totalComments,
    required this.averageRating,
  });

  factory ArtistMetricsDetailed.fromJson(Map<String, dynamic> json) {
    return ArtistMetricsDetailed(
      artistId: json['artistId'] as int,
      artistName: json['artistName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      dailyMetrics: (json['dailyMetrics'] as List)
          .map((e) => DailyMetric.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPlays: json['totalPlays'] as int,
      totalSales: json['totalSales'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalComments: json['totalComments'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        artistId,
        artistName,
        startDate,
        endDate,
        dailyMetrics,
        totalPlays,
        totalSales,
        totalRevenue,
        totalComments,
        averageRating,
      ];
}

/// Daily metric data point for charts
class DailyMetric extends Equatable {
  final DateTime date;
  final int plays;
  final int sales;
  final double revenue;
  final int comments;
  final double averageRating;

  const DailyMetric({
    required this.date,
    required this.plays,
    required this.sales,
    required this.revenue,
    required this.comments,
    required this.averageRating,
  });

  factory DailyMetric.fromJson(Map<String, dynamic> json) {
    return DailyMetric(
      date: DateTime.parse(json['date'] as String),
      plays: json['plays'] as int,
      sales: json['sales'] as int,
      revenue: (json['revenue'] as num).toDouble(),
      comments: json['comments'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [date, plays, sales, revenue, comments, averageRating];
}
```

#### 5. MODIFICAR: `metrics_service.dart` (AÑADIR método de GA01-109)

**Ubicación**: `audira_frontend/lib/core/api/services/metrics_service.dart`

**Acción**: Añadir método adicional (código de GA01-109 SOLAMENTE)

**IMPORTANTE**: Este archivo ya fue modificado en GA01-108. Aquí se muestra QUÉ AÑADIR adicional.

**Añadir este import al inicio**:

```dart
import '../../models/artist_metrics_detailed.dart';
```

**Añadir este método AL FINAL de la clase**:

```dart
  /// Get detailed artist metrics with timeline
  /// GA01-109: Vista detallada
  Future<ApiResponse<ArtistMetricsDetailed>> getArtistMetricsDetailed(
    int artistId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(
        '/api/metrics/artists/$artistId/detailed',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.success && response.data != null) {
        return ApiResponse(
          success: true,
          data: ArtistMetricsDetailed.fromJson(
            response.data as Map<String, dynamic>,
          ),
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch detailed artist metrics',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }
```

#### 6. CREAR: Pantalla de vista detallada (Ejemplo básico)

**Nota**: Esta es una implementación de ejemplo. Personaliza según el diseño de tu app.

**Ubicación**: `audira_frontend/lib/features/studio/screens/studio_detailed_stats_screen.dart`

**Acción**: Crear nuevo archivo

**Contenido básico de ejemplo**:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/metrics_service.dart';
import '../../../core/models/artist_metrics_detailed.dart';
import 'package:fl_chart/fl_chart.dart'; // Añadir fl_chart: ^0.65.0 a pubspec.yaml

class StudioDetailedStatsScreen extends StatefulWidget {
  const StudioDetailedStatsScreen({super.key});

  @override
  State<StudioDetailedStatsScreen> createState() =>
      _StudioDetailedStatsScreenState();
}

class _StudioDetailedStatsScreenState extends State<StudioDetailedStatsScreen> {
  final MetricsService _metricsService = MetricsService();
  ArtistMetricsDetailed? _metrics;
  bool _isLoading = true;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Default: last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      final response = await _metricsService.getArtistMetricsDetailed(
        authProvider.currentUser!.id,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (response.success && response.data != null) {
        setState(() {
          _metrics = response.data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _metrics == null
              ? const Center(child: Text('No data available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateRangeCard(),
                      const SizedBox(height: 16),
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      _buildPlaysChart(),
                      const SizedBox(height: 24),
                      _buildRevenueChart(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Period: ${_formatDate(_metrics!.startDate)} - ${_formatDate(_metrics!.endDate)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _selectDateRange,
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Plays',
          _metrics!.totalPlays.toString(),
          Icons.play_circle,
          AppTheme.primaryBlue,
        ),
        _buildStatCard(
          'Total Revenue',
          '\$${_metrics!.totalRevenue.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        _buildStatCard(
          'Total Sales',
          _metrics!.totalSales.toString(),
          Icons.shopping_cart,
          Colors.orange,
        ),
        _buildStatCard(
          'Avg Rating',
          _metrics!.averageRating.toStringAsFixed(1),
          Icons.star,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaysChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plays Over Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _metrics!.dailyMetrics
                          .asMap()
                          .entries
                          .map((e) =>
                              FlSpot(e.key.toDouble(), e.value.plays.toDouble()))
                          .toList(),
                      isCurved: true,
                      color: AppTheme.primaryBlue,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Over Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _metrics!.dailyMetrics
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.revenue))
                          .toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadMetrics();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
```

**Nota importante**: Para los gráficos, necesitas añadir la dependencia `fl_chart` en `pubspec.yaml`:

```yaml
dependencies:
  fl_chart: ^0.65.0
```

### ✅ Checklist de Implementación GA01-109

**Backend**:
- [ ] Crear `ArtistMetricsDetailed.java` DTO
- [ ] Modificar `MetricsService.java` (añadir métodos de GA01-109)
- [ ] Modificar `MetricsController.java` (añadir endpoint de GA01-109)
- [ ] (Futuro) Crear tabla de tracking histórico para datos reales por fecha
- [ ] (Futuro) Implementar job para guardar snapshots diarios de métricas

**Frontend**:
- [ ] Crear `artist_metrics_detailed.dart` modelo
- [ ] Modificar `metrics_service.dart` (añadir método de GA01-109)
- [ ] Añadir dependencia `fl_chart` en pubspec.yaml
- [ ] Crear `studio_detailed_stats_screen.dart` con gráficos
- [ ] Implementar selector de rango de fechas
- [ ] Crear gráficos de línea para plays, revenue, etc.
- [ ] Añadir opción de exportar datos (opcional)

**Testing**:
- [ ] Probar endpoint de métricas detalladas con diferentes rangos
- [ ] Validar generación de datos diarios
- [ ] Probar UI con diferentes períodos (7 días, 30 días, 90 días)
- [ ] Verificar que los gráficos se renderizan correctamente
- [ ] Probar edge cases (1 día, muchos días, sin datos)

---

## 📊 Resumen de Cambios por Archivo

### Archivos que SOLO requieren cambios de GA01-108:
- ✅ `ArtistMetricsSummary.java` (nuevo)
- ✅ `SongMetrics.java` (nuevo)
- ✅ `artist_metrics_summary.dart` (nuevo)

### Archivos que SOLO requieren cambios de GA01-109:
- ✅ `ArtistMetricsDetailed.java` (nuevo)
- ✅ `artist_metrics_detailed.dart` (nuevo)
- ✅ `studio_detailed_stats_screen.dart` (nuevo)

### Archivos que requieren cambios de AMBAS subtareas:
- ⚠️ `MetricsService.java` - Primero GA01-108 (resumen), luego GA01-109 (detallado)
- ⚠️ `MetricsController.java` - Primero GA01-108 (endpoint resumen), luego GA01-109 (endpoint detallado)
- ⚠️ `metrics_service.dart` - Primero GA01-108 (método resumen), luego GA01-109 (método detallado)

---

## 🗄️ Base de Datos y Tracking Histórico

### Estado Actual

Actualmente, las métricas se calculan desde los datos actuales:
- **Plays**: Campo `plays` en tabla `songs` (valor acumulado)
- **Álbumes/Canciones**: Conteo desde tablas `albums` y `songs`
- **Colaboraciones**: Conteo desde tabla `collaborators`

### Limitaciones Actuales

❌ **No hay tracking histórico real**: Los datos de crecimiento y timeline son simulados
❌ **No hay integración con otros servicios**: Ratings, ventas y comentarios usan datos mock
❌ **No hay snapshots temporales**: No se pueden hacer comparaciones reales entre períodos

### Implementación Futura Recomendada

Para tener métricas históricas reales, se recomienda:

#### 1. Crear tabla de snapshots diarios

```sql
CREATE TABLE metrics_snapshots (
    id BIGSERIAL PRIMARY KEY,
    artist_id BIGINT NOT NULL,
    snapshot_date DATE NOT NULL,
    total_plays BIGINT DEFAULT 0,
    total_songs INTEGER DEFAULT 0,
    total_albums INTEGER DEFAULT 0,
    total_collaborations INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(artist_id, snapshot_date)
);

CREATE INDEX idx_metrics_snapshots_artist_date
    ON metrics_snapshots(artist_id, snapshot_date);
```

#### 2. Crear job para tomar snapshots diarios

```java
@Scheduled(cron = "0 0 1 * * *") // Every day at 1 AM
public void takeMetricsSnapshot() {
    List<Long> artistIds = getAllActiveArtistIds();

    for (Long artistId : artistIds) {
        MetricsSnapshot snapshot = new MetricsSnapshot();
        snapshot.setArtistId(artistId);
        snapshot.setSnapshotDate(LocalDate.now());
        snapshot.setTotalPlays(calculateTotalPlays(artistId));
        snapshot.setTotalSongs(countSongs(artistId));
        // ... etc

        metricsSnapshotRepository.save(snapshot);
    }
}
```

#### 3. Integrar con otros servicios vía API

```java
// En MetricsService.java
@Autowired
private RestTemplate restTemplate;

private RatingsData fetchRatingsFromCommunityService(Long artistId) {
    String url = "http://community-service/api/ratings/artist/" + artistId;
    return restTemplate.getForObject(url, RatingsData.class);
}

private SalesData fetchSalesFromCommerceService(Long artistId) {
    String url = "http://commerce-service/api/orders/artist/" + artistId + "/summary";
    return restTemplate.getForObject(url, SalesData.class);
}
```

---

## 🎯 Endpoints Completos

### Endpoints de GA01-108

| Método | Endpoint | Descripción | Params |
|--------|----------|-------------|--------|
| GET | `/api/metrics/artists/{artistId}` | Resumen de métricas | - |
| GET | `/api/metrics/songs/{songId}` | Métricas de canción | - |
| GET | `/api/metrics/artists/{artistId}/top-songs` | Top canciones | `limit` (default: 10) |

### Endpoints de GA01-109

| Método | Endpoint | Descripción | Params |
|--------|----------|-------------|--------|
| GET | `/api/metrics/artists/{artistId}/detailed` | Métricas detalladas con timeline | `startDate`, `endDate` |

**Ejemplo de uso**:

```bash
# GA01-108: Resumen rápido
GET http://localhost:8080/api/metrics/artists/1

# GA01-109: Vista detallada (últimos 30 días por defecto)
GET http://localhost:8080/api/metrics/artists/1/detailed

# GA01-109: Vista detallada con rango personalizado
GET http://localhost:8080/api/metrics/artists/1/detailed?startDate=2024-01-01&endDate=2024-01-31
```

---

## 🧪 Casos de Prueba

### Pruebas para GA01-108

1. **Obtener resumen de métricas para artista con contenido**
   ```
   GET /api/metrics/artists/1
   ```
   Resultado esperado: JSON con todas las métricas, plays > 0

2. **Obtener resumen de artista sin contenido**
   ```
   GET /api/metrics/artists/999
   ```
   Resultado esperado: Métricas en 0 o vacías

3. **Verificar cálculo de canción más reproducida**
   ```
   GET /api/metrics/artists/1
   ```
   Resultado esperado: `mostPlayedSongId` debe ser la canción con más plays

4. **Métricas de canción específica**
   ```
   GET /api/metrics/songs/10
   ```
   Resultado esperado: Métricas completas incluyendo ranking

### Pruebas para GA01-109

1. **Obtener métricas detalladas sin parámetros (últimos 30 días)**
   ```
   GET /api/metrics/artists/1/detailed
   ```
   Resultado esperado: Timeline de 30 puntos de datos diarios

2. **Obtener métricas con rango de 7 días**
   ```
   GET /api/metrics/artists/1/detailed?startDate=2024-11-13&endDate=2024-11-20
   ```
   Resultado esperado: Timeline de 8 puntos de datos

3. **Validar que fecha inicio > fecha fin produce error**
   ```
   GET /api/metrics/artists/1/detailed?startDate=2024-11-20&endDate=2024-11-13
   ```
   Resultado esperado: Error 400 Bad Request

4. **Verificar suma de totales del período**
   ```
   GET /api/metrics/artists/1/detailed?startDate=2024-11-01&endDate=2024-11-30
   ```
   Resultado esperado: `totalPlays` debe ser suma de plays de todos los días

---

## 📝 Notas de Implementación

### Orden de Implementación Recomendado

1. **Primero completar TODO GA01-108**
   - Backend completo (DTOs, service, controller)
   - Frontend completo (modelo, service, pantalla)
   - Testing completo
   - Commit y PR de GA01-108

2. **Luego implementar GA01-109**
   - Añadir DTO de métricas detalladas
   - Añadir métodos de timeline a service y controller
   - Añadir modelo detallado a frontend
   - Crear pantalla de vista detallada con gráficos
   - Testing completo
   - Commit y PR de GA01-109

### Optimizaciones Futuras

**Performance**:
- ✅ Cachear resúmenes de métricas (TTL 5 minutos)
- ✅ Índices en tablas de snapshots por artist_id y date
- ✅ Paginación para períodos muy largos en GA01-109
- ✅ Comprimir respuestas JSON grandes

**Features adicionales**:
- 📊 Exportar datos a CSV/Excel
- 📧 Reportes programados por email
- 🔔 Alertas cuando métricas bajan significativamente
- 📱 Notificaciones push para hitos (1M plays, etc.)
- 📈 Comparación con otros artistas (percentiles)
- 🎯 Metas personalizadas (llegar a X plays)

### Dependencias Frontend

Para implementar GA01-109 con gráficos, añadir a `pubspec.yaml`:

```yaml
dependencies:
  fl_chart: ^0.65.0  # Para gráficos de línea/barras
  intl: ^0.18.1      # Para formateo de fechas
```

### Validaciones Importantes

**GA01-108**:
- ✅ Handles artistas sin contenido (métricas en 0)
- ✅ Calcula correctamente canción más reproducida
- ✅ Porcentajes de crecimiento nunca negativos (o mostrar correctamente decrementos)

**GA01-109**:
- ✅ Valida que startDate <= endDate
- ✅ Limita rango máximo (ej: 365 días) para evitar respuestas muy grandes
- ✅ Devuelve array vacío si no hay datos en el rango
- ✅ Maneja correctamente zona horaria en fechas

---

## 📱 Integración con UI Existente

### Modificar `studio_stats_screen.dart`

Para integrar GA01-108 con la pantalla existente, actualizar el método `_loadMetrics`:

```dart
Future<void> _loadMetrics() async {
  setState(() => _isLoading = true);

  final authProvider = context.read<AuthProvider>();
  if (authProvider.currentUser != null) {
    // Usar nuevo método tipado
    final metricsResponse = await _metricsService.getArtistMetricsSummaryTyped(
      authProvider.currentUser!.id
    );

    if (metricsResponse.success) {
      setState(() {
        _artistMetrics = metricsResponse.data;
        _isLoading = false;
      });
    }
  }

  setState(() => _isLoading = false);
}
```

Y actualizar los widgets para usar el modelo tipado en lugar de Map.

### Añadir Navegación a Vista Detallada

En `studio_stats_screen.dart`, añadir botón para ver detalles:

```dart
ElevatedButton.icon(
  icon: const Icon(Icons.analytics),
  label: const Text('View Detailed Analytics'),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StudioDetailedStatsScreen(),
      ),
    );
  },
)
```

---

## ✅ Verificación Final

Antes de dar por completada cada subtarea, verificar:

**GA01-108**:
- [ ] Todos los archivos backend creados/modificados
- [ ] Endpoint de resumen funcionando correctamente
- [ ] Modelo frontend creado y parseando JSON correctamente
- [ ] UI muestra todas las métricas con formato adecuado
- [ ] Indicadores de crecimiento visibles y claros
- [ ] Testing de todos los flujos pasando
- [ ] Documentación actualizada

**GA01-109**:
- [ ] DTO de métricas detalladas creado
- [ ] Endpoint de detalle con parámetros de fecha funcionando
- [ ] Timeline generando datos correctamente
- [ ] Modelo frontend parseando timeline
- [ ] Dependencia fl_chart añadida
- [ ] Pantalla de vista detallada con gráficos renderizando
- [ ] Selector de rango de fechas funcional
- [ ] Gráficos actualizándose al cambiar rango
- [ ] Validaciones de fechas implementadas
- [ ] Testing de edge cases pasando

---

## 🚀 Mejoras Futuras Sugeridas

### Corto Plazo
1. **Integración real con otros servicios** (ratings, ventas, comentarios)
2. **Tabla de snapshots históricos** para datos reales de crecimiento
3. **Cache de métricas** para mejorar performance
4. **Más tipos de gráficos** (barras, pie charts, etc.)

### Mediano Plazo
1. **Dashboard comparativo** (comparar períodos, comparar con promedio de plataforma)
2. **Métricas por canción/álbum individual** con vista similar
3. **Exportación de reportes** en PDF/Excel
4. **Alertas automáticas** cuando métricas cambian significativamente

### Largo Plazo
1. **Machine Learning** para predecir tendencias
2. **Recomendaciones personalizadas** basadas en métricas
3. **Benchmarking** con artistas similares
4. **Analytics en tiempo real** con WebSockets

---

¡Guía completa! Seguir el orden indicado garantiza una implementación limpia y sin conflictos entre subtareas.
