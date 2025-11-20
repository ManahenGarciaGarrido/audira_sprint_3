# DIAGNÓSTICO EXACTO DEL PROBLEMA

## El Error
```
org.hibernate.StaleObjectStateException: Row was updated or deleted by another transaction (or unsaved-value mapping was incorrect) : [io.audira.community.model.Artist#1]
```

## El Flujo que Causa el Error

### Configuración Actual
- **Herencia**: JOINED (users + artists son tablas separadas)
- **Colecciones**: @ElementCollection con FetchType.EAGER
- **Solución anterior**: entityManager.refresh(user) - ¡QUE NO FUNCIONA!

### El Problema EXACTO

El `entityManager.refresh(user)` está **CAUSANDO** el problema, no resolviéndolo.

#### Por qué refresh() FALLA con JOINED Inheritance:

1. **findById(1)** carga Artist#1:
   - Hibernate hace JOIN entre users y artists
   - Crea un snapshot del estado en memoria
   - Marca la entidad como MANAGED

2. **refresh(user)** recarga todo:
   - Ejecuta de nuevo los JOIN
   - **PROBLEMA**: Con JOINED + @ElementCollection EAGER, el refresh() puede causar que Hibernate:
     a) Pierda el tracking correcto del estado de las tablas hijas (artists)
     b) Piense que la entidad fue modificada externamente
     c) Genere un UPDATE que espera un estado diferente al real

3. **Modificas campos** del artist

4. **save()** no hace nada (ya está MANAGED)

5. **Commit → flush()**:
   - Hibernate ejecuta: UPDATE users ... WHERE id = 1 ✅
   - Hibernate ejecuta: UPDATE artists ... WHERE id = 1
   - **PERO** el WHERE clause incluye una comparación implícita del estado esperado
   - Como el refresh() desincronizó el snapshot, Hibernate espera un estado que NO coincide
   - El UPDATE retorna 0 filas afectadas
   - Hibernate lanza StaleObjectStateException

## La Causa Raíz

Con JOINED inheritance, Hibernate maneja DOS tablas separadas. El refresh() está:
1. Descartando el snapshot original
2. Creando un nuevo snapshot
3. Pero el @ElementCollection EAGER + JOINED causa que el nuevo snapshot esté "corrupto"
4. Cuando intenta guardar, el estado esperado vs el real no coincide

## Por Qué Hibernate Piensa que Fue "Modified by Another Transaction"

NO es porque otra transacción modificó el Artist.
ES porque el refresh() mismo corr umpió el estado interno de Hibernate, haciendo que PIENSE que algo más lo modificó.

