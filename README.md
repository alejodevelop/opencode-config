# opencode-config

Copia de referencia de la configuracion de OpenCode.

**Este repo NO se carga automaticamente.** La fuente de verdad es
~/.config/opencode/opencode.json (la instalacion global en cada PC).

## Contenido

| Archivo / directorio | Que es |
|---|---|
| opencode.global.json | Snapshot sanitizado de la config global (secretos como {env:...}) |
| .env.example | Variables de entorno requeridas (nombres, sin valores) |
| agents/ | Subagentes (memory-curator, memory-recall) |
| commands/ | Comandos (sync-memory, remember-feature, recall-feature, review-memory) |
| skills/ | Skills reutilizables |
| opencode-memory-kit/ | Scripts y plantillas del kit de memoria |

## Configurar otra PC

1. Copia opencode.global.json como ~/.config/opencode/opencode.json
2. Define las variables de .env.example en tu entorno
3. opencode auth login + opencode mcp auth
4. opencode debug config para verificar
5. Abre OpenCode

Copia los commands/, agents/, skills/ y opencode-memory-kit/
que necesites a ~/.config/opencode/ (o a ~/.agents/skills/ para skills).

## Reglas

- NUNCA apuntar OPENCODE_CONFIG / OPENCODE_CONFIG_DIR a este repo
- NUNCA versionar secretos
- Para actualizar: copia tu global actual a opencode.global.json, reemplaza secretos por placeholders
