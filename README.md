# opencode-config

Configuraciones globales de OpenCode V2 y Codex CLI, listas para instalar
manualmente y sin credenciales. Elige el cliente que quieras usar:

- [Configurar OpenCode](#configurar-opencode): usa OmniRoute como proveedor.
- [Acceso móvil y revisión grabada en Windows + WSL](docs/revision-movil-wsl.md): retoma OpenCode y prueba una app desde Android sin perder la captura.
- [Configurar Codex CLI](#configurar-codex-cli): usa OpenAI directamente con tu cuenta de ChatGPT.
- [Instalar las skills compartidas](#instalar-las-skills-compartidas): sirve para cualquiera de los dos, sin instalar el otro.

Ejecuta los comandos de copia desde la raíz del repositorio. No apuntes
`OPENCODE_CONFIG`, `OPENCODE_CONFIG_DIR` ni `CODEX_HOME` al checkout: las
credenciales y el estado local deben quedar fuera de Git.

## Configurar OpenCode

Necesitas [OpenCode V2](https://opencode.ai/docs/) y una instancia de OmniRoute
con acceso a los modelos `cx/gpt-6.2-sol-high` y `cx/gpt-6.2-sol-medium`.

1. Copia `opencode.global.json` a `~/.config/opencode/opencode.json`. Si ya
   tienes un `opencode.json` o `opencode.jsonc` en esa carpeta, integra los
   ajustes del snapshot en el archivo existente en vez de crear otro o
   reemplazarlo. Para una instalación nueva:

   ```bash
   opencode_dir="$HOME/.config/opencode"
   if [ -e "$opencode_dir/opencode.json" ] || [ -L "$opencode_dir/opencode.json" ] ||
      [ -e "$opencode_dir/opencode.jsonc" ] || [ -L "$opencode_dir/opencode.jsonc" ]; then
     printf '%s\n' 'Ya hay una configuración de OpenCode; integra el snapshot a mano.'
   else
     mkdir -p "$opencode_dir" &&
       (set -C; cat < opencode.global.json > "$opencode_dir/opencode.json")
   fi
   ```

2. En tu configuración instalada, deja `providers.omniroute` apuntando a
   `http://127.0.0.1:20131/v1` o ajusta la URL a la de tu instancia. Guarda la
   clave de OmniRoute en `~/.config/opencode/omniroute.key`, en una sola línea
   y sin comillas, con permisos `600`. No pongas la clave en el JSON ni en Git.
3. [Instala las skills compartidas](#instalar-las-skills-compartidas).
4. Si quieres usar los MCP incluidos, autentica los que necesites. Configura
   `"disabled": true` en cada entrada de `mcp.servers` que no vayas a usar.

   ```bash
   opencode mcp auth context7
   opencode mcp auth plane-ottcomputer
   opencode mcp auth gitea-ottcomputer
   ```

5. Verifica que OpenCode cargue la configuración y los agentes del snapshot:

   ```bash
   opencode debug config
   opencode debug agents
   opencode mcp list
   ```

   `build` es el agente predeterminado. `build`, `plan` y `reviewer` usan
   Sol High; `general`, `explore` y `title` usan Sol Medium.

## Configurar Codex CLI

Necesitas [Codex CLI](https://github.com/openai/codex#installing-and-running-codex-cli)
(configuración validada con 0.171.0) y una cuenta de ChatGPT con acceso a
GPT‑6.2 Sol. En Linux, comprueba los [requisitos del sandbox](https://learn.chatgpt.com/docs/sandboxing#prerequisites).
No necesitas OpenCode, OmniRoute ni una clave de API de OpenAI.

1. Instala los archivos de `codex/` en `~/.codex/`. Si ya usas un `CODEX_HOME`
   personalizado, usa ese directorio en su lugar y mantén la variable definida
   al ejecutar Codex. Conserva tus archivos existentes: si hay coincidencias,
   integra `config.toml`, `AGENTS.md` y los roles correspondientes a mano.
   Estos comandos copian solo los archivos que no existen:

   ```bash
   codex_dir=${CODEX_HOME:-"$HOME/.codex"}
   mkdir -p "$codex_dir/agents" &&
   for src in codex/config.toml codex/AGENTS.md codex/agents/*.toml; do
     dest="$codex_dir/${src#codex/}"
     if [ -e "$dest" ] || [ -L "$dest" ]; then
       printf 'Conservado: %s\n' "$dest"
     else
       (set -C; cat < "$src" > "$dest") || break
     fi
   done
   ```

2. [Instala las skills compartidas](#instalar-las-skills-compartidas).
3. Inicia sesión con ChatGPT y abre Codex desde tu proyecto:

   ```bash
   codex login
   codex login status
   codex --strict-config
   ```

   Si ya iniciaste sesión con ChatGPT en ese perfil, no necesitas repetir el
   login. En Codex, `/status` muestra el modelo y los permisos de la sesión;
   `/skills` muestra las skills disponibles y `/mcp`, las herramientas MCP.

La sesión principal, `/plan` y `reviewer` usan **Sol High**; `explore` y
`general` usan **Sol Medium**. Los subagentes heredan el sandbox y la política
de aprobación de la sesión. Para una revisión sin escrituras, usa una sesión
con `codex --sandbox read-only --ask-for-approval never` y sin MCP activos.

**MCP opcional:** Context7 viene desactivado. Para usarlo, cambia `enabled` a
`true` en la sección `[mcp_servers.context7]` de tu `config.toml` instalado,
ejecuta `codex mcp login context7` y comprueba la conexión con `codex mcp list`.
Esta configuración no incluye Plane ni Gitea.

## Instalar las skills compartidas

Ambos clientes leen `~/.agents/skills/`. Instálalas una sola vez. Los comandos
copian cada directorio completo, incluidos sus archivos de apoyo, sin
sobrescribir skills instaladas. Si ya tienes una skill con el mismo nombre,
revisa las diferencias antes de actualizarla.

```bash
mkdir -p "$HOME/.agents/skills" &&
for src in skills/*/; do
  name=${src%/}
  dest="$HOME/.agents/skills/${name##*/}"
  if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
    cp -R "$src" "$dest" || break
  fi
done
```

Cada `skills/<nombre>/SKILL.md` describe cuándo usarla y qué herramientas
necesita. Las que dependen de servicios externos, como Plane, requieren que
configures ese servicio en el cliente que vayas a usar.

## Actualizar el snapshot

Versiona solo configuraciones sanitizadas e instrucciones. No copies
`auth.json`, tokens MCP, `omniroute.key`, claves privadas, logs, bases de datos
ni historial de sesión. Conserva referencias a credenciales (por ejemplo,
`{file:...}`) en vez de sus valores.
