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
3. **Sin requisitos ocultos.** El setup declara qué necesita y lo instala. Dos cosas siguen siendo
   tuyas: una **cuenta de Zernio** si querés ejecución social real, y el **OAuth por plataforma** cuando
   conectes una cuenta. Ninguna hace falta para instalar el kit ni para usar las skills editoriales.

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

**52 skills**, en dos modos de entrega:

- **Pinned fetch.** Se copian textualmente desde un commit fijado en `manifest/skills.json`, así que
  el comportamiento no puede cambiar en silencio. Son 25 entradas del núcleo, incluidas las skills de
  Zernio y HyperFrames.
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
| Ejecución social | `zernio`, `zernio-api` |
| Motion graphics y video | `hyperframes` (router), `hyperframes-animation`, `hyperframes-audio`, `hyperframes-cli`, `hyperframes-core`, `hyperframes-creative`, `hyperframes-keyframes`, `hyperframes-registry`, `hyperframes-studio`, `media-use` |

`global/AGENTS.md` contiene las reglas de seguridad innegociables y una tabla de ruteo. Es
deliberadamente corto; el detalle va en las skills.

### Tres cosas que incluye este setup y que un conjunto solo-markdown no tendría

**1. Dependencias de runtime locales.** El software requerido es una parte gestionada del setup, no
una prerrequisito no documentado. El instalador lo aprovisiona o lo detecta, la verificación lo
informa, y otra máquina lo reproduce.

| Dependencia | Para qué | Ownership |
|---|---|---|
| Node.js LTS | Runtime de los dos CLI. Una instalación sirve para ambos | `shared`, nunca se quita solo |
| npm / npx | Viene con Node.js | `shared` |
| `@zernio/cli` | CLI de ejecución social | `kit-installed` |
| `hyperframes` (npm) | CLI de motion graphics y video | `kit-installed` |
| FFmpeg | Codifica los frames renderizados | `shared`, nunca se quita solo |
| Headless Chrome | Lo descarga el CLI de HyperFrames en el primer render | caché regenerable |

El ownership decide la eliminación, no la instalación. Una herramienta `shared` se instala si falta
porque la capacidad la necesita, pero un uninstall normal nunca la va a remover.

**2. Una dependencia de cuenta externa, solo para la ejecución social.** Zernio es un backend SaaS.
Publicar, programar, leer la bandeja de entrada y las analíticas necesitan una cuenta de Zernio más
`zernio.cmd auth:login`, que corrés vos para que la API key nunca pase por un agente. Todo lo demás
funciona sin eso. **Costo: el alcance previsto son las primeras 2 cuentas conectadas, que son
gratis, o sea $0/mes ($0/month).** Qué cuentas conectás es tu decisión y se puede cambiar en cualquier
momento. El
tier gratis cubre las cuentas, no todas las cargas de API de las plataformas: el uso de X se cobra a
las tarifas de X, donde una publicación con URL cuesta $0,200. `docs/zernio.md` tiene el detalle.

Postiz self-hosted se evaluó como alternativa y **no** forma parte de esta instalación. Necesita nueve
contenedores y no puede correr en una máquina con poca RAM. `docs/postiz.md` conserva la investigación.

**3. Contenido ejecutable en skills, con lista blanca.** La mayoría de las skills son texto de
instrucciones y referencia. Cinco skills de HyperFrames incluyen además **77 scripts revisados** que
sus propias instrucciones le piden al agente ejecutar. Es una excepción deliberada, acotada para que
no pueda ampliarse en silencio: una skill debe declararse en el manifiesto, las no declaradas se
siguen rechazando, y un cambio en la cantidad de archivos hace fallar la verificación.
`docs/security.md` SEC-15 tiene el razonamiento.

**Motion graphics, con honestidad:** HyperFrames está instalado como la capa local determinista de
motion y video, y su CLI pasa su propio chequeo de salud, pero **el smoke test de render todavía no se
ejecutó**. Se aplazó porque la máquina de referencia tiene 3,4 GB de RAM y el propio `doctor` del CLI
advierte que los renders pueden fallar. Nada de esto afirma que un render haya funcionado.

## Requisitos

| Requisito | Notas |
|---|---|
| Windows | Probado en Windows 11 Home, build 26200 |
| Windows PowerShell 5.1 | Viene con Windows. **No hace falta PowerShell 7.** |
| Git | Solo para clonar este repositorio y traer las skills fijadas por commit |
| Permisos de administrador | **No hacen falta.** Todo se instala en scope de usuario. Los enlaces simbólicos fallarían sin elevación; este kit usa hard links, que no la necesitan. |
| Node.js | **Se instala solo** si falta, vía winget en scope de usuario. No hay que hacer nada a mano. |
| FFmpeg | **Se instala solo** si falta, con el mismo mecanismo. |
| Una cuenta de Zernio | **Solo si querés publicar de verdad.** No hace falta para nada más. |
| Disco | Unos 2 GB, sobre todo paquetes npm y cachés de render. |

Como la política de ejecución por defecto es `Restricted`, **todos los comandos necesitan
`-ExecutionPolicy Bypass`**. Sin eso Windows se niega a ejecutar el script. Es el motivo más común de
que el instalador parezca no hacer nada.

Sobre los CLI instalados por npm: PowerShell resuelve un `zernio` a secas al shim `.ps1` de npm, que la
política `Restricted` bloquea. Invocalos como **`zernio.cmd`** y **`hyperframes.cmd`**. Las
instrucciones y los scripts del propio kit ya lo hacen así.

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

El repositorio está publicado y es público en esa URL.

> El prompt de instalación está en inglés a propósito: es lo que vas a pegarle al agente, y los
> agentes lo entienden mejor en inglés. Esta documentación es la que leés vos.

### Opción 2 — correr los scripts a mano

```powershell
git clone https://github.com/elibottacin/newsroom-agent-kit newsroom-agent-kit
cd newsroom-agent-kit

# 1. aprovisionar el runtime local requerido: Node.js, npm, FFmpeg, el CLI de
#    Zernio y el de HyperFrames. Detecta lo que ya está e instala solo lo que
#    falta. Todo va a scope de usuario, así que no hay aviso de UAC.
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -InstallPrerequisites

# 2. traer los commits fijados de los que vienen las skills (esto va antes del
#    dry run: la mayoría de las skills no están en este repositorio, así que un
#    dry run antes las reporta como faltantes)
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update.ps1 -Fetch

# 3. previsualizar todos los cambios sin escribir nada
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -DryRun

# 4. instalar las skills y las instrucciones globales
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1

# 5. confirmar. Informa el conjunto de skills Y cada dependencia con su versión.
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1
```

`verify.ps1` devuelve `0` si todo pasa, `1` si hay fallo, `2` si solo hay advertencias.

Un paso queda en tus manos, y no bloquea la instalación. Solo para la ejecución social real:

```powershell
zernio.cmd auth:login     # abre tu navegador; la API key nunca pasa por un agente
```

**Brecha conocida, anotada para la próxima fase.** El flujo de arriba aprovisiona un grupo de
dependencias a la vez. Se ejecutó de punta a punta en la máquina de referencia a lo largo de las fases
9 a 11, y las repeticiones son idempotentes, pero todavía no hay un único comando que aprovisione
dependencias, traiga, instale y verifique de una sola vez. `docs/maintaining.md` lo registra. Nada de
lo anterior depende de que esa brecha se cierre.

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

- El instalador escribe **configuración de agente** únicamente dentro de
  `%USERPROFILE%\.agents`, más un hard link en `%USERPROFILE%\.config\opencode\AGENTS.md`. No toca
  nada más de tu configuración de agente.
- Con `-InstallPrerequisites` también instala **software local**: Node.js, npm, FFmpeg y dos CLI de
  npm, todo en scope de usuario, cada uno detectado antes de instalar. Nunca instala nada en scope de
  máquina ni necesita elevación.
- Los logs se redactan a rutas relativas con `~/` y nunca imprimen contenido de archivos. La
  verificación informa si una credencial existe y su longitud, nunca su valor.
- La desinstalación solo borra skills y dependencias registradas en el registro de propiedad del kit.
  Las skills y el software compartido que ya tenías quedan intactos y se reportan. Nunca borra tus
  credenciales de Zernio.
- **Este kit no envía telemetría.** No hace llamadas de red más allá de traer los commits fijados y
  llamar a las APIs que vos configures.
- **Zernio es un backend SaaS de terceros** y es la única dependencia externa. Cuando lo usás, el
  contenido, los DMs, los comentarios y tus tokens OAuth de redes viven en los servidores de Zernio.
  Es un intercambio deliberado para una máquina local que no puede correr un stack de contenedores.
- **La telemetría de HyperFrames venía activada por defecto upstream y este kit la desactiva.** No hay
  sesión iniciada en HeyGen, que es lo que mantiene el uso anónimo y las funciones opcionales de nube
  y generativas sin configurar.
- Una skill seleccionada, `og-image`, viene de un repositorio **sin archivo de licencia**. Se trae en
  el momento de instalar en vez de redistribuirse acá, pero revisá `manifest/skills.json` antes de
  instalar.

## Estado de mantenimiento

Este repositorio se publica como una **instantánea funcional para el uso de una persona, no como un
proyecto compartido con mantenimiento.**

- Los 27 forks vendorizados están **congelados**. Cuando su upstream se mueva, no se van a actualizar
  acá. Siguen funcionando — son markdown autocontenido — pero no ganan mejoras de upstream.
- Las 13 skills fijadas por commit tampoco se actualizan solas. El pin garantiza que obtenés el
  artefacto revisado; también significa que las correcciones de upstream llegan solo si alguien lo
  actualiza.
- Los issues y pull requests son bienvenidos, pero **no se promete respuesta, revisión ni merge**, y no
  hay nada agendado para revisar.

Corré `update.ps1 -CheckRemote` para ver cuán atrás está upstream. Si hacés un fork de esto, presupuestá
los 27 forks que hay que mergear a mano o sacá los que no uses — mirá
[`docs/maintaining.md`](docs/maintaining.md), que cubre cómo dar de baja una skill, cómo agregar una, y
cómo sumar otro agente de programación.
## Documentación

| Archivo | Qué responde |
|---|---|
| `docs/architecture.md` | Cómo funciona el layout, la matriz de compatibilidad, cuándo borrar el puente |
| `docs/social-backend-decision.md` | **Por qué Zernio y no Postiz, con comparación directa y el razonamiento de coste** |
| `docs/zernio.md` | El backend social elegido: capacidades, auth, coste, límites por plataforma, comportamiento observado |
| `docs/postiz.md` | La alternativa evaluada y **no** elegida, conservada como evidencia |
| `docs/hyperframes.md` | La capa de motion y video: modelo Core Skills, dependencias, comportamiento observado |
| `docs/dependencies.md` | Cada dependencia de runtime, su ownership, aprovisionamiento y qué puede quitar el uninstall |
| `docs/discovery.md` | Por qué se eligió o rechazó cada candidato, con evidencia |
| `docs/security.md` | Hallazgos de cadena de suministro, licencias, riesgos residuales, incluida la decisión de la lista blanca |
| `docs/environment.md` | El estado de la máquina base, como evidencia |
| `docs/install-verification.md` | Qué se observó realmente después de instalar (instantánea histórica de Fase 4) |
| `docs/portability-verification.md` | Qué se verificó antes de publicar (instantánea histórica de Fase 5) |
| `docs/troubleshooting.md` | Todos los errores que pueden dar los scripts, y qué hacer |
| `docs/maintaining.md` | Agregar, retirar y actualizar skills y dependencias; brechas conocidas |
| `docs/bootstrap-state.md` | De dónde partió el repositorio |
| `docs/seed-discovery.md` | La investigación inicial que alimentó la Fase 2 |
| `PLAN.md` | Cada fase, tarea y validación, incluido lo que sigue aplazado |

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
