# opencode-config

Snapshot **portable y sanitizado** de mi configuración global de OpenCode (V2).
Sirve como copia de referencia para reconstruir el entorno en otra máquina.

**Este repositorio NO se carga automáticamente.** La fuente de verdad es la
instalación global de cada máquina:

- `~/.config/opencode/opencode.json` — configuración global.
- `~/.agents/skills/` — skills instaladas para los agentes.

Este repo es una copia de solo lectura pensada para revisión e instalación
manual. No lo apuntes con `OPENCODE_CONFIG` ni `OPENCODE_CONFIG_DIR`.

## Contenido

| Archivo / directorio | Qué es |
|---|---|
| `opencode.global.json` | Snapshot sanitizado de `~/.config/opencode/opencode.json` |
| `skills/agent-browser/SKILL.md` | Automatización de navegador para agentes |
| `skills/code-review-and-quality/SKILL.md` | Revisión de código multi-eje antes de mergear |
| `skills/find-skills/SKILL.md` | Descubrir e instalar skills |
| `skills/git-workflow-and-versioning/SKILL.md` | Flujo Git, commits, PRs, releases |
| `skills/project-memory-gate/` | Gate previo a integración para memoria durable, con política y plantillas |
| `skills/plane-work-management/SKILL.md` | Gestión de proyectos y work items en Plane |
| `skills/plane-workitem-development/SKILL.md` | Desarrollo de un work item de Plane de punta a punta |

Total: 7 skills. Los agentes viven dentro de `opencode.global.json` (no hay
carpeta `agents/` ni `commands/` en este snapshot).

`project-memory-gate` se evalúa antes de integrar trabajo terminado en la rama
base real del repositorio. Analiza si el cambio contiene conocimiento durable
que no pueda inferirse de forma fiable desde código, pruebas y configuración.
La evaluación siempre se realiza, pero crear o actualizar memoria requiere
confirmación explícita; un resultado `No memory update` es normal. La skill no
autoriza commits, pushes, cambios de PR ni merges.

## Configuración V2 (`opencode.global.json`)

Es un snapshot fiel de `~/.config/opencode/opencode.json`. Contiene:

- `$schema`: `https://opencode.ai/config.json`.
- `model` por defecto y `default_agent: "build"`.
- **Agentes** (`agents`):
  - `build` (primary) — orquesta, implementa cambios pequeños y **es el único
    que muta Plane y Git**.
  - `plan` (primary) — investigación y diseño, sin editar código ni ejecutar shell.
  - `general` (subagent) — ejecutor de implementaciones delegadas.
  - `explore` (subagent) — exploración de solo lectura.
  - `reviewer` (subagent) — revisión **estrictamente de solo lectura**.
  - `title` — generación de títulos.
- **Proveedor** (`providers.omniroute`): endpoint local
  `http://127.0.0.1:20131/v1`, con la credencial referenciada como
  `{file:~/.config/opencode/omniroute.key}`. **Nunca se copia el valor de la
  clave.**
- **Modelos** declarados: `cx/gpt-5.6-sol` y `opencode-go/deepseek-flash`.
- **MCP** (`mcp.servers`): dos servidores remotos por OAuth:
  - `plane` → `https://mcp.plane.so/http/mcp`
  - `context7` → `https://mcp.context7.com/mcp/oauth`

El archivo solo referencia credenciales; no contiene tokens, estado OAuth ni
secretos.

## Requisitos previos

- OpenCode V2 instalado (`opencode --version`).
- Un endpoint compatible con OpenAI accesible en la URL configurada
  (`http://127.0.0.1:20131/v1` en este snapshot). Ajusta `providers.omniroute`
  si tu endpoint es distinto.
- Acceso de red a los servidores MCP de Plane y Context7.

## Instalación segura en otra máquina

1. Instala OpenCode V2.
2. Copia el snapshot a la ruta global:
   ```bash
   mkdir -p ~/.config/opencode
   cp opencode.global.json ~/.config/opencode/opencode.json
   ```
3. Crea el archivo de credencial **sin exponer el valor** en el historial de
   shell ni en el repositorio. Por ejemplo, escríbelo con un editor y permisos
   restringidos:
   ```bash
   install -m 600 /dev/null ~/.config/opencode/omniroute.key
   # edita el archivo y pega la clave como única línea, sin comillas
   ```
   La clave vive **solo** en `~/.config/opencode/omniroute.key`; nunca en este
   repo.
4. Copia las skills que quieras a la ruta global de skills:
   ```bash
   mkdir -p ~/.agents/skills
   cp -r skills/<nombre> ~/.agents/skills/
   ```
5. Autentica los servidores MCP remotos por OAuth (abre el navegador):
   ```bash
   opencode mcp auth plane
   opencode mcp auth context7
   ```
6. Verifica la instalación:
   ```bash
   opencode mcp list          # debe mostrar plane y context7 como connected
   opencode debug config      # muestra las fuentes de configuración
   opencode debug agents      # lista los agentes cargados
   ```

## Exclusiones explícitas (no copiar)

Este snapshot es deliberadamente parcial. **Nunca** copies ni versiones:

- Credenciales y estado OAuth: `auth.json`, `account.json`,
  `credentials.json`, `~/.local/share/opencode/`, tokens de MCP.
- `service.json` y cualquier secreto de servicio.
- Backups (`*.bak`, `snapshot/`).
- Bases de datos (`opencode.db`, `*.sqlite`, `*.db-wal`/`-shm`), logs y cachés.
- El valor de `omniroute.key` y cualquier clave privada o material criptográfico.

La instalación global de cada máquina sigue siendo la fuente de verdad; este
repo es solo una copia de referencia sanitizada.

## Reglas

- NUNCA apuntar `OPENCODE_CONFIG` / `OPENCODE_CONFIG_DIR` a este repo.
- NUNCA versionar secretos: solo referencias como `{file:...}`.
- Para actualizar: copia tu `~/.config/opencode/opencode.json` a
  `opencode.global.json` y verifica que no haya quedado ningún valor sensible.
