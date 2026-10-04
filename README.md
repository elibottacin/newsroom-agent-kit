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
3. **No hidden requirements.** No account, no API key, no paid service, and — as installed — **zero
   executable files**. Every skill is markdown.

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

40 skills, in two delivery modes:

- **Pinned fetch.** Copied verbatim from a commit pinned in `manifest/skills.json`, so behaviour
  cannot change silently.
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

`global/AGENTS.md` carries the non-negotiable safety rules and a routing table. It is deliberately
short; detail belongs in skills.

## Prerequisites

| Requirement | Notes |
|---|---|
| Windows | Tested on Windows 11 Home, build 26200 |
| Windows PowerShell 5.1 | Ships with Windows. **PowerShell 7 is not required.** |
| Git | Only to clone this repository and to fetch pinned upstream skills |
| Administrator rights | **Not needed.** Symbolic links fail without elevation; this kit uses hard links, which do not need it. |
| Node.js / Python | **Not needed.** The installed set contains zero executable files. |


Python and Node.js can be installed on demand if you want them for your own tooling:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -InstallPrerequisites
```

The skill set does not need either. winget may raise a UAC prompt; if you decline it, nothing breaks.

Because the default execution policy is `Restricted`, **every command needs `-ExecutionPolicy Bypass`**.
Without it Windows refuses to run the script. This is the single most common reason the installer
appears to do nothing.

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

`https://github.com/elibottacin/newsroom-agent-kit` is a placeholder and will be replaced with the real GitHub URL at publication.

### Option 2 — run the scripts yourself

```powershell
git clone https://github.com/elibottacin/newsroom-agent-kit newsroom-agent-kit
cd newsroom-agent-kit

# 1. fetch the pinned upstream commits the skills come from (run this first:
#    most skills are not stored in this repository, so a dry run before the fetch
#    reports them as missing)
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update.ps1 -Fetch

# 2. preview every change without writing anything
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -DryRun

# 3. install
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1

# 4. confirm
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1











```

`verify.ps1` exits `0` when everything passes, `1` on failure, `2` on warnings only.

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

- The installer writes **only** inside `%USERPROFILE%\.agents`, plus one hard link at
  `%USERPROFILE%\.config\opencode\AGENTS.md`. Nothing else on your machine is touched.
- Logs are redacted to `~/`-relative paths and never print file contents.
- Uninstall removes only skills recorded in the kit's own ownership record. Skills you installed
  yourself are left alone and reported.
- No external account is ever connected. No telemetry is sent by this kit.
- One selected skill, `og-image`, comes from a repository with **no licence file**. It is fetched at
  install time rather than redistributed here, but review `manifest/skills.json` before installing.

## Maintenance status

This repository is published as a **working snapshot for one person's use, not as a maintained shared
project.**

- The 27 vendored forks are **frozen**. When their upstream moves, they will not be updated here. They
  keep working — they are self-contained markdown — but they gain no upstream improvements.
- The 13 pinned skills do not self-update either. The pin guarantees you get the reviewed artifact; it
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
