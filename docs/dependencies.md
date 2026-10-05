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

Applied to this extension, the consequences are:

- **Node.js is `shared`.** It is required by HyperFrames and by the Postiz CLI,
  but global npm packages and the user's own scripts live on it. Removing Node
  removes those too. The kit detects a compatible Node and never reinstalls or
  upgrades it unnecessarily; a major-version upgrade of an existing Node is not
  performed silently.
- **FFmpeg is `shared`.** It is broadly used by unrelated tooling. Never removed
  without explicit approval.
- **Docker Desktop is `shared`.** It is general-purpose container
  infrastructure. Postiz being removed is not a reason to remove Docker.
- **WSL2 is `os-feature`.** The kit installs it if the user authorises it, and
  never uninstalls it.
- **@hyperframes/cli, the `postiz` CLI and the Puppeteer browser cache are
  `kit-installed` / `ephemeral-cache`.** These are safe for the kit to remove.

## Postiz persistent data is user data

The compose stack's six named volumes hold the user's account, connected social
integrations, scheduled queue, uploaded media and Postiz configuration. A normal
uninstall removes containers and the compose project only.

The kit must never run `docker compose down -v`, `docker volume rm`, or any form
of prune as part of an uninstall or an ordinary update. Volumes are removed only
when the user explicitly asks, and the command that would do so must be shown
to them before it runs.

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

| Dependency | Required by | Version | State at discovery | Ownership |
|---|---|---|---|---|
| Node.js | HyperFrames CLI (`>=22`), Postiz CLI (`>=18`) | `>=22` | **missing** | shared |
| npm / npx | both CLIs | bundled with Node | **missing** | shared |
| `@hyperframes/cli` | HyperFrames | 0.8.126 at reviewed ref | **missing** | kit-installed |
| FFmpeg + ffprobe | HyperFrames render | recent, unpinned upstream | **missing** | shared |
| Headless Chrome | HyperFrames frame capture | puppeteer-managed | not cached (system Chrome/Edge present) | ephemeral-cache |
| WSL2 | Docker Desktop backend | WSL2 | **not installed** | os-feature |
| Docker Desktop | Postiz compose stack | current stable | **missing** | shared |
| `postiz` CLI | Postiz agent execution | 2.0.19 at reviewed ref, node `>=18` | **missing** | kit-installed |
| Postiz compose stack | Postiz runtime | 9 services, 1 published port | not created | kit-declared |

Full per-dependency detail — purpose, evidence, install mechanism, elevation,
ports, persistent data, update mechanism, uninstall implications, ownership note
and verification method — is in `manifest/dependencies.json`.

## Blockers found at discovery

### BLOCK-RAM — physical memory

This PC has **3.44 GB total physical memory, 0.31 GB free** at discovery time.

The official Postiz stack runs nine containers — the Postiz app, two PostgreSQL
instances, Redis, Elasticsearch, Temporal, Temporal admin-tools, Temporal UI and
Spotlight — on top of WSL2 and Docker Desktop. Elasticsearch alone commonly
needs 1 GB or more of heap in practice, and the stack declares seven health
checks that must pass.

The stack is therefore expected to be unusable or to fail health checks on this
hardware. This cannot be fixed by automation, because adding RAM is a hardware
change. It needs a user decision.

### BLOCK-WSL — no container backend

`wsl --status` reports that the Windows Subsystem for Linux is not installed, and
Docker Desktop on Windows 11 Home requires WSL2. Installing it needs
Administrator elevation and a reboot, neither of which an unelevated installer
may perform.

- **Why it is needed:** there is no container runtime without it, so Postiz
  cannot run.
- **Exact action:** run `wsl --install` from an Administrator PowerShell, then
  reboot.
- **Where:** Administrator PowerShell on this PC.
- **Non-secret result needed afterwards:** `wsl --status` reporting an installed
  default version 2.

## Trust level difference from a static skill

Postiz self-hosted and HyperFrames are **not** instruction-only skills, and the
project's provenance model reflects that:

- Postiz self-hosted runs a substantial AGPL-3.0 service stack that executes
  continuously, holds credentials and social platform tokens, and stores user
  content in persistent volumes.
- HyperFrames brings executable Node and render tooling plus an FFmpeg
  dependency, not just instruction text.
- Both bring dependencies that download and execute upstream code at runtime:
  container images for Postiz, npm packages and a managed browser for
  HyperFrames.

`docs/security.md` records each of these as its own finding rather than
inheriting the trust level of a static `SKILL.md`.

## Related

- `docs/postiz.md` — Postiz architecture, auth decision and overlap matrix.
- `docs/hyperframes.md` — HyperFrames architecture, Core Skills model and the
  install-location conflict.
- `docs/troubleshooting.md` — what to do when a dependency check fails.
