# Análisis del Problema Real de Optimistic Locking

## El Error Original
```
org.hibernate.StaleObjectStateException: Row was updated or deleted by another transaction
(or unsaved-value mapping was incorrect) : [io.audira.community.model.Artist#1]
```

## Configuración Actual

### User.java (clase abstracta padre)
- `@Inheritance(strategy = InheritanceType.JOINED)` ✅
- `@DiscriminatorColumn(name = "user_type")` ✅
- `@PreUpdate` que modifica `updatedAt` automáticamente
- **NO tiene @Version** ❌

### Artist.java (subclase)
- Extiende User
- `@DiscriminatorValue("ARTIST")` ✅
- Datos propios: artistName, artistBio, recordLabel

### Estructura de BD
```
users (tabla padre)
├── id (SERIAL PRIMARY KEY)
├── email, username, etc.
├── updated_at
└── user_type (discriminator)

artists (tabla hija)
├── id (PRIMARY KEY, FK → users.id)  ← NO ES SERIAL
├── artist_name
├── artist_bio
└── record_label
```

## El Problema REAL

### Sin @Version:
Hibernate **NO puede hacer optimistic locking verdadero**.

Lo único que hace es:
1. Ejecutar UPDATE
2. Verificar cuántas filas afectó
3. Si afecta 0 filas → StaleObjectStateException

### Con JOINED Inheritance:
Cuando actualizas un Artist, Hibernate ejecuta **DOS UPDATEs separados**:
```sql
UPDATE users
SET updated_at = NOW(), twitter_url = ?, ...
WHERE id = 1;  -- Esperado: 1 fila

UPDATE artists
SET artist_name = ?, artist_bio = ?, record_label = ?
WHERE id = 1;  -- Esperado: 1 fila
```

Si **CUALQUIERA** de estos retorna 0 filas, Hibernate lanza el error.

## ¿Por Qué el UPDATE de artists Retorna 0 Filas?

### Posibilidad 1: No existe la fila (Poco probable)
- Si el Artist no existiera, el findById() habría fallado antes

### Posibilidad 2: Problema con entityManager.refresh()
El `entityManager.refresh()` con JOINED + @ElementCollection EAGER causa:
1. Recarga entidad completa (4 SELECTs)
2. Descarta snapshot anterior
3. Crea nuevo snapshot
4. **Corrupción del estado interno** debido a la complejidad de:
   - JOINED inheritance (2 tablas)
   - @ElementCollection EAGER (2 tablas collection)
   - @PreUpdate (modificación automática)

Cuando Hibernate genera el UPDATE después del refresh(), el snapshot corrupto causa que el WHERE clause no coincida correctamente.

### Posibilidad 3: Requests concurrentes (MUY PROBABLE)
Si el frontend envía 2 requests simultáneos (doble clic):
- Request A: findById() → modifica → flush() ✅
- Request B: findById() → modifica → flush() ❌ (la fila ya cambió)

Sin @Version, Hibernate no puede detectar ni manejar esto correctamente.

## Conclusión

El problema tiene DOS causas combinadas:

1. **Falta de @Version**: Sin este campo, Hibernate no puede hacer optimistic locking real ni detectar conflictos de concurrencia.

2. **entityManager.refresh() empeora el problema**: En lugar de ayudar, corrompe el snapshot interno de Hibernate cuando se combina con JOINED inheritance + @ElementCollection EAGER.

## La Solución Correcta

Necesitas hacer AMBAS cosas:

1. **Agregar @Version a User.java**
   ```java
   @Version
   private Long version;
   ```

2. **Eliminar entityManager.refresh()** de UserService.java

Esto permitirá que Hibernate:
- Detecte correctamente conflictos de concurrencia
- Genere UPDATEs con WHERE version = ?
- Lance excepciones claras cuando hay conflictos REALES
- No corrompa el snapshot interno
