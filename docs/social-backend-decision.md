# Social execution backend — decision

**Phase 8B. Decision: Zernio is the social execution backend. Postiz
self-hosted is evaluated and not selected.**

Postiz research from Phase 8 is preserved in `docs/postiz.md` as the record of a
rejected alternative. Nothing in it was deleted or rewritten.

## Why Zernio — and what that reason is not

This choice was made because of **one specific constraint: the machine this kit
was installed on cannot run the Postiz self-hosted stack.** It has 3.44 GB of RAM
with 0.24 GB free, against nine containers needing roughly 2.3-3 GB plus 1-1.5 GB
of runtime, and WSL is not installed so there is no container backend at all.

**That is a hardware verdict, not a capability verdict.** On a machine with
adequate RAM and a container runtime, **Postiz self-hosted is the better choice
of the two**, and it would be selected instead. Its reasons are real and they are
not small: 28+ publishing channels against Zernio's 16, complete data control, no
per-account cost at any volume, no vendor dependency, and no pass-through
billing.

So read this decision as:

> **Zernio is the default because of what this machine can run. Postiz
> self-hosted remains the preferred backend wherever self-hosting is feasible.**

This is a note, not scaffolding. Nothing in the setup depends on Postiz, no
Postiz component is installed, provisioned or referenced as a requirement, and
switching back means running the Phase 8 research as an installation guide rather
than a rejection record. `docs/postiz.md` is written to be usable that way.

### When to revisit

Switch to Postiz self-hosted if any of these become true:

- The kit is installed on a machine with adequate RAM and WSL2 or Hyper-V.
- A channel is needed that only Postiz covers, such as Medium, Mastodon, the
  fediverse, WordPress-as-social or ListMonk.
- Content, DMs or social tokens must stay on your own infrastructure.
- Per-account cost becomes material at scale.

## Which accounts to connect is the installer's decision

**This kit does not choose, require or pre-select any social account.** There is
no default account list, no scaffolding for one, and nothing in the installer
touches connected accounts.

Whoever installs this decides which accounts to connect, and can change that
later: connect or disconnect any account at any time, and disconnecting stops the
charge. The free tier covers the **first 2 connected accounts**, so a new
installation can be validated in full before spending anything.

Worth knowing before connecting anything:

- Each connected profile on a platform counts as one billable account.
- Instagram requires a **Business** account. TikTok accounts connected through
  the TikTok for Business app publish **public only**. Bluesky uses an app
  password, Telegram a bot token, WhatsApp needs a number and a WABA.
- Facebook Groups cannot be connected at all. The kit publishes to Pages.

Per-account costs are in `docs/zernio.md`. The worked example there is one
plausible reading of a media outlet's platforms, included to show the arithmetic
— **not a recommendation and not a default.** The actual bill depends entirely on
which accounts get chosen.

## Why the question was reopened

Phase 8 selected Postiz self-hosted on capability, and recorded two blockers.
One of them turned out to be decisive:

- **BLOCK-WSL** — WSL is not installed, so there is no container backend.
- **BLOCK-RAM** — the machine has 3.44 GB of RAM with 0.24 GB free, against a
  nine-container stack that needs roughly 2.3-3 GB plus 1-1.5 GB of runtime.

Postiz could not be made to fit this machine. That is a property of the
hardware, not of the code, and it does not improve over time. So the question
became: is there a backend that does the job without requiring hardware this
machine does not have?

Zernio answers yes.

## Direct comparison

| Criterion | Postiz self-hosted | Zernio |
|---|---|---|
| **Runs on this PC** | **No.** 3.44 GB RAM, 0.24 GB free, against 9 containers. Expected to fail health checks. | **Yes.** A CLI and two markdown files. No local services. |
| **Local runtime footprint** | WSL2 + Docker Desktop + 9 containers, ~3.4-4.5 GB, continuously resident | ~150 MB Node at rest, ~0 idle; no background service |
| **Setup complexity** | Install an OS virtualization feature, reboot, install Docker, pull 9 images, create 6 volumes, wait for 7 health checks, first-run DB migration | `npm install -g @zernio/cli`, sign up, `zernio auth:login` |
| **Reproducibility** | Container images pinned by digest, compose file, volume layout — all kit-managed and heavy | One npm package at a pinned version |
| **Background resource usage** | Permanent. Docker Desktop and the stack run whether or not you post. | None. Invoked per command. |
| **Agent integration quality** | Single 31 KB skill, MIT-ish AGPL-3.0, CLI with 4 named commands | Single 11 KB skill + 24-file reference, MIT. JSON on stdout by default, prompts on stderr, `--pretty` flag. Documented "Tips for AI Agents". |
| **Context/tool overhead** | One skill | Two skills, one progressive-disclosure reference |
| **Touches vendor directories** | No | No. Verified: the CLI never writes to `.claude`, `.agents`, `.cursor`, `.codex` or `.gemini`. |
| **Telemetry** | Not assessed | **None.** Only calls resolve against the configured base URL. |
| **Publishing, scheduling, drafts** | Yes | Yes, plus a real Queue API with slot configuration and `next-slot` |
| **Failed-post recovery** | Not in the reviewed skill | `posts:retry`, plus per-post publishing logs retained 7 days |
| **Pre-flight validation** | None in the reviewed skill | `validate:post`, `post-length`, `media`, `subreddit` |
| **Account health** | None | `accounts:health` — rate limits and token expiry before posting |
| **Analytics** | Post and platform metrics | Post timeline, daily metrics, best times, posting frequency, content decay, Instagram and YouTube insights, follower history |
| **Comments and replies** | Comments only on its own posts | Read, reply, hide, pin, like, delete across platforms; reviews for Facebook and Google Business |
| **DMs / inbox** | **Not supported** | Full inbox: DMs, reactions, typing indicators, quick replies, carousels, message edit, delete |
| **Community workflows** | **None** | Broadcasts, multi-step sequences, and comment-to-DM automations |
| **Webhooks** | Not in the reviewed skill | 6 commands, real-time post status, messages, comments |
| **Media upload** | `postiz upload` first, then use the returned path | Presigned upload to 5 GB, returns a public URL |
| **Bulk operations** | Not in the reviewed skill | CSV bulk upload with `dryRun` |
| **Platform coverage** | 28+ channels | 16 platforms plus WordPress and Shopify blogs |
| **Platforms Zernio uniquely adds** | — | Snapchat, Discord, Slack, Reddit, WhatsApp messaging, Shopify |
| **Platforms Postiz uniquely adds** | Medium, Dev.to, Hashnode, Mastodon, Nostr, VK, Lemmy, Farcaster, Kick, Twitch, Dribbble, ListMonk | — |
| **Auth complexity** | Single unscoped API key from the local instance. `auth:login` is unusable because it targets `cli-auth.postiz.com`. | Device flow that creates the key automatically, plus manually scoped keys |
| **Credential scoping** | None. One key, full access. | `scope` to profiles, `permission: read`, `expiresIn`. Upstream recommends a read-only reporting key. |
| **Credential storage** | `~/.postiz/credentials.json`, POSIX modes unenforced on Windows | `~/.zernio/config.json`, overridable by env vars, no modes set |
| **Secrets out of Git** | Yes | Yes, and easier: the env var takes precedence over the file |
| **Data control** | **Full.** Data in local volumes you own. | Data on Zernio's infrastructure. Disconnect any time. |
| **Open source** | AGPL-3.0. Client and skill open; you run the service. | MIT. Client, CLI and skill open; the service is proprietary SaaS |
| **Vendor dependency** | None at runtime. Docker, WSL, and your own maintenance. | One vendor. Uptime claim 99.7%+, public status page, SOC 2 and GDPR docs |
| **Licence obligation** | AGPL-3.0. Self-host use is fine; no source obligation arises because the kit neither vendors nor modifies Postiz. | MIT client. Closed service |
| **Free tier** | Not applicable. Everything is yours once the hardware exists. | **First 2 connected accounts free, no credit card.** Unlimited posts, full API, 10,000 messages/month, analytics. |
| **Cost as usage grows** | Electricity and disk, plus your time | $6/account/month for accounts 3-10, $3 for 11-100, $1 for 101+. Graduated, itemised per account. |
| **Cost for this user's 8 platforms** | $0, if the hardware existed | **$36/month** |

The cost row is an **illustrative example**, computed from one reading of a media
outlet's likely platforms. It is not a default, not a recommendation, and not
what any installer will be charged. See "Which accounts to connect is the
installer's decision" above.| **Hidden pass-through costs** | None known | X API at X's exact rates, zero markup. **Posts with a URL cost $0.200 each.** Messages free to 10,000/month. WhatsApp billed by Meta from 1 Oct 2026. |
| **Reliability you own** | You own it, and you maintain it | Vendor-managed, 99.7%+ claimed |
| **Maturity** | Established project | Young: 5 npm releases since March 2026; reference docs lag the commercial model in three places |

## What Zernio genuinely does better

Not a wash. Zernio is not merely a lighter Postiz:

1. **Community management is a first-class surface.** DMs, comment replies,
   reviews, broadcasts, drip sequences and comment-to-DM automations. Postiz has
   none of this. For a community manager this is the single largest functional
   gain in the whole comparison.
2. **Pre-flight validation.** `validate:post` catches a bad post before the slot
   passes instead of after.
3. **Account health.** Rate limits and token expiry are queryable, so a post does
   not silently fail because a token expired.
4. **Credential scoping.** Read-only, profile-scoped, expiring keys. Postiz has
   one unscoped key.
5. **Failure recovery.** Retry a failed post; read per-post publishing logs.
6. **A real queue.** Configurable slots, queue preview, next-available-slot.
7. **Blogs API.** WordPress and Shopify, which closes a documented gap in the
   kit's skill coverage.
8. **Bulk CSV upload with dry run**, which fits `batch-content-plan` directly.

## What Postiz genuinely does better

Stated fairly, so the decision is not one-sided:

1. **Channel breadth.** 28+ channels versus 16. If this outlet ever needs
   Medium, Mastodon, Bluesky-adjacent fediverse, WordPress-as-social or
   ListMonk, Postiz covers it and Zernio does not.
2. **Data control.** Content and tokens never leave the machine.
3. **No per-account cost at any volume**, once the hardware exists.
4. **No vendor dependency**, no uptime risk, no pass-through billing.

None of these apply to this user's stated platforms, and none of them can be had
on this hardware.

## Overlap matrix against Zernio

The Phase 8 principle is unchanged: **skills do the thinking; the backend
executes.** Re-derived independently against Zernio's actual command surface.

| Skill | Classification | Rationale |
|---|---|---|
| `social-strategy` | keep — strategic/editorial | Decides channels, goals, trade-offs. No backend equivalent. |
| `content-pillars` | keep — strategic/editorial | Ownable themes. Pure strategy. |
| `content-calendar` | **Zernio becomes execution backend** | Cadence and recurring structure stay here. The Queue API (`preview`, `next-slot`, slots) is the operational queue. |
| `batch-content-plan` | **Zernio becomes execution backend** | Brief-writing stays. CSV bulk upload with `dryRun` executes a period's worth of posts. |
| `brand-profile` | keep — strategic/editorial | Durable brand context. |
| `voice-builder` | keep — strategic/editorial | Voice derivation. |
| `caption-writer-sms` | keep — complementary | Writes the caption. Zernio publishes it. |
| `hook-writer` | keep — complementary | Writes the opening. |
| `thread-writer-sms` | keep — complementary | Writes thread content. `threadItems` posts it. |
| `carousel-writer-sms` | keep — complementary | Writes slide copy. |
| `reels-script` | keep — complementary | Script craft. |
| `tiktok-script` | keep — complementary | Script craft. The TikTok-for-Business public-only constraint and `draft: true` workaround are a Zernio execution detail. |
| `youtube-shorts` | keep — complementary | Script craft and Studio analytics. |
| `threads-post` | **Zernio becomes execution backend** | Writing stays; creation and scheduling move. |
| `instagram-reels-publishing` | **Zernio becomes execution backend** | Safe-zone and cover craft stay as pre-flight guidance; publish, schedule and upload move to Zernio. Instagram requires a Business account, which Zernio surfaces. |
| `x-growth` | **Zernio becomes execution backend** | Reply craft and conversation strategy stay. `twitter-actions` and engagement commands execute. X costs are pass-through, so the skill's habit of reading X data cheaply matters. |
| `facebook-strategy` | **Zernio becomes execution backend** | Page strategy stays; Page publishing moves. |
| `facebook-groups` | **no meaningful overlap** | Zernio publishes to a Page, not a Group. Untouched. |
| `cross-platform-repurposing` | **Zernio becomes execution backend** | Transformation stays; per-platform `customContent` / `customMedia` fan-out executes. |
| `analytics-and-reporting` | **Zernio becomes execution backend** | Zernio supplies native metrics; the METER interpretation stays. **A read-only scoped API key fits this skill exactly.** |
| `content-audit` | keep — complementary | Triage reasoning. Zernio supplies part of the data. |
| `reply-and-comment-writer` | **Zernio becomes execution backend** | **Changed from Phase 8.** Postiz could not read or reply to comments; Zernio's inbox does. The skill's craft stays, and execution now genuinely exists. |
| `engagement-routine` | keep — strategic/editorial | Engagement cadence design. No overlap. |
| `community-management` | **Zernio becomes execution backend** | **Changed from Phase 8.** Belonging and rituals stay as reasoning; broadcasts, sequences and comment-to-DM automations execute the mechanical parts. |
| `crisis-and-moderation` | keep — strategic/editorial | **Deliberately conservative.** Zernio can hide, pin, like and delete comments. The skill must not use those automatically. High-stakes and human-in-the-loop. No change from Phase 8. |
| `email-and-newsletter` | keep — strategic/editorial | No newsletter integration configured. |
| `design-and-templates`, `og-image` | keep — complementary | Produce assets Zernio uploads. |
| `newsroom-style`, `ai-writing-detox`, `source-verification`, `fact-check-workflow`, `content-research-and-sourcing`, `editorial-workflow` | keep — strategic/editorial | Writing and verification. Never delegated to a backend. |
| `seo`, `accessibility-compliance`, `web-design-guidelines`, `hallmark`, `impeccable`, `frontend-design` | no meaningful overlap | Not social publishing. |

**Net effect: nothing removed, nothing demoted.** Nine installed skills gain
Zernio as their execution backend, up from seven with Postiz, because Zernio
actually implements inbox, comments and community workflows.

### `scheduling-and-queue`

**`replace`, unchanged from Phase 8.** Zernio's Queue API is the real thing:
slot configuration, queue preview, next-available-slot, and queueing a post
against a profile. An instruction-only scheduling skill should not be added to a
machine with the genuine backend. It stays uninstalled and recorded as
superseded.

### New in Phase 8B: the `knownGaps` entry closes

Phase 2 recorded "CMS and editorial publishing workflows: deliberately out of
scope". Zernio's Blogs API supports WordPress.com, self-hosted WordPress and
Shopify. That remains a **capability, not an installed skill** — the kit gains
the ability to publish articles, not editorial judgement about them. The gap
entry is updated to reflect that the execution path now exists.

## Shared dependency: one Node.js

| Consumer | Requirement | Source |
|---|---|---|
| `@hyperframes/cli` | `>=22` | its own `engines.node` |
| `@zernio/cli` | none declared; CI uses 24 | `publish.yml` |

Node 24 satisfies both. **One Node.js LTS install is a single shared managed
prerequisite.** The dependency plan provisions it once.

## Dependency plan after the decision

Removed from the required default plan: **WSL2, Docker Desktop, all nine Postiz
containers, the Postiz CLI.**

| Dependency | Purpose | Ownership |
|---|---|---|
| Node.js LTS (24) | Shared: HyperFrames CLI and Zernio CLI | `shared` |
| `@hyperframes/cli` | Motion graphics and video rendering | `kit-installed` |
| `@zernio/cli` | Social execution | `kit-installed` |
| FFmpeg + ffprobe | HyperFrames encoding | `shared` |
| Headless Chrome | HyperFrames frame capture | `ephemeral-cache` |

Nothing requires WSL, Docker, elevation or a reboot. **Every remaining
dependency installs at user level.**

## Human-only steps after the decision

1. **Create a Zernio account** at `zernio.com/signup`. Free, no credit card,
   first 2 connected accounts free.
2. **Run `zernio auth:login`.** The CLI opens a browser and creates the API key
   automatically. The user never handles a secret. This is the only credential
   step.
3. **Connect each social account** via OAuth. Genuinely unavoidable, and
   identical in kind to what Postiz would have required. Bluesky uses an app
   password; Telegram a bot token; WhatsApp needs a number and a WABA.
4. **Optional:** create a read-only, profile-scoped API key for reporting, as
   upstream recommends.

Platform OAuth, developer-app approval and account-specific permissions remain
human steps under either backend. Zernio removes steps 1 and 2's friction but
adds none.

## What this decision costs

Stated plainly, because it is a real trade:

- **$36/month** for eight connected accounts, rising per the graduated ladder.
- **$0.200 per X post containing a URL**, passed through at X's rates. For a news
  outlet this is the line to watch; roughly $10/month at 50 link posts. X
  analytics and inbox sync are opt-in and can be left off.
- **Content, DMs, comments and social tokens live on Zernio's servers**, not on
  the user's machine.
- **A young project**: 5 npm releases since March 2026, and its reference
  documentation lags its commercial model in three identified places.

Set against: Postiz cannot run on this machine at all, and would have required
new hardware plus ongoing container maintenance.

## Recommendation

**Adopt Zernio.** It fits this PC, it is materially better at the community and
inbox work that is this user's actual job, its agent integration is cleaner, its
credential model is stronger, and it is verifiable end-to-end at zero cost using
the free 2-account tier before any money is spent.

Revisit if any of these become true: the outlet needs a channel only Postiz
covers; data residency on your own infrastructure becomes a requirement; the
per-account cost becomes material at scale; or the free tier proves insufficient.

## Related

- `docs/zernio.md` — full Zernio evaluation.
- `docs/postiz.md` — preserved Postiz research.
- `docs/dependencies.md` — dependency inventory and ownership.
- `docs/hyperframes.md` — unchanged.
