# HyperFrames — code-driven motion graphics and video

HyperFrames is the kit's deterministic, code-driven motion graphics and video
layer. It renders HTML/CSS/SVG compositions locally on a deterministic timeline
and encodes them with FFmpeg. Generative video is not the objective and cloud
rendering is not part of the default architecture.

## Upstream review record

| Item | Value |
|---|---|
| Repository | `heygen-com/hyperframes` |
| License | Apache-2.0 |
| Reviewed ref | `dc3665ab61b254ca7a0de087b1bfbd2ddcfbf67e` |
| Ref date | 2026-10-04 |
| CLI package | `@hyperframes/cli` |
| CLI version at reviewed ref | `0.8.126` |
| CLI binaries | `hyperframes`, `hyperframes-localize-fonts` |
| CLI engine requirement | Node.js `>=22` |

Evidence for these values comes from the repository itself:
`LICENSE`, `packages/cli/package.json`, the README requirements badge, and
`skills-manifest.json`.

The repository is a Bun workspace (`bun.lock`, `packageManager` is Bun) for its
own development. That is **not** a consumer requirement: the published CLI is an
npm package and upstream documents invocation with `npx`.

## Required local software

See `dependencies.json` and `docs/dependencies.md` for the full inventory.
Summary:

- **Node.js >=22** — required by the CLI's own `engines` field.
- **npm / npx** — ships with Node.js; used for on-demand invocation.
- **@hyperframes/cli** — the CLI itself, installed by the kit.
- **FFmpeg (with ffprobe)** — required for encoding. Upstream names FFmpeg as a
  requirement but does not pin a major version.
- **Headless Chrome** — the renderer seeks each frame in headless Chrome. The
  CLI depends on `@puppeteer/browsers`, which downloads and caches a managed
  browser on first use.

On this machine none of Node.js, npm, npx, Bun, FFmpeg or ffprobe were present
at discovery. System Google Chrome and Microsoft Edge are installed, but the
renderer uses its own managed browser rather than the system one.

## The Core Skills model

Upstream splits its published skills in two, and this distinction drives the
installation strategy.

**Core set — installed eagerly (10 skills):**

`hyperframes` (the `/hyperframes` router), the `hyperframes-*` domain skills
(`hyperframes-animation`, `hyperframes-audio`, `hyperframes-cli`,
`hyperframes-core`, `hyperframes-creative`, `hyperframes-keyframes`,
`hyperframes-registry`, `hyperframes-studio`) and `media-use`.

**Workflow skills — installed lazily on demand (11 skills):**

`embedded-captions`, `faceless-explainer`, `figma`, `general-video`,
`motion-graphics`, `music-to-video`, `pr-to-video`, `product-launch-video`,
`remotion-to-hyperframes`, `slideshow`, `talking-head-recut`.

The `/hyperframes` router selects a workflow and installs it at that moment.
This is why the kit installs the core set and deliberately **not** the workflow
set: a blanket install would add hundreds of files the agent does not need and
would raise idle context cost for nothing.

Source of this split: `skills/hyperframes/references/skill-lifecycle.md` and
the README.

## Upstream command behaviour, and which commands are safe

Read from `skills/hyperframes/references/skill-lifecycle.md` and
`packages/cli/src/commands/skills.ts` at the reviewed ref.

| Command | Behaviour | Verdict for this kit |
|---|---|---|
| `npx hyperframes skills update` (bare) | Refreshes the core set plus anything already installed. Prunes unpublished skills. Does not expand the workflow set. | **Safe.** Non-interactive. |
| `npx hyperframes skills update <workflow>` | Installs one named workflow. | Safe but not used at install time. This is the router's on-demand path. |
| `npx hyperframes init` | Checks GitHub and refreshes the core set plus already-installed skills. No-op when current. Degrades gracefully offline. | **Safe**, but network-dependent. |
| `npx hyperframes skills check [--json]` | Reports freshness; exits non-zero when stale or incomplete. | **Safe.** Useful for verification. |
| `npx hyperframes skills` (bare) | Installs the **full published set explicitly**. | **Must avoid.** |
| `--all` | Sprays into many agent directories. | **Must avoid.** |
| `HYPERFRAMES_SKIP_SKILLS=1` | Opts out of skill installation for CI. | Useful for the kit's own test isolation. |

## The install-location conflict, and how this kit resolves it

Upstream's own installer does not respect this project's architecture. From
`packages/cli/src/commands/skills.ts` and `init.ts` at the reviewed ref:

1. Skills are written to **`~/.claude/skills`** and **`~/.agents/skills`**.
   The `~/.agents` half is canonical and correct. The `~/.claude` half is a
   vendor-specific duplicate.
2. After writing the canonical store, `mirrorGlobalSkills` **symlinks** the
   skills out into every other installed agent's global directory. The code has
   a safety check that reports "Skipped unsafe skill mirror target ... canonical
   skill stores were left unchanged" when a mirror is refused.

Both halves of that conflict with established project rules:

- `scripts/verify.ps1` fails if vendor directories such as `~/.claude/skills`
  exist, because vendor skill copies are exactly what this project forbids.
- Symbolic links cannot be created unelevated on this machine. Phase 1
  established this, and it is why the single compatibility bridge is an NTFS
  **hard link** rather than a symlink.

The `npx skills add heygen-com/hyperframes` alternative is also rejected: Phase
2 already established that the `skills` CLI writes to
`~/.config/opencode/skills` for OpenCode, which is a vendor directory this
project does not use.

### Decision

The kit **vendors the 10 core skills from the pinned reviewed ref** into
`vendor/skills/`, following the same model already used for the 27 existing
forks, and installs them into `%USERPROFILE%\.agents\skills` through the normal
installer. Consequences:

- `%USERPROFILE%\.agents` stays the single canonical store. No vendor
  directories, no symlinks, nothing outside the project's install path.
- The installed content is **reviewed before it runs**, which is the trust model
  the project already applies to every vendored skill.
- Upstream freshness stays checkable: `skills-manifest.json` publishes a content
  hash per skill, so the kit can detect upstream drift without executing
  upstream code to find out.
- Workflow skills remain lazy. The router's `hyperframes skills update <name>`
  path is documented for the user, but the kit does not pre-install them and
  does not pre-authorise a router-driven upstream fetch.

The vendored core set is roughly 382 files, dominated by
`hyperframes-animation` (122) and `media-use` (107).

## Capability boundary

**In scope, and the reason to adopt HyperFrames:** kinetic typography, animated
statistics and charts, lower thirds, headline and news cards, overlays, social
video, animated screenshots and product walkthroughs, deterministic explainer
visuals, reusable media templates, and longer compositions. Driven by HTML/CSS/
SVG, deterministic and seekable timelines, GSAP/CSS/WAAPI runtimes, local media
assets, local rendering.

**Explicitly not in the default architecture:** image-generation models,
video-generation models, hosted renderers, HeyGen Cloud, and the upstream
`aws-lambda` and `gcp-cloud-run` packages and examples. Those exist in the
repository as optional integrations; the kit leaves them unconfigured and
documents them as opt-in only.

Within `media-use`, this boundary is: local media handling, composition, audio,
icons and reuse of existing assets are core behaviour; generative image, music or
voice calls are optional and are not configured by the kit.

## Open verification item

The README invokes the CLI as `npx hyperframes ...` while the published package
name at the reviewed ref is `@hyperframes/cli`. Whether an alias package named
`hyperframes` exists on npm is **not yet confirmed**, because npm is not
installed on this machine. Phase 11 resolves this against the npm registry
before anything is installed, and records the result in `manifest/skills.json`.

## Related

- `docs/dependencies.md` — the dependency inventory and ownership rules.
- `docs/postiz.md` — the other capability added in this extension.
- `docs/security.md` — SEC records for executable dependency code.
