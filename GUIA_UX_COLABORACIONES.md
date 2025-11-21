# Guía de UX: Sistema de Colaboraciones

Esta guía documenta la experiencia de usuario (UX) y las pantallas creadas para el sistema completo de colaboraciones en Audira.

## Tabla de Contenidos
- [Descripción General](#descripción-general)
- [Flujo de Usuario](#flujo-de-usuario)
- [Pantallas y Componentes](#pantallas-y-componentes)
- [Archivos Creados](#archivos-creados)
- [Pasos de Migración](#pasos-de-migración)

---

## Descripción General

El sistema de colaboraciones permite a los artistas:
- **GA01-154**: Invitar colaboradores a canciones o álbumes
- **GA01-154**: Aceptar o rechazar invitaciones de colaboración
- **GA01-155**: Definir y gestionar porcentajes de ganancias para colaboradores

### Características Principales

✅ **Gestión de Colaboradores**
- Invitar artistas a canciones individuales o álbumes completos
- Especificar el rol del colaborador (productor, compositor, etc.)
- Ver todas las colaboraciones (donde participo y donde invité a otros)

✅ **Sistema de Invitaciones**
- Notificación visual de invitaciones pendientes
- Pantalla dedicada para ver y responder invitaciones
- Aceptar o rechazar con confirmación

✅ **Distribución de Ganancias**
- Establecer porcentaje de ganancias (0-100%)
- Validación de que el total no exceda 100%
- Ver distribución actual y porcentaje disponible
- Selección rápida con porcentajes predefinidos

---

## Flujo de Usuario

### 1. Acceso desde Studio Dashboard

El artista accede al sistema de colaboraciones desde el Studio Dashboard:

```
Studio Dashboard → Botón "Collaborations" → Pantalla de Colaboraciones
```

**Ubicación**: `/studio/collaborations`

### 2. Pantalla Principal de Colaboraciones

La pantalla principal tiene dos pestañas:

#### Pestaña "Mis Colaboraciones"
- Muestra las colaboraciones donde el usuario es el colaborador invitado
- Display: Tipo de contenido (canción/álbum), rol, porcentaje de ganancias
- Información de solo lectura (el colaborador no puede editar)

#### Pestaña "Colaboradores Invitados"
- Muestra las colaboraciones donde el usuario invitó a otros
- Acciones disponibles:
  - **Establecer Ganancias**: Botón para definir/editar porcentaje
  - **Eliminar**: Botón para eliminar la colaboración

### 3. Flujo: Invitar Colaborador

```
1. Botón FAB "Invitar Colaborador"
   ↓
2. Diálogo de Invitación
   ├── Seleccionar tipo: Canción o Álbum
   ├── Seleccionar canción/álbum del dropdown
   ├── Ingresar ID del artista
   └── Especificar rol (con sugerencias rápidas)
   ↓
3. Confirmación → Invitación enviada
```

**Roles Sugeridos**:
- Artista destacado
- Productor
- Compositor
- Vocalista
- Instrumentista
- Mezclador
- Masterizador

### 4. Flujo: Gestionar Invitaciones Pendientes

```
1. Badge de notificación en app bar (número rojo)
   ↓
2. Tap en icono de correo → Pantalla de Invitaciones
   ↓
3. Ver detalles de cada invitación:
   ├── Tipo de contenido y ID
   ├── Rol asignado
   ├── Porcentaje de ganancias (si aplica)
   ├── Quién invitó
   └── Fecha de invitación
   ↓
4. Decisión:
   ├── Botón "Aceptar" → Colaboración activa
   └── Botón "Rechazar" → Confirmación → Invitación rechazada
```

### 5. Flujo: Establecer Porcentaje de Ganancias

```
1. Tap en "Ganancias" en una colaboración
   ↓
2. Diálogo de Configuración de Ganancias
   ├── Ver información de la colaboración
   ├── Ver distribución actual del total
   ├── Ver porcentaje disponible
   ├── Ingresar porcentaje (0-100%)
   └── Selección rápida: 10%, 20%, 25%, 33.3%, 50%
   ↓
3. Validación:
   ├── ❌ Si excede 100% total → Error
   └── ✅ Si es válido → Guardar
   ↓
4. Confirmación → Porcentaje actualizado
```

**Validaciones**:
- Porcentaje debe estar entre 0 y 100
- El total de todas las colaboraciones no puede exceder 100%
- Muestra el porcentaje disponible en tiempo real

---

## Pantallas y Componentes

### 1. CollaborationsScreen
**Archivo**: `collaborations_screen.dart`
**Ruta**: `/studio/collaborations`

**Características**:
- TabBar con 2 pestañas (Mis Colaboraciones / Colaboradores Invitados)
- Badge de notificación para invitaciones pendientes
- Pull-to-refresh en ambas listas
- FAB para invitar colaboradores
- Cards expandibles con detalles de cada colaboración

**Estados vacíos**:
- "No tienes colaboraciones" → Mensaje informativo
- "No has invitado colaboradores" → Mensaje + botón de acción

### 2. CollaborationInvitationsScreen
**Archivo**: `collaboration_invitations_screen.dart`
**Ruta**: Navegación desde CollaborationsScreen

**Características**:
- Lista de invitaciones pendientes
- Cards con información detallada:
  - Tipo de contenido con icono distintivo
  - Badge "Pendiente" naranja
  - Detalles del rol, invitador, fecha
  - Porcentaje de ganancias si está definido
- Botones de acción:
  - "Rechazar" (rojo, con confirmación)
  - "Aceptar" (verde, principal)
- Pull-to-refresh
- Estado vacío con mensaje personalizado

### 3. AddCollaboratorDialog
**Archivo**: `add_collaborator_dialog.dart`
**Widget**: Dialog modal

**Características**:
- Selector de tipo (Canción/Álbum) con SegmentedButton
- Dropdown dinámico según tipo seleccionado
- Campo de ID de artista (solo números)
- Campo de rol con validación
- Chips de selección rápida para roles comunes
- Validación completa del formulario
- Loading state durante la invitación

**Validaciones**:
- Tipo de contenido seleccionado
- Canción o álbum debe estar seleccionado
- ID de artista debe ser numérico y válido
- Rol debe tener mínimo 2 caracteres

### 4. RevenueSettingsDialog
**Archivo**: `revenue_settings_dialog.dart`
**Widget**: Dialog modal

**Características**:
- Información de la colaboración en tarjeta destacada
- Distribución actual con visual distintivo:
  - Total asignado (color naranja)
  - Disponible (verde si hay, rojo si no)
- Campo de porcentaje con:
  - Validación 0-100
  - Formato decimal (2 decimales)
  - Helper text con máximo disponible
- Chips de selección rápida (10%, 20%, 25%, 33.3%, 50%)
  - Deshabilitados si exceden el disponible
- Loading state durante guardado

**Validaciones en tiempo real**:
- Porcentaje entre 0 y 100
- No exceder el porcentaje disponible
- Formato numérico válido

### 5. CollaborationService
**Archivo**: `collaboration_service.dart`

**Métodos API**:
```dart
// Obtener datos
getArtistCollaborations(int artistId)
getPendingInvitations(int artistId)
getSongCollaborations(int songId)
getAlbumCollaborations(int albumId)

// Invitar
inviteCollaboratorToSong({songId, artistId, role})
inviteCollaboratorToAlbum({albumId, artistId, role})

// Responder invitaciones
acceptInvitation(int collaborationId)
rejectInvitation(int collaborationId)

// Ganancias
updateRevenuePercentage({collaborationId, percentage})
getSongTotalRevenue(int songId)
getAlbumTotalRevenue(int albumId)

// Eliminar
deleteCollaboration(int collaborationId)
```

---

## Archivos Creados
 
### Servicio
```
audira_frontend/lib/core/api/services/
└── collaboration_service.dart                 # Servicio de API
```

### Pantallas
```
audira_frontend/lib/features/collaborations/screens/
├── collaborations_screen.dart                 # Pantalla principal
└── collaboration_invitations_screen.dart      # Invitaciones pendientes
```

### Widgets/Diálogos
```
audira_frontend/lib/features/collaborations/widgets/
├── add_collaborator_dialog.dart               # Invitar colaborador
└── revenue_settings_dialog.dart               # Establecer porcentaje
```

### Archivos Modificados
```
audira_frontend/lib/config/
└── routes.dart                                 # Nueva ruta agregada

audira_frontend/lib/features/studio/screens/
└── studio_dashboard_screen.dart               # Tarjeta de colaboraciones
```

---

## Pasos de Migración

### 1. Copiar archivos nuevos

```bash
# Servicio
cp collaboration_service.dart [TU_REPO]/audira_frontend/lib/core/api/services/

# Pantallas
mkdir -p [TU_REPO]/audira_frontend/lib/features/collaborations/screens
cp collaborations_screen.dart [TU_REPO]/audira_frontend/lib/features/collaborations/screens/
cp collaboration_invitations_screen.dart [TU_REPO]/audira_frontend/lib/features/collaborations/screens/

# Widgets
mkdir -p [TU_REPO]/audira_frontend/lib/features/collaborations/widgets
cp add_collaborator_dialog.dart [TU_REPO]/audira_frontend/lib/features/collaborations/widgets/
cp revenue_settings_dialog.dart [TU_REPO]/audira_frontend/lib/features/collaborations/widgets/
```

### 2. Actualizar routes.dart

Agregar el import:
```dart
import '../features/collaborations/screens/collaborations_screen.dart';
```

Agregar la constante de ruta:
```dart
static const String studioCollaborations = '/studio/collaborations';
```

Agregar el caso en generateRoute:
```dart
case studioCollaborations:
  return MaterialPageRoute(builder: (_) => const CollaborationsScreen());
```

### 3. Actualizar studio_dashboard_screen.dart

Agregar la tarjeta de colaboraciones:
```dart
_buildStudioCard(
  context,
  icon: Icons.people,
  title: 'Collaborations',
  subtitle: 'Manage collaborators and revenue sharing',
  color: Colors.pink,
  route: '/studio/collaborations',
).animate(delay: 500.ms).fadeIn().slideX(begin: -0.2),
```

### 4. Verificar backend

Asegúrate de que los endpoints del backend estén funcionando:

```bash
# Verificar que el CollaboratorController esté accesible
curl http://localhost:8080/api/collaborations/artist/1

# Verificar invitaciones pendientes
curl http://localhost:8080/api/collaborations/artist/1/pending
```

### 5. Compilar y ejecutar

```bash
cd audira_frontend
flutter pub get
flutter run
```

---

## Flujo Visual Completo

```
┌─────────────────────────────────────────┐
│     Studio Dashboard                    │
│  ┌────────────────────────────────┐    │
│  │  👥 Collaborations              │    │
│  │  Manage collaborators and      │    │
│  │  revenue sharing               │    │
│  └────────────────────────────────┘    │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│  Collaborations Screen                  │
│  ┌─────────┬──────────────────┐  [📧3] │
│  │ Mis     │  Colaboradores   │         │
│  │ Colabs  │  Invitados       │         │
│  └─────────┴──────────────────┘         │
│                                          │
│  [Expandir para ver detalles]          │
│  ┌────────────────────────────┐        │
│  │ 🎵 Canción ID: 123         │        │
│  │ Rol: Productor    │ 15.0%  │        │
│  │ ├─ Artista ID: 456         │        │
│  │ ├─ Creado: 20/11/2025      │        │
│  │ └─ [💰 Ganancias] [❌ Eliminar]  │
│  └────────────────────────────┘        │
│                                          │
│  [+] FAB: Invitar Colaborador          │
└─────────────────────────────────────────┘
         │                    │
         │                    │
    Tap [📧]            Tap [+]
         │                    │
         ▼                    ▼
┌──────────────────┐  ┌──────────────────┐
│  Invitaciones    │  │  Invitar         │
│  Pendientes      │  │  Colaborador     │
│                  │  │                  │
│  ┌─────────────┐ │  │  ○ Canción      │
│  │ 🎵 Canción  │ │  │  ○ Álbum        │
│  │ Rol: Vocal  │ │  │                  │
│  │ Por: User 5 │ │  │  Seleccionar:   │
│  │             │ │  │  [Dropdown ▼]   │
│  │ [Rechazar]  │ │  │                  │
│  │ [Aceptar ✓] │ │  │  ID Artista:    │
│  └─────────────┘ │  │  [________]     │
└──────────────────┘  │                  │
                      │  Rol:            │
                      │  [________]     │
                      │                  │
                      │  [Cancelar]     │
                      │  [Invitar]      │
                      └──────────────────┘

    Tap [💰 Ganancias]
         │
         ▼
┌──────────────────────────────┐
│  Porcentaje de Ganancias     │
│                              │
│  ┌─────────────────────┐    │
│  │ 🎵 Canción ID: 123  │    │
│  │ Artista: 456        │    │
│  │ Rol: Productor      │    │
│  └─────────────────────┘    │
│                              │
│  📊 Distribución actual      │
│  Total asignado: 35.0%       │
│  Disponible: 65.0%           │
│                              │
│  Porcentaje (%):             │
│  [_________] %               │
│                              │
│  Selección rápida:           │
│  [10%] [20%] [25%] [33%] [50%]│
│                              │
│  [Cancelar] [Guardar]        │
└──────────────────────────────┘
```

---

## Estados y Validaciones

### Estados de Colaboración

| Estado | Descripción | Color | Acciones |
|--------|-------------|-------|----------|
| **PENDING** | Invitación enviada, esperando respuesta | 🟠 Naranja | Aceptar/Rechazar |
| **ACCEPTED** | Colaboración activa | 🟢 Verde | Ver/Editar ganancias |
| **REJECTED** | Invitación rechazada | 🔴 Rojo | N/A |

### Reglas de Negocio

1. **Porcentaje de Ganancias**:
   - Mínimo: 0%
   - Máximo: 100%
   - Total de todos los colaboradores en una canción/álbum: ≤ 100%

2. **Invitaciones**:
   - Solo el dueño de la canción/álbum puede invitar
   - Un artista no puede ser invitado dos veces a la misma canción/álbum

3. **Permisos**:
   - Solo el invitador puede establecer porcentajes
   - Solo el invitador puede eliminar colaboraciones
   - El colaborador solo puede aceptar/rechazar

---

## Mensajes de Error y Feedback

### Errores Comunes

| Situación | Mensaje | Tipo |
|-----------|---------|------|
| Invitación exitosa | "Colaborador invitado exitosamente" | ✅ Success |
| Error al invitar | "Error: [detalles]" | ❌ Error |
| Invitación aceptada | "Invitación aceptada exitosamente" | ✅ Success |
| Invitación rechazada | "Invitación rechazada" | 🟠 Warning |
| Ganancias actualizadas | "Porcentaje de ganancias actualizado" | ✅ Success |
| Excede 100% | "Excede el porcentaje disponible (X%)" | ❌ Error |
| Colaboración eliminada | "Colaboración eliminada exitosamente" | ✅ Success |

---

## Mejoras Futuras Sugeridas

### Fase 2
- [ ] Buscar artistas por nombre (no solo ID)
- [ ] Previsualizar perfil del artista antes de invitar
- [ ] Enviar notificaciones push para invitaciones

### Fase 3
- [ ] Chat entre colaboradores
- [ ] Historial de cambios de porcentajes
- [ ] Exportar reporte de colaboraciones

### Fase 4
- [ ] Contratos digitales
- [ ] Firma electrónica
- [ ] Pagos automáticos según porcentajes

---

## Soporte y Preguntas Frecuentes

### ¿Cómo invito a un colaborador si no sé su ID?
Actualmente necesitas conocer el ID del artista. En futuras versiones se añadirá búsqueda por nombre.

### ¿Puedo cambiar el porcentaje después de aceptar?
Sí, el dueño de la canción/álbum puede modificar los porcentajes en cualquier momento.

### ¿Qué pasa si rechazo una invitación?
La invitación se marca como rechazada y ya no aparecerá en tu lista de pendientes. No se puede revertir.

### ¿Puedo eliminar una colaboración activa?
Sí, el dueño puede eliminar colaboraciones en cualquier momento desde la pantalla de colaboraciones.

---

## Conclusión

El sistema de colaboraciones ofrece una experiencia completa y moderna para:
- ✅ Gestionar colaboraciones en canciones y álbumes
- ✅ Responder a invitaciones de forma intuitiva
- ✅ Configurar distribución de ganancias con validación
- ✅ Ver el estado de todas las colaboraciones en un solo lugar

La interfaz es clara, con validaciones robustas y feedback inmediato en cada acción.
