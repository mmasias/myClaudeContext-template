# myClaudeContext — template

<div align=right>

||
|-
|<sub><i>Este repositorio es el sustrato de identidad de Claude Code:<br>la máquina es intercambiable, el contexto no.<br>Como en [SOMA](https://es.wikipedia.org/wiki/Soma_(videojuego)), pero sin el dilema filosófico.<br></i></sub>

</div>

Template para sincronizar el contexto de Claude Code y Gemini CLI entre múltiples máquinas mediante symlinks y git. Una vez configurado, ambos agentes arrancan con el mismo contexto en cualquier máquina.

> **De dónde viene esto.** El sistema nació de analizar tres problemas estructurales de la memoria de los agentes de IA: memoria contaminada, memoria caduca y memoria incompleta. Si quieres entender la motivación antes de usar la herramienta, los artículos están en [`docs/`](docs/losTresProblemas.md).

---

## El problema que resuelve

Claude Code y Gemini CLI guardan su contexto en archivos locales:

- `~/.claude/CLAUDE.md` / `~/.gemini/GEMINI.md` — instrucciones globales de comportamiento
- `~/.claude/projects/` — memoria de cada proyecto (decisiones, estado de sesión, notas)

Por defecto, ese contexto vive solo en la máquina local. Al trabajar en varias máquinas, cada una acumula su propia versión que evoluciona de forma independiente. Este repositorio resuelve esa divergencia.

---

## Estructura

```
myClaudeContext/
├── global/
│   └── CLAUDE.md              <- ~/.claude/CLAUDE.md y ~/.gemini/GEMINI.md
├── proyectos/
│   ├── CLAUDE.md              <- ~/misRepos/proyectos/CLAUDE.md
│   └── <proyecto>/
│       └── CLAUDE.md          <- <proyecto>/.claude/CLAUDE.md y <proyecto>/GEMINI.md
├── projects/                  <- ~/.claude/projects/ (memoria de proyectos)
├── linux/
│   ├── setup-claude-symlinks.sh
│   ├── pull-claude-context.sh
│   └── push-claude-context.sh
├── macos/
│   ├── setup-claude-symlinks.sh
│   ├── pull-claude-context.sh
│   └── push-claude-context.sh
├── bootstrap.sh               <- setup completo de máquina nueva (cross-platform)
├── add-repo.sh                <- añadir proyecto nuevo al sistema (cross-platform)
├── check-claude-integrity.sh  <- validación de integridad (cross-platform)
├── memory-audit.sh            <- auditoría de repos inactivos (cross-platform)
├── manifiesto.txt             <- repos que deben existir en el sistema
├── RITUALES.md                <- referencia completa de rituales
└── docs/                      <- motivación y análisis del sistema
```

Los ficheros reales viven en este repositorio. En cada máquina, symlinks apuntan a ellos desde las ubicaciones que cada herramienta espera.

Ambos agentes comparten el mismo archivo físico por nivel. Las secciones `[Solo Claude Code]` y `[Solo Gemini]` en `global/CLAUDE.md` permiten instrucciones específicas por agente sin duplicar archivos.

---

## Requisito previo: consistencia entre máquinas

Este sistema depende de mantener la misma estructura de directorios y el mismo nombre de usuario en todas las máquinas.

> *¿Quieres orden? Sé ordenado.*

Si en una máquina los proyectos viven en `~/misRepos/proyectos/` y en otra en `~/Documentos/proyectos/`, los symlinks apuntarán a rutas inexistentes y el sistema fallará en silencio. Sin avisos, sin errores obvios.

La estructura debe decidirse antes de comenzar y mantenerse de forma consistente. Se configura editando las dos variables al inicio de cada script:

```bash
REPO=~/misRepos/myClaudeContext      # ubicación de este repositorio
PROYECTOS_DIR=~/misRepos/proyectos   # ubicación de los proyectos
```

---

## Cómo usarlo

### 1. Clonar y adaptar

```bash
git clone https://github.com/mmasias/myClaudeContext-template
cd myClaudeContext-template

# Apuntar a un repositorio privado propio
git remote set-url origin https://github.com/<usuario>/myClaudeContext
```

Los `CLAUDE.md` incluidos usan a **Ibuprofeno Fernández** como personaje de ejemplo. Sustituirlos por el contexto real antes de usar el sistema.

### 2. Primera vez en una máquina nueva

```bash
git clone https://github.com/<usuario>/myClaudeContext ~/misRepos/myClaudeContext
chmod +x ~/misRepos/myClaudeContext/bootstrap.sh
~/misRepos/myClaudeContext/bootstrap.sh
```

`bootstrap.sh` clona los repos del manifiesto, crea los symlinks y sincroniza la memoria.

> **Crítico:** Claude Code no debe arrancarse antes de que `bootstrap.sh` termine. Si arranca primero, crea `~/.claude/projects/` como directorio real y los symlinks quedan mal instalados. Solución: ejecutar `setup-claude-symlinks.sh` de nuevo.

### 3. Flujo diario

```bash
# Al comenzar
memory-pull

# Al terminar (con Claude activo — Claude hace el cierre semántico)
# Al terminar (sin Claude)
memory-push
```

---

## Comandos globales

Tras ejecutar `bootstrap.sh` o `setup-claude-symlinks.sh`, los siguientes comandos están disponibles desde cualquier directorio:

| Comando | Equivale a |
|---|---|
| `memory-pull` | `linux/pull-claude-context.sh` (o `macos/`) |
| `memory-push` | `linux/push-claude-context.sh` (o `macos/`) |
| `memory-check` | `check-claude-integrity.sh` |
| `memory-bootstrap` | `bootstrap.sh` |
| `memory-audit` | `memory-audit.sh` |

Los scripts crean symlinks en `~/.local/bin/` apuntando a la versión correcta para cada plataforma.

> **macOS:** verificar que `~/.local/bin` está en `$PATH`. Homebrew no lo añade por defecto. Añadir al `.zshrc`: `export PATH="$HOME/.local/bin:$PATH"`

---

## Validación de integridad

```bash
memory-check
```

Verifica symlinks de Claude y Gemini, estado del remote, coherencia de la memoria indexada y correspondencia Linux/macOS. Output `[OK]` / `[WARN]` / `[ERROR]` por cada check. Exit code = número de errores.

**Cuándo ejecutarlo:** al llegar tras un problema, después de instalar en una máquina nueva, o cuando algo se comporta raro.

**Corrección según lo que reporte:**

| Error | Acción |
|---|---|
| Symlink roto o mal apuntado | `./linux/setup-claude-symlinks.sh` (o `macos/`) |
| `~/.claude/projects` es directorio real (Linux) | `./linux/setup-claude-symlinks.sh` |
| `~/.claude/projects` es symlink (macOS) | `./macos/setup-claude-symlinks.sh` |
| Repo faltante del manifiesto | El check da el comando `git clone` exacto |
| Referencia rota en MEMORY.md | Edición manual del archivo |
| Repo divergido del remote | Resolución manual de conflicto git |

---

## Añadir un proyecto nuevo

```bash
./add-repo.sh https://github.com/usuario/nuevo-proyecto.git
```

Clona el repo en `~/misRepos/proyectos/<nombre>`, lo añade al manifiesto y regenera los symlinks. Después ejecutar `memory-push` para sincronizar.

---

## Auditoría de repos inactivos

```bash
memory-audit
```

Evalúa los repos con memoria acumulada y emite un veredicto:

| Veredicto | Significado |
|---|---|
| `ARCHIVAR` | Sin memoria real; eliminar el directorio de `projects/` |
| `REVISAR` | Tiene memoria pero lleva >90 días inactivo |
| `ACTIVO` | Uso reciente |

---

## Cómo funciona la cascada de contexto

Cada agente carga sus instrucciones en orden, del más general al más específico:

**Claude Code:**
```
~/.claude/CLAUDE.md                              -> comportamiento global
~/misRepos/proyectos/CLAUDE.md                   -> contexto común a todos los proyectos
~/misRepos/proyectos/<proyecto>/.claude/CLAUDE.md -> contexto por proyecto
```

**Gemini CLI:**
```
~/.gemini/GEMINI.md                              -> comportamiento global (mismo archivo que Claude)
~/misRepos/proyectos/<proyecto>/GEMINI.md        -> contexto por proyecto (mismo archivo que Claude)
```

Los archivos de proyecto se excluyen vía `.gitignore` (`.claude/` y `GEMINI.md`) para que no sean públicos en GitHub.

---

## Qué se sincroniza y qué no

Dentro de `projects/`, solo se trackean en git los ficheros `*.md` (memoria intencional):

| Tipo | Qué es | En git |
|---|---|---|
| `*.md` | Memoria intencional de proyectos | ✓ |
| `*.jsonl` | Logs de sesión, escritura continua | ✗ |
| `*.json` | Índices de sesión y metadatos | ✗ |
| `*.txt` | Resultados de herramientas | ✗ |

---

## Notas de arquitectura

**`~/.claude/` puede existir antes de Claude Code.** Plugins de VSCode u otras herramientas pueden crear el directorio. Los scripts usan `mkdir -p` para manejar ambos casos sin conflicto.

**La identidad de un proyecto depende del path absoluto.** Claude Code genera el identificador de cada proyecto a partir de la ruta absoluta en disco. Si esa ruta difiere entre máquinas, la memoria no se comparte aunque el contenido del repositorio sea idéntico. Este es el motivo por el que la consistencia de paths es un requisito no negociable del sistema.

**Linux vs macOS: comportamiento diferente de `~/.claude/projects/`.** En Linux, `projects/` es un symlink directo al repo (Claude Code escribe directamente en git). En macOS, `projects/` debe ser un directorio real; los scripts `pull` y `push` se encargan de copiar los directorios y traducir los paths entre plataformas.

**Git como red de seguridad.** Aunque se pierda contexto en una sesión por un conflicto mal resuelto, `git log` y los tags `memory-stable-YYYY-MM-DD` permiten recuperar cualquier estado anterior de los `*.md`.

**Gestión de conflictos.** Si se trabaja en dos máquinas sin sincronizar y ambas modifican el mismo fichero, git generará un conflicto al hacer push. La resolución debe hacerse manualmente: resolver el conflicto, hacer push desde una sola máquina, y continuar desde la otra tras un pull.

---

> Referencia operativa completa: [RITUALES.md](RITUALES.md)
