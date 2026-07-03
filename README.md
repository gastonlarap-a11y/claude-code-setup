# claude-code-setup — Configuración portable de Claude Code

Respaldo versionado y **marketplace de plugins** (`gaston-plugins`) de mi configuración
global de Claude Code. Objetivo: que cualquier sesión tenga el máximo contexto real con el
mínimo de tokens — conocimiento por stack/dominio que solo carga cuando se usa,
investigación automática de docs oficiales, y guardrails deterministas.

> **Regla de autoría (absoluta):** commits, PRs, MRs e issues llevan SOLO mi identidad.
> Nunca `Co-Authored-By`, nunca "Generated with", ninguna mención a IA. Definida en
> `global/CLAUDE.md` (Git conventions) y repetida en `AGENT-INSTALL.md`.

## Índice

1. [Qué contiene](#qué-contiene)
2. [Cómo funciona (el modelo de eficiencia)](#cómo-funciona)
3. [Paso a paso: restaurar una máquina nueva](#restaurar-una-máquina-nueva)
4. [Paso a paso: empezar un proyecto](#empezar-un-proyecto)
5. [Paso a paso: resolver "cómo hago X"](#resolver-cómo-hago-x)
6. [Paso a paso: editar y publicar un plugin](#editar-y-publicar-un-plugin)
7. [Paso a paso: mantener el conocimiento al día](#mantener-el-conocimiento-al-día)
8. [Verificación rápida](#verificación-rápida)

## Qué contiene

| Ruta | Qué es | Para qué me sirve |
|---|---|---|
| `global/CLAUDE.md` | Instrucciones globales → `~/.claude/CLAUDE.md` | Reglas siempre activas: español/inglés, nunca asumir, investigar proactivamente, VCS por CLI (gh / az devops), autoría limpia |
| `global/settings.json` | Settings → `~/.claude/settings.json` | Modelo, ~45 permisos pre-aprobados, deny-list (rm -rf, force push, `.env*`, secretos, llaves SSH), hooks, statusline, qué plugins están activos |
| `global/rules/` | Reglas por lenguaje (`paths:`) → `~/.claude/rules/` | ts/go/kotlin/dart: cargan SOLO al tocar archivos de ese lenguaje |
| `global/hooks/` | Hooks → `~/.claude/hooks/` | `format-on-edit.sh` (autoformato), `filter-test-output.sh`+`run-test-filtered.sh` (solo fallos de tests al contexto — gran ahorro) |
| `global/statusline.sh` | Statusline → `~/.claude/statusline.sh` | Barra con % de contexto usado y % del límite 5h (necesita `jq`) |
| `global/skills/` | Skills globales → `~/.claude/skills/` | Cross-stack: `architecture`, `ci-cd`, `databases`, `docker-kubernetes` + **`research`** (auto-investigación) y **`refresh-knowledge`** (automejora) |
| `global/agents/` | Subagentes → `~/.claude/agents/` | `docs-researcher` (haiku): investiga docs en contexto aislado |
| `global/mcp-servers.json` | Definición MCP | context7 (docs de librerías), key vía `secrets.env` |
| `.claude-plugin/marketplace.json` | Manifiesto del marketplace | Declara los 10 plugins con `defaultEnabled: false` |
| `plugins/` (stack) | `nestjs`, `go`, `android-kotlin`, `react-nextjs`, `flutter`, `react-native` | Convenciones de arquitectura/testing/tooling por stack; flutter trae MCP oficial de Dart + LSP de Dart; los móviles traen `recipes` (cámara, permisos, notificaciones, deep links, modales) |
| `plugins/` (dominio) | `api-design`, `bots`, `realtime`, `background-jobs` | Conocimiento por tipo de desarrollo: APIs (REST/GraphQL/gRPC/auth/webhooks), bots (Telegram/Discord/WhatsApp), realtime (WS/SSE/push), jobs (colas/outbox/cron) — con `references/` que cargan solo si hacen falta |
| `plugins.txt` / `install.sh` | Instalador | Idempotente: copia config, registra marketplace, instala plugins |
| `secrets.env(.example)` | Keys reales (gitignored) / plantilla | `install.sh` las inyecta en `~/.claude/settings.local.json` |
| `AGENT-INSTALL.md` | Guía en inglés para agentes | Restauración automatizada + verificación |

## Cómo funciona

El diseño sigue la regla oficial de costo de contexto:

1. **Siempre cargado (barato)**: `CLAUDE.md` (~35 líneas) + descripciones de skills de plugins habilitados. Nada más.
2. **Carga al tocar archivos**: `rules/` por lenguaje (`paths:`).
3. **Carga al usarse**: cuerpo de cada skill; sus `references/*.md` solo si el tema lo pide.
4. **Cero costo hasta invocar**: skills manuales (`/research`, `/refresh-knowledge`, `/nestjs:new-module`).
5. **Contexto aislado**: la investigación corre en el subagente `docs-researcher` — tu conversación no se ensucia con páginas de docs.
6. **Costo cero**: hooks (formateo, filtrado de tests) y guardrails de permisos.

Por eso los plugins van **deshabilitados por defecto**: una sesión de Go jamás paga las
skills de Flutter. Cada proyecto habilita lo suyo (siguiente sección).

## Restaurar una máquina nueva

**Opción A — con un agente de IA (recomendada):** abre Claude Code en este directorio y dile:

> Lee AGENT-INSTALL.md y aplica toda la configuración de este directorio.

**Opción B — manual:**

```bash
npm install -g @anthropic-ai/claude-code   # 1. CLI (≥ 2.1.154)
brew install jq                            # 2. statusline
cp secrets.env.example secrets.env         # 3. rellena las keys reales
bash install.sh                            # 4. restaura todo
```

Luego abre una sesión nueva y pasa la [verificación rápida](#verificación-rápida).

## Empezar un proyecto

1. Crea el repo desde tu template (`~/Documents/Git/template-*`) o desde cero.
2. Habilita los plugins del proyecto en su `.claude/settings.json` (commitéalo):

```json
{ "enabledPlugins": { "nestjs@gaston-plugins": true, "api-design@gaston-plugins": true } }
```

| Tipo de proyecto | Habilita |
|---|---|
| API NestJS | `nestjs` + `api-design` (+ `background-jobs` si hay colas) |
| Servicio/CLI Go | `go` (+ `api-design`, `realtime` según toque) |
| App Android | `android-kotlin` (+ `realtime` para push) |
| Web Next.js | `react-nextjs` |
| App Flutter | `flutter` (+ `realtime` para push) |
| App React Native | `react-native` + `expo@claude-plugins-official` |
| Bot (cualquier stack) | stack + `bots` (+ `background-jobs`) |

Alternativa CLI: `claude plugin enable <name>@gaston-plugins --scope project`.

3. Abre la sesión: `/context` debe mostrar las skills del plugin habilitado y nada más.

## Resolver "cómo hago X"

Para "cómo abro un modal en Flutter", "cómo conecto la cámara", "cómo uso tal método":

1. **Si hay receta curada** (skills `recipes` de los plugins móviles, `references/` de dominio): Claude la usa directo — librería recomendada + patrón mínimo + fuente oficial.
2. **Si no hay receta o hay dudas de versión**: Claude dispara solo el skill `research` (regla global "research proactively"), que corre en el subagente `docs-researcher`: context7 → docs oficiales, SOLO la sección relevante, en inglés, y vuelve con versión + snippet + fuente. También puedes forzarlo: `/research how to persist auth session in expo router`.
3. **Nunca asume**: si tu pedido es ambiguo, pregunta antes de actuar (regla global).

## Editar y publicar un plugin

```bash
# 1. Edita plugins/<name>/... en este repo
# 2. Prueba en caliente sin instalar:
claude --plugin-dir ./plugins/<name>    # y /reload-plugins al iterar
# 3. Sube version en .claude-plugin/marketplace.json Y plugins/<name>/.claude-plugin/plugin.json
# 4. Publica:
claude plugin marketplace update gaston-plugins
claude plugin update <name>@gaston-plugins
# 5. Commit (Conventional, sin menciones de IA) y push
```

## Mantener el conocimiento al día

- **Automejora del recetario**: `/refresh-knowledge` (opcional: `/refresh-knowledge flutter`) re-verifica recipes y references contra docs oficiales estables, actualiza lo obsoleto, sube versiones, republica y commitea. Córrelo ~1 vez al mes o cuando `research` marque drift.
- **Sincronizar config global**: si cambias algo en `~/.claude/` directamente:

```bash
cp ~/.claude/CLAUDE.md ~/.claude/settings.json global/ 2>/dev/null
cp ~/.claude/statusline.sh global/ 2>/dev/null
cp -R ~/.claude/skills ~/.claude/agents ~/.claude/hooks ~/.claude/rules global/
git add -A && git commit -m "chore: sync claude config"
```

- Los plugins se editan SIEMPRE aquí (en `plugins/`), nunca en `~/.claude`.
- Plugins oficiales opcionales (no instalados): `playwright@claude-plugins-official` (e2e navegador), `code-review@claude-plugins-official`.

## Verificación rápida

```bash
claude mcp list                      # context7 conectado
claude plugin marketplace list      # gaston-plugins
claude plugin list                   # 3 LSP enabled; 10 stack/dominio + expo disabled
```

En una sesión nueva: statusline visible con % de contexto · `/context` sin skills de stack
(en un dir neutro) · leer un `.go` carga `rules/go.md` · pedir leer `.env` → denegado ·
`/research <pregunta>` responde con versión + fuente.

> Nota: la config por proyecto (`.claude/` y `CLAUDE.md` de cada repo) NO vive aquí —
> viaja en el git de cada repositorio. Este repo solo aporta el snippet `enabledPlugins`.
