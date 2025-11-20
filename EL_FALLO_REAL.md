# 🎯 EL FALLO EXACTO ENCONTRADO

## El Problema Real

En `User.java` líneas 19-20:

```java
@Inheritance(strategy = InheritanceType.JOINED)
@DiscriminatorColumn(name = "user_type", discriminatorType = DiscriminatorType.STRING)
```

**ESTE ES EL CONFLICTO:**
- `@DiscriminatorColumn` se usa con `InheritanceType.SINGLE_TABLE`
- `InheritanceType.JOINED` NO necesita ni debe usar `@DiscriminatorColumn`

## Por Qué Causa el Error

### Configuración Incorrecta Actual:
```
InheritanceType.JOINED + @DiscriminatorColumn
```
Hibernate se confunde porque:
1. JOINED usa tablas separadas (users, artists, regular_users, admins)
2. @DiscriminatorColumn intenta usar una columna (user_type) para distinguir tipos
3. Esta columna es REDUNDANTE e INCORRECTA con JOINED

### Lo Que Pasa Internamente:

1. **findById(1)** → Hibernate carga usando JOIN + verifica discriminator
2. **refresh(user)** → Hibernate recarga, pero ahora:
   - El discriminator value "ARTIST" vs el JOIN de la tabla artists NO coinciden en el snapshot interno
   - Hibernate piensa que la entidad cambió de tipo o es inconsistente
3. **Al hacer UPDATE:**
   - Hibernate genera WHERE con condiciones basadas en el discriminator
   - Pero la fila en artists NO cumple esas condiciones
   - UPDATE retorna 0 filas
   - → StaleObjectStateException

## El Flujo Exacto del Fallo:

```
1. findById(1)
   SELECT * FROM users u JOIN artists a WHERE u.id=1 AND u.user_type='ARTIST'
   → Carga OK
   
2. entityManager.refresh(user)
   SELECT * FROM users u JOIN artists a WHERE u.id=1 AND u.user_type='ARTIST'
   → Recarga, pero snapshot se corrompe por la mezcla JOINED + Discriminator

3. Modificas artist.setArtistName("nuevo")

4. Commit → flush()
   UPDATE users SET ... WHERE id=1 AND user_type='ARTIST'
   → ✅ OK (1 fila)
   
   UPDATE artists SET ... WHERE id=1 AND [condiciones del discriminator corrupto]
   → ❌ FALLA (0 filas) porque la condición extra del discriminator no se cumple
   
5. Hibernate: "Row was updated by another transaction"
   → FALSO. El row existe, pero el WHERE está mal generado
```

## La Raíz del Problema

**NO es el refresh() en sí.**
**ES la combinación de:**
1. `InheritanceType.JOINED` (correcto)
2. `@DiscriminatorColumn` (INCORRECTO para JOINED)
3. `entityManager.refresh()` (expone el bug)
4. `@ElementCollection EAGER` (amplifica el problema)

Cuando tienes JOINED + Discriminator juntos, el refresh() hace que Hibernate genere queries UPDATE con WHERE clauses incorrectos que incluyen condiciones del discriminator que no deberían estar ahí.

## Proof:

JPA Spec dice:
- SINGLE_TABLE → usa @DiscriminatorColumn (OBLIGATORIO)
- JOINED → usa JOINs, NO discriminator (OPCIONAL pero NO RECOMENDADO)  
- TABLE_PER_CLASS → tablas independientes, NO discriminator

Tu código tiene JOINED + Discriminator = CONFIGURACIÓN CONFLICTIVA

