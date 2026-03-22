# sistemas — Diseño de sistemas distribuidos

## Contexto del proyecto

Repositorio de diseño e implementación de sistemas distribuidos. Incluye arquitecturas de referencia, prototipos y documentación técnica.

## Stack tecnológico
- Backend: Python / Go según el componente
- Mensajería: Kafka, RabbitMQ
- Contenedores: Docker + Kubernetes
- Documentación: Markdown + PlantUML

## Decisiones de diseño establecidas

- Los diagramas de arquitectura van en `docs/arquitectura/` como `.puml` con SVG generado en `docs/images/`
- Los prototipos son autocontenidos: cada uno en su directorio con su propio `README.md` y `requirements.txt`
- Nunca modificar los SVGs directamente: regenerar desde el `.puml`

## Convenciones de código

- Python: tipado estático obligatorio, sin dependencias innecesarias
- Nombres de variables y funciones en inglés
- Tests en `tests/` con cobertura mínima del 80%

---

## Estado de sesión

- Último componente trabajado: —
- Decisiones tomadas: —
- Pendiente en próxima sesión: —
