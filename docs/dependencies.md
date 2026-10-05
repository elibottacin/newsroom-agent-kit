# Local software and runtime dependencies

This project treats local software as part of the reproducible setup, not as
undocumented prerequisites. If a capability needs a runtime, a package, a
container or a CLI, the kit is responsible for detecting it, installing it when
that is safe, verifying it, updating it, and being explicit about what it may
not remove on uninstall.

**Machine-readable source of truth: `manifest/dependencies.json`.** This file
explains and justifies; the manifest drives the scripts. Where the two could
disagree, the manifest is authoritative and this file is corrected.

## Ownership model

Every dependency declares one ownership value. The value alone decides whether
a normal uninstall may touch it.

| Value | Meaning | May a normal kit uninstall remove it? |
|---|---|---|
| `kit-installed` | The kit installed it and nothing else depends on it | Yes |
| `shared` | Other software may use it too | **No** |
| `user-owned` | Predates the kit or is outside its scope | **No** |
| `os-feature` | A Windows feature | **No** |
| `ephemeral-cache` | Regenerable download cache | Only on explicit request |

Applied to the selected setup, the consequences are:

- **Node.js is `shared`.** It is required by both `@hyperframes/cli` and
  `@zernio/cli`, but global npm packages and the user's own scripts live on it.
  Removing Node removes those too. The kit detects a compatible Node and never
  reinstalls or upgrades it unnecessarily; a major-version upgrade of an existing
  Node is not performed silently.
- **FFmpeg is `shared`.** It is broadly used by unrelated tooling. Never removed
  without explicit approval.
- **`@hyperframes/cli` and `@zernio/cli` are `kit-installed`.** Safe for the kit
  to remove.
- **The Puppeteer browser cache is `ephemeral-cache`.** Safe to clear only on
  request; it re-downloads.
- **There is no `os-feature` dependency in the default setup.** Nothing requires
  WSL, Docker, elevation or a reboot. Should Postiz ever be revisited, WSL2
  becomes `os-feature` and Docker Desktop becomes `shared` — the kit may install
  them with approval and must never uninstall them.

## Zernio credentials are user data

`%USERPROFILE%\.zernio\config.json` holds the API key, and no `chmod` is applied
to it, so on Windows it is readable by anything running as that user. A normal
uninstall therefore **does not delete it**. The documented setup avoids writing
the key to disk at all by using the `ZERNIO_API_KEY` environment variable, which
takes precedence over the file.

`%USERPROFILE%\.postiz\credentials.json` is the equivalent path if Postiz is
ever revived, and is governed by the same rule.

The kit must never run `docker compose down -v`, `docker volume rm`, or any form
of prune as part of an uninstall or an ordinary update. Volumes are removed only
when the user explicitly asks, and the command that would do so must be shown
to them before it runs. None of this applies to the selected setup, which has no
containers; the rule is retained for the record.

## Detection, not reinstallation

For each dependency the installer follows the same order:

1. Detect an existing installation and read its version.
2. If it satisfies the required version, use it and change nothing.
3. If it is missing, install it through the declared Windows mechanism.
4. If it exists but is too old, report it and stop rather than silently
   upgrading, unless the declared policy for that dependency explicitly permits
   a minor upgrade.
5. If installation is impossible without elevation, an OS confirmation, or an
   account, record it as an explicit blocked prerequisite with exact
   instructions, and do not pretend it succeeded.

The kit records which dependencies it installed in local, uncommitted state so
that ownership can be honoured later without guessing.

## Dependency summary

**Revised in Phase 8B.** Zernio replaced Postiz self-hosted, so WSL2, Docker
Desktop and the nine Postiz containers left the required default plan. One
Node.js runtime now serves both CLIs.

| Dependency | Required by | Version | State at discovery | Ownership |
|---|---|---|---|---|
| Node.js | **shared**: `@hyperframes/cli` (`>=22`) and `@zernio/cli` (CI uses 24) | `24.x` LTS satisfies both | **missing** | shared |
| npm / npx | both CLIs | bundled with Node | **missing** | shared |
| `@hyperframes/cli` | HyperFrames | 0.8.126 at reviewed ref | **missing** | kit-installed |
| `@zernio/cli` | Zernio social execution | 0.4.1 at reviewed ref | **missing** | kit-installed |
| FFmpeg + ffprobe | HyperFrames render | recent, unpinned upstream | **missing** | shared |
| Headless Chrome | HyperFrames frame capture | puppeteer-managed | not cached (system Chrome/Edge present) | ephemeral-cache |

Removed from the required plan: WSL2, Docker Desktop, `postiz-app`, Postgres ×2,
Redis, Elasticsearch, Temporal, Temporal UI, Temporal admin-tools, Spotlight, and
the `postiz` CLI. They remain documented under `manifest/dependencies.json` →
`postiz` as the record of the evaluated alternative.

**Nothing in the default setup requires WSL, Docker, elevation or a reboot.
Every remaining dependency installs at user level.**

Full per-dependency detail — purpose, evidence, install mechanism, elevation,
ports, persistent data, update mechanism, uninstall implications, ownership note
and verification method — is in `manifest/dependencies.json`.

## Blockers resolved by the Phase 8B decision

### BLOCK-RAM — physical memory: no longer blocking

This PC has **3.44 GB total physical memory, 0.24 GB free**. The official Postiz
stack is nine containers on top of WSL2 and Docker Desktop and was expected to
fail health checks.

**Resolution: avoided, not fixed.** Adding RAM is a hardware change and cannot be
automated. Phase 8B selected Zernio, which requires no local services, so the
blocker no longer applies. The finding is retained so it is not lost: if Postiz
is ever revisited on larger hardware, it becomes binding again.

### BLOCK-WSL — no container backend: no longer blocking

`wsl --status` reported the subsystem is not installed, and Docker Desktop on
Windows 11 Home requires WSL2. Installing it needs Administrator elevation and a
reboot.

**Resolution: avoided.** No container runtime is required by the selected setup.
If Postiz is revisited, the human step returns: run `wsl --install` from an
Administrator PowerShell, reboot, and confirm `wsl --status` reports version 2.

## The one shared runtime

`@zernio/cli` declares **no `engines` field**, so npm enforces no minimum. Its own
CI (`.github/workflows/publish.yml`) builds and publishes on **Node 24**, and its
`@types/node` is `^20.11.0`.

| Consumer | Requirement | Source |
|---|---|---|
| `@hyperframes/cli` | `>=22` | its own `engines.node` |
| `@zernio/cli` | none declared; CI uses 24 | `publish.yml` |

Node 24 satisfies both. **One install, one runtime.** The installer provisions it
once and both CLIs depend on it.

## Provisioned state (Phase 9)

| Dependency | Version | Ownership | Kit-removable |
|---|---|---|---|
| Node.js | v24.19.0 (LTS) | `shared` | **no** |
| npm / npx | 11.17.0 | `shared` | **no** |
| `@zernio/cli` | 0.4.1 | `kit-installed` | yes |
| `@hyperframes/cli` | not yet installed (Phase 11) | `kit-installed` | yes |
| FFmpeg | not yet installed (Phase 11) | `shared` | **no** |
| Headless Chrome | appears on first render (Phase 11) | `ephemeral-cache` | on request |

Node.js was installed by `winget install --id OpenJS.NodeJS.LTS -e --scope user`.
**User scope matters:** it keeps the install out of the machine-wide MSI path,
which needs a UAC prompt this kit must never require. winget fetched the official
zip from nodejs.org and verified its hash before extracting, so nothing was
executed from an unverified download. No elevation and no reboot were needed.

A freshly installed package is usually absent from the current session's `PATH`
even though it is on disk, which previously made an installed tool look missing.
Dependency detection therefore searches this session's `PATH`, the persisted user
and machine `PATH`, and winget's package store, and says so explicitly when a tool
is found but a new terminal is needed to use it.

### Provisioning a subset

```
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -InstallPrerequisites -Dependencies nodejs,npm-npx,zernio-cli
```

Each phase provisions only its own dependencies, so Phase 9 does not drag in
Phase 11's HyperFrames CLI and FFmpeg. Omit `-Dependencies` to provision the whole
declared plan.

### What detection deliberately does not do

- It never reinstalls a compatible existing installation.
- It never silently upgrades an existing installation that is merely older. It
  reports the version, prints the command to upgrade, and stops.
- An unreadable version is not treated as an old version. Reporting "too old"
  there produced a false warning for npm, whose version line was being swallowed
  by its own stderr notice.

## Ownership and removal

The ownership record lives at
`%USERPROFILE%\.agents\state\install-state.json`, in a `dependencies` section. It
is machine state, never committed. It records, per dependency: ownership,
whether it is installed, the detected version, whether the kit installed it, and
whether it is removable.

`removable` is the value that matters, and it is derived from ownership, not from
what the installer happened to do:

| Ownership | Removed by a normal uninstall? |
|---|---|
| `kit-installed` | yes, and only if the record also says the kit installed it |
| `ephemeral-cache` | only on explicit request |
| `shared` | **never** |
| `user-owned` | **never** |
| `os-feature` | **never** |

So uninstalling this kit removes `@zernio/cli` and the skills, and leaves Node.js,
npm and FFmpeg alone even if the kit installed them, because other software may
depend on them.

### Credentials are never deleted

`%USERPROFILE%\.zernio\config.json` holds the API key. `uninstall.ps1` reports it
and prints the exact command to remove it, but never runs it, because deleting it
would silently break an authenticated session the user still owns. Revoke the key
in the Zernio dashboard first, then delete the folder yourself.

## Trust level difference from a static skill

Zernio and HyperFrames are **not** instruction-only skills, and the project's
provenance model reflects that:

- **Zernio** is MIT client code, but the service is proprietary SaaS. The CLI is
  invoked per command and holds an API key; the platform holds long-lived OAuth
  tokens for every connected social account, plus all content, DMs and comments.
- **HyperFrames** brings executable Node and render tooling plus an FFmpeg
  dependency, not just instruction text. Its renderer downloads and executes a
  managed Chrome build on first use.
- **Postiz**, if it is ever revisited, would bring a nine-container AGPL-3.0
  service stack running continuously with persistent volumes.

All three download and execute upstream code. `docs/security.md` records each as
its own finding rather than inheriting the trust level of a static `SKILL.md`.

## Related

- `docs/zernio.md` — the selected backend's evaluation.
- `docs/social-backend-decision.md` — the comparison and the decision.
- `docs/postiz.md` — the preserved Postiz research.
- `docs/hyperframes.md` — HyperFrames architecture and the install-location conflict.
- `docs/troubleshooting.md` — what to do when a dependency check fails.
