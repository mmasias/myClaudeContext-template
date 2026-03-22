# Memoria incompleta: donde el humano deja de ser opcional

## ¿Por qué?

Los dos problemas anteriores son variantes de la misma categoría: señal incorrecta en el contexto. Memoria contaminada trae señal de otro proyecto. Memoria caduca trae señal del proyecto correcto pero desactualizada. En ambos casos hay algo en memoria que no debería estar, o que debería ser distinto. El problema es de calidad.

Este tercero es diferente en naturaleza. No hay señal incorrecta. Hay ausencia de señal. Y la ausencia no se percibe como ausencia.

## ¿Qué?

### El modelo no sabe lo que no sabe

Claude Code construye su contexto a partir de lo que está escrito en sus ficheros de memoria. Lo que nunca se escribió, simplemente no existe para él. No como dato faltante, no como NULL, no como incógnita marcada. Como nada.

La diferencia es importante. En una base de datos, un campo vacío es visible: hay una celda, está vacía, se puede detectar. En la memoria de Claude Code, lo que nunca se documentó no deja ninguna celda vacía. El esquema no tiene columna para ello porque nadie supo que había que añadirla.

El modelo opera con coherencia perfecta dentro de lo que conoce. No experimenta la incompletitud como un problema. De ahí el calificativo: **confortablemente** incompleta. El sistema funciona, da respuestas razonadas, parece saber lo que hace. La ausencia es invisible desde dentro.

### Por qué ocurre

La memoria de Claude Code se construye incrementalmente, a partir de lo que el usuario decide documentar y de lo que el modelo anota durante las sesiones. Ese proceso tiene sesgos estructurales:

- Se documenta lo que se trabaja, no lo que existe.
- Se anota lo que cambia, no lo que permanece estable.
- Se registran las decisiones tomadas, raramente las que están pendientes.
- Lo que todo el mundo sabe y nadie dice, no llega a escribirse nunca.

El resultado es una memoria que puede ser coherente, actualizada y aun así representar solo una fracción del proyecto real. El modelo no tiene forma de saberlo.

### La diferencia con los otros dos problemas

||Origen del problema|El modelo lo puede detectar|
|-|-|-|
|Contaminada|Señal de otro proyecto|No|
|Caduca|Señal desactualizada|No|
|Incompleta|Ausencia de señal|No, por definición|

Los tres comparten que el modelo no genera señal de alarma. Pero los dos primeros son detectables desde fuera con herramientas: paths, fechas, `git log`. La memoria incompleta no deja rastro porque lo que falta no dejó rastro al no escribirse.

## ¿Para qué?

Los modos de fallo son invisibles hasta que alguien externo nota la discrepancia.

**El modelo diseña sin conocer una restricción que existe.** Un equipo decide que todo acceso a datos externos pasa por una capa de caché. Nadie lo escribe en memoria porque es una decisión reciente, obvia para quien estuvo en la reunión. El modelo propone acceso directo. La propuesta es técnicamente correcta, arquitectónicamente incompatible.

**El modelo ignora un subsistema entero.** Un módulo de auditoría se añadió hace seis meses. Nunca se documentó en el contexto de Claude Code. El modelo hace cambios en el sistema de autenticación sin considerar sus efectos sobre auditoría. No porque no sepa razonar sobre efectos secundarios, sino porque para él ese módulo no existe.

**El modelo no conoce a parte del equipo.** Dos personas nuevas llevan meses en el proyecto. Sus áreas de responsabilidad, sus decisiones, sus convenciones de código: nada de eso está en memoria. El modelo sigue asignando tareas a quien recuerda, ignorando a quien no conoce.

En todos estos casos el comportamiento es internamente coherente. El problema es que el mundo real es más grande que el mundo que el modelo conoce, y el modelo no lo sabe.

## ¿Cómo?

Aquí hay que ser honesto sobre los límites: no existe solución técnica que elimine este problema. Las mitigaciones reducen la superficie de exposición. No la cierran.

### Onboarding explícito como práctica

Cuando se empieza a trabajar en un proyecto con Claude Code, la tendencia natural es ir directamente a la tarea. Una práctica más robusta es dedicar tiempo inicial a describir lo que existe, no solo lo que se va a hacer:

```
Antes de empezar: este proyecto tiene estos módulos, estas dependencias críticas,
estas restricciones no negociables, estas personas y sus áreas. Anótalo.
```

Ese onboarding no ocurre de forma automática. Requiere que el usuario lo decida y lo ejecute.

### Plantillas con secciones obligatorias

Un `CLAUDE.md` en blanco invita a escribir lo que se recuerda. Una plantilla con secciones fijas obliga a pensar en lo que podría faltar:

```markdown
## Equipo y responsabilidades
## Restricciones no negociables
## Integraciones externas
## Decisiones pendientes
## Lo que este proyecto NO hace
```

La última sección es especialmente útil: documentar el alcance negativo reduce el riesgo de que el modelo proponga soluciones fuera de él.

### Preguntar al modelo qué asume

El modelo no puede reportar lo que no sabe, pero sí puede reportar lo que asume. Periódicamente:

```
Lista los supuestos que estás haciendo sobre este proyecto que no están
explícitamente documentados en tu contexto.
```

La respuesta no es exhaustiva —los supuestos inconscientes no aflorarán— pero los supuestos conscientes sí. Y un supuesto listado es un supuesto que se puede verificar o corregir.

### El límite de todas estas mitigaciones

Ninguna de estas prácticas resuelve el problema de raíz. Todas dependen de que el usuario sepa qué información falta y tome la iniciativa de proporcionarla. Pero si el usuario sabe qué falta, el problema ya está parcialmente resuelto. El caso genuinamente difícil es el que el usuario tampoco identifica como laguna.

Ahí no hay mitigación técnica disponible.

## ¿Y ahora qué?

Los tres problemas descritos en esta serie forman una taxonomía completa de los modos de fallo de la memoria de Claude Code:

|Problema|Naturaleza|Solución|
|-|-|-|
|Contaminada|Identidad equivocada|Técnica: paths + git|
|Caduca|Temporalidad errónea|Proceso: datar + revisar + podar|
|Incompleta|Ausencia de señal|Humana: irreducible|

La escalada no es accidental. Cada problema es más difícil que el anterior. Cada solución requiere más del humano. El tercero lleva esa escalada hasta su conclusión lógica: hay algo que el sistema no puede darse a sí mismo, y ese algo solo lo aporta quien conoce el proyecto desde fuera de la memoria.

Esto responde de forma concreta una pregunta que el debate sobre herramientas de IA suele dejar en abstracto: dónde entra el humano. No como supervisor que detecta errores —eso es rol de revisión, parcialmente automatizable—. Como **fuente de señal que el sistema no puede generarse a sí mismo**.

No es una limitación de inteligencia del modelo. Es una restricción epistemológica: no puedes describir el contenido de un vacío que no percibes como vacío. ***El humano no es el safety net. Es una pieza arquitectónica del sistema***.
