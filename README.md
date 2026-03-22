# myClaudeContext — template

> *Este repositorio es el sustrato de identidad de Claude Code: la máquina es intercambiable, el contexto no. Como SOMA, pero sin el dilema filosófico.*

Template para sincronizar el contexto de Claude Code entre múltiples máquinas mediante symlinks y git. Clona, adapta a tu caso, y Claude Code arranca con el mismo contexto en cualquier máquina.

---

## El problema que resuelve

Claude Code guarda su contexto en dos lugares:

- `~/.claude/CLAUDE.md` — instrucciones globales de comportamiento
- `~/.claude/projects/` — memoria de cada proyecto (decisiones, estado de sesión, notas)

Por defecto, ese contexto vive solo en la máquina local. Si trabajas en varias máquinas, cada una tiene su propia versión que evoluciona de forma independiente. Este repo soluciona eso.

---

## Estructura

```
myClaudeContext/
├── global/
│   └── CLAUDE.md              ← ~/.claude/CLAUDE.md (todas las sesiones)
├── proyectos/
│   ├── CLAUDE.md              ← ~/misRepos/proyectos/CLAUDE.md
│   ├── sistemas/CLAUDE.md
│   ├── musica/CLAUDE.md
│   ├── vinilos/CLAUDE.md
│   └── charlas/CLAUDE.md
├── projects/                  ← ~/.claude/projects/ (memoria de proyectos)
├── setup-claude-symlinks.sh   ← ejecutar una vez por máquina
├── push-claude-context.sh     ← ejecutar al salir
└── pull-claude-context.sh     ← ejecutar al llegar
```

Los ficheros reales viven en este repo. En cada máquina, symlinks apuntan a ellos desde las ubicaciones que Claude Code espera.

---

## Cómo usarlo

### 1. Clonar y adaptar

```bash
# Clonar el template
git clone https://github.com/mmasias/myClaudeContext-template
cd myClaudeContext-template

# Crear tu propio repo privado en GitHub y apuntarlo
git remote set-url origin https://github.com/<tuusuario>/myClaudeContext
```

Edita los `CLAUDE.md` con tu contexto real. El personaje de Ibuprofeno Fernández es un ejemplo; sustitúyelo por lo tuyo.

### 2. Primera vez en una máquina

```bash
git clone https://github.com/<tuusuario>/myClaudeContext ~/misRepos/myClaudeContext
cd ~/misRepos/myClaudeContext
chmod +x setup-claude-symlinks.sh
./setup-claude-symlinks.sh
```

Después del setup, arrancar Claude Code y loguearse. **El orden importa**: el setup debe ejecutarse antes del primer arranque de Claude Code en la máquina.

### 3. Flujo diario

```bash
# Al llegar
./pull-claude-context.sh

# Al salir
./push-claude-context.sh
```

---

## Cómo funciona la cascada de contexto

Claude Code carga los `CLAUDE.md` en orden, del más general al más específico:

```
~/.claude/CLAUDE.md                              → comportamiento global
~/misRepos/proyectos/CLAUDE.md                   → contexto común a todos los proyectos
~/misRepos/proyectos/<proyecto>/.claude/CLAUDE.md → contexto y estado de sesión por proyecto
```

Los `CLAUDE.md` de cada proyecto están en `.claude/` (excluidos vía `.gitignore`) para que no sean públicos en sus respectivos repos de GitHub.

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

1. Crear el repo en `~/misRepos/proyectos/<nuevo>/`
2. Ejecutar `./setup-claude-symlinks.sh` — crea automáticamente la carpeta en `proyectos/<nuevo>/` con un `CLAUDE.md` vacío y el symlink correspondiente
3. Editar `proyectos/<nuevo>/CLAUDE.md` con el contexto específico
4. `./push-claude-context.sh`
5. En las demás máquinas: `./pull-claude-context.sh` + `./setup-claude-symlinks.sh`

---

## Notas de arquitectura

**`~/.claude/` puede existir antes de Claude Code.** Plugins de VSCode u otras herramientas pueden crear el directorio. El script usa `mkdir -p` para manejar ambos casos.

**La identidad de un proyecto depende del path absoluto.** Claude Code genera el nombre de cada proyecto a partir de la ruta en disco. Mantener paths consistentes entre máquinas (mismo usuario, misma estructura de directorios) es requisito del sistema.

**Git como red de seguridad.** Aunque se pierda contexto en una sesión por un conflicto mal resuelto, `git log` permite recuperar cualquier estado anterior de los `*.md`.

**Conflictos.** Si trabajas en dos máquinas sin sincronizar y ambas modifican el mismo fichero, git generará un conflicto al hacer push. Resolverlo manualmente y hacer push desde una sola máquina antes de continuar en la otra.
