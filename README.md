# claude-code-setup — Configuración portable de Claude Code

Respaldo versionado de mi configuración global de Claude Code (instrucciones, settings,
permisos, hooks, skills, agents, rules, MCP, statusline y plugins), optimizada para ahorro
de tokens y respuestas de nivel profesional. Sirve para restaurar todo tras formatear el PC
o al migrar a otra máquina. Además, este repo **es un marketplace de plugins**
(`gaston-plugins`) con un plugin por stack.

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
| `global/CLAUDE.md` | Instrucciones globales (perfil, estándares, idioma, VCS por CLI, git) — se copia a `~/.claude/CLAUDE.md` |
| `global/settings.json` | Modelo, permisos pre-aprobados, deny-list (incluye `.env*`/secretos/llaves), hooks, statusline, plugins habilitados/deshabilitados |
| `global/rules/` | Reglas por lenguaje con `paths:` (ts, go, kotlin, dart) — solo cargan al tocar archivos de ese lenguaje |
| `global/hooks/` | `format-on-edit.sh` (autoformato al editar), `filter-test-output.sh` + `run-test-filtered.sh` (filtra salida de tests para ahorrar tokens) |
| `global/statusline.sh` | Statusline con % de contexto usado y % del límite de 5h (requiere `jq`) |
| `global/skills/` | Skills globales cross-stack: `architecture`, `ci-cd`, `databases`, `docker-kubernetes` |
| `global/agents/` | Subagente `docs-researcher` (investiga docs de librerías con haiku, en contexto aislado) |
| `global/mcp-servers.json` | Definición MCP de context7 con placeholder `${CONTEXT7_API_KEY}` |
| `.claude-plugin/marketplace.json` | Manifiesto del marketplace personal `gaston-plugins` |
| `plugins/` | Los 6 plugins de stack: `nestjs`, `go`, `android-kotlin`, `react-nextjs`, `flutter`, `react-native` |
| `plugins.txt` | Plugins a instalar (LSP oficiales + expo + los 6 de stack) |
| `secrets.env` | **Keys reales — gitignored, nunca se sube.** `install.sh` las inyecta en `~/.claude/settings.local.json` |
| `secrets.env.example` | Plantilla de secrets sin valores |
| `AGENT-INSTALL.md` | Guía paso a paso pensada para que un agente de IA ejecute la restauración |

## Marketplace personal (`gaston-plugins`)

Este repo es a la vez la fuente del marketplace. `install.sh` lo registra con
`claude plugin marketplace add <ruta-del-repo>` e instala los 6 plugins de stack
**deshabilitados por defecto** (`defaultEnabled: false` + `false` explícito en
`global/settings.json`). Así ninguna sesión paga el costo de contexto de un stack
que no está usando.

Cada plugin de stack incluye skills de arquitectura, testing y tooling del stack.
El de `flutter` además registra el **MCP oficial de Dart** (`dart mcp-server`,
requiere Dart SDK ≥ 3.9) y el **LSP de Dart** (`dart language-server`) — solo en
proyectos donde el plugin esté habilitado.

### Habilitar por proyecto

En el `.claude/settings.json` del proyecto (commitéalo en el repo del proyecto):

```json
{ "enabledPlugins": { "nestjs@gaston-plugins": true } }
```

Variante React Native (co-habilita el plugin oficial de Expo):

```json
{
  "enabledPlugins": {
    "react-native@gaston-plugins": true,
    "expo@claude-plugins-official": true
  }
}
```

Alternativa por CLI dentro del proyecto: `claude plugin enable nestjs@gaston-plugins --scope project`.

### Snippet por template repo (`~/Documents/Git/`)

| Template | `enabledPlugins` |
|---|---|
| NestJS | `"nestjs@gaston-plugins": true` |
| Go | `"go@gaston-plugins": true` |
| Android | `"android-kotlin@gaston-plugins": true` |
| Next.js | `"react-nextjs@gaston-plugins": true` |
| Flutter | `"flutter@gaston-plugins": true` |
| React Native | `"react-native@gaston-plugins": true` + `"expo@claude-plugins-official": true` |

### Publicar cambios en un plugin

1. Edita el plugin en `plugins/<name>/` y sube `version` en `.claude-plugin/marketplace.json` (y en su `plugin.json`).
2. `claude plugin marketplace update gaston-plugins`
3. `claude plugin update <name>@gaston-plugins`

Para iterar en desarrollo sin instalar: `claude --plugin-dir ./plugins/<name>` y `/reload-plugins`.

### Plugins oficiales opcionales (no instalados por defecto)

- `playwright@claude-plugins-official` — e2e con navegador para proyectos Next.js/RN web.
- `code-review@claude-plugins-official` — review de PRs con scoring.

## Mantenerlo al día

Cuando cambies algo en `~/.claude/` (skills, hooks, rules, settings, CLAUDE.md), re-sincroniza y commitea:

```bash
cp ~/.claude/CLAUDE.md ~/.claude/settings.json global/ 2>/dev/null
cp ~/.claude/statusline.sh global/ 2>/dev/null
cp -R ~/.claude/skills ~/.claude/agents ~/.claude/hooks ~/.claude/rules global/
git add -A && git commit -m "chore: sync claude config"
```

O simplemente dile a Claude Code: *"sincroniza ~/.claude con ~/Desktop/claude-code-setup y commitea"*.
Los plugins se editan directamente aquí (en `plugins/`), no en `~/.claude`.

> Nota: la config por proyecto (`.claude/` y `CLAUDE.md` de cada repo) NO vive aquí —
> viaja en el git de cada repositorio. Lo único que este repo aporta a los proyectos
> es el snippet `enabledPlugins` de arriba.
