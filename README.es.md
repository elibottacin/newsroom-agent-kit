# Newsroom Agent Kit

**Idiomas:** [English](README.md) · [Español](README.es.md)

Una instalación global y portable de **Agent Skills** para Windows, construida sobre la convención
compartida de `.agents`. Instala un conjunto curado de skills de redacción periodística, community
management, redes, edición y diseño web en `%USERPROFILE%\.agents`, de modo que **cualquier agente de
programación que soporte la convención compartida los detecta** — no una herramienta en particular.

**Probado con OpenCode, Cline y Freebuff.** Son objetivos de validación, no el punto del proyecto.

---

## Por qué existe

Hacer community management, producción periodística y trabajo web para un medio implica el mismo
trabajo de preparación cada vez: buscar skills, revisar sus licencias, averiguar qué lee realmente un
agente desde el disco, e instalar sin pisar la configuración existente. Este repositorio lo hace una
vez, lo verifica, y lo hace repetible en otra máquina.

Tres propiedades se consideran innegociables:

1. **Una sola ubicación canónica.** `%USERPROFILE%\.agents`. Sin copias de skills por cada editor,
   porque dos copias se desincronizan.
2. **Nada destructivo.** El instalador es idempotente, se niega a sobrescribir archivos que no son
   suyos, hace backup antes de cambiar algo, y nunca ejecuta un script de instalación, un hook ni un
   binario de un repositorio de terceros.
3. **Sin requisitos ocultos.** Sin cuenta, sin API key, sin servicio pago y — tal como queda
   instalado — **cero archivos ejecutables**. Cada skill es markdown.

## Compatibilidad

Agent Skills es un formato compartido, pero los agentes difieren en *dónde* leen las skills
globales. Son dos propiedades distintas, y solo la segunda decide si hace falta algún paso extra.

| Capacidad | Soporte |
|---|---|
| Formato Agent Skills (`SKILL.md`) | Amplio: OpenCode, Cline, Cursor, GitHub Copilot, VS Code, Claude Code, Codex, Gemini CLI, Warp, Zed, Kiro, Roo Code, Factory, Amp, Goose y otros |
| Skills globales desde `%USERPROFILE%\.agents\skills` | OpenCode, Cline, Zed, Warp y varios otros lo leen de forma nativa |
| Instrucciones globales desde `%USERPROFILE%\.agents\AGENTS.md` | Cline y Freebuff lo leen de forma nativa |

**Existe una única excepción, y está acotada a un solo archivo.** OpenCode lee las instrucciones
globales únicamente desde `%USERPROFILE%\.config\opencode\AGENTS.md`. Este kit resuelve eso con un
único **hard link NTFS** hacia el archivo canónico `%USERPROFILE%\.agents\AGENTS.md`, de modo que hay
un solo archivo con dos nombres y una sola fuente de verdad. No es una copia, y se elimina
automáticamente el día que OpenCode soporte la ruta canónica de forma nativa.

Las skills **no** necesitan ningún puente en ninguno de los tres agentes confirmados acá.

Un tercer agente, **Freebuff Desktop 0.0.158**, también se verificó leyendo tanto las skills como las
instrucciones globales directamente desde la ubicación canónica, sin ninguna configuración. Ese es
justo el punto de la arquitectura: no depende de ningún vendor en particular.

`docs/architecture.md` tiene la matriz completa, incluido qué agentes necesitarían un link de
vendor documentado si agregás uno.

## Qué se instala

40 skills, en dos modos de entrega:

- **Pinned fetch.** Se copian textualmente desde un commit fijado en `manifest/skills.json`, así que
  el comportamiento no puede cambiar en silencio.
- **Fork vendorizado.** 27 skills en `vendor/skills/`, cada una con su `PROVENANCE.md`. Son copias
  modificadas: su upstream estaba escrito alrededor del producto de un vendor, y dejar esas
  afirmaciones en el texto haría que un agente concluyera que capacidades que *sí* tenés no existen.

| Área | Skills |
|---|---|
| Integridad editorial | `newsroom-style`, `source-verification`, `fact-check-workflow`, `ai-writing-detox`, `content-research-and-sourcing` |
| Planificación editorial | `editorial-workflow` |
| Community management | `community-management`, `engagement-routine`, `reply-and-comment-writer`, `crisis-and-moderation` |
| Marca y voz | `brand-profile`, `voice-builder`, `design-and-templates` |
| Planificación de redes | `social-strategy`, `content-pillars`, `content-calendar`, `batch-content-plan` |
| Analítica y auditoría | `content-audit`, `analytics-and-reporting` |
| Oficio y reconversión | `hook-writer`, `caption-writer-sms`, `thread-writer-sms`, `carousel-writer-sms`, `cross-platform-repurposing` |
| Canales | `instagram-reels-publishing`, `reels-script`, `facebook-strategy`, `facebook-groups`, `x-growth`, `threads-post`, `tiktok-script`, `youtube-shorts`, `email-and-newsletter` |
| Web | `seo`, `accessibility-compliance` |
| Diseño | `impeccable`, `hallmark`, `frontend-design`, `web-design-guidelines` |
| Assets de preview social | `og-image` |

`global/AGENTS.md` contiene las reglas de seguridad innegociables y una tabla de ruteo. Es
deliberadamente corto; el detalle va en las skills.

## Requisitos

| Requisito | Notas |
|---|---|
| Windows | Probado en Windows 11 Home, build 26200 |
| Windows PowerShell 5.1 | Viene con Windows. **No hace falta PowerShell 7.** |
| Git | Solo para clonar este repositorio y traer las skills fijadas por commit |
| Permisos de administrador | **No hacen falta.** Los enlaces simbólicos fallan sin elevación; este kit usa hard links, que no la necesitan. |
| Node.js / Python | **No hacen falta.** El conjunto instalado no tiene archivos ejecutables. |

Como la política de ejecución por defecto es `Restricted`, **todos los comandos necesitan
`-ExecutionPolicy Bypass`**. Sin eso Windows se niega a ejecutar el script. Es el motivo más común de
que el instalador parezca no hacer nada.

## Instalación

### Opción 1 — un solo prompt (recomendado)

Cloná este repositorio donde prefieras, y pegá el prompt de abajo en cualquier agente de programación
compatible para que lo haga por vos:

```text
Set up my global coding-agent skills from this repository on this Windows PC.

Clone https://github.com/elibottacin/newsroom-agent-kit, read its README and installation instructions, and follow the
repository's supported install path. Use %USERPROFILE%\.agents as the canonical global
source for AGENTS.md and skills. Preserve and back up any existing user configuration;
do not silently overwrite unrelated settings. Detect the coding agents installed on this
PC. Use native .agents discovery wherever supported and do not create vendor-specific
skill copies. Add compatibility handling only for a capability that is proven not to
support the canonical location. Install the curated core setup, leave optional external
account and MCP integrations unconnected unless I explicitly approve them, run the
repository's verification tooling, and report exactly what was installed, linked,
skipped, or needs my action.
```

`https://github.com/elibottacin/newsroom-agent-kit` es un marcador de posición y se reemplazará por la URL real de GitHub al publicar.

> El prompt de instalación está en inglés a propósito: es lo que vas a pegarle al agente, y los
> agentes lo entienden mejor en inglés. Esta documentación es la que leés vos.

### Opción 2 — correr los scripts a mano

```powershell
git clone https://github.com/elibottacin/newsroom-agent-kit newsroom-agent-kit
cd newsroom-agent-kit

# 1. traer los commits fijados de los que vienen las skills (esto va primero:
#    la mayoría de las skills no están en este repositorio, así que un dry run
#    antes del fetch las reporta como faltantes)
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update.ps1 -Fetch

# 2. previsualizar todos los cambios sin escribir nada
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -DryRun

# 3. instalar
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1

# 4. confirmar
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1
```

`verify.ps1` devuelve `0` si todo pasa, `1` si hay fallo, `2` si solo hay advertencias.

## Verificar, actualizar, desinstalar

```powershell
# qué hay instalado ahora, y si está bien
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1

# se movió algo upstream? solo informa, nunca mergea
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update.ps1 -CheckRemote

# ver qué se eliminaría
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 -DryRun

# eliminar de verdad, conservando lo que el kit no es dueño
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 -Confirm
```

La actualización es deliberadamente en dos pasos. Para una skill fijada por commit, cambiás
`source.ref` en el manifest, hacés fetch, leés el diff, y recién entonces instalás con `-Force`. Para
una skill **forkeada**, mergeás el upstream **a mano** dentro de `vendor/skills/<nombre>` y actualizás
su `PROVENANCE.md` — nunca copies un directorio upstream encima de un fork, porque eso es
exactamente lo que reintroduce las referencias al producto de terceros que el fork elimina.
`verify.ps1` falla la instalación si reaparece el nombre de un producto.

## Seguridad y privacidad

- El instalador escribe **únicamente** dentro de `%USERPROFILE%\.agents`, más un hard link en
  `%USERPROFILE%\.config\opencode\AGENTS.md`. No toca nada más de tu máquina.
- Los logs se redactan a rutas relativas con `~/` y nunca imprimen contenido de archivos.
- La desinstalación solo borra skills registradas en el registro de propiedad del kit. Las que
  instalaste vos quedan intactas y se reportan.
- Nunca se conecta ninguna cuenta externa. Este kit no envía telemetría.
- Una skill seleccionada, `og-image`, viene de un repositorio **sin archivo de licencia**. Se trae en
  el momento de instalar en vez de redistribuirse acá, pero revisá `manifest/skills.json` antes de
  instalar.

## Documentación

| Archivo | Qué responde |
|---|---|
| `docs/architecture.md` | Cómo funciona el layout, la matriz de compatibilidad, cuándo borrar el puente |
| `docs/discovery.md` | Por qué se eligió o rechazó cada candidato, con evidencia |
| `docs/security.md` | Hallazgos de cadena de suministro, licencias, riesgos residuales |
| `docs/environment.md` | El estado de la máquina base, como evidencia |
| `docs/install-verification.md` | Qué se observó realmente después de instalar |
| `docs/portability-verification.md` | Qué se verificó antes de publicar, incluida la prueba de bootstrap en una máquina limpia |
| `docs/troubleshooting.md` | Todos los errores que pueden dar los scripts, y qué hacer |

## Licencia

MIT — ver [`LICENSE`](LICENSE). Cubre solamente el trabajo propio de este proyecto. Las skills
vendorizadas conservan sus licencias upstream, documentadas skill por skill en
`vendor/skills/<nombre>/PROVENANCE.md` y resumidas en
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Integraciones opcionales, no instaladas

Los servidores MCP de Figma y Canva, la automatización de navegador y las APIs de datos sociales
**no** están conectados y no son necesarios. El MCP de Figma, además, exige un plan pago y que el
cliente esté en una lista habilitada. Todo está en `manifest/integrations.json`, con cada entrada en
`installAction: none`.