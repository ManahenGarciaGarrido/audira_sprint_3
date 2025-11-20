# EL FALLO EXACTO

## Ubicación del Error
`UserService.java:151` y `UserService.java:244`

## El Código Problemático
```java
// Refresh entity to get latest version from database (prevents optimistic locking errors)
entityManager.refresh(user);
```

## Por Qué Falla

### El Escenario Exacto:

Cuando actualizas el perfil de Artist#1, Hibernate debe hacer UPDATE en DOS tablas:
1. `UPDATE users SET ... WHERE id = 1`
2. `UPDATE artists SET ... WHERE id = 1`

Con JOINED inheritance, estas son operaciones SEPARADAS.

### La Secuencia del Fallo:

1. `findById(1)` → Carga Artist#1 (users + artists + user_followers + user_following)
   - Hibernate crea snapshot del estado

2. `refresh(user)` → ESTE ES EL PROBLEMA
   - Hibernate descarta el snapshot anterior
   - Recarga TODO de nuevo (incluidos los 4 elementos)
   - **Con @ElementCollection EAGER + JOINED, el refresh() causa:**
     - Hibernate ejecuta 4 SELECTs separados
     - Crea un NUEVO snapshot
     - PERO el nuevo snapshot de las tablas child (artists) queda DESINCRONIZADO
     - El persistence context piensa que hay cambios pendientes cuando NO los hay

3. Modificas campos (artistName, twitterUrl, etc.)

4. `save(user)` → No hace nada (ya está MANAGED)

5. **Transaction commit:**
   - Hibernate flush() compara estado actual vs snapshot   - Genera: `UPDATE users SET updated_at=NOW(), ... WHERE id=1` → ✅ OK (1 fila)
   - Genera: `UPDATE artists SET artist_name=?, ... WHERE id=1 AND ???` → ❌ FALLA (0 filas)
   
   **El WHERE incluye una condición implícita** que espera el estado del snapshot
   Como el snapshot está corrupto por el refresh(), la condición no se cumple
   
6. Hibernate ve que el UPDATE afectó 0 filas → Lanza StaleObjectStateException

## La Causa Raíz Real

**SIN un campo `@Version`, Hibernate NO puede hacer optimistic locking correctamente.**

Hibernate asume que:
- Si UPDATE afecta 0 filas = la fila fue modificada/borrada por otro
  
Pero la VERDADERA razón de 0 filas es:
- El refresh() corrompió el snapshot interno
- El WHERE clause no coincide con la realidad
- NO porque otra transacción la modificó

## Por Qué refresh() NO Resuelve el Problema Original

Si el problema original era optimistic locking, significa que:
1. HAY requests concurrentes modificando el mismo Artist
2. El refresh() NO ayuda porque solo recarga al INICIO
3. Entre el refresh() y el commit, OTRA transacción puede modificar el Artist
4. Además, el refresh() EMPEORA el problema al corromper el snapshot

