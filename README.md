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
3. [Paso a paso: restaurar una máquina nueva](#restaurar-una-máquina-nueva)
4. [Paso a paso: configurar un proyecto (nuevo o existente)](#configurar-un-proyecto-nuevo-o-existente)
5. [Paso a paso: compartir este directorio con otra persona](#compartir-este-directorio-con-otra-persona)
6. [Paso a paso: resolver "cómo hago X"](#resolver-cómo-hago-x)
7. [Paso a paso: editar y publicar un plugin](#editar-y-publicar-un-plugin)
8. [Paso a paso: mantener el conocimiento al día](#mantener-el-conocimiento-al-día)
9. [Rendimiento: consejos oficiales](#rendimiento-consejos-oficiales)
10. [Novedades Claude Code 2026](#novedades-claude-code-2026)
11. [Verificación rápida](#verificación-rápida)

## Qué contiene

| Ruta | Qué es | Para qué me sirve |
|---|---|---|
| `global/CLAUDE.md` | Instrucciones globales → `~/.claude/CLAUDE.md` | Reglas siempre activas: español/inglés, nunca asumir, investigar proactivamente, VCS por CLI (gh / az devops), autoría limpia |
| `global/settings.json` | Settings → `~/.claude/settings.json` | Modelo + `fallbackModel`, idioma, `attribution` vacía (autoría limpia determinista), sandbox nativo (protege `~/.ssh`/`~/.aws` a nivel OS), ~50 permisos pre-aprobados, deny-list (rm -rf, force push, `.env*`, secretos, llaves SSH), hooks, statusline, qué plugins están activos |
| `global/rules/` | Reglas por lenguaje (`paths:`) → `~/.claude/rules/` | ts/go/kotlin/dart: cargan SOLO al tocar archivos de ese lenguaje |
| `global/hooks/` | Hooks → `~/.claude/hooks/` | `format-on-edit.sh` (autoformato), `filter-test-output.sh`+`run-test-filtered.sh` (solo fallos de tests al contexto — gran ahorro), `guard-git-push.sh` (bloquea push directo a main/master) |
| `global/statusline.sh` | Statusline → `~/.claude/statusline.sh` | Barra con % de contexto usado y % del límite 5h (necesita `jq`) |
| `global/skills/` | Skills globales → `~/.claude/skills/` | Cross-stack: `architecture`, `ci-cd`, `databases`, `docker-kubernetes` + **`research`** (auto-investigación), **`refresh-knowledge`** (automejora del recetario) y **`setup-project`** (configura/audita/mejora la config de cualquier proyecto) |
| `global/agents/` | Subagentes → `~/.claude/agents/` | `docs-researcher` (haiku): investiga docs en contexto aislado |
| `global/mcp-servers.json` | Definición MCP | context7 (docs de librerías), key vía `secrets.env` |
| `.claude-plugin/marketplace.json` | Manifiesto del marketplace | Declara los 12 plugins con `defaultEnabled: false` |
| `plugins/` (stack) | `nestjs`, `go`, `android-kotlin`, `react-nextjs`, `flutter`, `react-native`, `dotnet` | Convenciones de arquitectura/testing/tooling por stack; flutter trae MCP oficial de Dart + LSP de Dart; los móviles traen `recipes`; dotnet trae EF Core + SQL Server local (OrbStack), Aspire, Azure y ruta de aprendizaje |
| `plugins/` (dominio) | `api-design`, `bots`, `realtime`, `background-jobs`, `ux` | Conocimiento por tipo de desarrollo: APIs (REST/GraphQL/gRPC/auth/webhooks), bots (Telegram/Discord/WhatsApp), realtime (WS/SSE/push), jobs (colas/outbox/cron), UX (estados de pantalla, accesibilidad, convenciones web/Android/móvil) — con `references/` que cargan solo si hacen falta |
| `plugins.txt` / `install.sh` / `install.ps1` | Instalador (bash y PowerShell nativo) | Idempotente: respalda lo que va a reemplazar (`~/.claude/.backup-<ts>`, últimos 3), copia config, poda huérfanos vía manifest, aplica `CLAUDE_LANGUAGE`, registra marketplace, instala plugins. `install.ps1` = Windows sin Git Bash |
| `.github/workflows/*.yml` + `scripts/check-*.sh` | CI del repo | En cada push: JSON lint, paridad de versiones (dual-bump) + sync de `enabledPlugins`, shellcheck, anclas de idioma, lint de PowerShell y `claude plugin validate --strict`; y smoke real de los installers (Linux + Windows PowerShell 5.1) cuando cambian |
| `secrets.env(.example)` | Keys reales (gitignored) / plantilla | Los installers las inyectan directo en el registro MCP a nivel usuario (`~/.claude.json`, jamás commiteado) |
| `START.md` | Bootstrap interactivo para agentes | Punto de entrada único: detecta el entorno, entrevista al usuario y enruta a la guía correcta (global, proyecto o ambos; owner o tercero; incluye Windows) |
| `AGENT-INSTALL.md` | Guía en inglés para agentes | Restauración de MI máquina (sobreescribe `~/.claude/`) + verificación |
| `AGENT-PROJECT-SETUP.md` | Guía en inglés para agentes | Configurar el proyecto de CUALQUIER persona usando este directorio, sin tocar su config global |
| `CLAUDE.md` (raíz) | Contexto de este repo | Orienta a cualquier agente abierto aquí: entradas, reglas de edición y versionado de plugins |

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
> nativo desde PowerShell, o `install.sh` desde Git Bash/WSL2. Nota: los hooks y la
> statusline son bash — sin Git for Windows quedan inertes (todo lo demás funciona).

**Opción B — manual:**

```bash
curl -fsSL https://claude.ai/install.sh | bash   # 1. CLI nativo, auto-actualizable (≥ 2.1.187)
                                                 #    Windows PowerShell: irm https://claude.ai/install.ps1 | iex
brew install jq        # 2. statusline — Windows: winget install jqlang.jq / Linux: apt install jq
cp secrets.env.example secrets.env               # 3. rellena las keys reales
bash install.sh                                  # 4. restaura todo (CLAUDE_LANGUAGE=<idioma> opcional;
                                                 #    respalda lo previo en ~/.claude/.backup-*)
                                                 #    Windows nativo: .\install.ps1
```

Luego abre una sesión nueva y pasa la [verificación rápida](#verificación-rápida).

## Configurar un proyecto (nuevo o existente)

Un solo comando para los tres casos — abre Claude Code en el repo y corre:

```
/setup-project
```

| Caso | Qué hace el protocolo |
|---|---|
| **Proyecto nuevo** (recién inicializado) | Entrevista guiada paso a paso (propósito → stack → arquitectura → deploy/CI → testing), habilita los plugins que correspondan y genera `AGENTS.md` canónico (lo leen también Codex/Cursor/Gemini) + `CLAUDE.md` delgado (`@AGENTS.md`) + `.claude/` mínimos que fijan la arquitectura desde la primera sesión |
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

## Resolver "cómo hago X"

Para "cómo abro un modal en Flutter", "cómo conecto la cámara", "cómo uso tal método":

1. **Si hay receta curada** (skills `recipes` de los plugins móviles, `references/` de dominio): Claude la usa directo — librería recomendada + patrón mínimo + fuente oficial.
2. **Si no hay receta o hay dudas de versión**: Claude dispara solo el skill `research` (regla global "research proactively"), que corre en el subagente `docs-researcher`: context7 → docs oficiales, SOLO la sección relevante, en inglés, y vuelve con versión + snippet + fuente. También puedes forzarlo: `/research how to persist auth session in expo router`.
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
  `~/.ssh`/`~/.aws` y la key de context7 para subprocesos; `docker`/`gh`/`kubectl` van excluidos
  (caen al flujo normal de permisos). macOS/Linux/WSL2; en Windows nativo no aplica (warning esperado).
- **Auto mode** (ya en plan Pro): un clasificador reemplaza los prompts de permiso — lo seguro corre,
  lo destructivo se bloquea. Complementa (no reemplaza) la allowlist.
- **`/code-review`**: bugs de corrección a nivel de esfuerzo elegido; `--fix` aplica, `--comment`
  comenta el PR, `ultra` = revisión multi-agente en la nube.
- **Observabilidad**: `/usage` (consumo por skill/subagente/plugin/MCP), `/doctor` (diagnóstico de
  config), `/cd` (cambiar de directorio sin perder caché), `--safe-mode` (arrancar sin customizaciones).
- **Modelos**: Sonnet 5 (contexto 1M), Opus 4.8 (effort high por defecto, `/effort xhigh`, fast mode
  2x costo / 2.5x velocidad). `fallbackModel` (hasta 3 en cadena) ya configurado aquí.
- **Skills/plugins**: `/reload-skills` sin reiniciar; skills de proyecto en `.claude/skills/` cargan
  sin marketplace (≥ 2.1.157); `claude plugin init` para scaffolding; `disallowed-tools` en frontmatter.
- **Windows**: desde 2.1.120 no requiere Git Bash (usa PowerShell tool); instalador nativo recomendado.
- **Equipo/nube**: `/team-onboarding` (empaqueta tu setup como guía replicable), Routines (agentes
  cloud programados desde la web), `claude agents` (vista de todas las sesiones).

## Verificación rápida

```bash
claude mcp list                      # context7 conectado
claude plugin marketplace list      # dev-plugins
claude plugin list                   # 4 LSP enabled; 12 stack/dominio + expo disabled
```

En una sesión nueva: statusline visible con % de contexto · `/context` sin skills de stack
(en un dir neutro) · leer un `.go` carga `rules/go.md` · pedir leer `.env` → denegado ·
`/research <pregunta>` responde con versión + fuente · `/setup-project` aparece en el
menú `/` · `/sandbox` muestra la config resuelta (macOS/Linux/WSL2) · pedir `git push`
estando en `main` → denegado por `guard-git-push.sh`.

> Nota: la config por proyecto (`.claude/` y `CLAUDE.md` de cada repo) NO vive aquí —
> viaja en el git de cada repositorio. Este repo aporta el protocolo que la genera y
> audita (`/setup-project`) y los plugins que habilita.
