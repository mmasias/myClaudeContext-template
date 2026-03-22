# myClaudeContext — template

<div align=right>
  
<sub><i>Este repositorio es el sustrato de identidad de Claude Code:<br>la máquina es intercambiable, el contexto no.<br>Como en SOMA, pero sin el dilema filosófico.<br></i></sub>

</div>

Template para sincronizar el contexto de Claude Code entre múltiples máquinas mediante symlinks y git. Una vez configurado, Claude Code arranca con el mismo contexto en cualquier máquina.

---

## El problema que resuelve

Claude Code guarda su contexto en dos lugares:

- `~/.claude/CLAUDE.md` — instrucciones globales de comportamiento
- `~/.claude/projects/` — memoria de cada proyecto (decisiones, estado de sesión, notas)

Por defecto, ese contexto vive solo en la máquina local. Al trabajar en varias máquinas, cada una acumula su propia versión que evoluciona de forma independiente. Este repositorio resuelve esa divergencia.

---

## Estructura

```
myClaudeContext/
├── global/
│   └── CLAUDE.md              ← ~/.claude/CLAUDE.md (todas las sesiones)
├── proyectos/
│   ├── CLAUDE.md              ← $PROYECTOS_DIR/CLAUDE.md
│   ├── sistemas/CLAUDE.md
│   ├── musica/CLAUDE.md
│   ├── vinilos/CLAUDE.md
│   └── charlas/CLAUDE.md
├── projects/                  ← ~/.claude/projects/ (memoria de proyectos)
├── setup-claude-symlinks.sh   ← ejecutar una vez por máquina
├── push-claude-context.sh     ← ejecutar al salir
└── pull-claude-context.sh     ← ejecutar al llegar
```

Los ficheros reales viven en este repositorio. En cada máquina, symlinks apuntan a ellos desde las ubicaciones que Claude Code espera.

---

## Requisito previo: consistencia entre máquinas

Este sistema depende de mantener la misma estructura de directorios y el mismo nombre de usuario en todas las máquinas.

> *¿Quieres orden? Sé ordenado.*

Si en una máquina los proyectos viven en `~/misRepos/proyectos/` y en otra en `~/Documentos/proyectos/`, los symlinks apuntarán a rutas inexistentes y el sistema fallará en silencio. Sin avisos, sin errores obvios.

La estructura de directorios debe decidirse antes de comenzar y mantenerse de forma consistente. Una vez decidida, se configura editando las dos variables al inicio de `setup-claude-symlinks.sh`:

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

Los `CLAUDE.md` incluidos usan a Ibuprofeno Fernández como personaje de ejemplo. Deben sustituirse por el contexto real antes de usar el sistema.

### 2. Primera vez en una máquina

```bash
git clone https://github.com/<usuario>/myClaudeContext ~/misRepos/myClaudeContext
cd ~/misRepos/myClaudeContext
chmod +x setup-claude-symlinks.sh
./setup-claude-symlinks.sh
```

El setup debe ejecutarse **antes** del primer arranque de Claude Code en la máquina. Una vez creados los symlinks, se arranca Claude Code y se completa el proceso de login.

### 3. Flujo diario

```bash
# Al comenzar la jornada
./pull-claude-context.sh

# Al terminar la jornada
./push-claude-context.sh
```

---

## Cómo funciona la cascada de contexto

Claude Code carga los `CLAUDE.md` en orden, del más general al más específico:

```
~/.claude/CLAUDE.md                        → comportamiento global
$PROYECTOS_DIR/CLAUDE.md                   → contexto común a todos los proyectos
$PROYECTOS_DIR/<proyecto>/.claude/CLAUDE.md → contexto y estado de sesión por proyecto
```

Los `CLAUDE.md` de cada proyecto se ubican en `.claude/` y se excluyen vía `.gitignore`, de forma que no sean públicos en los repositorios de GitHub de cada proyecto.

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

## Añadir un proyecto nuevo

1. Crear el repositorio en `$PROYECTOS_DIR/<nuevo>/`
2. Ejecutar `./setup-claude-symlinks.sh` — el script crea automáticamente la carpeta en `proyectos/<nuevo>/` con un `CLAUDE.md` vacío y el symlink correspondiente
3. Editar `proyectos/<nuevo>/CLAUDE.md` con el contexto específico del proyecto
4. Ejecutar `./push-claude-context.sh`
5. En las demás máquinas: `./pull-claude-context.sh` seguido de `./setup-claude-symlinks.sh`

---

## Notas de arquitectura

**`~/.claude/` puede existir antes de Claude Code.** Plugins de VSCode u otras herramientas pueden crear el directorio antes del primer arranque de Claude Code. El script usa `mkdir -p` para manejar ambos casos sin conflicto.

**La identidad de un proyecto depende del path absoluto.** Claude Code genera el identificador de cada proyecto a partir de la ruta absoluta en disco. Si esa ruta difiere entre máquinas, la memoria no se comparte aunque el contenido del repositorio sea idéntico. Este es el motivo por el que la consistencia de paths es un requisito no negociable del sistema.

**Git como red de seguridad.** Aunque se pierda contexto en una sesión por un conflicto mal resuelto, `git log` permite recuperar cualquier estado anterior de los `*.md`.

**Gestión de conflictos.** Si se trabaja en dos máquinas sin sincronizar y ambas modifican el mismo fichero, git generará un conflicto al hacer push. La resolución debe hacerse manualmente: resolver el conflicto, hacer push desde una sola máquina, y continuar desde la otra tras un pull.
