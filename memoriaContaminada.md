# Memoria contaminada: lo que Claude Code no documenta sobre cómo recuerda

## ¿Por qué?

Claude Code tiene memoria. No en el sentido metafórico de "contexto de conversación", sino en un sentido muy concreto y muy GNU/Linux: guarda ficheros en disco que persisten entre sesiones.

Trasteando la arquitectura detrás de esa memoria aparecen sorpresas que —si no se gestionan adecuadamente— pueden derivar en **memoria contaminada**: el modelo operando con recuerdos de un proyecto anterior que, por accidente arquitectónico, comparte identidad con el actual.

Un ejemplo ocurrido durante la elaboración de este artículo: se clonó el repositorio template de [ibuprofenofernandez/myClaudeContext-template](https://github.com/ibuprofenofernandez/myClaudeContext-template) para trabajar con él. Después se hizo un fork en [mmasias/myClaudeContext-template](https://github.com/mmasias/myClaudeContext-template), se borró el clone original del disco y se clonó el fork en el mismo path. Claude Code no se enteró del cambio. El path en disco era idéntico, así que siguió usando la misma carpeta de memoria, con el mismo contexto acumulado, como si nada hubiera ocurrido. Dos repositorios distintos, un solo "recuerdo".

Esto no tiene nada que ver con las (mal llamadas) alucinaciones de los LLMs. No es el modelo inventando cosas. Es un problema derivado de decisiones arquitectónicas concretas de Anthropic para modelar la persistencia en Claude Code. Muy GNU/Linux en su planteamiento: robusta en general, frágil en las zonas grises.

Y lo que se ha encontrado al explorarlo inquieta un poco.

## ¿Qué?

### Dónde vive la memoria de Claude Code

Claude Code guarda su contexto en dos ubicaciones:

```
~/.claude/CLAUDE.md
~/.claude/projects/
```

El primero es el fichero de instrucciones globales — comportamiento, estilo, convenciones. El segundo es el directorio de memoria por proyecto: decisiones tomadas, estado de sesión, notas acumuladas durante el trabajo.

Dentro de `~/.claude/projects/`, cada proyecto ocupa una carpeta cuyo nombre es la ruta absoluta del proyecto en disco, con los `/` sustituidos por `-`:

```
~/.claude/projects/-home-usuario-misRepos-miProyecto/
```

Aquí reside el problema.

### La identidad de un proyecto es su path

Claude Code no identifica un proyecto por su contenido, por su remote de git, ni por ningún identificador explícito. Lo identifica por la **ruta absoluta en disco** de la sesión activa.

Esto tiene consecuencias no obvias:

**Si se borra un repo y se clona otro en el mismo path**, Claude Code reutiliza la memoria del anterior. Los "recuerdos" del proyecto viejo están ahí, mezclados con los del nuevo. El modelo puede operar con decisiones de diseño, convenciones o estado de sesión que pertenecen a un proyecto completamente distinto.

**Si el mismo repo se clona en paths distintos entre máquinas** (`~/misRepos/proyecto` en una, `~/Documentos/proyecto` en otra), Claude Code genera identificadores distintos y la memoria no se comparte, aunque el contenido del repositorio sea idéntico.

**Si el nombre de usuario difiere entre máquinas** (`/home/manuel/` vs `/home/mmasias/`), mismo resultado: identidades distintas, memoria no compartida.

El sistema asume estabilidad de paths. Es un supuesto razonable para un desarrollador ordenado en un entorno controlado. Se rompe con facilidad en escenarios reales.

## ¿Para qué?

Entender esta arquitectura permite tomar decisiones informadas sobre tres cosas:

**Gestión de memoria entre máquinas.** Si se trabaja en varios ordenadores y se espera que Claude Code mantenga coherencia de contexto, hay que sincronizar activamente `~/.claude/projects/`. No ocurre de forma automática.

**Limpieza de memoria obsoleta.** Claude Code no hace limpieza automática. Los proyectos borrados dejan carpetas huérfanas en `~/.claude/projects/` que se acumulan indefinidamente. Y si se reutiliza un path, esa memoria huérfana vuelve a activarse.

**Diagnóstico de comportamiento inesperado.** Cuando Claude Code "recuerda" algo que no debería, o ignora algo que debería recordar, la primera causa a investigar es la identidad del proyecto: ¿está apuntando a la carpeta correcta?

## ¿Cómo?

### Una solución práctica: git como sustrato de sincronización

La solución que emerge de este experimento es tratar `~/.claude/projects/` como lo que es: un conjunto de ficheros de texto que deben versionarse y sincronizarse como cualquier otro dato importante.

La aproximación concreta:

1. Crear un repositorio privado (`myClaudeContext`) que centralice toda la memoria de Claude Code
2. Mover `~/.claude/projects/` a ese repositorio
3. Crear un symlink `~/.claude/projects → ~/misRepos/myClaudeContext/projects/`
4. Repetir el symlink en cada máquina
5. `git pull` al llegar, `git push` al salir

```
myClaudeContext/
├── global/CLAUDE.md       ← ~/.claude/CLAUDE.md
├── projects/              ← ~/.claude/projects/
└── proyectos/             ← CLAUDE.md por proyecto
```

Dentro de `projects/`, no todo merece ir a git. Los ficheros `*.jsonl`, `*.json` y `*.txt` son logs de sesión y resultados de herramientas: cambian continuamente y generan conflictos. Solo los `*.md` contienen memoria intencional y merecen versionarse.

```
# .gitignore
*.jsonl
projects/**/*.txt
projects/**/*.json
```

### El requisito no negociable

Este sistema solo funciona si los paths son consistentes entre máquinas. Mismo nombre de usuario, misma estructura de directorios. No es una limitación del sistema de sincronización: es una limitación de la arquitectura de Claude Code.

> *¿Quieres orden? Sé ordenado.*

### Lo que git aporta que el filesystem no da

Además de la sincronización, git proporciona algo que el sistema nativo de Claude Code no tiene: **trazabilidad**. Cada cambio en la memoria queda registrado con fecha y autor. Si Claude Code empieza a comportarse de forma inesperada, `git log` sobre `projects/` permite reconstruir qué cambió y cuándo.

Es la diferencia entre un sistema que falla y un sistema que falla pero se puede diagnosticar.

### Una observación lateral sobre `~/.claude/`

Durante el experimento se descubre que `~/.claude/` puede existir antes del primer arranque de Claude Code. Plugins de VSCode y otras herramientas de desarrollo crean el directorio como efecto secundario. El sistema de setup debe asumir que el directorio puede o no existir, y usar `mkdir -p` en consecuencia. La asunción de que `~/.claude/` solo lo crea Claude Code CLI es falsa.

## ¿Y ahora qué?

El repositorio template con la solución descrita está disponible en:
[github.com/mmasias/myClaudeContext-template](https://github.com/mmasias/myClaudeContext-template)

Incluye los scripts de setup, push y pull, ejemplos de `CLAUDE.md` en cascada, y documentación del sistema completo.

Quedan dos aspectos abiertos como trabajo futuro:

- **Detección de desincronización**: que el script avise cuando hay proyectos con contexto pero sin repo local, o repos locales sin contexto registrado
- **Validación de `$PROYECTOS_DIR`**: que el setup falle con un mensaje claro si el directorio de proyectos no existe, en lugar de completarse en silencio sin hacer nada útil

Ambos están documentados como issues abiertos en el repositorio.