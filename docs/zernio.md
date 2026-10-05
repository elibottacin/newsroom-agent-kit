# Zernio — evaluated social execution backend

Zernio was evaluated in Phase 8B as an alternative to the Postiz self-hosted
architecture researched in Phase 8. **Zernio is the selected social execution
backend.** Postiz remains documented as an evaluated, rejected alternative; its
Phase 8 research is preserved unchanged.

The selected architecture is:

```
Coding Agent -> zernio skill -> @zernio/cli -> Zernio REST API -> social platform APIs
```

No MCP layer is used, and no vendor-specific plugin is used.

## Upstream review record

| Item | Value |
|---|---|
| CLI repository | `zernio-dev/zernio-cli` |
| CLI ref reviewed | `bb446cc02e4e14e4e0a2135e4ebc29180bc2e030` |
| CLI ref date | 2026-09-09 |
| CLI licence | MIT |
| API reference repository | `zernio-dev/zernio-api` |
| API ref reviewed | `6a8356f4f85f51a4145eacdffd2c23591bd4d7fc` |
| API ref date | 2026-07-29 |
| API reference licence | MIT |
| npm package | `@zernio/cli` |
| npm latest at review | `0.4.1`, published 2026-09-09 |
| npm versions published | 5 (`0.1.1`, `0.2.0`, `0.3.0`, `0.4.0`, `0.4.1`) |
| npm package created | 2026-03-22 |
| CLI binaries | `zernio`, and legacy `late` |
| CLI dependencies | `@zernio/node`, `open`, `yargs` — three, no framework |
| API version | 1.0.4, last updated September 2026 |

## Three official skill sources exist

This matters, because it is the main design decision for the global skill set.

### 1. `zernio` — the CLI operations skill

Ships **inside the npm package itself**: `package.json` has `"files": ["dist",
"SKILL.md", "README.md"]`. Frontmatter declares `name: zernio`, homepage
`docs.zernio.com`, and required env `ZERNIO_API_KEY` plus optional
`ZERNIO_API_URL`. Roughly 11 KB. This is the primary skill and the one the
selected architecture uses.

### 2. `zernio-api` — the REST API reference skill

A separate repository, MIT, with `SKILL.md` plus 24 progressive-disclosure files
under `rules/` (accounts, ads, analytics, api-keys, authentication, broadcasts,
connect, contacts, errors, gmb, inbox, media, platforms, posts, queue, reddit,
sdks, sequences, tools, twitter-actions, users, webhooks, whatsapp).

Its value is **complementary and specific**. The CLI auto-generates commands from
the OpenAPI spec and covers 112 generated operations, but the CLI does **not**
expose blogs (WordPress and Shopify), voice and calls, phone-number inventory,
or the feedback endpoint. `zernio-api` documents those, and it also documents
per-platform constraints that no CLI command states.

### 3. The official Agent Skills index

`https://zernio.com/.well-known/agent-skills/index.json` publishes six
single-purpose skills under `schemas.agentskills.io` discovery `0.2.0`, each with
a `sha256` for pinning: `schedule-post`, `connect-account`, `list-analytics`,
`send-message`, `run-ads`, `manage-blog-articles`.

**Decision: do not install these six by default.** They describe raw REST calls
and duplicate what the `zernio` CLI skill already covers through a better
interface. Installing them would add six more always-loaded skill descriptions
for capabilities already reachable. They are recorded as an available,
hash-pinned option for a future phase if a specific gap appears.

### Which skills the kit installs

| Skill | Source | Why |
|---|---|---|
| `zernio` | `zernio-cli` at the pinned ref | The operational CLI path. Primary. |
| `zernio-api` | `zernio-api` at the pinned ref | Covers blogs, voice, phone numbers, per-platform constraints and webhooks that the CLI does not state. Progressive disclosure, so it costs little until read. |

Both are MIT, both are vendored from pinned refs by the existing materialisation
path, and both land in `%USERPROFILE%\.agents\skills`. No vendor directory is
created.

## What the CLI does not touch — and why that matters

Verified by searching the entire `src/` tree for `.claude`, `.agents`,
`.cursor`, `.codex`, `.gemini` and `skills`. The only hits are `cursor` used as
an API pagination parameter.

**The Zernio CLI never writes to any agent or vendor directory.** Compare this
with the HyperFrames installer, which writes to `~/.claude/skills` and symlinks
into other agents (`docs/hyperframes.md`, SEC-21). Zernio needs no equivalent
workaround: it is a plain CLI plus a skill file the kit installs itself.

Network calls in the CLI resolve only against the configured base URL. **There is
no telemetry and no third-party beacon.**

## Node.js: a shared prerequisite with HyperFrames

`@zernio/cli` declares **no `engines` field at all**, so npm enforces no minimum.
The authoritative signal is its own CI, `.github/workflows/publish.yml`, which
builds and publishes on **Node 24**. Its `@types/node` is `^20.11.0`.

Node 24 satisfies both consumers:

| Consumer | Requirement | Satisfied by Node 24 |
|---|---|---|
| `hyperframes` (npm) | `engines.node >=22` | yes |
| `@zernio/cli` | none declared; CI uses 24 | yes |

**One Node.js LTS install serves both. It is a single shared managed
prerequisite, not two.** The installer provisions it once and both CLIs depend on
it.

## Package-name caveat

The unscoped npm package `zernio` **does not exist**, so `npx zernio` fails. The
correct invocation is `npm install -g @zernio/cli` or `npx @zernio/cli`.

The legacy binary name `late` is a hazard: the unscoped npm package `late`
exists and is an **unrelated** project. Only ever install the scoped
`@zernio/cli`.

## Authentication

Two paths, both usable.

**`zernio auth:login`** — a device authorization flow. The CLI POSTs to
`{origin}/api/auth/cli/initiate`, prints a confirmation code and URL to
**stderr** so stdout stays clean for JSON, opens the browser, then polls
`{origin}/api/auth/cli/poll` with the device code. On success it writes the key
and prints JSON on stdout. This is the recommended path because the user never
handles a secret.

**`zernio auth:set --key <key>`** — saves a key manually. Note that this puts the
secret in command-line arguments, where it can land in shell history. The
environment variable is the safer route.

**Credential storage** (`src/utils/config.ts`):

- File: `%USERPROFILE%\.zernio\config.json`, holding `apiKey` and `baseUrl`.
- Precedence: `ZERNIO_API_KEY` / `ZERNIO_API_URL` environment variables **win**
  over the file, so the key can be kept entirely out of the file, or the file can
  be kept out of Git.
- Legacy fallbacks `LATE_API_KEY`, `LATE_API_URL` and `~/.late/config.json` are
  still read for backwards compatibility.
- No `chmod` is applied, so on Windows the file is plainly readable. Same caveat
  as Postiz's `credentials.json`. It must be treated as a secret, must never be
  committed, and is removed on uninstall only on explicit request.

**Base URL.** `ZERNIO_API_URL` is overridable, but there is no self-hosted
Zernio. The service is SaaS on Vercel. The override exists for proxies and
enterprise use, not for on-premise deployment.

## API key scoping — better than Postiz

From `rules/api-keys.md`. Keys are `sk_`-prefixed, 67 characters, and the full
value is returned exactly once at creation. A key can be scoped:

| Field | Values | Effect |
|---|---|---|
| `scope` | `full`, `profiles` | `profiles` restricts the key to named `profileIds[]` |
| `permission` | `read-write`, `read` | `read` limits the key to `GET` requests |
| `expiresIn` | days | optional expiry; omit for a non-expiring key |

Upstream explicitly recommends a narrow, read-only, profile-scoped key for
reporting integrations. Postiz offers a single unscoped API key with no scoping,
so this is a genuine security improvement, and it maps directly onto the
reporting half of `analytics-and-reporting`.

## Output shape

Every command prints **JSON on stdout by default**, with `--pretty` for
indented output. Errors are structured: `{"error": true, "message": "...",
"status": 401}`. Interactive prompts, such as the device-flow confirmation code,
go to **stderr**, so stdout stays parseable.

This is better suited to a coding agent than Postiz, whose CLI output shape is
less explicitly specified for machine parsing.

## Operational surface

Command groups registered in `src/index.ts`: auth, profiles, accounts, posts,
analytics, media, inbox, contacts, broadcasts, sequences, automations,
custom-fields, validate, account-groups, api-keys, usage, logs, tracking-tags,
plus **112 auto-generated commands** derived from the OpenAPI spec.

What this actually covers:

- **Profiles** — multi-brand grouping, several accounts per platform per profile.
- **Accounts** — connect, list, filter, disconnect, and `accounts:health`, which
  reports rate limits and token expiry before you post.
- **Posts** — publish now, schedule with timezone, save as draft, per-platform
  `customContent` and `customMedia`, threads via `threadItems`, first comment,
  list and filter by status, get details, delete, and **retry a failed post**.
- **Queue** — `preview`, `next-slot`, and configurable slots. This is the real
  operational queue, not an instruction file.
- **Media** — presigned upload up to 5 GB, returning a public URL.
- **Bulk** — CSV bulk upload with a `dryRun` parameter.
- **Analytics** — post timeline, daily metrics, best posting times, posting
  frequency, content decay, Instagram and YouTube insights, follower history.
- **Inbox** — DMs across platforms, **comments, replies to comments, reviews**,
  reactions, typing indicators, quick replies, carousels, message edit (Telegram)
  and delete.
- **Broadcasts** — generic and WhatsApp-template broadcasts with scheduling and
  delivery status.
- **Sequences** — multi-step drip campaigns defined in JSON.
- **Automations** — comment-to-DM, currently Instagram and Facebook.
- **Webhooks** — six commands; real-time events for post status, messages and
  comments.
- **Validate** — `post-length`, `post`, `media`, `subreddit`: pre-flight
  validation against platform rules **before** publishing.
- **Usage** — `usage:stats` and `usage:x-pricing` for live quota and cost checks.
- **Logs** — publishing logs per post, retained 7 days.

### The pre-flight validation point

`validate:post` checks a post against platform rules before it is created. For a
newsroom this is worth more than it looks: discovering a failed publish after the
slot has passed is worse than catching it at draft time. Postiz has no equivalent
in the reviewed skill.

## Platform coverage and the limitations that matter

Sixteen platforms per `llms.txt`: Instagram, TikTok, WhatsApp, Facebook,
YouTube, LinkedIn, X/Twitter, Threads, Reddit, Pinterest, Bluesky, Google
Business, Telegram, Snapchat, Discord, Slack. Blogs: WordPress.com,
self-hosted WordPress, Shopify.

Against this user's platforms:

| Platform | Publishing | Notes |
|---|---|---|
| Instagram | yes | **Requires a Business account.** Feed, Stories, Reels, carousels (max 10, no mixing). Stories need media and take no caption. Up to 3 collaborators. |
| Facebook | Page only | **Not Groups.** Cannot mix video and images; multiple videos unsupported. First comment supported. |
| X | yes | Threads via `threadItems`. See the pass-through cost below. |
| Threads | yes | Threads via `threadItems`. |
| TikTok | yes | Accounts connected through the TikTok for Business app publish **public only**; use `draft: true` to pick the audience in-app. Caps at 15 videos plus 15 photo posts per rolling 24 h, held rather than rejected. |
| YouTube | yes | Requires at least one video. Title max 100 chars, tags max 500 total chars. |
| Bluesky | yes | Via app password, not OAuth. |
| Telegram | yes | Via bot token; message editing supported. |
| Pinterest | yes | Requires a board. |
| **WhatsApp** | messages only | Cloud API. Needs a number and a WABA; billed by Meta. |
| **Facebook Groups** | **no** | As with Postiz. `facebook-groups` stays. |
| **Newsletter** | no | `email-and-newsletter` stays. |

So the same two gaps as Postiz — Facebook Groups and newsletter — and no new
ones. WhatsApp moves from "unavailable" to "available as messaging", which is an
improvement.

## Rate limits

| Tier | Requests/minute |
|---|---|
| Free (first 2 connected accounts) | 60 |
| Paid usage-based | 600 |
| Enterprise | 1,200 |

Headers `X-RateLimit-Limit`, `X-RateLimit-Remaining` and `X-RateLimit-Reset` are
returned. Posting volume itself is unlimited per account; the limit is request
throughput. Sixty requests per minute is ample for a community manager's
workflow.

`rules/errors.md` still lists an older four-tier plan ladder (Free 60, Build 120,
Accelerate 600, Unlimited 1200). That is stale; `llms.txt` and the pricing page
describe the current usage-based model. See "Documentation inconsistencies".

## Cost model

**Free: the first 2 connected social accounts, no credit card required.** That
includes unlimited posts, full API access, 10,000 inbox messages a month and
analytics. This matters for validation: the kit can be installed and proven
end-to-end at zero cost.

**Intended usage is the free tier: two accounts, everything else handled
manually.** The account bill is therefore $0/month.

One caveat that survives the free tier: **it covers accounts, not platform API
usage.** X costs are passed through at X's exact rates on every tier. If neither
connected account is on X, the bill is $0. If one is, a text post is about
$0.015 and a post containing a URL about $0.200.

Beyond 2 accounts, graduated per-account pricing:

| Connected accounts | Price per account per month |
|---|---|
| 1-2 | free |
| 3-10 | $6 |
| 11-100 | $3 |
| 101+ | $1 |

**What counts as an account:** one connected profile on one platform. An
Instagram account, a TikTok account, a Facebook Page, a YouTube channel each
count as one. Ad accounts count too. Connected WordPress and Shopify sites count
as accounts even though they are blogs rather than social publishing targets.

**Worked example, for arithmetic only.** If someone connected Instagram, Facebook
Page, X, Threads, Bluesky, TikTok, YouTube and Telegram, that is 8 accounts:

```
2 free + 6 x $6 = $36 / month
```

**This is not a default, not a recommendation, and not what this kit intends.**
The kit does not choose or pre-select any account. Connect whatever subset makes
sense, starting with the 2 free ones, and disconnect any account at any time to
stop the charge. Adding WhatsApp needs a dedicated number (from $3/month) plus
Meta's own per-message fees, billed by Meta directly.

**Pass-through charges that are not optional:**

- **X API is passed through at X's exact rates with zero markup.** Reads $0.005,
  user reads and Article actions $0.010, post and DM sends $0.015, and
  **posts containing a URL $0.200**. For a news outlet posting links on X, that
  last figure is the one that matters: roughly $0.20 per link post, about $10 per
  month at 50 link posts. X analytics and inbox sync are **opt-in**, so they can
  be left off.
- **Messages sent** are free to 10,000 a month, then $1 per 10,000. Received
  messages, comments and reviews are free and never metered.
- **WhatsApp** service messages were free until 30 September 2026 and are billed
  by Meta at its utility rate from 1 October 2026, after 1,000 free per number
  per month. That window has just closed.
- **Managed ads** are free for the first 500.

Cost is controllable and predictable, and `usage:stats` plus `usage:x-pricing`
let the kit report actual consumption rather than guess.

## Licensing and what is open source

Both GitHub repositories are **MIT**: the CLI, the SDK, and the API reference
skill. The **service is proprietary SaaS**, running on Vercel, with a published
status page, 99.7%+ uptime claim, and SOC 2 and GDPR documentation at
`trust.zernio.com`. Enterprise terms add SAML SSO, SCIM, audit logs and
role-based access, available from 2,000 accounts and never required to scale.

This is the fundamental trade: the client and the skill are open, the control
plane is not.

## A Claude Code plugin exists, and is not used

`zernio-dev/zernio-claude-plugin` is published and referenced from `llms.txt`. It
is vendor-specific and is **not** part of this kit. The portable skill plus CLI
covers everything, and adding it would violate the project's no-vendor-wrapper
rule.

## An MCP server exists, and is not used

`https://mcp.zernio.com/mcp`, Streamable HTTP, OAuth or API key, with a server
card at `/.well-known/mcp/server-card.json` and a listing as `com.zernio/zernio`
in the official MCP registry.

No MCP layer is proposed. The CLI already exposes 112 generated commands plus 19
hand-written groups, covering the entire operational surface, and it needs no
agent-specific registration. MCP would add a hosted endpoint, a second auth
model and extra tool definitions for no capability gain. If a concrete gap ever
appears, MCP remains available as a fallback and would need user approval first.

## Documentation inconsistencies found

Recorded because they affect how much the documentation can be trusted:

1. **Analytics add-on.** `rules/analytics.md` says all analytics endpoints
   "require the **analytics add-on**", and `zernio-cli/SKILL.md` repeats
   "requires analytics add-on". Both the pricing page FAQ and `llms.txt` state
   the opposite: analytics is bundled with every connected account with "no
   separate add-ons or tier upgrades". The commercial documentation is the newer
   authority and this kit assumes analytics is **included**, while recording that
   the reference material still says otherwise.
2. **Platform count.** Stated as 13 in the CLI skill body, 14 in the package
   description, 15 in the `zernio-api` skill description, and 16 in `llms.txt`.
   The `llms.txt` list of 16 is the current one.
3. **Rate-limit tiers.** `rules/errors.md` still describes a four-tier plan
   ladder that no longer matches the usage-based model.

None of these block adoption. They are a maturity signal: the project is young,
with 5 npm releases since March 2026, and its reference material lags its
commercial model.

## Privacy and data control

The trade against self-hosting, stated plainly:

- Every scheduled post, DM, comment, contact and connected-account token lives on
  Zernio's infrastructure, not on the user's machine.
- Zernio holds long-lived OAuth tokens for every connected social account.
- Reads and writes go over `https://zernio.com/api`.
- The user can disconnect any account at any time and stops being charged.

In exchange: no local runtime, no data to back up, no server to patch, and a
99.7%+ uptime claim with a public status page. For a single community manager's
workflow on a 3.44 GB laptop, that is the better side of the trade.

## Observed behaviour (Phase 10, live against the real service)

Recorded from actual responses, not from documentation. All calls were read-only
and no account was connected at the time.

### Authentication

`zernio.cmd auth:check` returns the account, not just a boolean:

```json
{"success":true,"message":"API key is valid",
 "users":[{"name":"...","role":"owner"}],"currentUserId":"..."}
```

### Read operations all return clean JSON on stdout

| Command | Observed |
|---|---|
| `profiles:list` | one profile `Default`, `accountCount: 0` |
| `accounts:list` | `{"accounts":[],"hasAnalyticsAccess":true}` |
| `posts:list --limit 3` | `{"posts":[],"pagination":{"total":0,"pages":0}}` |
| `usage:stats` | `planName: "Usage-Based"`, `connectedAccounts: 0`, `spend.currentPeriodCents: 0` |

`hasAnalyticsAccess: true` on a usage-based account with zero connected accounts
is **live evidence that analytics is not gated behind a paid add-on**, which
resolves contradiction 1 in "Documentation inconsistencies" below in favour of the
pricing page.

### `accounts:health` is a usable pre-flight gate

```json
{"summary":{"total":0,"healthy":0,"warning":0,"error":0,"needsReconnect":0},"accounts":[]}
```

With accounts connected this is the check that catches an expired token or a
rate-limited account before a batch is attempted.

### The pre-flight validators work, and one caught a real rule

`validate:post-length --text "Prueba corta"` returned per-platform limits for 15
platforms and variants, from `snapchat` at 160 characters up to `facebook` at
63,206.

`validate:post --platforms "instagram,twitter,facebook"` returned:

```json
{"valid":false,"errors":[{"platform":"instagram",
  "error":"Instagram posts require media content (images or videos)"}]}
```

**Operational gotcha: the CLI exits 0 even when validation fails.** The result must
be read from the `valid` field. An agent that trusts the exit code would schedule
a post the API had already said was invalid.

### `usage:x-pricing` is better than the pricing page

It returns `markup: "0%"`, a `lastVerified` date, and a `metering` label per
operation, which the pricing page does not:

| Metering label | Meaning |
|---|---|
| `always` | billed on every call: `content_create`, `dmSend`, article draft/publish |
| `analytics_optin` | billed **only if analytics sync is switched on** |
| `inbox_optin` | billed **only if inbox sync is switched on** |
| `absorbed` | not billed separately |

This is the practical cost-control lever: `posts_read` is `analytics_optin` and
`inbox_optin`, so **with both opt-ins off, reading X posts costs nothing.**
`content_create_with_url` is the `always` tier at $0.20.

### Confirmed absences

Searching the full `--help` output confirms the Phase 8B finding: there is **no**
`blogs`, `wordpress`, `shopify`, `voice`, `calls`, general phone-number purchase,
or `feedback` command. `whatsappphonenumbers:*` exists but is WhatsApp-specific,
not the general phone-number inventory the API documents. This is why the
`zernio-api` reference skill is installed alongside the CLI rather than instead of
it.

### `apikeys:list` leaks the first key in full — see SEC-32

The command is `apikeys:list`, with no hyphen. Its response redacts each key as
`keyPreview` (`sk_25d92...cb259700`) **but also returns a top-level `firstApiKey`
field containing a complete, unredacted key.** The value is a different key from
the one in `~/.zernio/config.json`, so the kit's own credential was not exposed,
but it is a live full-scope read-write credential. Never run this command where
its output might be logged or pasted, and revoke the signup key.

### The write path cannot be validated without a connected account

`posts:create` requires `--text` and `--accounts`, and `--draft` is a boolean
flag. With zero connected accounts there is no `accountId` to pass, so no draft
can be created. The write path stays unvalidated until an account is connected,
which is a deliberate deferral rather than a failure.


- `docs/social-backend-decision.md` — the Postiz-versus-Zernio comparison and
  the decision.
- `docs/postiz.md` — the preserved Phase 8 Postiz research, kept as the record
  of the rejected alternative.
- `docs/dependencies.md` — dependency inventory, including the shared Node.js
  prerequisite.
- `docs/security.md` — SEC records for both backends.
