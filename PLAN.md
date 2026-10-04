# PLAN — Newsroom Agent Kit

## Objective

Build a reusable, GitHub-hosted, **agent-agnostic** Windows setup for global AI-agent skills and instructions aimed at a community manager / content producer working for a media outlet.

The setup must:

- use `%USERPROFILE%\.agents` as the canonical global root;
- work directly with any coding agent that supports the shared `.agents` / Agent Skills convention;
- be explicitly tested on OpenCode and Cline without branding or architecting the project around either vendor;
- provide a curated, security-reviewed skill set for social media, newsroom/editorial work, content production, source verification, SEO, design, and web design;
- optionally support carefully selected MCP/plugin integrations without making them mandatory;
- be safe, idempotent, documented, version-controlled, reproducible, and easy to install on another Windows PC;
- end with a GitHub repository whose README contains a short copy/paste prompt that tells another coding agent to clone that repository and install the setup.

## Working mode

This plan is phase-gated.

**Execute only one phase per user interaction.** Within the current phase, continue autonomously until its exit criteria are met. Then:

1. validate the phase;
2. update every justified checkbox;
3. update durable docs/manifests;
4. commit all work;
5. ensure `git status` is clean;
6. summarize the phase and STOP for user review.

Do not start the next phase until the user responds.

---

## Phase 0 — Bootstrap the workspace and tracking

### Goals

Establish a safe local project repository before making any machine-level changes.

### Tasks

- [x] Read `AGENTS.md`, this `PLAN.md`, `README.md`, and `docs/seed-discovery.md`.
- [x] Confirm the current workspace path and that it is intended for this project.
- [x] Check whether the workspace is already a Git repository.
- [x] If it is not a Git repository, run `git init`.
- [x] Confirm that there is **no Git remote** at this stage.
- [x] Add a minimal `.gitignore` covering transient logs, temp directories, local backups, caches, secrets, and machine-specific generated state.
- [x] Record the starting repository state in `docs/bootstrap-state.md`.
- [x] Create an initial baseline commit containing the bootstrap files.
- [x] Verify `git status` is clean.

### Exit criteria

- Local Git history exists.
- No remote exists.
- Bootstrap files are committed.
- Working tree is clean.

### Phase checkpoint

STOP and report the baseline commit and next-phase scope.

---

## Phase 1 — Windows and agent environment discovery

### Goals

Discover the actual machine state without modifying global agent configuration.

### Tasks

- [x] Record Windows edition/build and PowerShell version.
- [x] Resolve `%USERPROFILE%` and the intended canonical root `%USERPROFILE%\.agents`.
- [x] Detect Git, Node.js, npm/npx, OpenCode, Cline, and GitHub CLI (`gh`) availability and versions.
- [x] Confirm OpenCode's current native support for `%USERPROFILE%\.agents\skills` and determine whether its global `AGENTS.md` still requires a separate documented path.
- [x] Confirm Cline's current native support for `%USERPROFILE%\.agents\skills` and `%USERPROFILE%\.agents\AGENTS.md`.
- [x] Locate any vendor-specific config paths only where needed for optional capabilities or a proven compatibility exception.
- [x] Inspect `%USERPROFILE%\.agents` if it already exists.
- [x] Inspect existing global agent rules/skills for conflicts or user-created content.
- [x] Do not modify, delete, relocate, or normalize existing global config during discovery.
- [x] Determine whether NTFS hardlinks/symlinks are viable only for any **proven instruction-file compatibility exception**; do not plan links for skills that are natively discovered from `.agents`.
- [x] Prefer direct native `.agents` discovery over any link or adapter.
- [x] Document all findings in `docs/environment.md`.
- [x] Update `docs/architecture.md` with confirmed rather than assumed paths.
- [x] Commit discovery documentation and plan checkbox updates.
- [x] Verify `git status` is clean.

### Exit criteria

- Actual installed agents and paths are known.
- Existing user state is documented.
- Compatibility strategy can be implemented without guessing.

### Phase checkpoint

STOP and present important conflicts or path differences before installation work.

---

## Phase 2 — Current skills, plugins, and integration discovery

### Goals

Build a curated shortlist rather than installing a random bundle.

### Research method

Use current web research and inspect upstream repositories directly. Prefer:

1. official project documentation;
2. upstream GitHub repositories;
3. established Agent Skills registries such as Skills.sh for discovery;
4. secondary commentary only as supplementary evidence.

For every candidate capture:

- exact name;
- upstream repository and path;
- purpose/triggers;
- license;
- current maintenance signals;
- whether it contains scripts, hooks, binaries, or executable code;
- network/API requirements;
- authentication or paid-service requirements;
- overlap with other candidates;
- portability across Agent Skills-compatible tools;
- security/audit warnings;
- recommendation: `core`, `optional`, `reject`, or `needs-review`.

### Seed candidates to revalidate

These are research leads, not pre-approved installs.

#### Cross-agent foundation

- [x] Revalidate the Agent Skills `SKILL.md` format and current portable directory conventions.
- [x] Revalidate OpenCode global `.agents/skills` discovery.
- [x] Revalidate Cline global `.agents/skills` discovery and global `.agents/AGENTS.md` behavior from current runtime/docs.
- [x] Revalidate OpenCode global instruction discovery and identify the smallest compatibility mechanism only if it still does not consume `~/.agents/AGENTS.md` directly.
- [x] Identify additional coding agents that natively support the shared Agent Skills / `.agents` convention, solely to document compatibility—not to add vendor-specific installation branches.
- [x] Evaluate whether a third-party skills manager adds value or whether this repo should manage canonical installs itself.
- [x] Explicitly evaluate the tradeoff between the `npx skills` CLI and a custom PowerShell installer. Do not let a tool silently violate the canonical `%USERPROFILE%\.agents` architecture.

#### Newsroom/editorial and factual integrity

- [x] Evaluate `jamditis/claude-skills-journalism` → `newsroom-style`.
- [x] Evaluate `jamditis/claude-skills-journalism` → `source-verification`.
- [x] Evaluate `notque/vexjoy-agent` → `fact-check`.
- [x] Evaluate `notque/vexjoy-agent` → `news-collection`.
- [x] Decide whether newsroom-style plus source-verification are sufficient or whether fact-check/news-collection add distinct value.

#### Social/community/content

- [x] Evaluate `social-media-skills/skills` → `brand-profile`.
- [x] Evaluate `social-media-skills/skills` channel-specific skills that are actually relevant to the user's platforms.
- [x] Evaluate `coreyhaines31/marketingskills` → `social-content`.
- [x] Evaluate `coreyhaines31/marketingskills` → `copywriting`.
- [x] Evaluate `blacktwist/social-media-skills` → `content-calendar-sms`.
- [x] Evaluate `notque/vexjoy-agent` → `content-calendar`.
- [x] Evaluate `scrapecreators/social-media-research-skills` → `content-repurposing`.
- [x] Evaluate `social-media-skills/skills` → `content-audit`.
- [x] Evaluate `social-media-skills/skills` → `design-and-templates`.
- [x] Avoid installing two calendar systems unless there is a clear operational reason.
- [x] Avoid installing multiple repurposing/brand-context systems unless they have clearly distinct jobs.
- [x] Evaluate whether a dedicated `brand-voice` skill adds value beyond `brand-profile`.

#### Website/content/SEO

- [x] Evaluate `vercel-labs/agent-skills` → `writing-guidelines`.
- [x] Evaluate a single SEO skill. Compare at least:
  - `affaan-m/ecc` → `seo`;
  - `iannuttall/seo` → `seo`;
  - one other strong current candidate if research finds a better fit.
- [x] Prefer a skill appropriate to an editorial/media website rather than SaaS-only marketing.

#### Design and web design

- [x] Evaluate `pbakaus/impeccable` → `impeccable` as a first-class candidate for production-grade UI design, critique, audit, polish, typography, layout, accessibility, responsive behavior, design-system context, and deterministic anti-pattern detection.
- [x] Inspect Impeccable's optional CLI/hook layer separately from the portable skill itself. Record Node/runtime requirements and do not require hooks for the agent-agnostic core unless they provide clear value.
- [x] Evaluate `Nutlope/hallmark` → `hallmark` as a first-class candidate for anti-AI-slop design, structural variety, redesign/audit workflows, design extraction from screenshots/URLs, and portable design-system output.
- [x] Inspect Hallmark's Together AI dependency/capability boundary and determine which features work as a plain portable skill versus which require external services. External-service-dependent features must not silently enter the no-account-required core.
- [x] Evaluate `PracticalSwan/agent-skills` → `frontend-design`.
- [x] Evaluate `vercel-labs/agent-skills` → `web-design-guidelines`.
- [x] Compare **Impeccable vs Hallmark vs frontend-design vs web-design-guidelines** for overlap, portability, context cost, executable dependencies, external-service requirements, design quality, audit capabilities, accessibility, and fit for editorial/media websites.
- [x] Prefer the smallest complementary combination. Do not install all four if one or two cover the workflow better.
- [x] Consider a structure such as one primary design-generation/refinement skill plus one lightweight standards/review skill if evidence supports it.
- [x] Evaluate whether a dedicated design-system skill is useful or redundant after the comparison above.
- [x] Evaluate `accesslint/skills` → `accessibility-audit` or a lower-dependency WCAG alternative; install only if its execution/dependency model passes review.
- [x] Evaluate an Open Graph/social-preview image skill such as `stevysmith/og-image-skill` → `og-image` if it fits media-site workflows.
- [x] Prefer accessible, responsive, production-quality web design guidance over purely stylistic prompting.

#### Additional discovery areas

The seed list is intentionally incomplete. Search for strong current candidates in these capability areas and add them to the comparison when they provide distinct value:

- [x] Content repurposing: article/video/transcript → platform-native social derivatives.
- [x] Content audit and analytics/reporting: identify winning/weak content and feed planning decisions.
- [x] Community management: comment/reply moderation, response drafting, escalation rules, sentiment/issue triage, and community playbooks.
- [x] Headline/hook/caption craftsmanship suitable for a news/media brand rather than only SaaS marketing.
- [x] Visual/social template systems, brand kits, and repeatable asset production.
- [x] Image/creative asset workflows, including Open Graph/social preview assets where appropriate.
- [x] Web accessibility/WCAG review for public-facing media pages.
- [x] Editorial web publishing/CMS workflows, including WordPress or another CMS only when broadly useful and not overly site-specific.
- [x] Browser/web QA skills useful for checking live pages, responsive layouts, metadata, previews, and publishing output.
- [x] Research/news monitoring and source-grounded content workflows that do not encourage fabrication or unattributed reuse.
- [x] Translation/localization and adaptation workflows if a high-quality portable candidate exists.
- [x] Reject generic mega-skill bundles when a smaller, auditable specialist set covers the same needs.

#### Optional MCP/plugins

These must remain optional unless the user explicitly wants them.

- [x] Evaluate the official Figma MCP server for design-context/design-to-code workflows and verify whether the installed OpenCode/Cline surfaces can currently use it.
- [x] Evaluate the official Canva MCP server for media/design production and determine whether it is useful for this user's workflow.
- [x] Inspect the official Cline plugin catalog for useful capabilities such as browser automation or image generation, but mark Cline-only capabilities as agent-specific rather than part of the portable core.
- [x] Search for cross-agent browser/web preview or accessibility tooling that improves website-content/design work without unnecessary cloud dependencies.
- [x] Do not authenticate or connect any external account during discovery.

### Selection deliverables

- [x] Create `docs/discovery.md` with evidence and decisions.
- [x] Create `docs/security.md` with supply-chain and capability risk notes.
- [x] Create `manifest/skills.json` containing the curated skill set with source metadata and intended install status.
- [x] Create `manifest/integrations.json` for optional MCP/plugins.
- [x] Keep the default core reasonably small; avoid context/trigger clutter.
- [x] Commit discovery, manifests, and plan progress.
- [x] Verify `git status` is clean.

### Exit criteria

A defensible curated set exists, with each item classified and no installation performed yet.

### Phase checkpoint

STOP and show the proposed core vs optional set. The user may add/remove candidates before installation.

---

## Phase 3 — Design and implement the portable installer

### Goals

Create the reusable installation system while keeping `%USERPROFILE%\.agents` canonical.

### Intended repository structure

Refine if discovery justifies changes.

```text
newsroom-agent-kit/
├── AGENTS.md
├── CLAUDE.md
├── PLAN.md
├── README.md
├── global/
│   └── AGENTS.md
├── manifest/
│   ├── skills.json
│   └── integrations.json
├── scripts/
│   ├── install.ps1
│   ├── update.ps1
│   ├── verify.ps1
│   └── uninstall.ps1
└── docs/
    ├── architecture.md
    ├── discovery.md
    ├── environment.md
    ├── security.md
    └── troubleshooting.md
```

### Tasks

- [x] Define the canonical layout under `%USERPROFILE%\.agents`.
- [x] Create the curated global `global/AGENTS.md` for the community-manager/newsroom workflow.
- [x] Keep global instructions high-signal; move detailed workflows into skills instead of inflating global context.
- [x] Implement a machine-readable skill manifest with pinned or otherwise reproducible upstream references.
- [x] Implement `scripts/install.ps1`.
- [x] Installer must support a dry-run/preview mode.
- [x] Installer must be idempotent.
- [x] Installer must detect existing files and refuse unsafe overwrite.
- [x] Installer must back up only the files it needs to change and keep those backups outside Git-tracked content.
- [x] Installer must install/sync canonical skills into `%USERPROFILE%\.agents\skills`.
- [x] Do **not** create OpenCode or Cline skill adapters if their installed versions natively scan `%USERPROFILE%\.agents\skills`.
- [x] Do **not** duplicate skills into `.cline`, `.opencode`, `.claude`, `.codex`, or other vendor directories merely for convenience.
- [x] Implement a tool-specific compatibility mechanism only for a capability that is proven missing from native `.agents` support.
- [x] If OpenCode still requires `~/.config/opencode/AGENTS.md` for global instructions, prefer a minimal reversible link to canonical `%USERPROFILE%\.agents\AGENTS.md` rather than an independently maintained copy.
- [x] Cline should consume `%USERPROFILE%\.agents\AGENTS.md` and `%USERPROFILE%\.agents\skills` natively when the installed version confirms support.
- [x] Do not destroy pre-existing unrelated agent skills, rules, config, or instructions.
- [x] Implement `scripts/verify.ps1`.
- [x] Implement `scripts/update.ps1` with upstream-change review rather than blind execution of newly introduced third-party scripts.
- [x] Implement safe `scripts/uninstall.ps1` that removes only artifacts owned by this kit and restores backed-up state when appropriate.
- [x] Add logging that does not leak secrets.
- [x] Add clear errors and remediation guidance.
- [x] Add `docs/troubleshooting.md`.
- [x] Add automated/static checks for malformed `SKILL.md` metadata where practical.
- [x] Commit implementation and checklist progress.
- [x] Verify `git status` is clean.

### Exit criteria

Installer/update/verify/uninstall tooling exists and can be reviewed before touching global user state.

### Phase checkpoint

STOP and summarize exactly what installation will modify on the machine.

---

## Phase 4 — Install globally and validate OpenCode + Cline

### Goals

Apply the setup to the current Windows user and prove it works.

### Tasks

- [ ] Run installer in dry-run mode and inspect the exact proposed changes.
- [ ] Resolve any conflict with existing user files without data loss.
- [ ] Run the real installer.
- [ ] Verify `%USERPROFILE%\.agents\AGENTS.md`.
- [ ] Verify canonical skills under `%USERPROFILE%\.agents\skills`.
- [ ] Verify no unnecessary vendor-specific skill copies/adapters were created.
- [ ] Verify representative skills are visible/usable directly from `%USERPROFILE%\.agents\skills` in OpenCode.
- [ ] Verify representative skills are visible/usable directly from `%USERPROFILE%\.agents\skills` in Cline.
- [ ] Verify global instructions are effectively loaded by OpenCode, documenting any minimal compatibility link needed for that file.
- [ ] Verify global instructions are effectively loaded natively by Cline from `%USERPROFILE%\.agents\AGENTS.md`.
- [ ] Run `scripts/verify.ps1` and save only non-sensitive diagnostic output needed for development.
- [ ] Rerun installer and verify idempotency.
- [ ] Confirm existing unrelated user configuration still exists.
- [ ] Test update behavior without accepting unreviewed upstream risk.
- [ ] Test uninstall in a reversible/sandboxed manner if practical, then reinstall; otherwise test its preview mode thoroughly.
- [ ] Update docs with actual observed behavior.
- [ ] Commit implementation fixes, evidence notes, and plan progress.
- [ ] Verify `git status` is clean.

### Exit criteria

The global setup actually works in OpenCode and Cline on this machine.

### Phase checkpoint

STOP and report the installed core skills, optional integrations not installed, and validation results.

---

## Phase 5 — Make the repository portable and one-prompt installable

### Goals

Turn the working setup into something another coding agent can install on another Windows PC.

### Tasks

- [ ] Remove machine-specific state from tracked files.
- [ ] Confirm no secrets, tokens, cookies, personal file contents, or backups are tracked.
- [ ] Ensure upstream source attribution and licenses are handled correctly.
- [ ] Decide whether third-party skills are vendored, fetched, or pinned by manifest based on license/security/maintainability.
- [ ] Make installer bootstrap missing non-sensitive prerequisites where appropriate.
- [ ] Document minimum prerequisites in `README.md`.
- [ ] Make the README/project identity explicitly agent-agnostic: a `.agents` / Agent Skills setup for any compatible coding agent.
- [ ] Do not title or describe the project as being "for OpenCode", "for Cline", or "for OpenCode and Cline".
- [ ] Add a concise compatibility section saying **tested with OpenCode and Cline**, while distinguishing native shared-standard support from any tool-specific exception.
- [ ] Add an installation prompt to `README.md` that another user can paste into a coding agent.
- [ ] The installation prompt must instruct the agent to clone the repository URL, inspect `README.md`/installation instructions, install to `%USERPROFILE%\.agents`, preserve existing config, create required compatibility adapters, run verification, and report results.
- [ ] Use a temporary placeholder for the final repository URL until GitHub publication.
- [ ] Add manual install instructions as a fallback.
- [ ] Add update and uninstall instructions.
- [ ] Add architecture and security notes concise enough for a non-developer operator.
- [ ] Test the bootstrap flow from a clean temporary directory as far as practical.
- [ ] Commit portability work and checkbox updates.
- [ ] Verify `git status` is clean.

### Exit criteria

The repository is ready to publish and install elsewhere, with only the real GitHub URL missing from the README prompt.

### Phase checkpoint

STOP and show the exact README installation prompt template before publication.

---

## Phase 6 — Create and publish the GitHub repository

### Goals

Create the remote repository and replace the README placeholder with the real clone URL.

### GitHub CLI rules

- Use `gh` CLI.
- If `gh` is missing, install GitHub CLI using `winget`.
- After installation, verify with `gh --version`.
- Check authentication with `gh auth status`.
- If not authenticated, STOP and ask the user to authenticate. Explain the exact command, normally:
  - `gh auth login`
  - select GitHub.com;
  - choose HTTPS unless the user prefers SSH;
  - authenticate through the browser/device flow;
  - rerun `gh auth status`.
- Do not request or print a GitHub token in chat or commit credentials.

### Tasks

- [ ] Detect the authenticated GitHub account with `gh`.
- [ ] Confirm repository name; default to `newsroom-agent-kit` unless unavailable or the user chose another name.
- [ ] If public/private visibility has not been decided, ask the user at this phase boundary before remote creation. Recommend `public` for frictionless cross-machine installation, but do not assume consent to publish.
- [ ] Create the repository using `gh repo create`.
- [ ] Ensure the GitHub repository description is agent-agnostic and centered on `.agents` / portable Agent Skills, not OpenCode or Cline.
- [ ] If repository topics are added, prefer standard/domain terms (`agent-skills`, `agents`, `community-management`, `content-workflow`, etc.); do not make vendor names the primary identity.
- [ ] Add the new GitHub remote to this previously local-only repository.
- [ ] Replace the README repository URL placeholder with the actual HTTPS GitHub URL.
- [ ] Ensure the README copy/paste prompt contains the actual repository URL.
- [ ] Commit the final URL/README update.
- [ ] Push the complete history.
- [ ] Verify the default branch and remote state.
- [ ] Verify the README renders correctly on GitHub.
- [ ] Verify the repository does not contain secrets or machine-specific backups.
- [ ] Record the final repository URL in docs.
- [ ] Verify `git status` is clean and local HEAD matches the remote branch.

### Exit criteria

A real GitHub repository exists and the README contains a working one-prompt bootstrap instruction using its real URL.

### Phase checkpoint

STOP and provide the repository URL plus the final copy/paste installation prompt.

---

## Phase 7 — Final reproducibility and handoff

### Goals

Confirm the project satisfies its original objective and document future maintenance.

### Tasks

- [ ] Run the complete verification suite.
- [ ] Verify all core skills in the manifest resolve to expected sources.
- [ ] Verify global setup remains canonical under `%USERPROFILE%\.agents`.
- [ ] Verify OpenCode and Cline both consume canonical `.agents` skills natively.
- [ ] Verify any remaining tool-specific compatibility mechanism exists only where native `.agents` support is actually missing.
- [ ] Verify README install/update/uninstall instructions match reality.
- [ ] Review optional MCP/plugin integrations and ensure none are presented as required.
- [ ] Document how to add another coding agent without duplicating canonical skills.
- [ ] Document how to add/remove a skill safely.
- [ ] Document the skill-update review process.
- [ ] Ensure the final plan state accurately reflects completed work.
- [ ] Commit final verification/documentation.
- [ ] Push final commit.
- [ ] Verify local and remote working trees are clean/in sync.

### Definition of Done

- `%USERPROFILE%\.agents` is the single canonical global source for skills and the global `AGENTS.md`.
- Any compatible agent can use the shared `.agents` core without vendor-specific skill copies.
- OpenCode and Cline are both tested successfully and are described as tested implementations, not as the project's identity.
- The selected skills cover the required content/newsroom/social/design/web domains without excessive redundancy.
- External executable integrations are optional and clearly separated from the portable skill core.
- Installation is idempotent and non-destructive.
- Existing user config is preserved.
- Update and uninstall paths exist.
- The repository is on GitHub.
- README contains a copy/paste prompt with the real GitHub URL for installing on another computer.
- Git history tracks implementation progress, including plan checkbox advancement.
- No secrets are committed.
- Documentation is current.
