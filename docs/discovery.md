# Discovery — Phase 2

Evidence and decisions for skill, plugin and integration selection.

- Research date: 2026-10-04
- Scope: evaluate candidates, classify them, install nothing.
- Method: every repository below was **cloned and read directly**, not judged from a registry listing. Frontmatter, file inventories, license files and executable content were extracted mechanically, and official documentation was fetched for platform behavior.

| Source of truth | Artifact |
|---|---|
| Machine-readable selection | `manifest/skills.json` |
| Optional integrations | `manifest/integrations.json` |
| Supply-chain and capability risk | `docs/security.md` |

## Research method actually used

1. Shallow-cloned 16 candidate repositories into a throwaway, gitignored `.research/` directory.
2. Inventoried every `SKILL.md`: frontmatter fields, `name` versus directory-name match, description length, license field, bundled code files, subdirectories.
3. Scanned each candidate skill for dependency and network signals: `npm`, `npx`, `pip install`, `curl`, `API_KEY`, `api key`, external hosts, runtime requirements.
4. Grepped for the specific seed claims to confirm or refute them.
5. Fetched current official documentation for the Agent Skills spec, OpenCode, Cline, the `skills` CLI, Figma MCP and Canva MCP.
6. Deleted the research clones before the phase closed.

Registry indexes such as Skills.sh were used only as a discovery index. No candidate was accepted on a listing alone.

---

## 1. Portable Agent Skills foundation

### 1.1 `SKILL.md` format — revalidated

Confirmed against the current specification at <https://agentskills.io/specification>:

| Field | Required | Constraint |
|---|---|---|
| `name` | yes | 1–64 chars, `a-z0-9` with single hyphens, no leading/trailing hyphen, no `--`, **must match the parent directory name** |
| `description` | yes | 1–1024 chars, should describe what *and* when |
| `license` | no | license name or bundled license file |
| `compatibility` | no | max 500 chars, for environment requirements |
| `metadata` | no | string-to-string map, for client-specific data |
| `allowed-tools` | no | space-separated pre-approved tools, **experimental** |

Optional directories: `scripts/`, `references/`, `assets/`.

Progressive disclosure is the documented cost model: metadata about 100 tokens per skill loaded at
startup, `SKILL.md` body under 5000 tokens recommended when activated, resources only as needed.
This is the basis for the "keep the core small" rule used throughout this document.

Validation tooling exists upstream: `skills-ref validate ./my-skill` from
`agentskills/agentskills`. Phase 3 should implement equivalent static checks rather than depend on
that tool, since the machine has no Python or Node.

### 1.2 Directory conventions — revalidated

Portable convention: one directory per skill, containing `SKILL.md`, optionally with
`references/`, `scripts/`, `assets/`. This is what every selected core skill uses, and it maps
directly onto `%USERPROFILE%\.agents\skills\<name>\SKILL.md`.

### 1.3 OpenCode and Cline discovery — revalidated

Phase 1 already proved this against the installed binaries. Phase 2 re-confirmed against current
documentation and found no contradiction:

- OpenCode documents `~/.agents/skills/<name>/SKILL.md` as a global search location.
- Cline's *Rules* documentation lists `~/.agents/AGENTS.md`. Its *Skills* documentation still
  lists only `~/.cline/skills`, which contradicts its own shipped 0.0.43 runtime. The runtime
  resolves `~/.agents/skills`; the documentation lags. Treat the runtime as authoritative and make
  Phase 4 verification behavioural rather than documentation-based.

**Conclusion: skills need no compatibility layer in either agent.**

### 1.4 Additional agents that support Agent Skills

From the Agent Skills client showcase and the `skills` CLI's supported-agent table, the format is
broadly supported: Cursor, GitHub Copilot, VS Code, Claude Code, ChatGPT/Codex, Gemini CLI, Warp,
Zed, Kiro, Roo Code, Factory/Droid, Amp, OpenHands, Goose, Mistral Vibe, Junie, Mux, TRAE, Tabnine,
OpenClaw and others.

**Important caveat for the compatibility matrix:** broad format support does **not** mean broad
*global canonical path* support. The `skills` CLI table shows that only some agents read global
skills from `~/.agents/skills`:

| Agent | Global skills path used by the `skills` CLI |
|---|---|
| Cline, Zed, Warp, Dexto, Kimi Code CLI, Loaf, Sarvam Code | `~/.agents/skills/` |
| **OpenCode** | **`~/.config/opencode/skills/`** |
| Gemini CLI | `~/.gemini/skills/` |
| GitHub Copilot | `~/.copilot/skills/` |
| Codex, Cursor | vendor-specific |
| Claude Code | `~/.claude/skills/` |

So a new agent may need a documented compatibility step even though it "supports Agent Skills".
The compatibility matrix in Phase 5 must record the *global path*, not just a yes/no.

Freebuff Desktop 0.0.158 is installed on this machine and is unverified. It is recorded as
unknown rather than assumed compatible.

---

## 2. Installer decision: `npx skills` versus a custom PowerShell installer

This was the single most consequential tooling decision in the phase, so it is documented in full.

The `skills` CLI (npm `skills`, v1.7.0, MIT, Vercel Labs, ~4.4M weekly downloads) is the obvious
off-the-shelf choice and appears in the seed discovery. **It is rejected as the installer.**

Evidence:

1. **It would break the canonical architecture.** Its own documentation states that installing
   globally for OpenCode targets `~/.config/opencode/skills/`. That is a vendor-specific skill
   tree, which the project rules forbid. It would also leave Cline reading
   `~/.agents/skills/` while OpenCode read a separate copy, guaranteeing drift.
2. **Its default install method is symlinks**, which **fail on this machine**. Phase 1 proved that
   symbolic links require Administrator privileges or Developer Mode, neither of which is present.
   The documented fallback is `--copy`, which produces independent duplicated files — precisely the
   maintenance hazard the project is designed to avoid.
3. **It ships usage telemetry.** Anonymous repository and skill identifiers are sent for
   repositories it can confirm are public, and identifiers may be sent for other remote source
   types. It can be disabled with `DISABLE_TELEMETRY=1`, but the default is on.
4. **It expands the credential surface.** It may invoke `gh repo clone` and reads
   `GITHUB_TOKEN`/`GH_TOKEN`, and it downloads remote archives.
5. **It requires Node.js**, which is not installed. Adopting it would force a Node prerequisite
   for a skill set that is entirely instruction-based.

A third-party skills manager would add value only if it preserved
`%USERPROFILE%\.agents\skills` as the single canonical store. It does not.

**Decision: this repository ships its own PowerShell installer** that writes only to
`%USERPROFILE%\.agents`, is idempotent, refuses unsafe overwrites, backs up what it changes, and
never executes an upstream install script. Phase 3 implements it.

Worth noting: because the CLI's own discovery walk finds skills at `skills/`, `.agents/skills/`
and similar container paths, it remains a useful *discovery* tool for a human, just not an
installer for this project.

---

## 3. Newsroom and editorial candidates

### 3.1 `jamditis/claude-skills-journalism` — MIT, commit `48fe27b` (2026-10-03)

Most recently updated repository in the review set and the only one with genuine newsroom scope.
63 `SKILL.md` files across topical bundles. The `journalism-core` bundle is directly on-target;
`dev-toolkit`, `security-toolkit`, `research-toolkit` and `superjawn` are not, and were not taken.

| Skill | Verdict | Why |
|---|---|---|
| `newsroom-style` | **core** | AP Style and newsroom conventions. 7.5 KB, zero code. |
| `source-verification` | **core** | SIFT plus an evidence trail, with 9 on-demand reference files covering documents, images, interviews, social accounts, source credibility and synthetic media. Zero code. |
| `fact-check-workflow` | **core** | Pre-publication verification workflow and claim rating. Zero code. |
| `editorial-workflow` | **core** | Assignments, deadlines, editorial calendar. Zero code. |
| `ai-writing-detox` | **core** | Removes AI writing patterns from articles and press releases. Zero code. |
| `accessibility-compliance` | **core** | WCAG patterns aimed at news and academic sites. See section 10. |
| `story-pitch` | optional | Only useful for external pitching. |
| `social-media-intelligence` | optional | 29 KB, OSINT-adjacent. |
| `page-monitoring` | **reject** | Six `API_KEY` references and a `pip install` step. Needs a paid change-detection service. |
| `security-toolkit`, `dev-toolkit`, `superjawn`, `research-toolkit` (rest) | reject | Backend/security/agent-framework scope, not newsroom scope. |

Note: each skill bundles an `agents/openai.yaml` sidecar. It is inert metadata and does not create a
vendor dependency at runtime.

### 3.2 `notque/vexjoy-agent` — MIT, commit `5218674` (2026-10-02)

**The seed discovery was wrong about this repository.** It was listed as providing `fact-check` and
`content-calendar`. A full recursive search for `SKILL.md` files matching `fact` or `calendar`
returned nothing. Neither skill exists.

The repository is also the heaviest reviewed after the two mega-bundles: 2131 files, 724 code
files, plus `hooks/`, `plugins/`, `scripts/`, `services/`. Its 62 skills are oriented to a broad
agent framework (game engines, WebGL, Kubernetes, video editing, code review) rather than to
newsroom work.

**Verdict: reject the repository.** Its editorial-adjacent skills (`content/headlines`,
`research/news-collection`) are real but not better than the selected alternatives, and the seed's
two named entry points do not exist.

**Consequence:** `fact-check` was replaced by `jamditis` `fact-check-workflow`, and the single
calendar decision was made between `social-media-skills` `content-calendar` and `blacktwist`
`content-calendar-sms`.

---

## 4. Social, community and content candidates

### 4.1 `social-media-skills/skills` — MIT, commit `6e30eeb` (2026-07-19)

106 skills, 714 files, and only **3 code files in the entire repository**. By far the most portable
set reviewed, and the best domain fit for a community manager at a media outlet. It includes
`community-management`, `crisis-and-moderation` and `reply-and-comment-writer`, which map directly
onto the user's stated job.

Selected core: `brand-profile`, `community-management`, `crisis-and-moderation`,
`reply-and-comment-writer`, `content-research-and-sourcing`, `content-calendar`, `content-audit`,
`cross-platform-repurposing`, `hook-writer`.

Held optional to avoid redundancy: `social-strategy`, `content-pillars`,
`analytics-and-reporting`, `writing-style-and-tone`, `design-and-templates`.

**Material caveat, recorded as SEC-07 in `docs/security.md`:** this set is written around a
commercial product called **WoopSocial**, which appears **1330 times** across its markdown. Skill
descriptions assert product facts such as "WoopSocial publishes", "WoopSocial has no analytics
surface" and "ADVISORY: WoopSocial has no comment/DM/inbox surface". The underlying craft guidance
is genuinely good and permissively licensed, but the user does not use that product. The global
`AGENTS.md` written in Phase 3 must instruct the agent to ignore product-surface claims and to ask
the user which platforms and tools actually exist in their newsroom. This is raised at the phase
checkpoint for an explicit decision.

Positive note: several skills already encode the discipline this project wants. `reply-and-comment-writer`
treats inbound comments and DMs as data rather than instructions (prompt-injection safe), and
`crisis-and-moderation` explicitly forbids autonomous action on high-stakes situations and requires
human approval.

### 4.2 `blacktwist/social-media-skills` — MIT, commit `4f85b0` (2026-05-01)

14 skills, 64 files, **1 code file**. Extremely light and genuinely platform-specific: separate
skills for text-first platforms (LinkedIn, X, Threads, Bluesky) and visual-first platforms
(Facebook, Instagram, TikTok, Pinterest, YouTube).

None selected as core, deliberately:
- `content-calendar-sms` rejected as a **second** calendar system.
- `hook-writer-sms` rejected as a **second** hook implementation.
- `caption-writer-sms`, `thread-writer-sms`, `carousel-writer-sms` listed as **optional** — real
  craft value, but the core already covers the job and the plan warns against trigger clutter.

This repository is the strongest "expand later" source for platform-specific depth.

### 4.3 `coreyhaines31/marketingskills` — MIT, commit `dda3841` (2026-10-02)

50 skills, 545 files, 97 code files. Well maintained, but the frame is SaaS and product marketing:
`churn-prevention`, `paywalls`, `cro`, `attribution`, `cold-email`, `directory-submissions`.

The seed named `social-content`; the actual skill is named **`social`**. Its triggers ("social
media", "content calendar", "social scheduling", "repurpose this content") overlap almost exactly
with the selected social skills. `copywriting` targets landing and pricing pages rather than an
editorial site.

**Verdict: reject.** Installing it alongside `social-media-skills/skills` would create direct
trigger competition for no net gain.

### 4.4 `scrapecreators/social-media-research-skills` — MIT, commit `64ba7b4` (2026-08-26)

13 skills, 49 files, 1 code file. Attractive domain fit, but the frontmatter is decisive:

```yaml
metadata:
  openclaw:
    requires:
      env:
        - SCRAPECREATORS_API_KEY
```

`content-repurposing` and `scrapecreators-api` are both gated behind a **paid third-party API**.
`scrapecreators-api` alone contains 55 external URLs and 4 `API_KEY` references.

**Verdict: reject for the core.** The repurposing job is covered better by
`cross-platform-repurposing`, which needs nothing. If the user later wants real cross-platform
listening and scraping, this becomes a legitimate *optional* integration with a documented
scraping/terms-of-service consideration.

---

## 5. Website, content and SEO

Three SEO candidates were compared as required.

| Candidate | License | Shape | Verdict |
|---|---|---|---|
| `affaan-m/ecc` → `skills/seo` | MIT | **One file**, 4.3 KB, zero code. Covers technical SEO, on-page, structured data, Core Web Vitals, content strategy, keyword mapping. | **Selected** |
| `iannuttall/seo` → `skills/seo` | Apache-2.0 | 2957 files, 1148 code files, monorepo with `apps/`, `packages/`, `scripts/`, `evals/`. Its own description says it "Routes to evidence-backed local reports through the SEO CLI and MCP server". | Reject |
| `coreyhaines31/marketingskills` → `seo-audit` | MIT | Instruction-only, 17 KB. Reads as site-architecture and traffic-recovery oriented. | Reject, overlaps and weaker editorial fit |

`affaan-m/ecc` is a mega-bundle (section 6) and is rejected **as a repository**, but its
`skills/seo` directory is a single self-contained instruction file with no code and no dependency.
Extracting one directory from a large repository is auditable in a way that installing the bundle
is not. The manifest pins the exact commit and subdirectory so the extraction is reproducible and
reviewable.

`vercel-labs/agent-skills` → `writing-guidelines` was also considered and rejected. See section 9.

---

## 6. Rejected mega-bundles

Two repositories were rejected outright on size and scope.

| Repository | Files | Code files | `SKILL.md` count | Why rejected |
|---|---|---|---|---|
| `affaan-m/ecc` | 4241 | 1006 | **1027** | Contains `hooks/`, `mcp-configs/`, `docker/`, `scripts/`, `scaffolds/`, `integrations/`, `tests/`, and ~20 vendor-specific directories (`.claude`, `.codex`, `.cursor`, `.gemini`, `.opencode`, `.zed`, `.trae`, …). Installing it would flood global skill discovery and import an enormous executable surface for one needed file. |
| `PracticalSwan/agent-skills` | 2275 | 438 | **248** | Predominantly Azure, Databricks, Hugging Face, CUDA, Figma, Stitch, Tavily and document-automation skills. Two individual skills are extracted; the bundle is not. |

`PracticalSwan/agent-skills` deserves credit: it is the best-licensed repository reviewed. It ships
`LICENSE.txt`, `LICENSE-APACHE-2.0.txt`, `LICENSE-GITHUB-MIT.txt` and `THIRD_PARTY_NOTICES.md`
inside each skill directory, declares `license: "MIT AND Apache-2.0"` in frontmatter, and stamps
`last_updated` dates. That discipline is exactly what the two unlicensed repositories lack.

---

## 7. Design and web design comparison

The plan required a real comparison rather than a popularity ranking. Criteria: quality of
generated and refined UI, resistance to generic AI patterns, editorial/media fit, brand-system
preservation, audit and critique capability, accessibility and responsive guidance, context cost,
Agent Skills portability, executable code and hooks, external account requirements, Windows
compatibility, licensing, maintenance health.

| | **Impeccable** | **Hallmark** | **frontend-design** | **web-design-guidelines** (PracticalSwan) |
|---|---|---|---|---|
| Repo / license | `pbakaus/impeccable` · Apache-2.0 | `Nutlope/hallmark` · MIT | `PracticalSwan/agent-skills` · MIT AND Apache-2.0 | `PracticalSwan/agent-skills` · MIT |
| Version | 4.5.0 | 1.1.0 | 2.0 (2026-09-08) | 2.0 (2026-09-08) |
| Last commit | **2026-10-04** | 2026-08-06 | 2026-09-14 | 2026-09-14 |
| `SKILL.md` size | **~1.6k words** | ~9.8k words | ~16.5 KB | ~3.8 KB |
| Supporting files | 41 reference `.md` | ~100 reference `.md` | 8 files incl. accessibility checklist | 1 |
| Executable code in skill | 0 installed (optional CLI excluded) | **0** | 1 (stdlib-only Python contrast checker) | 0 |
| External service | none | none found | none | none |
| Windows support | ships `scripts/impeccable.cmd` | pure docs | Python needed for the checker | pure docs |
| Accessibility | covered in skill + `craft-floor`/`harden` refs | `responsive.md` + refs | dedicated `references/accessibility-checklist.md` | explicit guidelines review |
| Audit / critique | `audit`, `critique`, `doctor`, `component-review` refs | `audit`, `slop-test` refs | rendered verification | whole skill is a review pass |
| Deterministic anti-pattern detection | yes, via optional CLI | `slop-test.md` reference | no | no |
| Media/editorial fit | strong; explicit UX-copy and editorial states | strong; named editorial components (`ft1-mast-headed`, `h5-letter-hero`) | strong; mentions editorial surfaces | neutral |
| Native `.agents` layout | **yes**, ships `.agents/skills/impeccable` | `skills/hallmark` | repo-root skill dir | repo-root skill dir |

### Together AI boundary — resolved

The seed flagged Hallmark as "powered by Together AI" and required identifying which features need
an external service. A full-text search of all 107 files for `TOGETHER_API`, `api.together`,
`together.ai`, `API_KEY`, and "requires an api/key/token" returned **zero matches**. The only
occurrence is a single branding line in `SKILL.md`: `**Powered by Together AI.**`

**Finding: Hallmark has no functional external-service dependency.** It is entirely instruction and
reference material. This is recorded in the manifest with an instruction to re-verify on update, in
case a future version introduces a real integration.

### Impeccable CLI boundary — resolved

The plan required separating Impeccable's portable skill from its optional CLI/hook layer.

- **No prebuilt binary is committed** at the pinned ref (`0` `.exe` files under `.agents/`).
- The launcher (`scripts/impeccable` bash + `scripts/impeccable.cmd` for Windows) "runs a
  self-contained binary that ships next to it or is downloaded once on first run".
- Upstream explicitly states **no Node or other runtime is required**, which corrects the seed's
  assumption that the CLI needed Node.
- The skill has a documented degraded path: if the launcher refuses or fails, the agent is
  instructed to say so and read project context directly. The `reference/degraded/` files cover
  operation without the four CLI-backed sub-agents.

**Decision: install the instruction layer only.** `SKILL.md` plus the 41 `reference/*.md` files.
Exclude `scripts/` and the hook/live-browser surface, because a first-run binary download is remote
code execution and does not belong in a default install. Recorded as SEC-05.

### Decision

**Primary design skill: `impeccable`.** Lightest always-on cost, most recent maintenance, broadest
capability coverage, deterministic anti-pattern detection available as an opt-in extra, Apache-2.0,
and it already ships a native `.agents/skills` layout so no vendor copy is needed.

**Review/standards skill: `web-design-guidelines`** from PracticalSwan — 3.8 KB, self-contained,
properly licensed. This gives the "one primary plus one lightweight review" structure the plan
anticipated.

**`hallmark` → optional.** Excellent content and a genuine editorial component library, but 9.8k
words of always-on-when-activated content overlapping Impeccable's job. Available if the user
prefers its anti-slop emphasis.

**`frontend-design` → optional.** Credible alternative primary with an explicit accessibility
checklist, but it duplicates a role already filled.

**A dedicated design-system skill → not needed.** `impeccable` covers design systems, tokens and
theming internally, and `design-and-templates` covers the brand-kit case for social assets. Adding
another would be redundancy.

Only **two** design skills are installed, not four.

---

## 8. Accessibility

The plan asked for `accesslint/skills` → `accessibility-audit` or a lower-dependency WCAG
alternative, installed only if its execution model passes review. It does not pass:

```yaml
allowed-tools: Read, Glob, Grep, Bash, Skill, Task,
  mcp__plugin_accesslint_accesslint__list_rules,
  mcp__plugin_accesslint_accesslint__explain_rule
```

Without the AccessLint MCP server the skill is inert, and the repository has **no LICENSE file**.
All five accesslint skills share this dependency.

**Selected instead:** `jamditis/claude-skills-journalism` → `accessibility-compliance`. MIT, two
files, zero code, and specifically scoped to "news and academic sites" — WCAG audits, alt text,
accessible data visualization, assistive technology. Its `SKILL.md` mentions `npm`/`node` only as
examples of what an auditor might reach for, not as a requirement.

This yields WCAG 2.2 coverage with no service, no account and no executable code.

---

## 9. Licensing findings that changed selections

Three repositories have **no LICENSE file** at their pinned refs:

| Repository | Ref | PracticalSwan equivalent |
|---|---|---|
| `vercel-labs/agent-skills` | `063bee9` | `web-design-guidelines` is byte-identical in description and properly licensed |
| `stevysmith/og-image-skill` | `7314a1e` | none |
| `accesslint/skills` | `2e9d733` | `accessibility-compliance` (jamditis, MIT) |

Without an explicit grant, default copyright applies and redistribution is not permitted. For a
repository intended to be published publicly and installed on other machines, that is a blocker,
not a preference.

- `vercel-labs/agent-skills` also has `package.json` with `"private": true` and no `license` field,
  and both of its candidate skills are ~1.3 KB pointers that fetch an external handbook at runtime.
  **Rejected** in favour of the properly licensed PracticalSwan equivalents.
- `stevysmith/og-image-skill` → `og-image` is technically a strong fit for a media site (Open Graph
  and social preview images at 1200×630 built from the existing design system), but is classified
  **`needs-review`** rather than rejected outright, so the user can decide. It also needs a headless
  browser to actually produce images.

Note the contrast with `pbakaus/impeccable`, which ships **19 copies** of the same skill under 19
different vendor directories. Only `.agents/skills/impeccable` is selected; the other 18 are never
installed.

---

## 10. Additional capability areas searched

| Area | Outcome |
|---|---|
| Content repurposing | Covered: `cross-platform-repurposing` (core). Paid-API alternative rejected. |
| Content audit and analytics | Covered: `content-audit` (core), `analytics-and-reporting` (optional). |
| Community management: replies, moderation, escalation, sentiment triage, playbooks | Strongly covered: `community-management`, `reply-and-comment-writer`, `crisis-and-moderation`. Sentiment triage specifically is the weakest sub-area; triage and severity live inside `crisis-and-moderation`. |
| Headline / hook / caption craftsmanship for a news brand | Covered: `hook-writer` (core), `newsroom-style` for headline conventions. Deeper per-platform options are optional. |
| Visual / social template systems and brand kits | Optional: `design-and-templates`. |
| Open Graph and social preview assets | **`needs-review`**: `og-image`, blocked on missing license. |
| Web accessibility / WCAG for public media pages | Covered: `accessibility-compliance` (core). |
| Editorial web publishing / CMS workflows | **Gap.** No candidate met the bar. WordPress-specific skills are site-specific; a generic CMS skill will not trigger reliably. Revisit once the CMS is known. |
| Browser / web QA for live pages | Optional: `web-testing`, `web-quality-audit`. Excluded from core because they need a browser runtime. |
| Research / news monitoring without encouraging fabrication | Covered: `source-verification`, `fact-check-workflow`, `content-research-and-sourcing`. `page-monitoring` rejected for needing a paid service. |
| Translation / localization | **Gap.** No strong portable candidate found in the sources reviewed. |
| Video, audio, podcast production | Out of scope. Candidates exist (`jamditis/video-toolkit`) but were not selected for a text-first kit. |

Gaps are recorded in `manifest/skills.json` under `coverage.knownGaps` so they are explicit rather
than silently missing.

---

## 11. Optional integrations evaluated

No integration was connected, authenticated, or configured.

### Figma MCP — optional, likely blocked

Official remote server; Figma strongly recommends the remote endpoint over the desktop app. Two
findings drive the classification:

1. **It is plan-gated.** Per Figma's own rate-limit documentation: Starter seats get up to 20 tool
   calls per month; View/Collab seats on Organization or Enterprise get up to 6 per month; Dev/Full
   seats get up to 200/day on Professional and up to 600/day on Enterprise. Meaningful design-to-code
   use effectively requires a paid Dev or Full seat.
2. **Client support is unverified and may be disqualifying.** Figma states that *only* clients
   listed in the Figma MCP Catalog can connect, and that new clients must join a waitlist. Whether
   OpenCode 2.0.22 and Cline 0.0.43 are catalog-listed was **not** verified and must not be assumed.

Requires per-user OAuth. Figma also publishes its own skills for MCP clients; those are
agent-specific and would never belong in the canonical core.

### Canva MCP — optional, account-bound

Official remote server exposing design generation and editing, brand kits and asset management,
multi-format export, and comments. Attractive for social asset production. Kept optional because it
requires a Canva Developer Platform app plus per-user OAuth, and the published documentation is
written for IT admins and platform teams rather than for an individual connecting a personal coding
agent. Whether it helps this user's actual workflow is unknown.

### Cline plugin catalog — inspected, rejected for the core

Cloned and read. 20 plugins, of which 18 bundle skills. Findings:

- Every plugin is an **executable `index.ts`** that runs inside Cline. Not portable.
- `plugins/jev-browser` is the highest-risk item reviewed anywhere in this phase: dedicated
  `credentials.ts` and `credentials.test.ts`, per-platform bundled remote-helper binaries, IPC, and
  a recording overlay. It manages external service credentials.
- `plugins/agent-browser` provides general browser automation.
- `plugins/clickhouse-data-analyst` alone contributes 17 nested skills and two Python
  `verify_install.py` scripts — a ClickHouse data platform, not a newsroom concern.
- `plugins/mac-notify` is macOS-only and irrelevant on Windows.

Browser automation is genuinely useful for a website and social workflow, but the Cline-native
options are agent-specific executables. Cross-agent browser QA is covered at skill level instead
(`web-testing`, `web-quality-audit`, both optional). Recorded as SEC-09.

### Tooling prerequisites

- **GitHub CLI** — absent; required only in Phase 6; will be installed with `winget` and
  authenticated interactively with the user present.
- **Node.js** — absent. The selected core is deliberately Node-free, and neither OpenCode's CLI nor
  Cline's sidecar needs system Node. Do not install it by default.

---

## 12. Core set summary

18 core skills, all instruction-only, all permissively licensed, none requiring an account, an API
key, a network call, or an executable.

| Domain | Core skills |
|---|---|
| Editorial and factual integrity | `newsroom-style`, `source-verification`, `fact-check-workflow`, `editorial-workflow`, `ai-writing-detox` |
| Brand and community | `brand-profile`, `community-management`, `crisis-and-moderation`, `reply-and-comment-writer` |
| Social planning, craft and audit | `content-research-and-sourcing`, `content-calendar`, `content-audit`, `cross-platform-repurposing`, `hook-writer` |
| Website and SEO | `seo` |
| Design and accessibility | `impeccable`, `web-design-guidelines`, `accessibility-compliance` |

Redundancy rules applied, per the plan:

- **One calendar system.** `content-calendar` chosen; `content-calendar-sms` left optional.
- **One hook implementation.** `hook-writer` chosen; `hook-writer-sms` left optional.
- **One repurposing system.** `cross-platform-repurposing` chosen; the paid-API alternative rejected.
- **One brand-context system.** `brand-profile` chosen; no separate `brand-voice` skill added,
  because `brand-profile` already owns voice and the repo's `voice-builder` sits behind it.
- **One SEO skill.** `seo` chosen from three candidates.
- **One accessibility system.** Instruction-only WCAG chosen over the MCP-gated alternative.
- **Two design skills**, not four: one primary plus one review pass.

Estimated always-on cost at ~100 tokens of metadata per skill is roughly 1800 tokens, which is a
deliberate trade for eliminating nine overlapping implementations.

---

## 13. Decisions requiring user confirmation at the checkpoint

1. **The `social-media-skills/skills` vendor framing (SEC-07).** Nine of the eighteen core skills come
   from this repository, and its text assumes a product called WoopSocial that the user does not
   use. Options: accept with a documented instruction in the global `AGENTS.md` to ignore
   product-surface claims; accept a smaller subset; or drop the repository and accept weaker
   community-management coverage.
2. **`og-image` (needs-review).** Good media fit, blocked only by a missing license.
3. **Impeccable CLI excluded.** Confirm that the default install should stay instruction-only, with
   the binary-downloading CLI as an opt-in extra.
4. **CMS/publishing and localization gaps.** Confirm whether to source a skill once the CMS and
   language needs are known.