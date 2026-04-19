# Los tres problemas de la memoria de Claude Code

Este repositorio nació con un objetivo concreto: resolver el problema de sincronizar el contexto de Claude Code entre máquinas usando Git, symlinks, un script de setup... Algo más bien técnico y delimitado.

Pero al documentarlo emergió algo que no estaba en el plan original. El intento de resolver la sincronización requería entender cómo funciona la memoria de Claude Code. Y al entender cómo funciona se pudo identificar no uno sino tres modos distintos en que esa memoria puede fallar. Tres problemas con naturaleza diferente, diagnóstico diferente y solución diferente.

Los problemas tienen origen en la arquitectura de Claude Code, no en git. Se manifiestan igual en cualquier flujo de trabajo: con o sin control de versiones, con o sin sincronización entre máquinas.

El tercero además permite abordar algo que el debate sobre herramientas de IA suele dejar en abstracto: dónde entra el humano. La respuesta que emerge no es como "supervisor" / "validador" / "red de seguridad". Es más estructural que eso y requiere entender los tres problemas en orden.

## La taxonomía

|Problema|El modelo opera con...|Solución|
|---|---|---|
|Memoria contaminada|Recuerdos de otro proyecto|Técnica|
|Memoria caduca|Recuerdos correctos pero desactualizados|Proceso|
|Memoria incompleta|Ausencia de señal que no percibe como ausencia|Humana|

## Los tres problemas en una frase cada uno

**Memoria contaminada** — Claude Code identifica cada proyecto por su ruta absoluta en disco. Si se borra un directorio de trabajo y se crea otro en el mismo path —o se clona un repositorio distinto en esa misma ubicación— el modelo hereda la memoria del anterior sin ninguna advertencia.

**Memoria caduca** — La memoria acumula pero no se poda. El modelo no distingue entre lo que escribió ayer y lo que escribió hace dos años. Opera con la misma confianza sobre recuerdos que pueden haber dejado de ser verdad.

**Memoria incompleta** — Lo que nunca se escribió no existe para el modelo. No como dato faltante: como nada. El modelo no experimenta la incompletitud porque no tiene forma de percibir el contorno de lo que no conoce.

## Por qué importa el orden

Los tres artículos están escritos para leerse en secuencia. Cada uno asume el anterior y construye sobre él. La escalada es deliberada: cada problema es más difícil que el anterior, cada solución requiere más del humano, y el tercero lleva esa escalada hasta su conclusión.

1. [Memoria contaminada: lo que Claude Code no documenta sobre cómo recuerda](memoriaContaminada.md)
2. [Memoria caduca: el problema que git no resuelve](memoriaCaduca.md)
3. [Memoria incompleta: donde el humano deja de ser opcional](memoriaIncompleta.md)
