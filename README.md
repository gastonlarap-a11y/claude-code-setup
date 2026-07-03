# claude-code-setup — Configuración portable de Claude Code

Respaldo versionado de mi configuración global de Claude Code (instrucciones, settings,
permisos, hooks, skills, agents, MCP y plugins), optimizada para ahorro de tokens y
respuestas de nivel profesional. Sirve para restaurar todo tras formatear el PC o al
migrar a otra máquina.

## Restaurar en una máquina nueva

**Opción A — con un agente de IA (recomendada):** abre Claude Code en este directorio y dile:

> Lee AGENT-INSTALL.md y aplica toda la configuración de este directorio.

**Opción B — manual:**

```bash
# 1. Instala Claude Code si no está
npm install -g @anthropic-ai/claude-code

# 2. Si vienes de un backup sin secrets.env, créalo primero:
cp secrets.env.example secrets.env   # y rellena las keys reales

# 3. Restaura todo
bash install.sh
```

## Qué contiene

| Ruta | Qué es |
|---|---|
| `global/CLAUDE.md` | Instrucciones globales (perfil, estándares, idioma, git) — se copia a `~/.claude/CLAUDE.md` |
| `global/settings.json` | Modelo, permisos pre-aprobados, deny-list, hooks, plugins habilitados |
| `global/hooks/` | `format-on-edit.sh` (autoformato al editar), `filter-test-output.sh` + `run-test-filtered.sh` (filtra salida de tests para ahorrar tokens) |
| `global/skills/` | Skills bajo demanda: `architecture`, `ci-cd`, `databases`, `docker-kubernetes` |
| `global/agents/` | Subagente `docs-researcher` (investiga docs de librerías con haiku, en contexto aislado) |
| `global/mcp-servers.json` | Definición MCP de context7 con placeholder `${CONTEXT7_API_KEY}` |
| `plugins.txt` | Plugins a reinstalar del marketplace oficial (LSP de TypeScript, Go y Kotlin) |
| `secrets.env` | **Keys reales — gitignored, nunca se sube.** `install.sh` las inyecta en `~/.claude/settings.local.json` |
| `secrets.env.example` | Plantilla de secrets sin valores |
| `AGENT-INSTALL.md` | Guía paso a paso pensada para que un agente de IA ejecute la restauración |

## Mantenerlo al día

Cuando cambies algo en `~/.claude/` (skills, hooks, settings, CLAUDE.md), re-sincroniza y commitea:

```bash
cp ~/.claude/CLAUDE.md ~/.claude/settings.json global/ 2>/dev/null
cp -R ~/.claude/skills ~/.claude/agents ~/.claude/hooks global/
git add -A && git commit -m "chore: sync claude config"
```

O simplemente dile a Claude Code: *"sincroniza ~/.claude con ~/Desktop/claude-code-setup y commitea"*.

> Nota: la config por proyecto (`.claude/` y `CLAUDE.md` de cada repo) NO vive aquí —
> viaja en el git de cada repositorio.
