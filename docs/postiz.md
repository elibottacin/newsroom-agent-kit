# Postiz — self-hosted social execution layer (evaluated, not selected)

> **STATUS: evaluated in Phase 8, rejected as the default backend in Phase 8B.**
>
> Zernio was selected instead. This file is preserved **unmodified below this
> note** as the record of the evaluated alternative. Do not act on it: do not
> provision WSL2, Docker Desktop or the Postiz stack, and do not install the
> `postiz` CLI.
>
> Why it was rejected: the self-hosted stack cannot run on this machine. The PC
> has 3.44 GB of RAM with 0.24 GB free against nine containers needing roughly
> 2.3-3 GB plus 1-1.5 GB of runtime, and WSL is not installed so there is no
> container backend at all. Neither blocker is automatable.
>
> See `docs/social-backend-decision.md` for the comparison and the decision, and
> `docs/zernio.md` for what was selected.

Postiz is the kit's operational execution layer for social publishing: posting,
scheduling, drafts, queueing, cross-posting, media upload, integration
discovery and provider settings, plus the post and platform analytics Postiz
itself can read.

The intended architecture is:

```
Coding Agent -> Postiz Agent Skill / CLI -> local self-hosted Postiz -> social platform APIs
```

Postiz Cloud is not the runtime. The hosted Postiz MCP service is not used.

## Upstream review record

| Item | Value |
|---|---|
| Runtime repository | `gitroomhq/postiz-app` |
| Compose repository | `gitroomhq/postiz-docker-compose` |
| Compose ref reviewed | `dd4969e5e694cd009619a0d53cff14c21104580b` (2026-07-30) |
| Skill and CLI repository | `gitroomhq/postiz-agent` |
| Agent ref reviewed | `93a823f6fe6074016207a32c7f192b70b1752044` (2026-09-22) |
| License | AGPL-3.0 |
| CLI package | `postiz` |
| CLI version observed | `2.0.19` |
| CLI engine requirement | Node.js `>=18` |
| CLI dependencies | `@types/pg`, `node-fetch`, `yargs` — small, no framework |

**Which repository is the runtime source.** `postiz-docker-compose` is the
deployment source: it is the complete, runnable stack. `postiz-app` is the
application source, referenced for implementation and API context, and
referenced by the compose file only through its published image
`ghcr.io/gitroomhq/postiz-app:latest`.

## The compose stack

From `postiz-docker-compose/docker-compose.yaml` at the reviewed ref. One port
is published: **`4007:5000`**, so the local URL is `http://localhost:4007`.

| Service | Image | Role |
|---|---|---|
| `postiz` | `ghcr.io/gitroomhq/postiz-app:latest` | main application |
| `postiz-postgres` | `postgres:17-alpine` | application database |
| `postiz-redis` | `redis:7.2` | cache and queue |
| `spotlight` | `ghcr.io/getsentry/spotlight:latest` | Postiz operations UI |
| `temporal` | `temporalio/auto-setup:1.28.1` | durable workflow engine |
| `temporal-postgresql` | `postgres:16` | Temporal database |
| `temporal-elasticsearch` | `elasticsearch:7.17.27` | Temporal visibility store |
| `temporal-admin-tools` | `temporalio/admin-tools:1.28.1-...` | Temporal administration |
| `temporal-ui` | `temporalio/ui:2.34.0` | Temporal operations UI |

Six named volumes hold all persistent state: `postgres-volume`,
`postiz-redis-data`, `postiz-config`, `postiz-uploads`, `temporal-postgres-data`,
`temporal-elasticsearch-data`. The file declares seven health checks and four
`depends_on` edges.

Configuration is by environment variable, and upstream explicitly does **not**
recommend a `.env` file beside the compose file. The supported options are
variables in the compose file, or a `postiz.env` mounted into `/config` for the
Postiz container. The kit follows upstream and does not commit a `.env`.

## Authentication: the decisive detail

The CLI supports two authentication paths and only one is self-hosted.

**Rejected — `postiz auth:login`, the OAuth2 device flow.** Source evidence,
`postiz-agent/src/auth.ts:9`:

```ts
const DEFAULT_AUTH_SERVER = 'https://cli-auth.postiz.com';
```

This flow depends on Postiz-hosted infrastructure. The CLI does expose an
`--auth-server` flag, but a self-hosted Postiz does not operate that service, so
there is nothing useful to point it at. This path is forbidden by the project
architecture.

**Adopted — API key against a custom endpoint.** Source evidence,
`postiz-agent/src/auth.ts:191` and `src/config.ts:16`:

```ts
apiUrl = process.env.POSTIZ_API_URL || 'https://api.postiz.com';
```

`POSTIZ_API_URL` fully overrides the API endpoint, so an API key issued by a
local instance produces a fully local control plane with no hosted dependency:

```
POSTIZ_API_URL=http://localhost:4007
POSTIZ_API_KEY=<key created in the local instance>
```

The key is created under **Settings → API Keys** (upstream also documents
Settings → Developers → Public API) in the local web UI.

**Credential storage.** Upstream writes credentials to
`%USERPROFILE%\.postiz\credentials.json`, with the directory set to mode 0700
and the file to 0600. Those are POSIX modes and are largely not enforced on
Windows, so this file must be treated as a secret on this platform. It is never
committed, never printed by verification, and removed on uninstall only on
explicit request.

## The one unavoidable human step

The API key must be generated by the user inside their own local Postiz
instance. The agent must not handle or receive that secret. The user should
enter it directly into the local environment, not paste it into a chat.

## Agent Skill and CLI capabilities

The portable skill is `skills/postiz/SKILL.md` in `postiz-agent` — a single
skill, about 31 KB, whose frontmatter declares a required environment variable
`POSTIZ_API_URL`. Capability areas from its own headings: authentication,
integration discovery, creating posts, managing posts, analytics, connecting
missing posts, media upload, and clipping long video into short clips.

Observed commands include `postiz upload`, `postiz posts:create`,
`postiz analytics:platform <integration-id> -d 30`,
`postiz analytics:post <post-id> -d 7`, and `postiz integrations:settings`.

Two of the skill's own hard rules matter for integration correctness:

- **Rule 2** — every local file passed as media must first go through
  `postiz upload`; the returned `.path` is what gets used. Raw filesystem paths
  do not work.
- **Rule 3** — when posting to TikTok, `content_posting_method` must be
  `DIRECT_POST` unless the user explicitly asked to finish the post inside the
  app.

### Why Skill + CLI and not MCP

The skill plus the npm CLI is inspectable, agent-agnostic, and low-context. It
needs no MCP server registration, no hosted endpoint and no extra agent-specific
configuration. No concrete capability was found that the skill and CLI cannot
reach, so **no MCP layer is proposed**, and none will be added without user
approval and a documented missing capability.

## Channel coverage, and why Postiz cannot replace everything

Postiz's own integration list covers 28+ channels including X, LinkedIn,
Instagram, Facebook Page, Threads, YouTube, TikTok, Pinterest, Bluesky,
Telegram, Mastodon, WordPress, Discord, Slack, Twitch and more.

Against this user's platforms:

| Platform | Postiz | Consequence |
|---|---|---|
| X | covered | `x-growth` execution moves to Postiz |
| Threads | covered | `threads-post` execution moves to Postiz |
| Instagram | covered | Reels publishing execution moves to Postiz |
| Facebook Page | covered | Page publishing execution moves to Postiz |
| YouTube / Shorts | covered | scheduling moves to Postiz |
| TikTok | covered | scheduling moves to Postiz |
| Bluesky | covered | scheduling moves to Postiz |
| Telegram | covered | scheduling moves to Postiz |
| Pinterest | covered | — |
| **Facebook Groups** | **not covered** | Postiz publishes to a Page, not a Group. `facebook-groups` stays and is not rationalised away. |
| **WhatsApp** | **not in the list at this ref** | must stay manual |
| **Newsletter / email** | not configured (ListMonk exists but is unset up) | `email-and-newsletter` stays |

## Overlap matrix — every existing social skill

Guiding principle, applied consistently: **skills do the thinking — strategy,
editorial judgement, writing, brand voice, planning, community reasoning and
content transformation. Postiz becomes the execution layer wherever it provides
reliable native functionality.**

Classification values: *keep — strategic/editorial*, *keep — complementary*,
*Postiz becomes execution backend*, *demote to optional*, *remove from default
install*, *replace*, *no meaningful overlap*.

### Installed default set (40 skills)

| Skill | Domain | Classification | Rationale |
|---|---|---|---|
| `social-strategy` | planning | keep — strategic/editorial | Decides channels, goals and trade-offs. No Postiz equivalent. |
| `content-pillars` | planning | keep — strategic/editorial | Ownable themes. Pure strategy. |
| `content-calendar` | planning | **Postiz becomes execution backend** | Cadence and recurring structure stay here; the actual queue and queue-state live in Postiz. |
| `batch-content-plan` | planning | keep — strategic/editorial | Produces briefs for a period. Planning, not execution. |
| `brand-profile` | brand | keep — strategic/editorial | Durable brand context. No overlap. |
| `voice-builder` | brand | keep — strategic/editorial | Voice derivation. No overlap. |
| `caption-writer-sms` | craft | keep — complementary | Writes the caption. Postiz publishes it. |
| `hook-writer` | craft | keep — complementary | Writes the opening. No Postiz equivalent. |
| `thread-writer-sms` | craft | keep — complementary | Writes thread content. Postiz posts threads. |
| `carousel-writer-sms` | craft | keep — complementary | Writes slide copy. No Postiz equivalent. |
| `reels-script` | channel | keep — complementary | Script craft. Postiz handles scheduling and upload. |
| `tiktok-script` | channel | keep — complementary | Script craft, plus the `DIRECT_POST` rule is respected downstream. |
| `youtube-shorts` | channel | keep — complementary | Script craft and Studio analytics reading. Postiz handles scheduling. |
| `threads-post` | channel | **Postiz becomes execution backend** | The skill writes the copy; Postiz creates and schedules the thread. Name is ambiguous — the writing half stays. |
| `instagram-reels-publishing` | channel | **Postiz becomes execution backend** | Publish mechanics, safe zone and cover selection stay as craft guidance; the actual publish, schedule and media upload move to Postiz. |
| `x-growth` | channel | **Postiz becomes execution backend** | Conversation strategy, reply craft and first-hour behaviour stay; posting and scheduling move to Postiz. |
| `facebook-strategy` | channel | **Postiz becomes execution backend** | Reels and Page strategy stay; Page publishing execution moves to Postiz. |
| `facebook-groups` | channel | **no meaningful overlap** | Postiz cannot post to a Group. Stays, untouched. |
| `cross-platform-repurposing` | repurposing | **Postiz becomes execution backend** | The transformation from one piece into many stays; the multi-platform fan-out execution moves to Postiz. |
| `analytics-and-reporting` | analytics | **Postiz becomes execution backend** | Postiz supplies native post and platform metrics for the platforms it covers; the skill keeps the METER interpretation and the goal mapping. For platforms Postiz does not cover, the skill still reads native dashboards directly. |
| `content-audit` | analytics | keep — complementary | Triage and keep/kill/refresh reasoning. Postiz supplies part of the data. |
| `reply-and-comment-writer` | community | **no meaningful overlap** | Postiz supports comments attached to its own posts, not replying to arbitrary inbound comments. Stays. |
| `engagement-routine` | community | keep — strategic/editorial | Engagement cadence design. No overlap. |
| `community-management` | community | keep — strategic/editorial | Community reasoning and belonging. No overlap. |
| `crisis-and-moderation` | community | keep — strategic/editorial | High-stakes human-in-the-loop. Deliberately not routed through an automated backend. |
| `email-and-newsletter` | channel | keep — strategic/editorial | Not covered by a configured Postiz integration. |
| `design-and-templates` | design | keep — complementary | Produces assets that Postiz then uploads. |
| `og-image` | design | keep — complementary | Produces preview images. |
| `newsroom-style`, `ai-writing-detox` | editorial | keep — strategic/editorial | Writing craft. |
| `source-verification`, `fact-check-workflow`, `content-research-and-sourcing` | fact integrity | keep — strategic/editorial | Verification. Deliberately never delegated to an automated backend. |
| `editorial-workflow` | editorial | keep — strategic/editorial | Assignments and deadlines. |
| `seo`, `accessibility-compliance`, `web-design-guidelines`, `hallmark`, `impeccable`, `frontend-design` | website/design | **no meaningful overlap** | Not social publishing. |

**Net effect on the installed set: no skill is removed and none is demoted.**
Postiz takes over execution; the reasoning layer is untouched. That is the
intended outcome and it is deliberate — no strategy or editorial skill is
discarded merely because Postiz can publish its output.

### Optional, not currently installed (11 skills)

| Skill | Classification | Rationale |
|---|---|---|
| `scheduling-and-queue` | **replace** | This is exactly Postiz's native execution surface: queueing, scheduling, post status management and operational post retrieval. An instruction-only scheduling skill should not be added to a machine that has the real thing. It stays uninstalled and is recorded as superseded. |
| `social-media-intelligence` | keep — strategic/editorial (uninstalled) | Competitive and trend intelligence is not a Postiz capability. Unrelated to this decision. |
| `content-recycling` | keep — complementary (uninstalled) | Decides what to reuse. Postiz executes the resulting posts. |
| `profile-optimization` | keep — strategic/editorial (uninstalled) | Bio and profile decisions. Unrelated to Postiz. |
| `page-monitoring` | **Postiz becomes execution backend** (uninstalled) | Postiz surfaces post status and errors; native platform alerts still matter for the platforms it does not cover. |
| `goals-and-kpis` | keep — strategic/editorial (uninstalled) | Target setting. No overlap. |
| `writing-style-and-tone`, `humanizer` | keep — strategic/editorial (uninstalled) | Writing craft. |
| `story-pitch` | keep — strategic/editorial (uninstalled) | Editorial pitching. |
| `web-testing`, `web-quality-audit` | **no meaningful overlap** (uninstalled) | Web QA. |

## Rationalisation record

These decisions are also recorded in machine-readable form so the installer and
verification can act on them rather than on prose:

- `manifest/skills.json` gains a `postizRationalisation` section, and
  `scheduling-and-queue` is marked superseded so it is never added to the
  default install.
- `manifest/integrations.json` gains the Postiz entry with its install action,
  auth method and endpoint.
- Per-skill records gain an `executionBackend` field so an agent reading the
  manifest can tell strategy skills from execution skills.

## Blockers on this machine

Two blockers were found during discovery. Both are recorded in full in
`manifest/dependencies.json` under `blockingFindings` and summarised in
`docs/dependencies.md`. Neither is a discovery defect; both are hardware or
elevation limits on this PC, and both need a user decision before Phase 9 can
proceed. See the Phase 8 report.

## Related

- `docs/dependencies.md` — the dependency inventory and ownership rules.
- `docs/hyperframes.md` — the other capability added in this extension.
- `docs/security.md` — SEC records, including the AGPL-3.0 review.
