# Los tres problemas de la memoria de Claude Code

Claude Code tiene memoria persistente: guarda ficheros en disco que sobreviven entre sesiones y construyen el contexto de cada proyecto. Eso es una ventaja. También es una fuente de fallos que no siempre son obvios.

Los fallos de memoria de Claude Code caen en tres categorías distintas. Cada una tiene naturaleza diferente, diagnóstico diferente y solución diferente. Entender la distinción evita buscar soluciones técnicas donde hacen falta soluciones de proceso, y soluciones de proceso donde lo que hace falta es presencia humana.

## La taxonomía

|Problema|El modelo opera con...|Solución|
|---|---|---|
|Memoria contaminada|Recuerdos de otro proyecto|Técnica|
|Memoria caduca|Recuerdos correctos pero desactualizados|Proceso|
|Memoria incompleta|Ausencia de señal que no percibe como ausencia|Humana|

## Los tres problemas en una frase cada uno

**Memoria contaminada** — Claude Code identifica cada proyecto por su ruta absoluta en disco. Si se clona un repositorio distinto en el mismo path, el modelo hereda la memoria del anterior sin ninguna advertencia.

**Memoria caduca** — La memoria acumula pero no se poda. El modelo no distingue entre lo que escribió ayer y lo que escribió hace dos años. Opera con la misma confianza sobre recuerdos que pueden haber dejado de ser verdad.

**Memoria incompleta** — Lo que nunca se escribió no existe para el modelo. No como dato faltante: como nada. El modelo no experimenta la incompletitud porque no tiene forma de percibir el contorno de lo que no conoce.

## Por qué importa el orden

Los tres artículos están escritos para leerse en secuencia. Cada uno asume el anterior y construye sobre él. La escalada es deliberada: cada problema es más difícil que el anterior, cada solución requiere más del humano, y el tercero lleva esa escalada hasta su conclusión.

1. [Memoria contaminada: lo que Claude Code no documenta sobre cómo recuerda](memoriaContaminada.md)
2. [Memoria caduca: el problema que git no resuelve](memoriaCaduca.md)
3. [Memoria incompleta: donde el humano deja de ser opcional](memoriaIncompleta.md)
