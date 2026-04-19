# myClaudeContext — template

<div align=right>

<sub><i>Este repositorio es el sustrato de identidad de Claude Code:<br>la máquina es intercambiable, el contexto no.<br>Como en SOMA, pero sin el dilema filosófico.<br></i></sub>

</div>

Template para sincronizar el contexto de Claude Code y Gemini CLI entre múltiples máquinas mediante symlinks y git. Una vez configurado, ambos agentes arrancan con el mismo contexto en cualquier máquina.

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
│   └── CLAUDE.md              ← ~/.claude/CLAUDE.md y ~/.gemini/GEMINI.md
├── proyectos/
│   ├── CLAUDE.md              ← $PROYECTOS_DIR/CLAUDE.md
│   └── <proyecto>/
│       └── CLAUDE.md          ← <proyecto>/.claude/CLAUDE.md y <proyecto>/GEMINI.md
├── projects/                  ← ~/.claude/projects/ (memoria de proyectos)
├── setup-claude-symlinks.sh   ← ejecutar una vez por máquina
├── pull-claude-context.sh     ← ejecutar al llegar
├── push-claude-context.sh     ← ejecutar al salir
└── check-claude-integrity.sh  ← validar integridad del sistema
```

Los ficheros reales viven en este repositorio. En cada máquina, symlinks apuntan a ellos desde las ubicaciones que cada herramienta espera.

Ambos agentes comparten el mismo archivo físico por nivel. Las secciones `[Solo Claude Code]` y `[Solo Gemini]` en `global/CLAUDE.md` permiten instrucciones específicas por agente sin duplicar archivos.

---

## Requisito previo: consistencia entre máquinas

Este sistema depende de mantener la misma estructura de directorios y el mismo nombre de usuario en todas las máquinas.

> *¿Quieres orden? Sé ordenado.*

Si en una máquina los proyectos viven en `~/misRepos/proyectos/` y en otra en `~/Documentos/proyectos/`, los symlinks apuntarán a rutas inexistentes y el sistema fallará en silencio. Sin avisos, sin errores obvios.

La estructura debe decidirse antes de comenzar y mantenerse de forma consistente. Se configura editando las dos variables al inicio de `setup-claude-symlinks.sh` y `check-claude-integrity.sh`:

```bash
REPO=~/misRepos/myClaudeContext      # ubicación de este repositorio
PROYECTOS_DIR=~/misRepos/proyectos   # ubicación de los proyectos
```

---

## Cómo usarlo

### 1. Clonar y adaptar

```bash
# Clonar el template
git clone https://github.com/mmasias/myClaudeContext-template
cd myClaudeContext-template

# Apuntar a un repositorio privado propio
git remote set-url origin https://github.com/<usuario>/myClaudeContext
```

Los `CLAUDE.md` incluidos usan a **Ibuprofeno Fernández** como personaje de ejemplo. Sustituirlos por el contexto real antes de usar el sistema.

### 2. Primera vez en una máquina

```bash
git clone https://github.com/<usuario>/myClaudeContext ~/misRepos/myClaudeContext
cd ~/misRepos/myClaudeContext
chmod +x setup-claude-symlinks.sh
./setup-claude-symlinks.sh
```

El setup debe ejecutarse **antes** del primer arranque de Claude Code en la máquina. Si Claude Code arranca primero, crea `~/.claude/projects/` como directorio real y los symlinks quedan mal instalados. Solución: ejecutar `setup-claude-symlinks.sh` de nuevo.

### 3. Flujo diario

```bash
# Al comenzar la jornada
./pull-claude-context.sh

# Al terminar la jornada
./push-claude-context.sh
```

---

## Cómo funciona la cascada de contexto

Cada agente carga sus instrucciones en orden, del más general al más específico:

**Claude Code:**
```
~/.claude/CLAUDE.md                              → comportamiento global
$PROYECTOS_DIR/CLAUDE.md                         → contexto común a todos los proyectos
$PROYECTOS_DIR/<proyecto>/.claude/CLAUDE.md      → contexto por proyecto
```

**Gemini CLI:**
```
~/.gemini/GEMINI.md                              → comportamiento global (mismo archivo que Claude)
$PROYECTOS_DIR/<proyecto>/GEMINI.md              → contexto por proyecto (mismo archivo que Claude)
```

Los archivos de proyecto se excluyen vía `.gitignore` (`.claude/` y `GEMINI.md`) para que no sean públicos en GitHub.

---

## Validación de integridad

```bash
./check-claude-integrity.sh
```

Verifica symlinks de Claude y Gemini, estado del remote, y coherencia de la memoria indexada. Output `[OK]` / `[WARN]` / `[ERROR]` por cada check. Exit code = número de errores.

**Cuándo ejecutarlo:** al llegar tras un problema, después de instalar en una máquina nueva, o cuando algo se comporta raro.

**Corrección según lo que reporte:**

| Error | Acción |
|---|---|
| Symlink roto o mal apuntado | `./setup-claude-symlinks.sh` |
| `~/.claude/projects` es directorio real | `./setup-claude-symlinks.sh` |
| `GEMINI.md` no en `.gitignore` | `./setup-claude-symlinks.sh` |
| Repo divergido del remote | Resolución manual de conflicto git |
| Recuperar memoria anterior | `git checkout <tag> -- projects/.../memory/` |

---

## Añadir un proyecto nuevo

1. Crear el directorio del proyecto en `$PROYECTOS_DIR/<nuevo>/`
2. Ejecutar `./setup-claude-symlinks.sh` — crea automáticamente la carpeta en `proyectos/<nuevo>/` con un `CLAUDE.md` vacío y los symlinks de Claude y Gemini
3. Editar `proyectos/<nuevo>/CLAUDE.md` con el contexto específico del proyecto
4. Ejecutar `./push-claude-context.sh`
5. En las demás máquinas: `./pull-claude-context.sh` + `./setup-claude-symlinks.sh`

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

**`~/.claude/` puede existir antes de Claude Code.** Plugins de VSCode u otras herramientas pueden crear el directorio. El script usa `mkdir -p` para manejar ambos casos sin conflicto.

**La identidad de un proyecto depende del path absoluto.** Claude Code genera el identificador de cada proyecto a partir de la ruta absoluta en disco. Si esa ruta difiere entre máquinas, la memoria no se comparte aunque el contenido del repositorio sea idéntico. Este es el motivo por el que la consistencia de paths es un requisito no negociable del sistema.

**Git como red de seguridad.** Aunque se pierda contexto en una sesión por un conflicto mal resuelto, `git log` y los tags `memory-stable-YYYY-MM-DD` permiten recuperar cualquier estado anterior de los `*.md`.

**Gestión de conflictos.** Si se trabaja en dos máquinas sin sincronizar y ambas modifican el mismo fichero, git generará un conflicto al hacer push. La resolución debe hacerse manualmente: resolver el conflicto, hacer push desde una sola máquina, y continuar desde la otra tras un pull.
