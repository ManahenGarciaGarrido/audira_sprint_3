# Análisis Exacto del Flujo de Actualización de Perfil

## Estructura de Herencia (JOINED Strategy)

```
users (tabla padre)
├── id (PRIMARY KEY, SERIAL)
├── email, username, firstName, lastName
├── updated_at
└── user_type (discriminator)

artists (tabla hija)
├── id (PRIMARY KEY, FK → users.id)  ← NO ES SERIAL!
├── artist_name
├── artist_bio
└── record_label

user_followers (ElementCollection)
└── user_id, follower_id

user_following (ElementCollection)
└── user_id, following_id
```

## Flujo EXACTO con entityManager.refresh()

### 1. findById(1)
```sql
-- Query 1: Carga Join de users + artists
SELECT u.*, a.* FROM users u
LEFT JOIN artists a ON u.id = a.id
WHERE u.id = 1

-- Query 2 y 3: ElementCollection EAGER
SELECT follower_id FROM user_followers WHERE user_id = 1
SELECT following_id FROM user_following WHERE user_id = 1
```
**Estado Hibernate:** Artist#1 MANAGED con snapshot del estado original

### 2. entityManager.refresh(user)
```sql
-- REPITE las mismas 3 queries del paso 1
```
**Estado Hibernate:** REEMPLAZA el snapshot, pero mantiene la misma instancia

### 3. Modificación de campos
```java
artist.setArtistName("nuevo nombre")
user.setTwitterUrl("https://twitter.com/artista")
```
**Estado Hibernate:** Marca campos como dirty

### 4. userRepository.save(user)
**No hace nada** (entidad ya está MANAGED)

### 5. Transaction commit → flush()
```sql
-- Hibernate ejecuta UPDATE con @PreUpdate
UPDATE users
SET updated_at = NOW(), twitter_url = '...'
WHERE id = 1
-- ✅ Retorna 1 fila afectada

UPDATE artists
SET artist_name = 'nuevo nombre', artist_bio = '...'
WHERE id = 1
-- ❌ Retorna 0 filas afectadas ← AQUÍ FALLA
```

## ¿POR QUÉ el UPDATE artists retorna 0 filas?

### Posibilidad #1: Problema con @ElementCollection EAGER + refresh()
El refresh() de colecciones EAGER puede causar que Hibernate pierda el tracking correcto de la entidad padre.

### Posibilidad #2: Problema con JOINED + Lombok + refresh()
`@EqualsAndHashCode(callSuper = true)` + refresh() puede causar que Hibernate detecte el objeto como "cambiado" cuando realmente no lo está.

### Posibilidad #3: Doble transacción concurrente (EL MÁS PROBABLE)
Si el frontend envía 2 requests simultáneos:
- Request A: findById() → refresh() → modifica → save()
- Request B: findById() → refresh() → modifica → save()

Uno de los dos fallará con optimistic locking.

### Posibilidad #4: @PreUpdate modifica el parent pero no las child tables
El `@PreUpdate` solo afecta la tabla `users`, no `artists`. Si Hibernate usa `updated_at` para detectar conflictos...
