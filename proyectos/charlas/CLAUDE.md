# charlas — Preparación de presentaciones

## Contexto del proyecto

Repositorio de materiales para charlas técnicas y divulgativas. Ibuprofeno da charlas sobre sistemas distribuidos, sobre música generada por algoritmos, y ocasionalmente sobre por qué la industria del streaming ha arruinado la masterización. Las audiencias varían; el rigor no.

## Estructura

```
charlas/
├── <año>-<titulo>/
│   ├── README.md       ← sinopsis, audiencia, duración, contexto
│   ├── slides/         ← fuentes de las diapositivas
│   ├── notas/          ← notas del ponente
│   └── recursos/       ← imágenes, demos, código de ejemplo
```

## Convenciones

- Cada charla en su propio directorio con el año como prefijo
- El `README.md` de cada charla documenta: título, audiencia objetivo, duración, abstract y lecciones aprendidas tras darla
- Las demos de código son autocontenidas y ejecutables sin configuración previa
- Las diapositivas se construyen en Markdown (Marp o similar) salvo excepción justificada

## Principios de diseño de charlas

- Una idea central por charla. Las demás son subordinadas.
- El ejemplo concreto antes que la abstracción.
- Si la demo puede fallar en directo, tiene un vídeo de respaldo. Siempre.

---

## Estado de sesión

- Última charla trabajada: —
- Decisiones tomadas: —
- Pendiente en próxima sesión: —
