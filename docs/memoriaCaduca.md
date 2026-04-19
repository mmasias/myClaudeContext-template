# Memoria caduca: el problema que git no resuelve

## ¿Por qué?

El artículo sobre memoria contaminada describe un problema de **identidad equivocada**: Claude Code cree que está en un proyecto cuando en realidad está en otro. La solución —git más symlinks— resuelve eso. Pero hay un segundo problema, más silencioso, que persiste incluso con el sistema de sincronización perfectamente configurado.

Claude Code acumula memoria. No la poda. Y no distingue entre lo que escribió ayer y lo que escribió hace dos años.

## ¿Qué?

### Cómo envejece la memoria

Cada entrada que Claude Code escribe en sus ficheros `*.md` de proyecto refleja el estado del sistema en ese momento: decisiones de arquitectura, convenciones acordadas, estado de una tarea, nombre de la persona responsable de un módulo, una restricción técnica que existía entonces.

Con el tiempo, esas entradas se quedan obsoletas. La arquitectura cambia. Las restricciones desaparecen. La persona responsable se va. La tarea "en progreso" lleva meses resuelta.

El sistema nativo de Claude Code no tiene ningún mecanismo para detectar esto:

- No hay timestamps en las entradas de memoria.
- No hay TTL ni invalidación automática.
- No hay distinción entre memoria reciente y memoria antigua.

El modelo lee todo el contexto acumulado al inicio de cada sesión, con la misma confianza, independientemente de cuándo fue escrito.

### La diferencia con memoria contaminada

Memoria contaminada es un problema de **identidad**: el modelo opera sobre recuerdos de un proyecto distinto.

Memoria caduca es un problema de **temporalidad**: el modelo opera sobre recuerdos del proyecto correcto, pero que ya no son verdad.

Son problemas ortogonales. El sistema de sincronización resuelve el primero. No toca el segundo.

### El modo de fallo específico

Lo que hace que la memoria caduca sea especialmente difícil de detectar es que el modelo actúa con **confianza fundada pero desactualizada**. No está inventando. No está confundiendo proyectos. Está recordando correctamente algo que dejó de ser cierto.

El usuario no tiene ninguna señal que distinga "recuerdo fresco" de "recuerdo obsoleto". Ambos llegan al contexto de la misma forma, con la misma autoridad.

## ¿Para qué?

||
|-|
|<sub>Un ejemplo ocurrido durante la elaboración de este artículo. En el proyecto [pySigHor](https://github.com/mmasias/pySigHor) se adoptó desde el principio una estrategia de memoria explícita: un fichero `conversation-log.md` que registraba cronológicamente cada sesión con Claude Code —decisiones tomadas, estado del proyecto, instrucciones para la siguiente sesión. La intención era correcta: resolver el problema de que el modelo empieza cada sesión sin recuerdo de las anteriores. El resultado, después de 49 conversaciones, fue un fichero de más de 4.500 líneas que el modelo debía leer íntegro al inicio de cada sesión para extraer el estado actual. La última instrucción registrada decía literalmente: *"Leer conversation-log.md (Conversación 49)"*. El fichero tuvo que partirse manualmente en dos —[`conversation-log-001.md`](https://github.com/mmasias/pySigHor/blob/main/conversation-log-001.md) y [`conversation-log.md`](https://github.com/mmasias/pySigHor/blob/main/conversation-log.md)— cuando el crecimiento hizo el sistema inmanejable. La solución al problema de incompletitud había derivado en un problema de caducidad masiva. Y la ruptura en dos ficheros introdujo un nuevo riesgo: una sesión que solo leyera el fichero actual se perdería los 49 primeros. Los tres problemas de esta serie, en un solo caso real.</sub>|

Entender esta dinámica cambia cómo se diagnostican ciertos comportamientos de Claude Code:

**Cuando el modelo propone soluciones anacrónicas.** Si la memoria registra que "la base de datos no soporta transacciones", el modelo evitará proponer transacciones aunque el sistema lleve un año soportándolas. No es ignorancia: es recuerdo caduco.

**Cuando el modelo asigna responsabilidades a personas que ya no están.** Si la memoria dice "el módulo de pagos lo lleva Ana", el modelo seguirá asumiendo que Ana es el punto de contacto. La memoria no sabe que Ana se fue.

**Cuando el modelo evita caminos que ya no están bloqueados.** Las restricciones técnicas que se documentaron como workarounds temporales quedan en memoria indefinidamente. El modelo las respeta como si siguieran vigentes.

En todos estos casos, el comportamiento del modelo es internamente coherente. El problema está en los datos de entrada, no en el razonamiento.

## ¿Cómo?

Git proporciona trazabilidad. Eso ayuda a *diagnosticar* memoria caduca —`git log` sobre `projects/` muestra cuándo cambió cada entrada— pero no ayuda a *prevenirla*. El modelo no consulta el historial de git antes de leer su contexto.

La solución tiene que operar en otro nivel: en el propio contenido de los ficheros de memoria.

### Datar las entradas

La intervención mínima es añadir fechas explícitas a las secciones que más envejecen:

```markdown
## Estado de sesión
_Actualizado: 2025-11-14_

- La restricción de memoria en el módulo de exportación sigue activa (issue #312)
- El módulo de pagos lo lleva Ana
```

Una entrada con fecha es una entrada que puede evaluarse. Una entrada sin fecha es atemporal por defecto, lo que en la práctica significa que el modelo la trata como si fuera siempre verdad.

### Distinguir tipos de memoria por caducidad

No toda la memoria envejece igual. Conviene separarlo:

|Tipo|Ejemplos|Caducidad|
|-|-|-|
|Arquitectural|convenciones de código, estructura del proyecto|lenta|
|Operativa|estado de tareas, restricciones activas, responsables|rápida|
|Histórica|decisiones tomadas, alternativas descartadas|no caduca|

La memoria operativa es la que más necesita revisión periódica. La histórica, paradójicamente, es la más duradera porque registra *por qué* se decidió algo, no *cómo está* algo.

### Revisión periódica como disciplina

El modelo no hace limpieza automática, pero el usuario puede delegar la tarea al propio modelo. Una sesión de revisión con una instrucción explícita:

```
Lee el CLAUDE.md de este proyecto y marca como [obsoleto?] cualquier entrada
que no puedas verificar leyendo el código actual.
```

Eso no garantiza que el modelo detecte todo lo que ha caducado, pero introduce fricción donde antes no había ninguna. Una entrada marcada como `[obsoleto?]` es visible; una entrada silenciosamente falsa no lo es.

### Lo que no resuelve nada

Añadir más memoria no es la solución. Si el estado A queda registrado y luego se añade el estado B sin borrar A, el contexto contiene dos verdades contradictorias. El modelo intentará reconciliarlas. A veces lo hace bien; a veces el resultado es ruido.

La disciplina de limpieza importa tanto como la disciplina de escritura.

## ¿Y ahora qué?

Memoria contaminada y memoria caduca comparten estructura: ambas son problemas de **señal incorrecta en el contexto**, no de razonamiento defectuoso del modelo. La diferencia está en el origen de la señal incorrecta.

El sistema de sincronización descrito en este repositorio resuelve la contaminación. La caducidad requiere disciplina editorial: datar, clasificar, revisar y podar. Nada de eso ocurre de forma automática con las herramientas actuales.

Queda un problema abierto que ninguna de estas dos aproximaciones resuelve: ***el modelo no sabe lo que no sabe***. Si la memoria dice algo falso con suficiente confianza, el modelo no tiene incentivo para cuestionarlo. El único mecanismo de detección disponible hoy es externo: el usuario que nota la discrepancia entre lo que el modelo asume y lo que el código dice.

Ese tercer problema tiene naturaleza distinta. Y su solución también: [Memoria incompleta: donde el humano deja de ser opcional](memoriaIncompleta.md).
