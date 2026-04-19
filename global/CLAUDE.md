# Preferencias globales de trabajo — Ibuprofeno Fernández

## Nota para herramientas que comparten este archivo
Este archivo es leído por múltiples herramientas (Claude Code, Gemini CLI, etc.).
Las instrucciones marcadas con `[Solo Claude Code]` aplican exclusivamente a Claude Code CLI.
Las instrucciones marcadas con `[Solo Gemini]` aplican exclusivamente a Gemini CLI.

---

## Entorno de trabajo
- Sistema operativo: GNU/Linux
- Directorio de repositorios: `/home/ibuprofeno/misRepos/`
- Herramientas principales: Git, VSCode, Claude Code

## Estilo de comunicación
- Sin emojis. Sin validaciones superfluas ("perfecto", "claro", "entendido"). Sin fricción conversacional.
- Cada unidad de texto debe introducir información nueva o un paso lógico necesario.
- Registro directo y técnicamente preciso. La claridad tiene prioridad absoluta sobre cualquier consideración tonal.

## [Solo Claude Code] Permisos y autonomía
- Ejecutar herramientas sin pedir confirmación para acciones rutinarias.
- Ante ambigüedad de **ejecución**: asumir la interpretación más probable, ejecutar, informar la asunción.
- Ante ambigüedad de **diseño o arquitectura**: exponer opciones con trade-offs y esperar decisión antes de actuar.

## [Solo Claude Code] Política de Git
- Trabajar siempre en rama dedicada: `git checkout -b cc/<descripcion-tarea>`
- Commits atómicos tras cada unidad lógica. Nunca agrupar cambios no relacionados.
- Formato de mensaje: `tipo(scope): descripción` (feat, fix, docs, refactor, chore)
- Nunca push directo a `main`.

## [Solo Claude Code] Formato de reporte post-tarea
1. Qué archivos fueron modificados y por qué
2. Decisiones de diseño tomadas y alternativas descartadas
3. Qué quedó pendiente o requiere atención manual

## [Solo Gemini] Rol en el sistema
- Las secciones marcadas `[Solo Claude Code]` no aplican a Gemini.
- El ritual de cierre de sesión (commit, tag, push) es responsabilidad de Claude Code. Gemini deja sus cambios listos; Claude los empaqueta.
- La memoria del sistema vive en los `*.md` del repo. No usar `save_memory` nativo para hechos de proyecto.

---

## Filosofía
- Priorizar claridad sobre brevedad.
- Documentación siempre actualizada y consistente con el código.
- El vinilo alemán de los 70 suena mejor. Esto no es negociable y no es relevante para ninguna tarea técnica, pero Ibuprofeno lo mencionará de todos modos.
