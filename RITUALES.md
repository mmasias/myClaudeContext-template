# Rituales

Referencia operativa del sistema de contexto. Cada ritual cubre un momento del ciclo de vida.

---

## 1. Máquina nueva

Una sola vez, antes del primer arranque de Claude Code:

```bash
git clone https://github.com/<usuario>/myClaudeContext ~/misRepos/myClaudeContext
chmod +x ~/misRepos/myClaudeContext/bootstrap.sh
~/misRepos/myClaudeContext/bootstrap.sh
```

`bootstrap.sh` se encarga de todo: clonar los repos del manifiesto, crear symlinks (Claude Code y Gemini CLI) y sincronizar memoria. Al terminar, lanzar Claude Code o Gemini CLI.

> **Crítico:** Claude Code no debe arrancarse antes de que bootstrap termine. Si arranca primero, crea `~/.claude/projects/` como directorio real y los symlinks quedan mal instalados. Solución: ejecutar `setup-claude-symlinks.sh` de nuevo.

---

## 2. Inicio de sesión

```bash
memory-pull
```

Verifica la integridad mínima (symlinks, estado del remote) antes de sincronizar. Aborta con mensaje claro si algo está mal.

> **Si el script falla:** ejecutar `memory-bootstrap`. Bootstrap reconstruye el estado correcto desde cero y es seguro ejecutarlo en cualquier momento — no sobreescribe lo que ya está bien.

---

## 3. Cierre de sesión con Claude activo

Claude genera el commit, el tag semántico y hace push:

```bash
# Claude ejecuta:
git add <archivos modificados>
git commit -m "tipo(scope): descripción semántica"
git tag "stable-<verbo-objeto-kebab-case>"
git push
git push origin "refs/tags/stable-<descripcion>" --force
```

El tag refleja el tema dominante de la sesión. Ejemplos:
- `stable-configurando-entorno`
- `stable-actualizando-memoria-proyecto`
- `stable-anadiendo-proyecto-nuevo`

Formato: kebab-case, máximo 50 caracteres.

---

## 4. Cierre de sesión sin Claude

```bash
memory-push
```

Genera commit genérico (`sync: estado sesión YYYY-MM-DD HH:MM`) y tag de fecha (`memory-stable-YYYY-MM-DD`) como fallback. Menos semántico pero garantiza que la memoria queda sincronizada.

---

## 5. Validación de integridad

```bash
memory-check
```

Output `[OK]` / `[WARN]` / `[ERROR]` por cada check. Exit code = número de errores.

Cuándo ejecutarlo: al llegar tras un problema, después de una reinstalación, o cuando algo se comporta raro.

**Corrección según lo que reporte:**

| Error | Acción |
|---|---|
| Symlink roto o apuntando a lugar incorrecto (Claude o Gemini) | `./linux/setup-claude-symlinks.sh` (o `macos/`) |
| Repo faltante del manifiesto | El check da el comando `git clone` exacto |
| Referencia rota en MEMORY.md | Edición manual del archivo |
| Archivos `.jsonl/.json/.txt` trackeados en git | `git rm --cached <archivo>` |
| Repo divergido del remote | Resolución manual de conflicto git |

---

## 6. Recuperación de memoria

Ver el historial de estados estables:

```bash
cd ~/misRepos/myClaudeContext
git tag -l "stable-*" | sort
git tag -l "memory-stable-*" | sort
```

Inspeccionar un estado pasado:

```bash
git show <tag>:projects/<proyecto>/memory/MEMORY.md
```

Restaurar la memoria de un proyecto a un punto anterior:

```bash
git checkout <tag> -- projects/<proyecto>/memory/
git commit -m "fix(memory): restaurar estado desde <tag>"
git push
```

---

## 7. Auditoría periódica

Cuando el sistema acumula repos inactivos:

```bash
memory-audit
```

Evalúa los repos con memoria en `projects/` y emite un veredicto por cada uno:

| Veredicto | Significado |
|---|---|
| `ARCHIVAR` | Sin memoria real; eliminar el directorio de `projects/` |
| `REVISAR` | Tiene memoria pero lleva >90 días inactivo |
| `ACTIVO` | Uso reciente |

---

## 8. Añadir un repo nuevo al sistema

```bash
~/misRepos/myClaudeContext/add-repo.sh https://github.com/usuario/nuevo-repo.git
```

Clona el repo en `~/misRepos/proyectos/<nombre>`, lo añade al manifiesto y regenera symlinks. Después cerrar sesión normalmente (ritual 3 o 4) para sincronizar el manifiesto.

En las demás máquinas: `memory-pull` + `./linux/setup-claude-symlinks.sh` (o `macos/`).
