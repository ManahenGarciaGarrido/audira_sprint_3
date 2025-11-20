# Guía de Migración: Sistema de Colaboraciones por Subtarea

Esta guía detalla **TODOS** los cambios necesarios para implementar el sistema completo de colaboraciones con invitaciones y reparto de ganancias, organizados por subtarea para facilitar la migración al repositorio original de GitHub.

**IMPORTANTE**: Esta guía separa claramente el código de cada subtarea. Si un archivo necesita cambios de ambas subtareas, se muestra primero lo de GA01-154 (sin incluir GA01-155) y luego lo que hay que añadir en GA01-155 (sin repetir GA01-154).

---

## 📋 Índice de Subtareas

1. [GA01-154: Añadir/aceptar colaboradores](#ga01-154-añadiracept

ar-colaboradores)
2. [GA01-155: Definir porcentaje de ganancias](#ga01-155-definir-porcentaje-de-ganancias)

---

## 📦 Información General

### Contexto
El sistema de colaboraciones ya tiene una base implementada pero le faltan funcionalidades críticas:
- **Actualmente**: Solo se pueden crear colaboradores directamente sin invitación ni control
- **GA01-154**: Sistema de invitaciones que los artistas deben aceptar/rechazar
- **GA01-155**: Definición de porcentajes de ganancias para cada colaborador

### Arquitectura
- **Backend**: music-catalog-service (Spring Boot)
- **Frontend**: Flutter con Provider para state management
- **Base de datos**: PostgreSQL con JPA/Hibernate

---

## GA01-154: Añadir/aceptar colaboradores

Esta subtarea implementa el sistema de invitaciones de colaboración donde:
- Los artistas pueden invitar a otros a colaborar en canciones/álbumes
- Los invitados deben aceptar o rechazar la invitación
- Se registra quién invitó y el estado de cada colaboración

### 📁 Archivos a Crear/Modificar (Backend)

#### 1. CREAR: `CollaborationStatus.java`

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/model/CollaborationStatus.java`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```java
package io.audira.catalog.model;

/**
 * Status of a collaboration invitation
 * GA01-154: Añadir/aceptar colaboradores
 */
public enum CollaborationStatus {
    PENDING,    // Invitation sent, waiting for response
    ACCEPTED,   // Collaboration accepted by artist
    REJECTED    // Collaboration rejected by artist
}
```

#### 2. MODIFICAR: `Collaborator.java`

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/model/Collaborator.java`

**Acción**: Modificar archivo existente (SOLO cambios de GA01-154)

**Cambios necesarios**:

**IMPORTANTE**: Este archivo también necesita cambios de GA01-155. Aquí se muestran SOLO los cambios de GA01-154.

**Buscar y reemplazar el archivo completo** con esta versión que incluye SOLO campos de GA01-154:

```java
package io.audira.catalog.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Collaborator entity representing artist collaborations on songs/albums
 * GA01-154: Añadir/aceptar colaboradores - status, invitedBy, albumId
 */
@Entity
@Table(name = "collaborators")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Collaborator {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "song_id")
    private Long songId;

    @Column(name = "album_id")
    private Long albumId; // GA01-154: Support album collaborations

    @Column(name = "artist_id", nullable = false)
    private Long artistId; // The collaborator artist ID

    @Column(nullable = false, length = 100)
    private String role; // feature, producer, composer, etc.

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private CollaborationStatus status = CollaborationStatus.PENDING; // GA01-154: Invitation status

    @Column(name = "invited_by", nullable = false)
    private Long invitedBy; // GA01-154: ID of user who created the invitation

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        if (this.status == null) {
            this.status = CollaborationStatus.PENDING;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Check if collaboration is for a song
     */
    public boolean isForSong() {
        return songId != null;
    }

    /**
     * Check if collaboration is for an album
     */
    public boolean isForAlbum() {
        return albumId != null;
    }

    /**
     * Get the entity ID (song or album)
     */
    public Long getEntityId() {
        return songId != null ? songId : albumId;
    }

    /**
     * Get the entity type
     */
    public String getEntityType() {
        return songId != null ? "SONG" : "ALBUM";
    }
}
```

**Resumen de cambios en Collaborator.java para GA01-154**:
- ✅ Añadir `albumId` (columna `album_id`) - soporte para colaboraciones en álbumes
- ✅ Cambiar `songId` de `nullable = false` a nullable (porque puede ser álbum)
- ✅ Añadir campo `status` (enum CollaborationStatus)
- ✅ Añadir campo `invitedBy` (quien creó la invitación)
- ✅ Añadir campo `updatedAt`
- ✅ Añadir métodos helper: `isForSong()`, `isForAlbum()`, `getEntityId()`, `getEntityType()`
- ✅ Actualizar `@PrePersist` para inicializar `status`
- ✅ Añadir `@PreUpdate` para actualizar `updatedAt`

#### 3. CREAR: `CollaborationRequest.java`

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/dto/CollaborationRequest.java`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```java
package io.audira.catalog.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for creating collaboration invitations
 * GA01-154: Añadir/aceptar colaboradores
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CollaborationRequest {

    private Long songId; // Either songId or albumId must be provided

    private Long albumId; // Either songId or albumId must be provided

    @NotNull(message = "Artist ID is required")
    private Long artistId; // The artist being invited to collaborate

    @NotNull(message = "Role is required")
    @Size(min = 1, max = 100, message = "Role must be between 1 and 100 characters")
    private String role; // feature, producer, composer, etc.
}
```

#### 4. MODIFICAR: `CollaboratorRepository.java`

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/repository/CollaboratorRepository.java`

**Acción**: Modificar archivo existente (SOLO cambios de GA01-154)

**Cambios necesarios**:

**Buscar y reemplazar el archivo completo** con esta versión que incluye SOLO queries de GA01-154:

```java
package io.audira.catalog.repository;

import io.audira.catalog.model.Collaborator;
import io.audira.catalog.model.CollaborationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repository for Collaborator entity
 * GA01-154: Añadir/aceptar colaboradores - status queries
 */
@Repository
public interface CollaboratorRepository extends JpaRepository<Collaborator, Long> {

    // Existing queries
    List<Collaborator> findBySongId(Long songId);

    List<Collaborator> findByArtistId(Long artistId);

    void deleteBySongId(Long songId);

    // GA01-154: New queries for collaboration invitations
    List<Collaborator> findByAlbumId(Long albumId);

    List<Collaborator> findByArtistIdAndStatus(Long artistId, CollaborationStatus status);

    List<Collaborator> findBySongIdAndStatus(Long songId, CollaborationStatus status);

    List<Collaborator> findByAlbumIdAndStatus(Long albumId, CollaborationStatus status);

    List<Collaborator> findByInvitedBy(Long invitedBy);

    void deleteByAlbumId(Long albumId);
}
```

**Resumen de nuevos métodos para GA01-154**:
- `findByAlbumId()` - Colaboradores de un álbum
- `findByArtistIdAndStatus()` - Filtrar por artista y estado
- `findBySongIdAndStatus()` - Filtrar colaboradores de canción por estado
- `findByAlbumIdAndStatus()` - Filtrar colaboradores de álbum por estado
- `findByInvitedBy()` - Colaboraciones creadas por un usuario
- `deleteByAlbumId()` - Eliminar colaboradores de un álbum

#### 5. MODIFICAR: `CollaboratorService.java`

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/service/CollaboratorService.java`

**Acción**: Modificar archivo existente (SOLO cambios de GA01-154)

**IMPORTANTE**: Este archivo también necesita cambios de GA01-155. Aquí se muestran SOLO los cambios de GA01-154.

**Añadir estos imports al inicio del archivo**:

```java
import io.audira.catalog.dto.CollaborationRequest;
import io.audira.catalog.model.CollaborationStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
```

**Añadir después de los imports y antes de la clase**:

```java
/**
 * Service for managing collaborations
 * GA01-154: Añadir/aceptar colaboradores
 */
```

**Añadir dentro de la clase, después del campo `collaboratorRepository`**:

```java
private static final Logger logger = LoggerFactory.getLogger(CollaboratorService.class);
```

**Añadir estos nuevos métodos AL FINAL de la clase** (después de `deleteCollaboratorsBySongId`):

```java
    // ===== GA01-154: New methods for collaboration invitations =====

    /**
     * Invite an artist to collaborate on a song or album
     * GA01-154: Añadir/aceptar colaboradores
     */
    @Transactional
    public Collaborator inviteCollaborator(CollaborationRequest request, Long inviterId) {
        // Validate that either songId or albumId is provided
        if (request.getSongId() == null && request.getAlbumId() == null) {
            throw new IllegalArgumentException("Either songId or albumId must be provided");
        }
        if (request.getSongId() != null && request.getAlbumId() != null) {
            throw new IllegalArgumentException("Cannot specify both songId and albumId");
        }

        // Check if collaboration already exists
        List<Collaborator> existing;
        if (request.getSongId() != null) {
            existing = collaboratorRepository.findBySongId(request.getSongId());
        } else {
            existing = collaboratorRepository.findByAlbumId(request.getAlbumId());
        }

        boolean alreadyExists = existing.stream()
                .anyMatch(c -> c.getArtistId().equals(request.getArtistId()));

        if (alreadyExists) {
            throw new IllegalArgumentException("Collaboration already exists for this artist");
        }

        Collaborator collaborator = Collaborator.builder()
                .songId(request.getSongId())
                .albumId(request.getAlbumId())
                .artistId(request.getArtistId())
                .role(request.getRole())
                .status(CollaborationStatus.PENDING)
                .invitedBy(inviterId)
                .build();

        Collaborator saved = collaboratorRepository.save(collaborator);

        logger.info("Collaboration invitation created: {} invited artist {} for {} {}",
                inviterId, request.getArtistId(),
                saved.isForSong() ? "song" : "album",
                saved.getEntityId());

        return saved;
    }

    /**
     * Accept a collaboration invitation
     * GA01-154: Añadir/aceptar colaboradores
     */
    @Transactional
    public Collaborator acceptCollaboration(Long collaborationId, Long artistId) {
        Collaborator collaborator = collaboratorRepository.findById(collaborationId)
                .orElseThrow(() -> new RuntimeException("Collaboration not found with id: " + collaborationId));

        // Verify the artist is the one being invited
        if (!collaborator.getArtistId().equals(artistId)) {
            throw new IllegalArgumentException("You are not authorized to accept this collaboration");
        }

        // Verify status is PENDING
        if (collaborator.getStatus() != CollaborationStatus.PENDING) {
            throw new IllegalArgumentException("Collaboration is not in pending status");
        }

        collaborator.setStatus(CollaborationStatus.ACCEPTED);
        Collaborator saved = collaboratorRepository.save(collaborator);

        logger.info("Collaboration accepted: artist {} accepted collaboration {} for {} {}",
                artistId, collaborationId,
                saved.isForSong() ? "song" : "album",
                saved.getEntityId());

        return saved;
    }

    /**
     * Reject a collaboration invitation
     * GA01-154: Añadir/aceptar colaboradores
     */
    @Transactional
    public Collaborator rejectCollaboration(Long collaborationId, Long artistId) {
        Collaborator collaborator = collaboratorRepository.findById(collaborationId)
                .orElseThrow(() -> new RuntimeException("Collaboration not found with id: " + collaborationId));

        // Verify the artist is the one being invited
        if (!collaborator.getArtistId().equals(artistId)) {
            throw new IllegalArgumentException("You are not authorized to reject this collaboration");
        }

        // Verify status is PENDING
        if (collaborator.getStatus() != CollaborationStatus.PENDING) {
            throw new IllegalArgumentException("Collaboration is not in pending status");
        }

        collaborator.setStatus(CollaborationStatus.REJECTED);
        Collaborator saved = collaboratorRepository.save(collaborator);

        logger.info("Collaboration rejected: artist {} rejected collaboration {} for {} {}",
                artistId, collaborationId,
                saved.isForSong() ? "song" : "album",
                saved.getEntityId());

        return saved;
    }

    /**
     * Get pending collaboration invitations for an artist
     * GA01-154: Añadir/aceptar colaboradores
     */
    public List<Collaborator> getPendingInvitations(Long artistId) {
        return collaboratorRepository.findByArtistIdAndStatus(artistId, CollaborationStatus.PENDING);
    }

    /**
     * Get collaborations by album ID
     * GA01-154: Añadir/aceptar colaboradores
     */
    public List<Collaborator> getCollaboratorsByAlbumId(Long albumId) {
        return collaboratorRepository.findByAlbumId(albumId);
    }

    /**
     * Get accepted collaborations for a song
     * GA01-154: Añadir/aceptar colaboradores
     */
    public List<Collaborator> getAcceptedCollaboratorsBySongId(Long songId) {
        return collaboratorRepository.findBySongIdAndStatus(songId, CollaborationStatus.ACCEPTED);
    }

    /**
     * Get accepted collaborations for an album
     * GA01-154: Añadir/aceptar colaboradores
     */
    public List<Collaborator> getAcceptedCollaboratorsByAlbumId(Long albumId) {
        return collaboratorRepository.findByAlbumIdAndStatus(albumId, CollaborationStatus.ACCEPTED);
    }

    /**
     * Get collaborations created by a user
     * GA01-154: Añadir/aceptar colaboradores
     */
    public List<Collaborator> getCollaborationsByInviter(Long inviterId) {
        return collaboratorRepository.findByInvitedBy(inviterId);
    }

    /**
     * Delete collaborations by album ID
     * GA01-154: Añadir/aceptar colaboradores
     */
    @Transactional
    public void deleteCollaboratorsByAlbumId(Long albumId) {
        collaboratorRepository.deleteByAlbumId(albumId);
    }
```

**Resumen de nuevos métodos en CollaboratorService para GA01-154**:
- `inviteCollaborator()` - Crear invitación de colaboración
- `acceptCollaboration()` - Aceptar invitación
- `rejectCollaboration()` - Rechazar invitación
- `getPendingInvitations()` - Obtener invitaciones pendientes
- `getCollaboratorsByAlbumId()` - Colaboradores de álbum
- `getAcceptedCollaboratorsBySongId()` - Colaboradores aceptados de canción
- `getAcceptedCollaboratorsByAlbumId()` - Colaboradores aceptados de álbum
- `getCollaborationsByInviter()` - Colaboraciones creadas por usuario
- `deleteCollaboratorsByAlbumId()` - Eliminar colaboradores de álbum

#### 6. MODIFICAR: `CollaboratorController.java`

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/controller/CollaboratorController.java`

**Acción**: Modificar archivo existente (SOLO cambios de GA01-154)

**IMPORTANTE**: Este archivo también necesita cambios de GA01-155. Aquí se muestran SOLO los cambios de GA01-154.

**Añadir estos imports al inicio del archivo**:

```java
import io.audira.catalog.dto.CollaborationRequest;
import jakarta.validation.Valid;
```

**Actualizar el comentario de la clase**:

```java
/**
 * Controller for managing collaborations
 * GA01-154: Añadir/aceptar colaboradores
 */
```

**Añadir estos nuevos endpoints AL FINAL de la clase** (después del último método):

```java
    // ===== GA01-154: New endpoints for collaboration invitations =====

    /**
     * Invite an artist to collaborate
     * GA01-154: Añadir/aceptar colaboradores
     */
    @PostMapping("/invite")
    public ResponseEntity<Collaborator> inviteCollaborator(
            @Valid @RequestBody CollaborationRequest request,
            @RequestParam Long inviterId) {
        try {
            Collaborator collaboration = collaboratorService.inviteCollaborator(request, inviterId);
            return ResponseEntity.status(HttpStatus.CREATED).body(collaboration);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Accept a collaboration invitation
     * GA01-154: Añadir/aceptar colaboradores
     */
    @PutMapping("/{id}/accept")
    public ResponseEntity<Collaborator> acceptCollaboration(
            @PathVariable Long id,
            @RequestParam Long artistId) {
        try {
            Collaborator collaboration = collaboratorService.acceptCollaboration(id, artistId);
            return ResponseEntity.ok(collaboration);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Reject a collaboration invitation
     * GA01-154: Añadir/aceptar colaboradores
     */
    @PutMapping("/{id}/reject")
    public ResponseEntity<Collaborator> rejectCollaboration(
            @PathVariable Long id,
            @RequestParam Long artistId) {
        try {
            Collaborator collaboration = collaboratorService.rejectCollaboration(id, artistId);
            return ResponseEntity.ok(collaboration);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Get pending collaboration invitations for an artist
     * GA01-154: Añadir/aceptar colaboradores
     */
    @GetMapping("/pending/{artistId}")
    public ResponseEntity<List<Collaborator>> getPendingInvitations(@PathVariable Long artistId) {
        List<Collaborator> invitations = collaboratorService.getPendingInvitations(artistId);
        return ResponseEntity.ok(invitations);
    }

    /**
     * Get collaborations by album ID
     * GA01-154: Añadir/aceptar colaboradores
     */
    @GetMapping("/album/{albumId}")
    public ResponseEntity<List<Collaborator>> getCollaboratorsByAlbumId(@PathVariable Long albumId) {
        List<Collaborator> collaborators = collaboratorService.getCollaboratorsByAlbumId(albumId);
        return ResponseEntity.ok(collaborators);
    }

    /**
     * Get accepted collaborations for a song
     * GA01-154: Añadir/aceptar colaboradores
     */
    @GetMapping("/song/{songId}/accepted")
    public ResponseEntity<List<Collaborator>> getAcceptedCollaboratorsBySongId(@PathVariable Long songId) {
        List<Collaborator> collaborators = collaboratorService.getAcceptedCollaboratorsBySongId(songId);
        return ResponseEntity.ok(collaborators);
    }

    /**
     * Get accepted collaborations for an album
     * GA01-154: Añadir/aceptar colaboradores
     */
    @GetMapping("/album/{albumId}/accepted")
    public ResponseEntity<List<Collaborator>> getAcceptedCollaboratorsByAlbumId(@PathVariable Long albumId) {
        List<Collaborator> collaborators = collaboratorService.getAcceptedCollaboratorsByAlbumId(albumId);
        return ResponseEntity.ok(collaborators);
    }

    /**
     * Get collaborations created by a user
     * GA01-154: Añadir/aceptar colaboradores
     */
    @GetMapping("/inviter/{inviterId}")
    public ResponseEntity<List<Collaborator>> getCollaborationsByInviter(@PathVariable Long inviterId) {
        List<Collaborator> collaborations = collaboratorService.getCollaborationsByInviter(inviterId);
        return ResponseEntity.ok(collaborations);
    }

    /**
     * Delete collaborations by album ID
     * GA01-154: Añadir/aceptar colaboradores
     */
    @DeleteMapping("/album/{albumId}")
    public ResponseEntity<Void> deleteCollaboratorsByAlbumId(@PathVariable Long albumId) {
        collaboratorService.deleteCollaboratorsByAlbumId(albumId);
        return ResponseEntity.noContent().build();
    }
```

**Resumen de nuevos endpoints para GA01-154**:
- `POST /api/collaborators/invite` - Invitar colaborador
- `PUT /api/collaborators/{id}/accept` - Aceptar invitación
- `PUT /api/collaborators/{id}/reject` - Rechazar invitación
- `GET /api/collaborators/pending/{artistId}` - Invitaciones pendientes
- `GET /api/collaborators/album/{albumId}` - Colaboradores de álbum
- `GET /api/collaborators/song/{songId}/accepted` - Colaboradores aceptados de canción
- `GET /api/collaborators/album/{albumId}/accepted` - Colaboradores aceptados de álbum
- `GET /api/collaborators/inviter/{inviterId}` - Colaboraciones creadas por usuario
- `DELETE /api/collaborators/album/{albumId}` - Eliminar colaboradores de álbum

### 📁 Archivos a Crear/Modificar (Frontend)

#### 7. MODIFICAR: `collaborator.dart` (Modelo)

**Ubicación**: `audira_frontend/lib/core/models/collaborator.dart`

**Acción**: Reemplazar archivo existente (SOLO cambios de GA01-154)

**IMPORTANTE**: Este archivo también necesita cambios de GA01-155. Aquí se muestra SOLO con campos de GA01-154.

**Buscar y reemplazar el archivo completo**:

```dart
import 'package:equatable/equatable.dart';

/// Collaboration status enum
/// GA01-154: Añadir/aceptar colaboradores
enum CollaborationStatus {
  pending,
  accepted,
  rejected;

  String toJson() => name.toUpperCase();

  static CollaborationStatus fromJson(String json) {
    return CollaborationStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == json.toUpperCase(),
      orElse: () => CollaborationStatus.pending,
    );
  }
}

/// Collaborator model representing collaborations on songs/albums
/// GA01-154: Añadir/aceptar colaboradores - status, invitedBy, albumId
class Collaborator extends Equatable {
  final int id;
  final int? songId;
  final int? albumId; // GA01-154: Support album collaborations
  final int artistId;
  final String role; // feature, producer, composer, etc.
  final CollaborationStatus status; // GA01-154: Invitation status
  final int invitedBy; // GA01-154: User who created the invitation
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Collaborator({
    required this.id,
    this.songId,
    this.albumId,
    required this.artistId,
    required this.role,
    required this.status,
    required this.invitedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    return Collaborator(
      id: json['id'] as int,
      songId: json['songId'] as int?,
      albumId: json['albumId'] as int?,
      artistId: json['artistId'] as int,
      role: json['role'] as String,
      status: json['status'] != null
          ? CollaborationStatus.fromJson(json['status'] as String)
          : CollaborationStatus.pending,
      invitedBy: json['invitedBy'] as int,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (songId != null) 'songId': songId,
      if (albumId != null) 'albumId': albumId,
      'artistId': artistId,
      'role': role,
      'status': status.toJson(),
      'invitedBy': invitedBy,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Check if collaboration is for a song
  bool get isForSong => songId != null;

  /// Check if collaboration is for an album
  bool get isForAlbum => albumId != null;

  /// Get the entity ID (song or album)
  int? get entityId => songId ?? albumId;

  /// Get the entity type
  String get entityType => songId != null ? 'SONG' : 'ALBUM';

  /// Check if collaboration is pending
  bool get isPending => status == CollaborationStatus.pending;

  /// Check if collaboration is accepted
  bool get isAccepted => status == CollaborationStatus.accepted;

  /// Check if collaboration is rejected
  bool get isRejected => status == CollaborationStatus.rejected;

  Collaborator copyWith({
    int? id,
    int? songId,
    int? albumId,
    int? artistId,
    String? role,
    CollaborationStatus? status,
    int? invitedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Collaborator(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      albumId: albumId ?? this.albumId,
      artistId: artistId ?? this.artistId,
      role: role ?? this.role,
      status: status ?? this.status,
      invitedBy: invitedBy ?? this.invitedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        songId,
        albumId,
        artistId,
        role,
        status,
        invitedBy,
        createdAt,
        updatedAt,
      ];
}
```

**Resumen de cambios en collaborator.dart para GA01-154**:
- ✅ Añadir enum `CollaborationStatus` con pending/accepted/rejected
- ✅ Añadir campo `albumId`
- ✅ Hacer `songId` nullable
- ✅ Añadir campo `status`
- ✅ Añadir campo `invitedBy`
- ✅ Añadir campo `updatedAt`
- ✅ Añadir getters helper: `isForSong`, `isForAlbum`, `entityId`, `entityType`, `isPending`, `isAccepted`, `isRejected`

### ✅ Checklist de Implementación GA01-154

**Backend**:
- [ ] Crear `CollaborationStatus.java` enum
- [ ] Modificar `Collaborator.java` (añadir campos de GA01-154)
- [ ] Crear `CollaborationRequest.java` DTO
- [ ] Modificar `CollaboratorRepository.java` (añadir queries de GA01-154)
- [ ] Modificar `CollaboratorService.java` (añadir métodos de GA01-154)
- [ ] Modificar `CollaboratorController.java` (añadir endpoints de GA01-154)
- [ ] Ejecutar migración de base de datos para nuevas columnas

**Frontend**:
- [ ] Modificar `collaborator.dart` modelo (añadir campos de GA01-154)
- [ ] Crear servicio de colaboraciones con endpoints de GA01-154
- [ ] Crear provider para gestión de estado
- [ ] Crear pantalla de invitaciones pendientes
- [ ] Crear componente para invitar colaboradores
- [ ] Integrar en pantalla de detalles de canción/álbum

**Testing**:
- [ ] Probar invitación de colaborador en canción
- [ ] Probar invitación de colaborador en álbum
- [ ] Probar aceptar invitación
- [ ] Probar rechazar invitación
- [ ] Probar listar invitaciones pendientes
- [ ] Validar que no se puede duplicar colaborador

---

## GA01-155: Definir porcentaje de ganancias

Esta subtarea implementa el sistema de reparto de ganancias donde:
- El creador puede asignar porcentaje de ganancias a cada colaborador aceptado
- El sistema valida que el total no exceda 100%
- Se puede consultar el porcentaje total asignado

**IMPORTANTE**: Esta subtarea requiere que GA01-154 esté implementada primero.

### 📁 Archivos a Crear/Modificar (Backend)

#### 1. CREAR: `UpdateRevenueRequest.java`

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/dto/UpdateRevenueRequest.java`

**Acción**: Crear nuevo archivo

**Contenido completo**:

```java
package io.audira.catalog.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Request DTO for updating revenue percentage of a collaboration
 * GA01-155: Definir porcentaje de ganancias
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateRevenueRequest {

    @NotNull(message = "Revenue percentage is required")
    @DecimalMin(value = "0.00", message = "Revenue percentage must be at least 0")
    @DecimalMax(value = "100.00", message = "Revenue percentage cannot exceed 100")
    private BigDecimal revenuePercentage;
}
```

#### 2. MODIFICAR: `Collaborator.java` (AÑADIR campo de GA01-155)

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/model/Collaborator.java`

**Acción**: Añadir campo adicional (código de GA01-155 SOLAMENTE)

**IMPORTANTE**: Este archivo ya fue modificado en GA01-154. Aquí se muestra QUÉ AÑADIR adicional.

**Después de la línea del campo `invitedBy`, AÑADIR**:

```java
    @Column(name = "revenue_percentage", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal revenuePercentage = BigDecimal.ZERO; // GA01-155: Percentage of revenue (0-100)
```

**Añadir este import al inicio**:

```java
import java.math.BigDecimal;
```

**Actualizar el comentario de la clase** para incluir GA01-155:

```java
/**
 * Collaborator entity representing artist collaborations on songs/albums
 * GA01-154: Añadir/aceptar colaboradores - status, invitedBy, albumId
 * GA01-155: Definir porcentaje de ganancias - revenuePercentage
 */
```

**En el método `@PrePersist`, AÑADIR al final** (antes del cierre):

```java
        if (this.revenuePercentage == null) {
            this.revenuePercentage = BigDecimal.ZERO;
        }
```

**Archivo completo resultante** (GA01-154 + GA01-155):

```java
package io.audira.catalog.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Collaborator entity representing artist collaborations on songs/albums
 * GA01-154: Añadir/aceptar colaboradores - status, invitedBy, albumId
 * GA01-155: Definir porcentaje de ganancias - revenuePercentage
 */
@Entity
@Table(name = "collaborators")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Collaborator {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "song_id")
    private Long songId;

    @Column(name = "album_id")
    private Long albumId; // GA01-154: Support album collaborations

    @Column(name = "artist_id", nullable = false)
    private Long artistId; // The collaborator artist ID

    @Column(nullable = false, length = 100)
    private String role; // feature, producer, composer, etc.

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private CollaborationStatus status = CollaborationStatus.PENDING; // GA01-154: Invitation status

    @Column(name = "invited_by", nullable = false)
    private Long invitedBy; // GA01-154: ID of user who created the invitation

    @Column(name = "revenue_percentage", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal revenuePercentage = BigDecimal.ZERO; // GA01-155: Percentage of revenue (0-100)

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        if (this.status == null) {
            this.status = CollaborationStatus.PENDING;
        }
        if (this.revenuePercentage == null) {
            this.revenuePercentage = BigDecimal.ZERO;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Check if collaboration is for a song
     */
    public boolean isForSong() {
        return songId != null;
    }

    /**
     * Check if collaboration is for an album
     */
    public boolean isForAlbum() {
        return albumId != null;
    }

    /**
     * Get the entity ID (song or album)
     */
    public Long getEntityId() {
        return songId != null ? songId : albumId;
    }

    /**
     * Get the entity type
     */
    public String getEntityType() {
        return songId != null ? "SONG" : "ALBUM";
    }
}
```

#### 3. MODIFICAR: `CollaboratorService.java` (AÑADIR métodos de GA01-155)

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/service/CollaboratorService.java`

**Acción**: Añadir métodos adicionales (código de GA01-155 SOLAMENTE)

**IMPORTANTE**: Este archivo ya fue modificado en GA01-154. Aquí se muestra QUÉ AÑADIR adicional.

**Añadir este import al inicio**:

```java
import io.audira.catalog.dto.UpdateRevenueRequest;
import java.math.BigDecimal;
```

**Actualizar el comentario de la clase** para incluir GA01-155:

```java
/**
 * Service for managing collaborations
 * GA01-154: Añadir/aceptar colaboradores
 * GA01-155: Definir porcentaje de ganancias
 */
```

**Añadir AL FINAL del archivo** (después del último método de GA01-154):

```java
    // ===== GA01-155: New methods for revenue percentage =====

    /**
     * Update revenue percentage for a collaboration
     * GA01-155: Definir porcentaje de ganancias
     */
    @Transactional
    public Collaborator updateRevenuePercentage(Long collaborationId, UpdateRevenueRequest request, Long userId) {
        Collaborator collaborator = collaboratorRepository.findById(collaborationId)
                .orElseThrow(() -> new RuntimeException("Collaboration not found with id: " + collaborationId));

        // Verify the user is the one who created the invitation
        if (!collaborator.getInvitedBy().equals(userId)) {
            throw new IllegalArgumentException("Only the creator can update revenue percentage");
        }

        // Verify collaboration is accepted
        if (collaborator.getStatus() != CollaborationStatus.ACCEPTED) {
            throw new IllegalArgumentException("Can only set revenue percentage for accepted collaborations");
        }

        // Validate total revenue percentage doesn't exceed 100%
        BigDecimal currentTotal = calculateTotalRevenuePercentage(
                collaborator.getSongId(),
                collaborator.getAlbumId(),
                collaborationId
        );

        BigDecimal newTotal = currentTotal.add(request.getRevenuePercentage());
        if (newTotal.compareTo(BigDecimal.valueOf(100)) > 0) {
            throw new IllegalArgumentException(
                    String.format("Total revenue percentage would exceed 100%%. Current: %.2f%%, Requested: %.2f%%, Total would be: %.2f%%",
                            currentTotal, request.getRevenuePercentage(), newTotal)
            );
        }

        collaborator.setRevenuePercentage(request.getRevenuePercentage());
        Collaborator saved = collaboratorRepository.save(collaborator);

        logger.info("Revenue percentage updated: collaboration {} set to {}%",
                collaborationId, request.getRevenuePercentage());

        return saved;
    }

    /**
     * Calculate total revenue percentage for a song or album (excluding specific collaboration)
     * GA01-155: Definir porcentaje de ganancias
     */
    private BigDecimal calculateTotalRevenuePercentage(Long songId, Long albumId, Long excludeCollaborationId) {
        List<Collaborator> collaborators;

        if (songId != null) {
            collaborators = collaboratorRepository.findBySongIdAndStatus(songId, CollaborationStatus.ACCEPTED);
        } else if (albumId != null) {
            collaborators = collaboratorRepository.findByAlbumIdAndStatus(albumId, CollaborationStatus.ACCEPTED);
        } else {
            return BigDecimal.ZERO;
        }

        return collaborators.stream()
                .filter(c -> !c.getId().equals(excludeCollaborationId))
                .map(Collaborator::getRevenuePercentage)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    /**
     * Get total revenue percentage for a song
     * GA01-155: Definir porcentaje de ganancias
     */
    public BigDecimal getTotalRevenuePercentageForSong(Long songId) {
        return calculateTotalRevenuePercentage(songId, null, null);
    }

    /**
     * Get total revenue percentage for an album
     * GA01-155: Definir porcentaje de ganancias
     */
    public BigDecimal getTotalRevenuePercentageForAlbum(Long albumId) {
        return calculateTotalRevenuePercentage(null, albumId, null);
    }
```

**Actualizar el método `inviteCollaborator()` (de GA01-154)** añadiendo la inicialización de revenue:

Buscar esta línea dentro de `inviteCollaborator()`:
```java
        Collaborator collaborator = Collaborator.builder()
                .songId(request.getSongId())
                .albumId(request.getAlbumId())
                .artistId(request.getArtistId())
                .role(request.getRole())
                .status(CollaborationStatus.PENDING)
                .invitedBy(inviterId)
                .build();
```

Y añadir antes del `.build()`:
```java
                .revenuePercentage(BigDecimal.ZERO)
```

**Resumen de nuevos métodos en CollaboratorService para GA01-155**:
- `updateRevenuePercentage()` - Actualizar porcentaje de ganancias
- `calculateTotalRevenuePercentage()` - Calcular total (privado)
- `getTotalRevenuePercentageForSong()` - Total para canción
- `getTotalRevenuePercentageForAlbum()` - Total para álbum

#### 4. MODIFICAR: `CollaboratorController.java` (AÑADIR endpoints de GA01-155)

**Ubicación**: `music-catalog-service/src/main/java/io/audira/catalog/controller/CollaboratorController.java`

**Acción**: Añadir endpoints adicionales (código de GA01-155 SOLAMENTE)

**IMPORTANTE**: Este archivo ya fue modificado en GA01-154. Aquí se muestra QUÉ AÑADIR adicional.

**Añadir estos imports al inicio**:

```java
import io.audira.catalog.dto.UpdateRevenueRequest;
import java.math.BigDecimal;
import java.util.Map;
```

**Actualizar el comentario de la clase** para incluir GA01-155:

```java
/**
 * Controller for managing collaborations
 * GA01-154: Añadir/aceptar colaboradores
 * GA01-155: Definir porcentaje de ganancias
 */
```

**Añadir AL FINAL del archivo** (después del último endpoint de GA01-154):

```java
    // ===== GA01-155: New endpoints for revenue percentage =====

    /**
     * Update revenue percentage for a collaboration
     * GA01-155: Definir porcentaje de ganancias
     */
    @PutMapping("/{id}/revenue")
    public ResponseEntity<Collaborator> updateRevenuePercentage(
            @PathVariable Long id,
            @Valid @RequestBody UpdateRevenueRequest request,
            @RequestParam Long userId) {
        try {
            Collaborator collaboration = collaboratorService.updateRevenuePercentage(id, request, userId);
            return ResponseEntity.ok(collaboration);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Get total revenue percentage for a song
     * GA01-155: Definir porcentaje de ganancias
     */
    @GetMapping("/song/{songId}/revenue-total")
    public ResponseEntity<Map<String, BigDecimal>> getTotalRevenuePercentageForSong(@PathVariable Long songId) {
        BigDecimal total = collaboratorService.getTotalRevenuePercentageForSong(songId);
        return ResponseEntity.ok(Map.of("totalPercentage", total));
    }

    /**
     * Get total revenue percentage for an album
     * GA01-155: Definir porcentaje de ganancias
     */
    @GetMapping("/album/{albumId}/revenue-total")
    public ResponseEntity<Map<String, BigDecimal>> getTotalRevenuePercentageForAlbum(@PathVariable Long albumId) {
        BigDecimal total = collaboratorService.getTotalRevenuePercentageForAlbum(albumId);
        return ResponseEntity.ok(Map.of("totalPercentage", total));
    }
```

**Resumen de nuevos endpoints para GA01-155**:
- `PUT /api/collaborators/{id}/revenue` - Actualizar porcentaje de ganancias
- `GET /api/collaborators/song/{songId}/revenue-total` - Total para canción
- `GET /api/collaborators/album/{albumId}/revenue-total` - Total para álbum

### 📁 Archivos a Crear/Modificar (Frontend)

#### 5. MODIFICAR: `collaborator.dart` (AÑADIR campo de GA01-155)

**Ubicación**: `audira_frontend/lib/core/models/collaborator.dart`

**Acción**: Añadir campo adicional (código de GA01-155 SOLAMENTE)

**IMPORTANTE**: Este archivo ya fue modificado en GA01-154. Aquí se muestra QUÉ AÑADIR adicional.

**Actualizar el comentario de la clase**:

```dart
/// Collaborator model representing collaborations on songs/albums
/// GA01-154: Añadir/aceptar colaboradores - status, invitedBy, albumId
/// GA01-155: Definir porcentaje de ganancias - revenuePercentage
```

**Después del campo `invitedBy`, AÑADIR**:

```dart
  final double revenuePercentage; // GA01-155: Percentage of revenue (0-100)
```

**En el constructor, AÑADIR después de `invitedBy`**:

```dart
    required this.revenuePercentage,
```

**En `fromJson()`, AÑADIR después de la línea de `invitedBy`**:

```dart
      revenuePercentage: (json['revenuePercentage'] as num?)?.toDouble() ?? 0.0,
```

**En `toJson()`, AÑADIR después de la línea de `invitedBy`**:

```dart
      'revenuePercentage': revenuePercentage,
```

**En `copyWith()`, AÑADIR el parámetro**:

```dart
    double? revenuePercentage,
```

Y en el return:

```dart
      revenuePercentage: revenuePercentage ?? this.revenuePercentage,
```

**En `props`, AÑADIR**:

```dart
        revenuePercentage,
```

**Ver archivo completo resultante en la sección GA01-154** (que ya incluye ambos cambios).

### ✅ Checklist de Implementación GA01-155

**Backend**:
- [ ] Crear `UpdateRevenueRequest.java` DTO
- [ ] Modificar `Collaborator.java` (añadir campo `revenuePercentage`)
- [ ] Modificar `CollaboratorService.java` (añadir métodos de GA01-155)
- [ ] Modificar `CollaboratorController.java` (añadir endpoints de GA01-155)
- [ ] Ejecutar migración de base de datos para columna `revenue_percentage`

**Frontend**:
- [ ] Modificar `collaborator.dart` modelo (añadir campo `revenuePercentage`)
- [ ] Añadir métodos al servicio de colaboraciones para GA01-155
- [ ] Crear UI para asignar porcentaje de ganancias
- [ ] Mostrar porcentaje total en pantalla de colaboradores
- [ ] Validar que total no exceda 100%

**Testing**:
- [ ] Probar asignar porcentaje a colaborador aceptado
- [ ] Probar que no se pueda asignar a colaborador pendiente/rechazado
- [ ] Probar validación de 100% máximo
- [ ] Probar consultar total de porcentajes
- [ ] Validar que solo el creador pueda modificar porcentajes

---

## 📊 Resumen de Cambios por Archivo

### Archivos que SOLO requieren cambios de GA01-154:
- ✅ `CollaborationStatus.java` (nuevo)
- ✅ `CollaborationRequest.java` (nuevo)

### Archivos que SOLO requieren cambios de GA01-155:
- ✅ `UpdateRevenueRequest.java` (nuevo)

### Archivos que requieren cambios de AMBAS subtareas:
- ⚠️ `Collaborator.java` - Primero GA01-154 (status, invitedBy, albumId), luego GA01-155 (revenuePercentage)
- ⚠️ `CollaboratorRepository.java` - Solo GA01-154 añade queries nuevas
- ⚠️ `CollaboratorService.java` - Primero GA01-154 (métodos de invitación), luego GA01-155 (métodos de porcentaje)
- ⚠️ `CollaboratorController.java` - Primero GA01-154 (endpoints de invitación), luego GA01-155 (endpoints de porcentaje)
- ⚠️ `collaborator.dart` - Primero GA01-154 (status, invitedBy, albumId), luego GA01-155 (revenuePercentage)

---

## 🗄️ Migraciones de Base de Datos

### Migración para GA01-154

```sql
-- Añadir columnas para GA01-154
ALTER TABLE collaborators
    ADD COLUMN album_id BIGINT,
    ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    ADD COLUMN invited_by BIGINT NOT NULL,
    ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ALTER COLUMN song_id DROP NOT NULL;

-- Añadir índices para mejorar rendimiento
CREATE INDEX idx_collaborators_album_id ON collaborators(album_id);
CREATE INDEX idx_collaborators_status ON collaborators(status);
CREATE INDEX idx_collaborators_invited_by ON collaborators(invited_by);
CREATE INDEX idx_collaborators_artist_status ON collaborators(artist_id, status);

-- Añadir constraint para asegurar que song_id o album_id esté presente
ALTER TABLE collaborators
    ADD CONSTRAINT chk_collaborators_entity
    CHECK ((song_id IS NOT NULL AND album_id IS NULL) OR (song_id IS NULL AND album_id IS NOT NULL));
```

### Migración para GA01-155

```sql
-- Añadir columna para GA01-155
ALTER TABLE collaborators
    ADD COLUMN revenue_percentage DECIMAL(5, 2) NOT NULL DEFAULT 0.00;

-- Añadir constraint para validar rango de porcentaje
ALTER TABLE collaborators
    ADD CONSTRAINT chk_revenue_percentage
    CHECK (revenue_percentage >= 0 AND revenue_percentage <= 100);
```

---

## 🧪 Casos de Prueba

### Pruebas para GA01-154

1. **Invitar colaborador a canción**
   ```
   POST /api/collaborators/invite?inviterId=1
   {
     "songId": 10,
     "artistId": 5,
     "role": "feature"
   }
   ```
   Resultado esperado: Colaboración creada con status PENDING

2. **Invitar colaborador a álbum**
   ```
   POST /api/collaborators/invite?inviterId=1
   {
     "albumId": 3,
     "artistId": 7,
     "role": "producer"
   }
   ```
   Resultado esperado: Colaboración creada con status PENDING

3. **Aceptar invitación**
   ```
   PUT /api/collaborators/15/accept?artistId=5
   ```
   Resultado esperado: Status cambia a ACCEPTED

4. **Rechazar invitación**
   ```
   PUT /api/collaborators/16/reject?artistId=7
   ```
   Resultado esperado: Status cambia a REJECTED

5. **Obtener invitaciones pendientes**
   ```
   GET /api/collaborators/pending/5
   ```
   Resultado esperado: Lista de colaboraciones con status PENDING para artistId=5

### Pruebas para GA01-155

1. **Asignar porcentaje de ganancias**
   ```
   PUT /api/collaborators/15/revenue?userId=1
   {
     "revenuePercentage": 25.50
   }
   ```
   Resultado esperado: Porcentaje asignado correctamente

2. **Validar límite de 100%**
   ```
   # Asignar 60% al primer colaborador
   PUT /api/collaborators/15/revenue?userId=1
   {"revenuePercentage": 60.00}

   # Intentar asignar 50% al segundo (total sería 110%)
   PUT /api/collaborators/16/revenue?userId=1
   {"revenuePercentage": 50.00}
   ```
   Resultado esperado: Segunda petición falla con error "Total would exceed 100%"

3. **Consultar total de porcentajes**
   ```
   GET /api/collaborators/song/10/revenue-total
   ```
   Resultado esperado: `{"totalPercentage": 60.00}`

4. **Validar solo creador puede asignar**
   ```
   PUT /api/collaborators/15/revenue?userId=99
   {"revenuePercentage": 10.00}
   ```
   Resultado esperado: Error 400 "Only the creator can update revenue percentage"

---

## 📝 Notas de Implementación

### Orden de Implementación Recomendado

1. **Primero completar TODO GA01-154**
   - Backend completo (modelo, service, controller)
   - Frontend completo (modelo, service, UI)
   - Testing completo
   - Commit y PR de GA01-154

2. **Luego implementar GA01-155**
   - Añadir campo revenue a modelo backend
   - Añadir métodos de revenue a service y controller
   - Añadir campo revenue a modelo frontend
   - Crear UI para asignar porcentajes
   - Testing completo
   - Commit y PR de GA01-155

### Validaciones Importantes

**GA01-154**:
- ✅ No permitir duplicar colaboradores en la misma canción/álbum
- ✅ Solo el artista invitado puede aceptar/rechazar
- ✅ Solo se puede aceptar/rechazar invitaciones PENDING
- ✅ Debe especificarse songId O albumId (no ambos, no ninguno)

**GA01-155**:
- ✅ Solo el creador de la invitación puede asignar porcentaje
- ✅ Solo se puede asignar porcentaje a colaboraciones ACCEPTED
- ✅ El porcentaje debe estar entre 0 y 100
- ✅ La suma total de porcentajes no puede exceder 100%

---

## 🎯 Endpoints Completos

### Endpoints de GA01-154

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/collaborators/invite?inviterId={id}` | Invitar colaborador |
| PUT | `/api/collaborators/{id}/accept?artistId={id}` | Aceptar invitación |
| PUT | `/api/collaborators/{id}/reject?artistId={id}` | Rechazar invitación |
| GET | `/api/collaborators/pending/{artistId}` | Invitaciones pendientes |
| GET | `/api/collaborators/album/{albumId}` | Colaboradores de álbum |
| GET | `/api/collaborators/song/{songId}/accepted` | Colaboradores aceptados de canción |
| GET | `/api/collaborators/album/{albumId}/accepted` | Colaboradores aceptados de álbum |
| GET | `/api/collaborators/inviter/{inviterId}` | Colaboraciones creadas por usuario |
| DELETE | `/api/collaborators/album/{albumId}` | Eliminar colaboradores de álbum |

### Endpoints de GA01-155

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| PUT | `/api/collaborators/{id}/revenue?userId={id}` | Actualizar porcentaje |
| GET | `/api/collaborators/song/{songId}/revenue-total` | Total de porcentajes de canción |
| GET | `/api/collaborators/album/{albumId}/revenue-total` | Total de porcentajes de álbum |

---

## ✅ Verificación Final

Antes de dar por completada cada subtarea, verificar:

**GA01-154**:
- [ ] Todos los archivos backend creados/modificados
- [ ] Todos los archivos frontend creados/modificados
- [ ] Migración de base de datos ejecutada
- [ ] Tests de todos los flujos pasando
- [ ] Documentación actualizada
- [ ] Código revisado y sin warnings

**GA01-155**:
- [ ] Campo revenue_percentage añadido al modelo
- [ ] Métodos de asignación y validación funcionando
- [ ] UI para asignar porcentajes implementada
- [ ] Validación de 100% máximo funcionando
- [ ] Tests de validaciones pasando
- [ ] Integración con GA01-154 funcionando correctamente

---

¡Guía completa! Seguir el orden indicado garantiza una implementación limpia y sin conflictos entre subtareas.
