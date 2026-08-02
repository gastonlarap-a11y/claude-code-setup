# claude-code-setup — Configuración portable de Claude Code

Respaldo versionado y **marketplace de plugins** (`dev-plugins`) de mi configuración
global de Claude Code. Objetivo: que cualquier sesión tenga el máximo contexto real con el
mínimo de tokens — conocimiento por stack/dominio que solo carga cuando se usa,
investigación automática de docs oficiales, guardrails deterministas, y un protocolo
(`/setup-project`) que configura o mejora CUALQUIER proyecto (nuevo, legacy sin config, o
con config existente que se preserva y afina) dejándolo auto-mejorable.

> **Regla de autoría (absoluta):** commits, PRs, MRs e issues llevan SOLO mi identidad.
> Nunca `Co-Authored-By`, nunca "Generated with", ninguna mención a IA. Definida en
> `global/CLAUDE.md` (Git conventions) y repetida en `AGENT-INSTALL.md`.

## Índice

1. [Qué contiene](#qué-contiene)
2. [Cómo funciona (el modelo de eficiencia)](#cómo-funciona)
3. [Comandos y skills disponibles](#comandos-y-skills-disponibles)
4. [Paso a paso: restaurar una máquina nueva](#restaurar-una-máquina-nueva)
5. [Paso a paso: configurar un proyecto (nuevo o existente)](#configurar-un-proyecto-nuevo-o-existente)
6. [Paso a paso: compartir este directorio con otra persona](#compartir-este-directorio-con-otra-persona)
7. [Paso a paso: resolver "cómo hago X"](#resolver-cómo-hago-x)
8. [Paso a paso: editar y publicar un plugin](#editar-y-publicar-un-plugin)
9. [Paso a paso: mantener el conocimiento al día](#mantener-el-conocimiento-al-día)
10. [Rendimiento: consejos oficiales](#rendimiento-consejos-oficiales)
11. [Novedades Claude Code 2026](#novedades-claude-code-2026)
12. [Verificación rápida](#verificación-rápida)

## Qué contiene

| Ruta | Qué es | Para qué me sirve |
|---|---|---|
| `global/CLAUDE.md` | Instrucciones globales → `~/.claude/CLAUDE.md` | Reglas siempre activas: español/inglés, nunca asumir, investigar proactivamente, VCS por CLI (gh / az devops), autoría limpia |
| `global/settings.json` | Settings → `~/.claude/settings.json` | Modelo + `fallbackModel`, idioma, `attribution` vacía (autoría limpia determinista), sandbox nativo (protege `~/.ssh`/`~/.aws` a nivel OS + allowlist de red estricta), ~54 permisos pre-aprobados (incluidos `Read`/`Edit`/`Write`/`MultiEdit`, para que editar no salga más caro que abrir una shell), deny-list (rm -rf, force push, `.env*`, secretos, llaves SSH, `.git/` y lockfiles), hooks, statusline, env (modelo de subagentes: Sonnet), qué plugins están activos |
| `global/rules/` | Reglas por lenguaje (`paths:`) → `~/.claude/rules/` | ts/go/kotlin/dart/java/csharp: cargan SOLO al tocar archivos de ese lenguaje |
| `global/hooks/` | Hooks → `~/.claude/hooks/` | `format-on-edit.sh` (autoformato), `filter-test-output.sh`+`run-test-filtered.sh` (solo fallos de tests al contexto — gran ahorro), `guard-shell-edit.sh` (bloquea reescribir archivos fuente vía shell: heredocs de python, `sed -i`, redirecciones — obliga a usar Edit/Write, que manda un diff en vez del archivo entero), `guard-git-push.sh` (bloquea push directo a main/master), `guard-git-add-all.sh` (bloquea staging masivo `-A`/`.`), `audit-config-change.sh` (auditoría de cambios de settings/skills → `~/.claude/config-audit.log`), `notify-os.sh` (notificaciones del SO, **opt-in** — snippet abajo). Los tres guards comparten `hooks/lib/agent-io.sh`, que detecta el dialecto del agente, así que el mismo script sirve a Claude Code, Codex y Antigravity (`install.sh` los registra en los tres). Todos con puerto PowerShell nativo (`.ps1`) que `install.ps1` cablea cuando no hay bash |
| `global/statusline.sh` / `.ps1` | Statusline → `~/.claude/` | Barra con % de contexto usado y % del límite 5h (la variante bash necesita `jq`; el puerto PowerShell no) |
| `global/skills/` | Skills globales → `~/.claude/skills/` | Cross-stack: `architecture`, `ci-cd`, `databases`, `docker-kubernetes` + **`research`** (auto-investigación), **`refresh-knowledge`** (automejora del recetario) y **`setup-project`** (configura/audita/mejora la config de cualquier proyecto) + **`azure-deploy`** (deploy a Azure Container Apps vía `/azure-deploy`) + **`harness`** (catálogo de todo lo invocable, vía `/harness`), **`post-merge-cleanup`** (limpieza verificada tras un merge) y **`github-new-repo`** (publicar un repo con protección estándar) |
| `global/agents/` | Subagentes → `~/.claude/agents/` | `docs-researcher` (sonnet): investiga docs en contexto aislado |
| `global/mcp-servers.json` | Definición MCP (data-driven) | Hoy vacío por decisión (sin servicios freemium): cualquier server que se añada aquí lo registran los installers a nivel usuario, resolviendo sus keys desde `secrets.env` |
| `.claude-plugin/marketplace.json` | Manifiesto del marketplace | Declara los 12 plugins con `defaultEnabled: false` |
| `plugins/` (stack) | `nestjs`, `go`, `android-kotlin`, `react-nextjs`, `flutter`, `react-native`, `dotnet` | Convenciones de arquitectura/testing/tooling por stack; flutter trae MCP oficial de Dart + LSP de Dart; los móviles traen `recipes`; dotnet trae EF Core + SQL Server local (OrbStack), Aspire, Azure y ruta de aprendizaje |
| `plugins/` (dominio) | `api-design`, `bots`, `realtime`, `background-jobs`, `ux` | Conocimiento por tipo de desarrollo: APIs (REST/GraphQL/gRPC/auth/webhooks), bots (Telegram/Discord/WhatsApp), realtime (WS/SSE/push), jobs (colas/outbox/cron), UX (estados de pantalla, accesibilidad, convenciones web/Android/móvil) — con `references/` que cargan solo si hacen falta |
| `plugins.txt` / `install.sh` / `install.ps1` | Instalador (bash y PowerShell nativo) | Idempotente: respalda lo que va a reemplazar (`~/.claude/.backup-<ts>`, últimos 3), copia config, poda huérfanos vía manifest, aplica `CLAUDE_LANGUAGE`, registra marketplace, instala plugins. `install.ps1` = Windows sin Git Bash |
| `.github/workflows/*.yml` + `scripts/check-*.sh` | CI del repo | En cada push: JSON lint, paridad de versiones (dual-bump) + sync de `enabledPlugins`, gate de bump olvidado (ramas), shellcheck, anclas de idioma, consistencia de modelo de subagentes, validación de esqueletos de plantillas, escaneo de secretos (gitleaks), lint de PowerShell y `claude plugin validate --strict`; y smoke real de los installers (Linux + Windows PowerShell 5.1) cuando cambian |
| `secrets.env(.example)` | Keys reales (gitignored) / plantilla | Hoy sin keys; cuando un server MCP declare una, los installers la inyectan directo en el registro a nivel usuario (`~/.claude.json`, jamás commiteado) |
| `START.md` | Bootstrap interactivo para agentes | Punto de entrada único: detecta el entorno, entrevista al usuario y enruta a la guía correcta (global, proyecto o ambos; owner o tercero; incluye Windows) |
| `AGENT-INSTALL.md` | Guía en inglés para agentes | Restauración de MI máquina (sobreescribe `~/.claude/`) + verificación |
| `AGENT-PROJECT-SETUP.md` | Guía en inglés para agentes | Configurar el proyecto de CUALQUIER persona usando este directorio, sin tocar su config global |
| `AGENTS.md` (raíz) | Contexto canónico de este repo (estándar cross-agente) | Orienta a cualquier agente abierto aquí: entradas, reglas de edición y versionado de plugins; lo leen también Codex/Cursor |
| `CLAUDE.md` (raíz) | Shim de Claude Code | Importa `@AGENTS.md` y añade solo el delta específico de Claude (pinning del modelo de subagentes) |

## Cómo funciona

El diseño sigue la regla oficial de costo de contexto:

1. **Siempre cargado (barato)**: `CLAUDE.md` (~37 líneas, con techo verificado en CI) + descripciones de skills de plugins habilitados. Nada más.
2. **Carga al tocar archivos**: `rules/` por lenguaje (`paths:`).
3. **Carga al usarse**: cuerpo de cada skill; sus `references/*.md` solo si el tema lo pide.
4. **Cero costo hasta invocar**: skills manuales (`/research`, `/refresh-knowledge`, `/nestjs:new-module`).
5. **Contexto aislado**: la investigación corre en el subagente `docs-researcher` — tu conversación no se ensucia con páginas de docs.
6. **Costo cero**: hooks (formateo, filtrado de tests) y guardrails de permisos.

Por eso **nada se habilita globalmente** — tampoco los LSP: una sesión de Go jamás paga las
skills de Flutter ni el language server de C#. Los 17 plugins se instalan apagados y cada
proyecto enciende los suyos en su `.claude/settings.json` (siguiente sección); `/setup-project`
hace ese mapeo. Detalle del instalador: `claude plugin install` enciende un plugin salvo que su
manifiesto declare `defaultEnabled: false` — los oficiales (LSP, expo) no lo hacen, así que
`install.sh` re-aplica el bloque `enabledPlugins` al terminar. Sin ese paso, los LSP volverían
a encenderse solos en cada instalación.

> **Modelo de subagentes:** `global/settings.json` fija `env.CLAUDE_CODE_SUBAGENT_MODEL: sonnet`
> — todos los subagentes (Explore/Plan/`docs-researcher`/…) corren en Sonnet heredando
> `effortLevel: high` en vez de Haiku, para resúmenes y reportes de mayor calidad. El env var
> tiene prioridad sobre el `model:` de cualquier agente; `ANTHROPIC_DEFAULT_HAIKU_MODEL` sube
> además el modelo rápido usado en compactaciones. `scripts/check-subagent-model.sh` evita que
> el frontmatter y el env var diverjan.

## Comandos y skills disponibles

Referencia completa de todo lo invocable que aporta este repo. Los pasos detallados
viven en las secciones "Paso a paso" enlazadas.

**Skills globales manuales** (se escriben en el prompt de Claude Code):

| Comando | Qué hace | Cuándo usarlo |
|---|---|---|
| `/harness [término]` | Muestra TODO lo que da esta config: cada skill y para qué sirve, los guards que corren solos, las rules por tipo de archivo, los plugins y qué se traslada a otros agentes. Se genera leyendo los archivos instalados, así que no puede quedar desactualizado. Con un término, filtra y muestra la descripción completa | Cuando no recuerdes qué tienes disponible o qué hace una pieza concreta. Fuera de cualquier agente: `bash ~/.claude/skills/harness/show.sh` |
| `/setup-project [foco]` | Protocolo completo: descubre el stack real, audita config existente, propone y genera `AGENTS.md`+`CLAUDE.md`, `.claude/` (rules/skills/settings), README, plugins, puentes multi-agente (Codex/Antigravity) y ofertas MCP — nada se escribe sin aprobar | Proyecto sin config de IA, config con drift (un comando documentado falla, una convención contradice el código), o re-auditoría tras cambios estructurales (`/setup-project audit`) |
| `/refresh-knowledge [alcance]` | Re-verifica el conocimiento curado (recipes/references + claims de versión del propio repo) contra docs oficiales, actualiza, sube versiones (dual-bump), republica y reporta coste de tokens (`plugin details`) | ~1 vez al mes, o cuando `research` marque drift; alcance opcional: un plugin o skill concreto |
| `/research <pregunta>` | Investiga la forma oficial ACTUAL de hacer algo (docs oficiales en la web) aislado en el subagente `docs-researcher`; vuelve con versión + snippet + fuente | Cualquier duda de API/versión de terceros — también se dispara sola por la regla global "research proactively" |
| `/azure-deploy` | Deploy de aplicaciones en contenedor a Azure Container Apps vía Azure CLI | Solo bajo orden explícita (side-effectful; nunca se auto-invoca) |

**Skills globales automáticas** (cero costo hasta que el tema aparece; no requieren comando):

| Skill | Se activa cuando |
|---|---|
| `architecture` | eliges estructura o patrones, arrancas/reestructuras un proyecto (su catálogo de principios lo usa `setup-project`) |
| `ci-cd` | creas o modificas workflows de GitHub Actions, pipelines o deploys |
| `databases` | diseñas esquemas, escribes migraciones o eliges datastore |
| `docker-kubernetes` | escribes o revisas Dockerfiles, compose o manifests de K8s |
| `research` | aparece superficie de terceros no cubierta por un skill ya cargado |
| `post-merge-cleanup` | confirmas que un PR se mergeó, o una rama local queda `[gone]`: verifica el merge de verdad antes de borrar nada, poda y arranca desde un `main` fresco |
| `github-new-repo` | publicas un repo local en GitHub: escaneo previo de secretos, email noreply, y el ruleset de protección de `main` |

**Skills de plugins** (requieren el plugin habilitado en el proyecto — ver mapeo más abajo):
`/nestjs:new-module` es el único manual (scaffolding de módulo NestJS). El resto de los
12 plugins son skills automáticas por tema: `architecture`/`testing`/`tooling` del stack
activo, `recipes` en los móviles, `auth`/`design`/`webhooks` (api-design), `patterns`
(realtime/background-jobs), `ux`.

**Installers** (solo máquinas del owner — [paso a paso](#restaurar-una-máquina-nueva)):

| Comando | Qué hace | Cuándo |
|---|---|---|
| `bash install.sh` / `.\install.ps1` | Restaura `~/.claude/` completo: backup previo (últimos 3), copia, poda huérfanos por manifest, MCP data-driven con secretos, marketplace y plugins; idempotente | Máquina nueva o para propagar cambios de `global/` |
| `--dry-run` / `-DryRun` | Preview de backup/copias/podas/idioma sin escribir nada | Antes de restaurar sobre una config existente |
| `CLAUDE_LANGUAGE=<idioma>` | Fija el idioma de respuesta en la copia instalada y lo persiste por máquina | Primera instalación cuando no se quiere español |

**Scripts de validación** (`scripts/` — CI los corre en cada push; útiles a mano antes de commitear):

| Script | Valida |
|---|---|
| `check-versions.sh` | dual-bump: paridad marketplace ↔ `plugin.json` ↔ `plugins.txt` ↔ `enabledPlugins` |
| `check-plugin-version-bump.sh` | en ramas: plugin tocado sin subir su versión → falla nombrándolo |
| `check-language-anchors.sh` | las anclas de idioma que reescriben los installers siguen en las fuentes |
| `check-subagent-model.sh` | frontmatter de `global/agents/` vs `CLAUDE_CODE_SUBAGENT_MODEL` |
| `check-templates.sh` | los esqueletos JSON/TOML de `setup-project` siguen siendo config válida |
| `check-context-budget.sh` | el techo de lo siempre-cargado: `global/CLAUDE.md` ≤ 45 líneas (aviso a 40) y cada `rules/*.md` ≤ 40 |
| `installer-smoke.sh` / `.ps1` | ejecución real de los installers: instalación fresca, idioma, poda, dry-run, ruta de fallo (y wiring `.ps1` en Windows) |

**Flujo de plugins** (resumen — [paso a paso](#editar-y-publicar-un-plugin)):
`claude plugin init <name>` (esqueleto) · `claude --plugin-dir ./plugins/<name>` (prueba
en caliente) + `/reload-skills` (iterar sin reiniciar) · `claude plugin validate
./plugins/<name> --strict` · `claude plugin marketplace update dev-plugins` ·
`claude plugin update <name>@dev-plugins` · `claude plugin details <name>` (coste de
tokens por componente).

## Restaurar una máquina nueva

**Opción A — con un agente de IA (recomendada), sirve para CUALQUIER máquina o persona:**
abre Claude Code en este directorio y dile:

> Lee START.md y configúrate.

El agente detecta el entorno (macOS/Linux/Windows, CLI, secrets), te entrevista solo por
lo que no puede detectar (¿owner o tercero? ¿global, proyecto o ambos? ¿máquina personal
o de empresa?) y ejecuta la ruta correcta: restauración global (`AGENT-INSTALL.md`),
configuración de proyectos (`AGENT-PROJECT-SETUP.md`), o ambas — sin tocar jamás el
`~/.claude` de un tercero. La entrevista incluye el **idioma de respuesta**
(`CLAUDE_LANGUAGE`, persistido por máquina — español por defecto) y, antes de sobrescribir,
el installer **respalda lo existente** en `~/.claude/.backup-<timestamp>` (últimos 3;
rollback y desinstalación documentados en `AGENT-INSTALL.md` → "Rollback & uninstall").

> **Windows**: ejecutar Claude Code ya NO requiere Git Bash (desde 2.1.120 usa PowerShell
> como shell tool si bash no está). Para restaurar la config tienes dos rutas: `install.ps1`
> nativo desde PowerShell, o `install.sh` desde Git Bash/WSL2. Los hooks y la statusline
> tienen puertos PowerShell nativos: sin Git for Windows, `install.ps1` cablea
> automáticamente las variantes `.ps1` — todo funciona igual.

**Opción B — manual:**

```bash
curl -fsSL https://claude.ai/install.sh | bash   # 1. CLI nativo, auto-actualizable (≥ 2.1.187)
                                                 #    Windows PowerShell: irm https://claude.ai/install.ps1 | iex
brew install jq        # 2. statusline — Windows: winget install jqlang.jq / Linux: apt install jq
cp secrets.env.example secrets.env               # 3. opcional — hoy no hay keys que rellenar
bash install.sh                                  # 4. restaura todo (CLAUDE_LANGUAGE=<idioma> opcional;
                                                 #    respalda lo previo en ~/.claude/.backup-*)
                                                 #    Windows nativo: .\install.ps1
                                                 #    Preview sin escribir: --dry-run / -DryRun
```

Luego abre una sesión nueva y pasa la [verificación rápida](#verificación-rápida).

**Hook opcional de notificaciones** (`notify-os.sh` se instala pero no se activa): para
recibir avisos del SO cuando Claude espera permiso o input, añade a `~/.claude/settings.json`:

```json
"Notification": [{ "matcher": "permission_prompt|idle_prompt", "hooks": [
  { "type": "command", "command": "bash \"$HOME/.claude/hooks/notify-os.sh\"" } ] }]
```

## Configurar un proyecto (nuevo o existente)

Un solo comando para los tres casos — abre Claude Code en el repo y corre:

```
/setup-project
```

| Caso | Qué hace el protocolo |
|---|---|
| **Proyecto nuevo** (recién inicializado) | Entrevista guiada paso a paso (propósito → stack → arquitectura → deploy/CI → testing), habilita los plugins que correspondan y genera `AGENTS.md` canónico (lo leen nativo Codex, Cursor y Antigravity) + `CLAUDE.md` delgado (`@AGENTS.md`) + `.claude/` mínimos que fijan la arquitectura desde la primera sesión |
| **Proyecto existente sin config de IA** | Deriva las convenciones DEL código real (módulos recientes, comandos verificados corriéndolos, CI) y las codifica en config token-lean adaptada a ese repo — nunca impone estilo ajeno |
| **Proyecto con config de IA previa** (CLAUDE.md, AGENTS.md, .cursorrules, .claude/…) | Audita: mantiene lo que sirve, afina lo impreciso, mueve lo mal ubicado (procedimientos → skills, estilo por lenguaje → rules con `paths:`, garantías → permisos/hooks) y muestra TODO cambio antes de aplicarlo — jamás descarta en silencio |

Reglas del protocolo (completo en `global/skills/setup-project/SKILL.md`): nada se escribe
sin aprobar la propuesta; todo comando documentado fue ejecutado; presupuestos de contexto
(archivo canónico raíz ≤ ~60 líneas — `AGENTS.md` en configs nuevas, multi-agente; los
proyectos con solo `CLAUDE.md` no se migran a la fuerza); y deja un bloque de
**auto-mantenimiento** en el `CLAUDE.md` del proyecto: tras cualquier tarea que cambie
estructura/comandos/convenciones — o si un comando documentado falla, una convención
contradice el código o corriges lo mismo dos veces — el agente propone el fix de config en
esa misma sesión. Re-correr `/setup-project` sobre un proyecto ya configurado = re-auditoría (solo
propone el delta). Además: **README obligatorio** al crear/configurar (actualización no
destructiva si ya existe); comandos consolidados en el **runner canónico del stack**
(package.json scripts, Makefile, Gradle, dotnet CLI); **set estándar de skills de
proyecto** (scaffold de la unidad de trabajo, verify, deploy, db-migration) derivado del
código Y del roadmap del repo; **preguntas batcheadas automáticas** tras el análisis
(OpenAPI/Swagger en backends HTTP, hook de formato si hay formatter, plugin LSP con chequeo
de compatibilidad, timing del skill de deploy); y bloque de **estándares de ingeniería**
(tests + verificación antes de declarar done) en el `CLAUDE.md` generado.

**Costo real**: la config siempre-cargada queda mínima (decenas de líneas); el conocimiento
pesado vive en plugins/skills/rules que cargan solo al usarse. El ahorro (cero vueltas en
falso, cero re-explicaciones, docs solo en subagente) supera el costo fijo por sesión.

Mapeo de plugins que aplica el protocolo (referencia, por si lo haces a mano):

| Tipo de proyecto | Habilita |
|---|---|
| API NestJS | `nestjs` + `api-design` (+ `background-jobs` si hay colas) |
| Servicio/CLI Go | `go` (+ `api-design`, `realtime` según toque) |
| App Android | `android-kotlin` + `ux` (+ `realtime` para push) |
| Web Next.js | `react-nextjs` + `ux` |
| App Flutter | `flutter` + `ux` (+ `realtime` para push) |
| App React Native | `react-native` + `expo@claude-plugins-official` + `ux` |
| API/Servicio .NET (C#) | `dotnet` + `api-design` (+ `background-jobs` si hay colas) |
| Bot (cualquier stack) | stack + `bots` (+ `background-jobs`) |
| Stack sin plugin (Python, Rust, …) | rules/skills locales generados por el protocolo (auto-suficientes) |

Manual: `.claude/settings.json` con `{ "enabledPlugins": { "nestjs@dev-plugins": true } }`
o `claude plugin enable <name>@dev-plugins --scope project`. Verifica con `/context`:
deben aparecer las skills del plugin habilitado y nada más.

## Compartir este directorio con otra persona

Para que alguien (cualquier stack, con o sin config previa en su proyecto) aproveche esto
sin heredar mi configuración personal:

1. Pásale el directorio (o el repo git).
2. En SU proyecto, abre Claude Code y le dice al agente:

   > Lee `<ruta-al-directorio>/AGENT-PROJECT-SETUP.md` y configura este proyecto.

3. El agente ejecuta el protocolo `setup-project`: detecta stack, preserva/mejora la config
   que el proyecto ya tenga, y opcionalmente registra el marketplace
   (`claude plugin marketplace add <ruta>`) para habilitar los plugins del stack.

Importante: **`install.sh` es solo para mis máquinas** — sobreescribe `~/.claude/` con mi
config personal (idioma, autoría, statusline). `AGENT-PROJECT-SETUP.md` lo advierte y los
agentes no deben sugerirlo a terceros. Las preferencias personales de cada quien van en su
propio `~/.claude/CLAUDE.md`, nunca en los archivos compartidos del proyecto.

### Editar este repo con otros agentes (Codex / Antigravity CLI)

`AGENTS.md` es el estándar cross-agent (Linux Foundation) y lo leen nativo tanto Codex
(+ `.codex/config.toml` al hacer `codex trust`) como Antigravity CLI — Claude Code lo toma
vía el `CLAUDE.md` delgado que lo importa. Los tres leen las skills del symlink
`.agents/skills → .claude/skills`, que es también la ubicación por defecto de Antigravity.
Gemini CLI dejó de servir cuentas individuales el 2026-06-18 y su sucesor no necesita el
antiguo bridge `.gemini/settings.json`. En Windows los symlinks de git
requieren Developer Mode (o admin); si el checkout lo dejó como archivo de texto,
recrearlo: `cmd /c mklink /D .agents\skills ..\.claude\skills` desde la raíz del repo.

## Resolver "cómo hago X"

Para "cómo abro un modal en Flutter", "cómo conecto la cámara", "cómo uso tal método":

1. **Si hay receta curada** (skills `recipes` de los plugins móviles, `references/` de dominio): Claude la usa directo — librería recomendada + patrón mínimo + fuente oficial.
2. **Si no hay receta o hay dudas de versión**: Claude dispara solo el skill `research` (regla global "research proactively"), que corre en el subagente `docs-researcher`: localiza la página oficial y trae SOLO la sección relevante, en inglés, y vuelve con versión + snippet + fuente. También puedes forzarlo: `/research how to persist auth session in expo router`.
3. **Nunca asume**: si tu pedido es ambiguo, pregunta antes de actuar (regla global).

## Editar y publicar un plugin

```bash
# 0. Plugin nuevo desde cero: claude plugin init <name> genera el esqueleto oficial
# 1. Edita plugins/<name>/... en este repo
# 2. Prueba en caliente sin instalar:
claude --plugin-dir ./plugins/<name>    # y /reload-plugins (o /reload-skills) al iterar
# 3. Sube version en .claude-plugin/marketplace.json Y plugins/<name>/.claude-plugin/plugin.json
# 4. Valida y publica:
claude plugin validate ./plugins/<name> --strict
claude plugin marketplace update dev-plugins
claude plugin update <name>@dev-plugins
# 5. Commit (Conventional, sin menciones de IA) y push — el CI repite la validación
```

> Ayuda de autoría: el plugin oficial `skill-creator` (repo `anthropics/skills`) scaffoldea
> y evalúa skills con la metodología oficial — `claude plugin marketplace add
> anthropics/skills` y luego `claude plugin install skill-creator`. Preferirlo a construir
> un meta-skill propio.

## Mantener el conocimiento al día

- **Automejora del recetario**: `/refresh-knowledge` (opcional: `/refresh-knowledge flutter`) re-verifica recipes y references contra docs oficiales estables, actualiza lo obsoleto, sube versiones, republica y commitea. Córrelo ~1 vez al mes o cuando `research` marque drift.
- **Sincronizar config global**: si cambias algo en `~/.claude/` directamente:

```bash
cp ~/.claude/CLAUDE.md ~/.claude/settings.json global/ 2>/dev/null
cp ~/.claude/statusline.sh global/ 2>/dev/null
cp -R ~/.claude/skills ~/.claude/agents ~/.claude/hooks ~/.claude/rules global/
git add global && git commit -m "chore: sync claude config"   # staging dirigido: el hook guard-git-add-all deniega add -A/.
```

- Los plugins se editan SIEMPRE aquí (en `plugins/`), nunca en `~/.claude`.
- Plugins oficiales opcionales (no instalados): `playwright@claude-plugins-official` (e2e navegador), `code-review@claude-plugins-official`, `security-guidance@claude-plugins-official` (revisa vulnerabilidades en los cambios mientras Claude trabaja).

## Rendimiento: consejos oficiales

El contexto es el recurso #1: el rendimiento del modelo degrada a medida que se llena.
Destilado de [best-practices](https://code.claude.com/docs/en/best-practices) y
[costs](https://code.claude.com/docs/en/costs) (verificado 2026-07):

- **`/clear` entre tareas no relacionadas** — la "sesión cajón de sastre" es el anti-patrón
  #1. Tras 2 correcciones fallidas sobre lo mismo: `/clear` y un prompt mejor con lo aprendido.
- **Da siempre una verificación ejecutable** (test, build, screenshot a comparar): Claude
  itera contra el check en vez de "parecer listo". Pide evidencia (output real), no afirmaciones.
- **Plan mode solo para lo complejo/incierto**; si el diff cabe en una frase, directo.
- **Subagentes para investigar** ("usa un subagente para investigar X"): la exploración se
  queda en otro contexto y solo vuelve el resumen. También como revisor adversarial del diff.
- **Prompts específicos**: archivos concretos (`@ruta`), criterios de aceptación, patrones a
  imitar. Lo vago dispara escaneos anchos que queman contexto.
- **Corrige temprano**: `Esc` para frenar, `Esc Esc`/`/rewind` para volver a un checkpoint.
- **`/usage`**: atribuye consumo a skills/subagentes/plugins/MCP — retira lo que no se usa.
- **Effort por tarea**: `/effort` bajo para lo simple; keyword `ultrathink` en el prompt para
  razonamiento puntual sin cambiar la sesión.
- **`/btw`** para preguntas laterales sin ensuciar el historial; **`/rename`** + `--resume`
  para retomar sesiones largas como ramas.
- **Permisos sin fricción**: allowlist de comandos rutinarios (ya en `global/settings.json`)
  o modo `auto` (clasificador aprueba lo seguro) para tareas confiables.

## Novedades Claude Code 2026

Verificado 2026-07 contra el [changelog](https://code.claude.com/docs/en/changelog) y
[what's new](https://code.claude.com/docs/en/whats-new) oficiales — `/refresh-knowledge`
mantiene esta lista al día:

- **Sandbox nativo de Bash** ([`/sandbox`](https://code.claude.com/docs/en/sandboxing)): aislamiento
  de archivos/red a nivel OS. Ya activo en `global/settings.json`: `sandbox.credentials` bloquea
  `~/.ssh`/`~/.aws` para subprocesos; `sandbox.network` con `strictAllowlist` (≥ 2.1.219) deniega
  en silencio el egress a hosts fuera de la allowlist (registries npm/Go/pub.dev/Maven/NuGet +
  GitHub) — en CLIs anteriores degrada a prompts; `docker`/`gh`/`kubectl` van excluidos
  (caen al flujo normal de permisos, no al proxy de red). macOS/Linux/WSL2; en Windows nativo
  no aplica (warning esperado).
- **Auto mode** (ya en plan Pro): un clasificador reemplaza los prompts de permiso — lo seguro corre,
  lo destructivo se bloquea. Complementa (no reemplaza) la allowlist.
- **`/code-review`**: bugs de corrección a nivel de esfuerzo elegido; `--fix` aplica, `--comment`
  comenta el PR, `ultra` = revisión multi-agente en la nube.
- **Observabilidad**: `/usage` (consumo por skill/subagente/plugin/MCP), `/doctor` (diagnóstico de
  config), `/cd` (cambiar de directorio sin perder caché), `--safe-mode` (arrancar sin customizaciones).
- **Modelos**: familia Claude 5 — Opus 5 con contexto de 1M (`opus[1m]`, el modelo primario en
  `global/settings.json`), Fable 5 (alias `fable`, tier Mythos), Opus 5 (`claude-opus-5`, default de Claude Code desde 2.1.219;
  `claude-opus-4-8` queda como linaje Bedrock/Vertex) y Sonnet 5 (contexto 1M). `/effort xhigh`,
  fast mode 2x costo / 2.5x velocidad. `fallbackModel` (hasta 3 en cadena) ya configurado aquí:
  `claude-opus-5` → `claude-sonnet-5`.
- **Skills/plugins**: `/reload-skills` sin reiniciar; skills de proyecto en `.claude/skills/` cargan
  sin marketplace (≥ 2.1.157); `claude plugin init` para scaffolding; `disallowed-tools` en frontmatter.
- **MCP tool search**: los esquemas de herramientas MCP se difieren por defecto (cargan solo los
  nombres; el schema completo llega al usarse) — añadir servidores MCP ya casi no cuesta contexto
  inicial; `claude plugin details <name>` reporta el coste real por componente.
- **Windows**: desde 2.1.120 no requiere Git Bash (usa PowerShell tool); instalador nativo recomendado.
- **Equipo/nube**: `/team-onboarding` (empaqueta tu setup como guía replicable), Routines (agentes
  cloud programados desde la web), `claude agents` (vista de todas las sesiones).

## Verificación rápida

```bash
claude mcp list                      # sin servers globales (mcp-servers.json hoy vacío)
claude plugin marketplace list      # dev-plugins
claude plugin list                   # los 17 instalados y TODOS disabled (se habilitan por proyecto)
```

En una sesión nueva: statusline visible con % de contexto · `/context` sin skills de stack
(en un dir neutro) · leer un `.go` carga `rules/go.md` · pedir leer `.env` → denegado ·
`/research <pregunta>` responde con versión + fuente · `/setup-project` y `/harness` aparecen
en el menú `/` · `/sandbox` muestra la config resuelta (macOS/Linux/WSL2) · pedir `git push`
estando en `main` → denegado por `guard-git-push.sh` · pedir `git add -A` → denegado por
`guard-git-add-all.sh` · pedir escribir un `.ts` con un heredoc de `python3` o un `sed -i` →
denegado por `guard-shell-edit.sh` (el mismo comando apuntando a `$TMPDIR` o `dist/` pasa) ·
editar `~/.claude/settings.json` desde fuera durante una sesión → línea nueva en
`~/.claude/config-audit.log`.

`/harness` es el atajo para ver todo lo anterior sin memorizarlo: lista cada skill con para
qué sirve, los guards activos, las rules por tipo de archivo y los plugins. Se genera leyendo
los archivos instalados, así que si algo no aparece ahí, no está instalado.

> Nota: la config por proyecto (`.claude/` y `CLAUDE.md` de cada repo) NO vive aquí —
> viaja en el git de cada repositorio. Este repo aporta el protocolo que la genera y
> audita (`/setup-project`) y los plugins que habilita.
