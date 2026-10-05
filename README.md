# Newsroom Agent Kit

**Languages:** [English](README.md) · [Español](README.es.md)

A portable, global **Agent Skills** setup for Windows, built on the shared
`.agents` convention. It installs a curated set of newsroom, community-management,
social, editorial and web-design skills into `%USERPROFILE%\.agents`, so **any coding
agent that supports the shared convention picks them up** — not one specific tool.

**Tested with OpenCode, Cline and Freebuff.** They are validation targets, not the point.

---

## Why this exists

Doing community management, newsroom production and web work for a media outlet means the same
setup work every time: sourcing skills, checking their licences, working out what an agent actually
reads from disk, and installing without trampling existing configuration. This repository does that
once, checks the work, and makes it repeatable on another machine.

Three properties are treated as non-negotiable:

1. **One canonical location.** `%USERPROFILE%\.agents`. No per-vendor skill copies, because two
   copies drift.
2. **Nothing destructive.** The installer is idempotent, refuses to overwrite files it does not own,
   backs up before changing anything, and never runs an install script, hook or binary from a
   third-party repository.
3. **No hidden requirements.** The setup states exactly what it needs and provisions it. Two things
   remain genuinely yours: a **Zernio account** if you want live social execution, and **per-platform
   OAuth** when you connect an account. Neither is needed to install the kit or to use the editorial
   skills.

## Compatibility

Agent Skills is a shared format, but agents differ in *where* they read global skills from. Those are
different properties, and only the second one decides whether an installation needs any extra step.

| Capability | Support |
|---|---|
| Agent Skills format (`SKILL.md`) | Broad: OpenCode, Cline, Cursor, GitHub Copilot, VS Code, Claude Code, Codex, Gemini CLI, Warp, Zed, Kiro, Roo Code, Factory, Amp, Goose and others |
| Global skills from `%USERPROFILE%\.agents\skills` | OpenCode, Cline, Zed, Warp and several others read this natively |
| Global instructions from `%USERPROFILE%\.agents\AGENTS.md` | Cline and Freebuff read this natively |

**One exception exists, and it is scoped to a single file.** OpenCode reads global instructions only
from `%USERPROFILE%\.config\opencode\AGENTS.md`. This kit bridges that with a single **NTFS hard
link** to the canonical `%USERPROFILE%\.agents\AGENTS.md`, so there is one file with two names and
one source of truth. It is not a copy, and it is removed automatically the day OpenCode supports the
canonical path natively.

Skills need **no** bridge in any of the three agents confirmed here.

A third agent, **Freebuff Desktop 0.0.158**, was also verified reading both the skills and the global
instructions straight from the canonical location, with no configuration at all. That is the point of
the architecture: it does not depend on any one vendor.

`docs/architecture.md` holds the full matrix, including which agents would need a documented vendor
link if you add one.

## What gets installed

**52 skills**, in two delivery modes:

- **Pinned fetch.** Copied verbatim from a commit pinned in `manifest/skills.json`, so behaviour
  cannot change silently. 25 core entries, including the Zernio and HyperFrames skills.
- **Vendored fork.** 27 skills under `vendor/skills/`, each with a `PROVENANCE.md`. These are
  modified copies: their upstream was written around one vendor's product, and leaving those claims in
  place would make an agent conclude that capabilities you *do* have do not exist.

| Area | Skills |
|---|---|
| Editorial integrity | `newsroom-style`, `source-verification`, `fact-check-workflow`, `ai-writing-detox`, `content-research-and-sourcing` |
| Editorial planning | `editorial-workflow` |
| Community management | `community-management`, `engagement-routine`, `reply-and-comment-writer`, `crisis-and-moderation` |
| Brand and voice | `brand-profile`, `voice-builder`, `design-and-templates` |
| Social planning | `social-strategy`, `content-pillars`, `content-calendar`, `batch-content-plan` |
| Analytics and audit | `content-audit`, `analytics-and-reporting` |
| Craft and repurposing | `hook-writer`, `caption-writer-sms`, `thread-writer-sms`, `carousel-writer-sms`, `cross-platform-repurposing` |
| Channels | `instagram-reels-publishing`, `reels-script`, `facebook-strategy`, `facebook-groups`, `x-growth`, `threads-post`, `tiktok-script`, `youtube-shorts`, `email-and-newsletter` |
| Website | `seo`, `accessibility-compliance` |
| Design | `impeccable`, `hallmark`, `frontend-design`, `web-design-guidelines` |
| Social preview assets | `og-image` |
| Social execution | `zernio`, `zernio-api` |
| Motion graphics and video | `hyperframes` (router), `hyperframes-animation`, `hyperframes-audio`, `hyperframes-cli`, `hyperframes-core`, `hyperframes-creative`, `hyperframes-keyframes`, `hyperframes-registry`, `hyperframes-studio`, `media-use` |

`global/AGENTS.md` carries the non-negotiable safety rules and a routing table. It is deliberately
short; detail belongs in skills.

### Three things this setup includes that a markdown-only skill set would not

**1. Local runtime dependencies.** Required software is a managed part of the setup, not an
undocumented prerequisite. The installer provisions or detects it, verification reports it, and a
fresh machine reproduces it.

| Dependency | Why | Ownership |
|---|---|---|
| Node.js LTS | Runtime for both CLIs. One install serves both | `shared`, never auto-removed |
| npm / npx | Ships with Node.js | `shared` |
| `@zernio/cli` | Social execution CLI | `kit-installed` |
| `hyperframes` (npm) | Motion graphics and video CLI | `kit-installed` |
| FFmpeg | Encodes rendered frames | `shared`, never auto-removed |
| Headless Chrome | Downloaded on first render by the HyperFrames CLI | regenerable cache |

Ownership decides removal, not installation. A `shared` tool is installed when absent because the
capability needs it, but a normal uninstall will still never remove it.

**2. An external account dependency, for social execution only.** Zernio is a SaaS backend. Live
publishing, scheduling, inbox and analytics need a Zernio account plus `zernio.cmd auth:login`, which
you run yourself so the API key never passes through an agent. Everything else works without it.
**Cost: the intended scope is the first 2 connected accounts, which are free, so $0/month.** Which
accounts you connect is your decision, changeable at any time. The free tier covers accounts, not
every platform API charge: X usage is passed through at X's own rates, where a post containing a URL
costs $0.200. `docs/zernio.md` has the full breakdown.

Postiz self-hosted was evaluated as the alternative and is **not** part of this installation. It needs
nine containers and cannot run on a low-memory machine. `docs/postiz.md` keeps the research.

**3. Allowlisted executable skill content.** Most skills are instruction and reference text. Five
HyperFrames skills also ship **77 reviewed scripts** that their own instructions tell the agent to
run. That is a deliberate exception, bounded so it cannot widen silently: a skill must be declared in
the manifest, undeclared skills are still rejected, and a change in the file count fails
verification. `docs/security.md` SEC-15 has the reasoning.

**Motion graphics, honestly:** HyperFrames is installed as the deterministic local motion and video
layer and its CLI passes its own health check, but **the render smoke test has not been run**. It was
deferred because the reference machine has 3.4 GB of RAM and the CLI's own `doctor` warns renders may
fail. Nothing here claims a successful render.

## Prerequisites

| Requirement | Notes |
|---|---|
| Windows | Tested on Windows 11 Home, build 26200 |
| Windows PowerShell 5.1 | Ships with Windows. **PowerShell 7 is not required.** |
| Git | Only to clone this repository and to fetch pinned upstream skills |
| Administrator rights | **Not needed.** Everything installs at user scope. Symbolic links would fail without elevation; this kit uses hard links, which do not need it. |
| Node.js | **Provisioned automatically** if absent, via winget at user scope. Nothing to do by hand. |
| FFmpeg | **Provisioned automatically** if absent, same mechanism. |
| A Zernio account | **Only if you want live social publishing.** Not needed for anything else. |
| Disk | About 2 GB, mostly npm packages and render caches. |

Because the default execution policy is `Restricted`, **every command needs `-ExecutionPolicy Bypass`**.
Without it Windows refuses to run the script. This is the single most common reason the installer
appears to do nothing.

Note on npm-installed CLIs: PowerShell resolves a bare `zernio` to npm's `.ps1` shim, which the
`Restricted` policy blocks. Invoke them as **`zernio.cmd`** and **`hyperframes.cmd`**. The kit's own
instructions and scripts already do this.

## Install

### Option 1 — one prompt (recommended)

Clone this repository somewhere, then paste the prompt below into any compatible coding agent and
let it do the work:

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

The repository is published and public at that URL.

### Option 2 — run the scripts yourself

```powershell
git clone https://github.com/elibottacin/newsroom-agent-kit newsroom-agent-kit
cd newsroom-agent-kit

# 1. provision the required local runtime: Node.js, npm, FFmpeg, the Zernio CLI
#    and the HyperFrames CLI. Detects anything already present and installs
#    only what is missing. Everything lands at user scope, so no UAC prompt.
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -InstallPrerequisites

# 2. fetch the pinned upstream commits the skills come from (run this before the
#    dry run: most skills are not stored in this repository, so a dry run first
#    reports them as missing)
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update.ps1 -Fetch

# 3. preview every change without writing anything
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -DryRun

# 4. install the skills and global instructions
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1

# 5. confirm. Reports the skill set AND every dependency with its version.
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1

```

`verify.ps1` exits `0` when everything passes, `1` on failure, `2` on warnings only.

One step stays yours, and it does not block the install. For live social execution only:

```powershell
zernio.cmd auth:login     # opens your browser; the API key never passes through an agent
```

**Known gap, tracked for the next phase.** The flow above provisions one dependency set at a time. It
has been run end to end on the reference machine across phases 9 to 11 and reruns are idempotent, but
there is not yet a single command that provisions dependencies, fetches, installs and verifies in one
pass. `docs/maintaining.md` records it. Nothing above depends on that gap being closed.

## Verify, update, uninstall

```powershell
# what is installed right now, and is it correct?
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1

# has anything upstream moved? reports only, never merges
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update.ps1 -CheckRemote

# see what would be removed
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 -DryRun

# actually remove, keeping anything the kit does not own
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 -Confirm
```

Updating is deliberately two-step. For a pinned skill, change `source.ref` in the manifest, fetch,
read the diff, then install with `-Force`. For a **forked** skill, merge upstream **by hand** into
`vendor/skills/<name>` and update its `PROVENANCE.md` — never copy an upstream directory over a
fork, because that is exactly what reintroduces the third-party product references the fork removes.
`verify.ps1` fails the installation if a product name reappears.

## Safety and privacy

- The installer writes **agent configuration** only inside `%USERPROFILE%\.agents`, plus one hard
  link at `%USERPROFILE%\.config\opencode\AGENTS.md`. Nothing else in your agent configuration is
  touched.
- With `-InstallPrerequisites` it also installs **local software**: Node.js, npm, FFmpeg and two npm
  CLIs, all at user scope, each detected before install. It never installs anything at machine scope
  and never needs elevation.
- Logs are redacted to `~/`-relative paths and never print file contents. Verification reports whether
  a credential exists and its length, never its value.
- Uninstall removes only skills and dependencies recorded in the kit's own ownership record. Skills
  and shared software you already had are left alone and reported. It never deletes your Zernio
  credentials.
- **This kit sends no telemetry.** It makes no network calls other than fetching pinned upstream
  commits and calling the APIs you configure.
- **Zernio is a third-party SaaS backend** and is the one external dependency. Content, DMs, comments
  and your social OAuth tokens live on Zernio's servers when you use it. That is a deliberate trade
  for a local machine that cannot run a container stack.
- **HyperFrames telemetry was enabled by default upstream and this kit disables it.** It is not signed
  in to HeyGen, which is what keeps usage anonymous and the optional cloud and generative features
  unconfigured.
- One selected skill, `og-image`, comes from a repository with **no licence file**. It is fetched at
  install time rather than redistributed here, but review `manifest/skills.json` before installing.

## Maintenance status

This repository is published as a **working snapshot for one person's use, not as a maintained shared
project.**

- The 27 vendored forks are **frozen**. When their upstream moves, they will not be updated here. They
  keep working — they are self-contained markdown — but they gain no upstream improvements.
- The pinned skills do not self-update either. The pin guarantees you get the reviewed artifact; it
  also means upstream fixes arrive only if someone bumps it.
- Issues and pull requests are welcome, but **no response, review or merge is promised**, and nothing
  is scheduled for review.

Run `update.ps1 -CheckRemote` to see how far behind upstream you are. If you fork this, budget for the
27 hand-merged forks or drop the ones you do not use — see
[`docs/maintaining.md`](docs/maintaining.md), which covers retiring a skill, adding one, and adding
another coding agent.
## Documentation

| File | What it answers |
|---|---|
| `docs/architecture.md` | How the layout works, the compatibility matrix, when to delete the bridge |
| `docs/discovery.md` | Why each candidate was chosen or rejected, with evidence |
| `docs/security.md` | Supply-chain findings, licences, residual risks |
| `docs/environment.md` | The bootstrap machine's state, as evidence |
| `docs/install-verification.md` | What was actually observed after installing |
| `docs/portability-verification.md` | What was checked before publishing, including the clean-machine bootstrap test |
| `docs/troubleshooting.md` | Every error the scripts can produce, and what to do |

## Licence

MIT — see [`LICENSE`](LICENSE). It covers this project's own work only. Vendored skills keep their
upstream licences, documented per skill in `vendor/skills/<name>/PROVENANCE.md` and summarised in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Optional integrations, not installed

Figma and Canva MCP servers, browser automation, and social data APIs are **not** connected and are
not required. Figma's MCP server is additionally gated behind a paid seat and a client allow-list.
Everything lives in `manifest/integrations.json`, every entry `installAction: none`.
