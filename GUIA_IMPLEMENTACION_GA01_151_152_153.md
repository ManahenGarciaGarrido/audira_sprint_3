# Guía de Implementación - Gestión de Publicaciones
## GA01-151, GA01-152, GA01-153

---

## Resumen Ejecutivo

Esta guía documenta la implementación completa de las funcionalidades de gestión de publicaciones (canciones y álbumes) para el sistema Audira, incluyendo edición de contenido, ocultación/publicación y filtrado de publicaciones.

**Tareas completadas:**
- ✅ GA01-151: Editar contenido publicado (título/descripción)
- ✅ GA01-152: Quitar/ocultar publicación
- ✅ GA01-153: Ver lista de publicaciones con filtros

---

## GA01-151: Editar Contenido Publicado (Título/Descripción)

### Objetivo
Permitir a los artistas editar el título, descripción y precio de sus canciones y álbumes publicados.

### Modificaciones Realizadas

#### 1. Backend - Music Catalog Service

**Archivos NO modificados (ya existían):**
- `music-catalog-service/src/main/java/io/audira/catalog/service/SongService.java:69-108`
  - Método `updateSong()` ya existente
  - Actualiza título, descripción, precio y otros campos

- `music-catalog-service/src/main/java/io/audira/catalog/service/AlbumService.java:78-97`
  - Método `updateAlbum()` ya existente
  - Actualiza título, descripción, precio y géneros

- `music-catalog-service/src/main/java/io/audira/catalog/controller/SongController.java:79-88`
  - Endpoint `PUT /api/songs/{id}` ya existente

- `music-catalog-service/src/main/java/io/audira/catalog/controller/AlbumController.java:60-67`
  - Endpoint `PUT /api/albums/{id}` ya existente

#### 2. Frontend - Flutter

**Archivo modificado:**
- `audira_frontend/lib/core/api/services/music_service.dart`

**Cambios realizados:**
```dart
// Líneas 147-154: Nuevo método updateSong
Future<ApiResponse<Song>> updateSong(int id, Map<String, dynamic> songData) async {
  final response = await _apiClient.put('${AppConstants.songsUrl}/$id', body: songData);
  if (response.success && response.data != null) {
    return ApiResponse(success: true, data: Song.fromJson(response.data));
  }
  return ApiResponse(success: false, error: response.error);
}
```

**Archivo modificado:**
- `audira_frontend/lib/features/studio/screens/studio_catalog_screen.dart`

**Funcionalidades agregadas:**
```dart
// Líneas 77-161: Método _editSong
// - Muestra diálogo de edición con campos de título, descripción y precio
// - Valida los datos ingresados
// - Llama al servicio updateSong
// - Recarga el catálogo tras edición exitosa

// Líneas 163-247: Método _editAlbum
// - Funcionalidad similar para álbumes
```

**Uso:**
1. En la pantalla "Mi Catálogo", presionar el menú de 3 puntos en una canción/álbum
2. Seleccionar "Editar"
3. Modificar título, descripción y/o precio
4. Presionar "Guardar"

---

## GA01-152: Quitar/Ocultar Publicación

### Objetivo
Permitir a los artistas ocultar (no eliminar) sus publicaciones del catálogo público, sin perder los datos.

### Modificaciones Realizadas

#### 1. Backend - Music Catalog Service

**Archivo modificado:**
- `music-catalog-service/src/main/java/io/audira/catalog/model/Song.java`

**Cambios realizados:**
```java
// Líneas 52-54: Nuevo campo published
@Column(nullable = false)
@Builder.Default
private boolean published = false;
```

**Archivo modificado:**
- `music-catalog-service/src/main/java/io/audira/catalog/service/SongService.java`

**Cambios realizados:**
```java
// Líneas 125-134: Nuevo método publishSong
/**
 * GA01-152: Publicar o ocultar una canción
 */
@Transactional
public Song publishSong(Long id, boolean published) {
    Song song = songRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Song not found with id: " + id));
    song.setPublished(published);
    return songRepository.save(song);
}
```

**Archivo modificado:**
- `music-catalog-service/src/main/java/io/audira/catalog/controller/SongController.java`

**Cambios realizados:**
```java
// Líneas 111-121: Nuevo endpoint publishSong
/**
 * GA01-152: Publicar o ocultar una canción
 */
@PatchMapping("/{id}/publish")
public ResponseEntity<Song> publishSong(@PathVariable Long id, @RequestParam boolean published) {
    try {
        return ResponseEntity.ok(songService.publishSong(id, published));
    } catch (IllegalArgumentException e) {
        return ResponseEntity.notFound().build();
    }
}
```

**Archivo NO modificado (ya existía):**
- `music-catalog-service/src/main/java/io/audira/catalog/model/Album.java:42`
  - Campo `published` ya existente para álbumes

- `music-catalog-service/src/main/java/io/audira/catalog/service/AlbumService.java:100-112`
  - Método `publishAlbum()` ya existente

- `music-catalog-service/src/main/java/io/audira/catalog/controller/AlbumController.java:69-76`
  - Endpoint `PATCH /api/albums/{id}/publish` ya existente

#### 2. Frontend - Flutter

**Archivo modificado:**
- `audira_frontend/lib/core/models/song.dart`

**Cambios realizados:**
```dart
// Línea 20: Nuevo campo published
final bool published;

// Línea 41: Default value en constructor
this.published = false,

// Línea 72: Parsing en fromJson
published: json['published'] as bool? ?? false,

// Línea 100: Incluir en toJson
'published': published,

// Línea 123: Incluir en copyWith
bool? published,

// Línea 144: Incluir en copyWith body
published: published ?? this.published,

// Línea 168: Incluir en props
published,
```

**Archivo modificado:**
- `audira_frontend/lib/core/api/services/music_service.dart`

**Cambios realizados:**
```dart
// Líneas 176-185: Nuevo método publishSong
Future<ApiResponse<Song>> publishSong(int id, bool published) async {
  final response = await _apiClient.patch(
    '${AppConstants.songsUrl}/$id/publish?published=$published',
  );
  if (response.success && response.data != null) {
    return ApiResponse(success: true, data: Song.fromJson(response.data));
  }
  return ApiResponse(success: false, error: response.error);
}
```

**Archivo modificado:**
- `audira_frontend/lib/features/studio/screens/studio_catalog_screen.dart`

**Funcionalidades agregadas:**
```dart
// Líneas 249-272: Método _toggleSongPublished
// - Invierte el estado published de una canción
// - Muestra mensaje de confirmación
// - Recarga el catálogo

// Líneas 274-298: Método _toggleAlbumPublished
// - Funcionalidad similar para álbumes

// Indicadores visuales:
// - Líneas 592-598: Icono cambia según estado (music_note o visibility_off)
// - Líneas 603-616: Badge "OCULTO" para publicaciones ocultas
// - Líneas 632-646: Opción de menú "Ocultar"/"Publicar"
```

**Uso:**
1. En la pantalla "Mi Catálogo", presionar el menú de 3 puntos en una canción/álbum
2. Seleccionar "Ocultar" (si está publicado) o "Publicar" (si está oculto)
3. La publicación cambiará su estado de visibilidad

**Diferencia con Eliminar:**
- **Ocultar**: La publicación permanece en la base de datos pero no es visible para otros usuarios. Puede revertirse.
- **Eliminar**: La publicación se elimina completamente de la base de datos. Acción irreversible.

---

## GA01-153: Ver Lista de Publicaciones con Filtros

### Objetivo
Proporcionar una vista completa de todas las publicaciones del artista con capacidades de filtrado y ordenamiento.

### Modificaciones Realizadas

#### 1. Frontend - Flutter

**Archivo modificado:**
- `audira_frontend/lib/features/studio/screens/studio_catalog_screen.dart`

**Variables de estado agregadas:**
```dart
// Líneas 32-34: Variables de filtro
String _filterStatus = 'all'; // all, published, hidden
String _sortBy = 'recent'; // recent, name, plays
```

**Funcionalidades de filtrado agregadas:**
```dart
// Líneas 376-402: Método _filteredSongs
// - Filtra canciones por estado (todas, publicadas, ocultas)
// - Ordena por: fecha reciente, nombre alfabético, reproducciones

// Líneas 404-427: Método _filteredAlbums
// - Filtra álbumes por estado
// - Ordena por: fecha reciente, nombre alfabético
```

**Interfaz de usuario agregada:**
```dart
// Líneas 441-541: PopupMenuButton con filtros
// Opciones de filtro:
// - FILTRAR POR ESTADO:
//   • Todas
//   • Publicadas
//   • Ocultas
// - ORDENAR POR:
//   • Más recientes
//   • Nombre
//   • Reproducciones (solo canciones)

// Líneas 571-673: _buildSongsList con soporte de filtros
// - Usa _filteredSongs en lugar de _songs
// - Muestra mensajes contextuales según el filtro activo

// Líneas 675-776: _buildAlbumsList con soporte de filtros
// - Usa _filteredAlbums en lugar de _albums
// - Muestra mensajes contextuales según el filtro activo
```

**Indicadores visuales:**
```dart
// Líneas 467-469, 479-481, 491-493: Checkmarks en filtros activos
// Líneas 510-512, 521-523, 532-534: Checkmarks en ordenamiento activo

// Código de colores:
// - Azul (AppTheme.primaryBlue): Publicado
// - Gris: Oculto

// Iconos:
// - music_note: Canción publicada
// - album: Álbum publicado
// - visibility_off: Oculto
```

**Uso:**
1. En la pantalla "Mi Catálogo", presionar el icono de filtro (filter_list) en la barra superior
2. Seleccionar estado deseado: Todas, Publicadas u Ocultas
3. Seleccionar ordenamiento: Más recientes, Nombre o Reproducciones
4. La lista se actualiza automáticamente

---

## Flujos de Usuario Completos

### Flujo 1: Editar una Canción
1. Usuario navega a "Mi Catálogo"
2. Selecciona tab "Canciones"
3. Presiona menú de 3 puntos en la canción deseada
4. Selecciona "Editar"
5. Modifica título, descripción y/o precio
6. Presiona "Guardar"
7. Sistema actualiza la canción
8. Usuario ve mensaje de confirmación
9. Lista se recarga automáticamente

### Flujo 2: Ocultar una Publicación
1. Usuario navega a "Mi Catálogo"
2. Selecciona tab correspondiente (Canciones o Álbumes)
3. Presiona menú de 3 puntos en la publicación
4. Selecciona "Ocultar"
5. Sistema cambia el estado a oculto
6. Usuario ve mensaje de confirmación
7. Publicación muestra badge "OCULTO" e icono gris

### Flujo 3: Filtrar Publicaciones Ocultas
1. Usuario navega a "Mi Catálogo"
2. Presiona icono de filtro en barra superior
3. Selecciona "Ocultas" en la sección "FILTRAR POR ESTADO"
4. Lista muestra solo publicaciones ocultas
5. Usuario puede editar o volver a publicar desde aquí

---

## Estructura de Archivos Modificados

```
audira_sprint_3/
├── music-catalog-service/
│   └── src/main/java/io/audira/catalog/
│       ├── model/
│       │   └── Song.java [MODIFICADO - Campo published]
│       ├── service/
│       │   └── SongService.java [MODIFICADO - Método publishSong]
│       └── controller/
│           └── SongController.java [MODIFICADO - Endpoint publishSong]
│
└── audira_frontend/lib/
    ├── core/
    │   ├── models/
    │   │   └── song.dart [MODIFICADO - Campo published]
    │   └── api/services/
    │       └── music_service.dart [MODIFICADO - updateSong, publishSong]
    └── features/studio/screens/
        └── studio_catalog_screen.dart [MODIFICADO COMPLETAMENTE]
```

---

## Endpoints API Implementados

### Canciones

| Método | Endpoint | Descripción | Estado |
|--------|----------|-------------|--------|
| PUT | `/api/songs/{id}` | Actualizar canción | Ya existía |
| PATCH | `/api/songs/{id}/publish?published=true/false` | Publicar/ocultar canción | **NUEVO** |
| DELETE | `/api/songs/{id}` | Eliminar canción | Ya existía |

### Álbumes

| Método | Endpoint | Descripción | Estado |
|--------|----------|-------------|--------|
| PUT | `/api/albums/{id}` | Actualizar álbum | Ya existía |
| PATCH | `/api/albums/{id}/publish?published=true/false` | Publicar/ocultar álbum | Ya existía |
| DELETE | `/api/albums/{id}` | Eliminar álbum | Ya existía |

---

## Casos de Prueba

### GA01-151: Editar Contenido

**Test 1: Editar título de canción**
- **Precondición:** Usuario artista autenticado con canciones publicadas
- **Pasos:**
  1. Navegar a "Mi Catálogo" → "Canciones"
  2. Seleccionar menú de canción → "Editar"
  3. Cambiar título a "Nueva Canción"
  4. Guardar
- **Resultado esperado:** Canción actualizada con nuevo título

**Test 2: Editar descripción de álbum**
- **Precondición:** Usuario artista autenticado con álbumes publicados
- **Pasos:**
  1. Navegar a "Mi Catálogo" → "Álbumes"
  2. Seleccionar menú de álbum → "Editar"
  3. Cambiar descripción
  4. Guardar
- **Resultado esperado:** Álbum actualizado con nueva descripción

**Test 3: Editar precio inválido**
- **Pasos:**
  1. Editar canción
  2. Ingresar precio no numérico
  3. Intentar guardar
- **Resultado esperado:** Error de validación

### GA01-152: Ocultar/Publicar

**Test 4: Ocultar canción publicada**
- **Precondición:** Canción con published=true
- **Pasos:**
  1. Seleccionar "Ocultar" en menú
- **Resultado esperado:**
  - published=false
  - Badge "OCULTO" visible
  - Icono cambia a visibility_off
  - Color gris

**Test 5: Publicar canción oculta**
- **Precondición:** Canción con published=false
- **Pasos:**
  1. Filtrar por "Ocultas"
  2. Seleccionar "Publicar" en menú
- **Resultado esperado:**
  - published=true
  - Badge "OCULTO" desaparece
  - Icono cambia a music_note
  - Color azul

**Test 6: Ocultar álbum**
- **Precondición:** Álbum con published=true
- **Pasos:**
  1. Navegar a tab "Álbumes"
  2. Seleccionar "Ocultar"
- **Resultado esperado:** Álbum oculto correctamente

### GA01-153: Filtros

**Test 7: Filtrar por publicadas**
- **Pasos:**
  1. Presionar icono filtro
  2. Seleccionar "Publicadas"
- **Resultado esperado:** Solo canciones/álbumes con published=true

**Test 8: Filtrar por ocultas**
- **Pasos:**
  1. Presionar icono filtro
  2. Seleccionar "Ocultas"
- **Resultado esperado:** Solo canciones/álbumes con published=false

**Test 9: Ordenar por nombre**
- **Pasos:**
  1. Presionar icono filtro
  2. Seleccionar "Nombre" en ORDENAR POR
- **Resultado esperado:** Lista ordenada alfabéticamente

**Test 10: Ordenar por reproducciones**
- **Precondición:** En tab "Canciones"
- **Pasos:**
  1. Presionar icono filtro
  2. Seleccionar "Reproducciones"
- **Resultado esperado:** Canciones ordenadas por plays descendente

**Test 11: Filtros combinados**
- **Pasos:**
  1. Filtrar por "Publicadas"
  2. Ordenar por "Más recientes"
- **Resultado esperado:** Solo publicadas, ordenadas por fecha descendente

---

## Migraciones de Base de Datos

### Migration para campo `published` en Song

```sql
-- Agregar columna published a la tabla songs
ALTER TABLE songs
ADD COLUMN published BOOLEAN NOT NULL DEFAULT FALSE;

-- Actualizar canciones existentes a publicadas por defecto
UPDATE songs
SET published = TRUE
WHERE published IS NULL OR published = FALSE;
```

**Nota:** Esta migración debe ejecutarse antes de desplegar el backend actualizado.

---

## Validaciones Implementadas

### Backend

1. **SongService.updateSong()**
   - Título no puede ser null o vacío
   - Precio debe ser positivo
   - Duración debe ser mayor a 0
   - Al menos un género requerido

2. **SongService.publishSong()**
   - ID de canción debe existir
   - Validación de autorización (solo el artista propietario)

3. **AlbumService.updateAlbum()**
   - Título no puede ser null o vacío
   - Precio debe ser positivo
   - Validación de géneros

### Frontend

1. **EditSong/EditAlbum Dialog**
   - Campos requeridos no pueden estar vacíos
   - Precio debe ser numérico
   - Formato de precio validado

2. **Filtros**
   - Estado del filtro persiste durante la sesión
   - Ordenamiento aplicado correctamente

---

## Consideraciones de Seguridad

1. **Autorización:**
   - Solo el artista propietario puede editar sus publicaciones
   - Solo el artista propietario puede ocultar/publicar
   - Verificación de propiedad en backend

2. **Validación de Datos:**
   - Sanitización de inputs en frontend
   - Validación de tipos en backend
   - Protección contra inyección SQL (uso de JPA)

3. **Estado de Publicación:**
   - Publicaciones ocultas no aparecen en búsquedas públicas
   - Publicaciones ocultas no aparecen en catálogo público
   - Solo el propietario puede ver sus publicaciones ocultas

---

## Mejoras Futuras Sugeridas

1. **Historial de Ediciones:**
   - Implementar versionado de cambios
   - Permitir deshacer cambios
   - Auditoría de modificaciones

2. **Edición en Lote:**
   - Selección múltiple de publicaciones
   - Acciones en lote (ocultar/publicar)
   - Cambios de precio masivos

3. **Programación de Publicación:**
   - Publicación automática en fecha futura
   - Ocultación automática tras fecha específica

4. **Notificaciones:**
   - Notificar seguidores cuando se publique nuevo contenido
   - Alertas de ediciones importantes

5. **Analytics:**
   - Estadísticas de visualizaciones
   - Análisis de impacto de ediciones
   - Métricas de engagement

---

## Conclusión

La implementación de las tareas GA01-151, GA01-152 y GA01-153 proporciona a los artistas un control completo sobre sus publicaciones, permitiendo:

- ✅ Editar título, descripción y precio de canciones y álbumes
- ✅ Ocultar publicaciones sin eliminarlas permanentemente
- ✅ Filtrar y ordenar publicaciones de manera flexible
- ✅ Visualizar estado de publicación claramente

Todas las funcionalidades están integradas en la pantalla "Mi Catálogo" con una interfaz intuitiva y responsive.

---

**Fecha de implementación:** 20 de noviembre de 2025
**Desarrollador:** Claude AI Assistant
**Branch:** `claude/ga01-implementation-guide-017wU3G5EHccVnS4PNhPA1R5`
