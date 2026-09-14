# opencode-config

Copia portable de la configuración declarativa de OpenCode. Sin secretos, sin estado, sin cachés.

## Arquitectura

- `opencode.json`: configuración principal. Credenciales solo como `{env:NOMBRE}`.
- `agents/`: subagentes (`memory-curator`, `memory-recall`).
- `commands/`: comandos (`sync-memory`, `remember-feature`, `recall-feature`, `review-memory`).
- `skills/`: skills externas para que `OPENCODE_CONFIG_DIR` las descubra.
- `opencode-memory-kit/scripts/`: `bootstrap-project` y `doctor` (`.ps1`/`.sh`).
- `opencode-memory-kit/templates/`: plantillas de `docs/ai-memory` y bloque `AGENTS.md`.
- `package.json`: fija `@opencode-ai/plugin` (requerido por la config portada).
- `.env.example`: nombres de variables secretas, sin valores.
- `scripts/check-portable.ps1`: chequeo de portabilidad (sin dependencias nuevas).

Variables secretas requeridas (solo nombres): `CONTEXT7_API_KEY`, `STITCH_API_KEY`, `NINEROUTER_API_KEY`.

Requisitos locales: Node + `npx` (servidores MCP `stitch`, `playwright`); endpoints `http://127.0.0.1:20128/v1` (provider local) y `https://mcp.plane.so/http/mcp`, `https://mcp.context7.com/mcp` (remotos).

## Backup / update

Desde la máquina de origen, copiar solo lo declarativo (`opencode.json`, `agents/`, `commands/`, `opencode-memory-kit/scripts`, `opencode-memory-kit/templates`, `skills/`, `package.json` si aplica). Nunca copiar `node_modules`, locks no versionados, `install-manifest.tsv`, manifiestos de skills, cachés, DB (`*.db*`), logs, auth (`auth.json`, `mcp-auth/`), `.env*` con valores, sesiones ni estado.

## Restauración Windows (PowerShell)

```powershell
git clone <repo-url> C:\ruta\opencode-config
$env:OPENCODE_CONFIG = "C:\ruta\opencode-config\opencode.json"
$env:OPENCODE_CONFIG_DIR = "C:\ruta\opencode-config"
# Define CONTEXT7_API_KEY, STITCH_API_KEY, NINEROUTER_API_KEY en tu entorno
opencode auth login
opencode mcp auth
opencode debug config
# Reinicia OpenCode
```

## Restauración Linux / macOS / WSL

```sh
git clone <repo-url> ~/opencode-config
export OPENCODE_CONFIG="$HOME/opencode-config/opencode.json"
export OPENCODE_CONFIG_DIR="$HOME/opencode-config"
# Define CONTEXT7_API_KEY, STITCH_API_KEY, NINEROUTER_API_KEY en tu entorno
opencode auth login
opencode mcp auth
opencode debug config
# Reinicia OpenCode
```

## Notas

- `OPENCODE_CONFIG` debe apuntar a `<checkout>/opencode.json`; `OPENCODE_CONFIG_DIR` a `<checkout>`.
- Las sesiones no se incluyen; exportarlas aparte con `opencode export --sanitize` cuando aplique.
