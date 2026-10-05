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

- [x] Run installer in dry-run mode and inspect the exact proposed changes.
- [x] Resolve any conflict with existing user files without data loss.
- [x] Run the real installer.
- [x] Verify `%USERPROFILE%\.agents\AGENTS.md`.
- [x] Verify canonical skills under `%USERPROFILE%\.agents\skills`.
- [x] Verify no unnecessary vendor-specific skill copies/adapters were created.
- [x] Verify representative skills are visible/usable directly from `%USERPROFILE%\.agents\skills` in OpenCode.
- [x] Verify representative skills are visible/usable directly from `%USERPROFILE%\.agents\skills` in Cline.
- [x] Verify global instructions are effectively loaded by OpenCode, documenting any minimal compatibility link needed for that file.
- [x] Verify global instructions are effectively loaded natively by Cline from `%USERPROFILE%\.agents\AGENTS.md`.
- [x] Run `scripts/verify.ps1` and save only non-sensitive diagnostic output needed for development.
- [x] Rerun installer and verify idempotency.
- [x] Confirm existing unrelated user configuration still exists.
- [x] Test update behavior without accepting unreviewed upstream risk.
- [x] Test uninstall in a reversible/sandboxed manner if practical, then reinstall; otherwise test its preview mode thoroughly.
- [x] Update docs with actual observed behavior.
- [x] Commit implementation fixes, evidence notes, and plan progress.
- [x] Verify `git status` is clean.

### Exit criteria

The global setup actually works in OpenCode and Cline on this machine.

### Phase checkpoint

STOP and report the installed core skills, optional integrations not installed, and validation results.

---

## Phase 5 — Make the repository portable and one-prompt installable

### Goals

Turn the working setup into something another coding agent can install on another Windows PC.

### Tasks

- [x] Remove machine-specific state from tracked files.
- [x] Confirm no secrets, tokens, cookies, personal file contents, or backups are tracked.
- [x] Ensure upstream source attribution and licenses are handled correctly.
- [x] Decide whether third-party skills are vendored, fetched, or pinned by manifest based on license/security/maintainability.
- [x] Make installer bootstrap missing non-sensitive prerequisites where appropriate.
- [x] Document minimum prerequisites in `README.md`.
- [x] Make the README/project identity explicitly agent-agnostic: a `.agents` / Agent Skills setup for any compatible coding agent.
- [x] Do not title or describe the project as being "for OpenCode", "for Cline", or "for OpenCode and Cline".
- [x] Add a concise compatibility section saying **tested with OpenCode and Cline**, while distinguishing native shared-standard support from any tool-specific exception.
- [x] Add an installation prompt to `README.md` that another user can paste into a coding agent.
- [x] The installation prompt must instruct the agent to clone the repository URL, inspect `README.md`/installation instructions, install to `%USERPROFILE%\.agents`, preserve existing config, create required compatibility adapters, run verification, and report results.
- [x] Use a temporary placeholder for the final repository URL until GitHub publication.
- [x] Add manual install instructions as a fallback.
- [x] Add update and uninstall instructions.
- [x] Add architecture and security notes concise enough for a non-developer operator.
- [x] Test the bootstrap flow from a clean temporary directory as far as practical.
- [x] Commit portability work and checkbox updates.
- [x] Verify `git status` is clean.

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

- [x] Detect the authenticated GitHub account with `gh`.
- [x] Confirm repository name; default to `newsroom-agent-kit` unless unavailable or the user chose another name.
- [x] If public/private visibility has not been decided, ask the user at this phase boundary before remote creation. Recommend `public` for frictionless cross-machine installation, but do not assume consent to publish.
- [x] Create the repository using `gh repo create`.
- [x] Ensure the GitHub repository description is agent-agnostic and centered on `.agents` / portable Agent Skills, not OpenCode or Cline.
- [x] If repository topics are added, prefer standard/domain terms (`agent-skills`, `agents`, `community-management`, `content-workflow`, etc.); do not make vendor names the primary identity.
- [x] Add the new GitHub remote to this previously local-only repository.
- [x] Replace the README repository URL placeholder with the actual HTTPS GitHub URL.
- [x] Ensure the README copy/paste prompt contains the actual repository URL.
- [x] Commit the final URL/README update.
- [x] Push the complete history.
- [x] Verify the default branch and remote state.
- [x] Verify the README renders correctly on GitHub.
- [x] Verify the repository does not contain secrets or machine-specific backups.
- [x] Record the final repository URL in docs.
- [x] Verify `git status` is clean and local HEAD matches the remote branch.

### Exit criteria

A real GitHub repository exists and the README contains a working one-prompt bootstrap instruction using its real URL.

### Phase checkpoint

STOP and provide the repository URL plus the final copy/paste installation prompt.

---

## Phase 7 — Final reproducibility and handoff

### Goals

Confirm the project satisfies its original objective and document future maintenance.

### Tasks

- [x] Run the complete verification suite.
- [x] Verify all core skills in the manifest resolve to expected sources.
- [x] Verify global setup remains canonical under `%USERPROFILE%\.agents`.
- [x] Verify OpenCode and Cline both consume canonical `.agents` skills natively.
- [x] Verify any remaining tool-specific compatibility mechanism exists only where native `.agents` support is actually missing.
- [x] Verify README install/update/uninstall instructions match reality.
- [x] Review optional MCP/plugin integrations and ensure none are presented as required.
- [x] Document how to add another coding agent without duplicating canonical skills.
- [x] Document how to add/remove a skill safely.
- [x] Document the skill-update review process.
- [x] Ensure the final plan state accurately reflects completed work.
- [x] Commit final verification/documentation.
- [x] Push final commit.
- [x] Verify local and remote working trees are clean/in sync.

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

---

# EXTENSION — Postiz self-hosted and HyperFrames

> **SUPERSEDED IN PART BY PHASE 8B.** Phase 8 was written to add Postiz
> self-hosted. Phase 8B evaluated Zernio as an alternative and selected it
> instead, so the social backend is now Zernio and the "Self-hosted Postiz only"
> principle below no longer describes the default setup. The Phase 8 text is kept
> as the record of what was decided and then revisited. The governing principles
> are in `docs/social-backend-decision.md` and in `AGENTS.md`.
>
> The HyperFrames half of this extension is unchanged.

Phases 0-7 above are complete and are not reopened, duplicated, or rewritten.
This extension adds two capabilities to the same project, and it changes the
project's shape in one important way:

**Local software becomes part of the reproducible setup.** Previously the kit
installed instruction files only, and deliberately required no runtime. From
Phase 8 onward, any runtime, package, container, service or CLI that a
capability needs is detected, provisioned, verified, updated and reproduced by
the kit. Required software is not left as an undocumented manual prerequisite
unless installing it is genuinely unsafe or impossible, in which case it is
recorded as an explicit blocked prerequisite with exact instructions.

The project identity does not change. It remains an **agent-agnostic `.agents` /
Agent Skills toolkit**, tested with OpenCode and Cline. Neither Postiz nor
HyperFrames becomes the identity of the project.

## Extension principles

- `%USERPROFILE%\.agents` remains the single canonical agent configuration root.
  Runtime software lives in its technically appropriate location and is managed
  reproducibly; it does not live under `.agents`.
- Vendor skill directories stay forbidden, including ones created by upstream
  installers.
- Ownership is explicit for every dependency. A normal uninstall removes only
  what is safely attributable to the kit.
- Self-hosted Postiz only. No Postiz Cloud, no `api.postiz.com`, no
  `cli-auth.postiz.com`, no hosted Postiz MCP.
- Local deterministic rendering only. No generative media models, no hosted
  renderers, no cloud rendering as a default.
- No secrets and no runtime data in Git.
- Unavoidable human steps are limited to account, OAuth, developer-approval,
  genuine elevation/reboot, irreversible actions, and material architecture or
  cost decisions. Ordinary software installation is not a human step.

---

## Phase 8 - Extension discovery, overlap analysis, dependency inventory, and architecture decisions

### Goals

Research the actual upstream state from primary sources, decide the
architecture, build the dependency inventory that will drive every later script
change, and rationalise the existing skill set against Postiz. Install nothing
in this phase.

### Tasks

- [x] Inspect repository state: branch, remote, clean tree, phases 0-7 intact.
- [x] Clone and review the four upstream repositories at pinned refs; record ref, date and licence for each.
- [x] Inspect the live installed skill set and `manifest/skills.json` as the baseline for the overlap analysis.
- [x] Determine which Postiz repository is the runtime source and which is implementation context.
- [x] Extract the Postiz compose stack: services, images, published ports, named volumes, health checks.
- [x] Inspect the Postiz CLI and skill: install method, auth paths, custom-endpoint override, credential storage, capabilities, upstream hard rules.
- [x] Determine whether the Postiz OAuth device flow depends on Postiz-hosted infrastructure.
- [x] Choose the fully self-hosted-compatible auth path and record why the other is rejected.
- [x] Confirm whether any capability requires an MCP layer. If not, record that no MCP is proposed and the condition for revisiting it.
- [x] Confirm HyperFrames licence, CLI package, version, engine requirement and documented prerequisites.
- [x] Revalidate the HyperFrames Core Skills model (eager core set vs lazy workflow skills) against current upstream.
- [x] Determine where the upstream HyperFrames installer writes skills, and identify any conflict with this project's rules.
- [x] Choose the HyperFrames skill install method and record the rationale.
- [x] Build the dependency inventory for both capabilities with purpose, version, installed state, Windows mechanism, elevation, run model, ports, persistent data, update, uninstall, ownership and verification.
- [x] Detect the actual current state of every dependency on this machine.
- [x] Produce the mandatory Postiz overlap matrix classifying every existing social skill.
- [x] Record dependency ownership values and the uninstall rules they imply.
- [x] Create `manifest/dependencies.json` as the machine-readable source of truth.
- [x] Update `manifest/skills.json` with the rationalisation and supersession records.
- [x] Update `manifest/integrations.json` with the Postiz, Postiz CLI, HyperFrames and now-required Node.js entries.
- [x] Write `docs/postiz.md`, `docs/hyperframes.md` and `docs/dependencies.md`.
- [x] Add the new executable-code findings to `docs/security.md`.
- [x] Add durable extension invariants to project `AGENTS.md` and to the global instruction template.
- [x] Fix the defect found while validating: `verify.ps1` advised `install.ps1 -Force` to restore the canonical `AGENTS.md`, but `install.ps1` ignored `-Force` for that file, so the documented recovery path did not exist.
- [x] Confirm the existing toolchain still passes verification after the manifest changes.
- [x] Commit Phase 8 with a clean working tree.

### Validation

- `manifest/dependencies.json`, `manifest/skills.json` and `manifest/integrations.json` all parse as JSON.
- `scripts/verify.ps1` still reports the previously passing result, proving the manifest changes broke nothing.
- No skill was removed or demoted without a documented reason.
- Every blocker found is recorded with whether it can be automated and what the user must decide.

### Exit criteria

- Dependency inventory exists and is machine-readable.
- Overlap matrix covers every installed social skill.
- Architecture decisions for both capabilities are recorded with evidence.
- Working tree clean, committed.

### Phase checkpoint

STOP. Report the inventory, the overlap decisions, and every blocker requiring
a user decision, before any install begins.

---


---

## Phase 8B - Zernio evaluation and social backend decision

### Goals

Evaluate Zernio as an alternative operational social backend, compare it
directly against the Postiz self-hosted architecture researched in Phase 8, and
decide which one becomes the kit's social execution layer.

Phase 8 is **not** undone or rewritten. Its Postiz research, findings,
manifests and documentation stay as the record of an evaluated alternative.

Nothing is installed in this phase.

### Tasks

- [x] Confirm the current published and installed state, and the clean tree, before changing anything.
- [x] Clone and review `zernio-dev/zernio-cli` and `zernio-dev/zernio-api` at pinned refs; record ref, date and licence.
- [x] Verify the npm registry facts for `@zernio/cli`: published version, licences, dependencies, bins, declared engines.
- [x] Determine whether `zernio-cli` ships its own `SKILL.md`, and whether `zernio-api` provides a separate skill.
- [x] Check the official Agent Skills discovery index and catalogue what it publishes.
- [x] Determine whether the CLI writes to any vendor or agent directory, and whether it carries telemetry.
- [x] Determine the current Node.js requirement from the package and its CI, not from marketing.
- [x] Inspect authentication: the device flow, the API key, where the key is stored, and whether env vars override it.
- [x] Confirm credentials can live outside Git, and record the local storage path.
- [x] Verify JSON and stdout behaviour is suitable for a coding agent.
- [x] Catalogue the operational surface: profiles, accounts, posts, drafts, scheduling, queue, media, analytics, inbox, comments and replies, contacts, broadcasts, sequences, automations, logs, usage, validation, webhooks.
- [x] Establish platform coverage and the per-platform limitations that matter for this user.
- [x] Establish current rate limits and what they are per plan.
- [x] Establish the free-tier limits and define exactly what counts as an account.
- [x] Identify usage-based and pass-through charges, including platform API fees.
- [x] Determine licensing and which components are open source versus SaaS.
- [x] Confirm whether any MCP path exists and whether it is needed.
- [x] Repeat the Phase 8 social-skill overlap analysis against Zernio, including every skill the user named.
- [x] Check whether one Node.js version can serve both Zernio and HyperFrames, and record it as a shared prerequisite if so.
- [x] Produce a direct Postiz-versus-Zernio comparison across all requested criteria.
- [x] Decide the social execution backend, or stop and show the unresolved tradeoff.
- [x] Record the decision, and the reasoning, in documentation and manifests.
- [x] Mark Postiz as evaluated but not selected, without deleting its Phase 8 evidence.
- [x] Revise the not-yet-executed phases so they implement the selected backend, and remove WSL2, Docker and Postiz from the required default dependency plan.
- [x] Keep HyperFrames planning unchanged.
- [x] Confirm no secret, key or runtime data is committed, and the working tree is clean.
- [x] Record that the choice was hardware-driven, not capability-driven, and that Postiz self-hosted is the preferred backend wherever self-hosting is feasible.
- [x] Record that this is a note only: nothing in the setup depends on Postiz, and `docs/postiz.md` is written to be usable as an installation guide.
- [x] Record that which social accounts to connect is the installer's decision, with no default account list and no installer scaffolding for one.
- [x] Reframe every cost figure as an illustrative example rather than a prediction.
- [x] Commit and push Phase 8B.

### Validation

- Both manifests and the new documentation parse as JSON or Markdown without error.
- The existing `verify.ps1` still passes, proving no regression to the installed core.
- Every cost and limit claim is traceable to a quoted source line, not to marketing prose.
- Every overlap classification is justified against a named capability.
- Phase 0-8 history, checkboxes and commits remain intact.

### Exit criteria

- A defensible decision with concrete evidence, or an explicit unresolved tradeoff shown to the user.
- The chosen backend's dependency plan is realistic for this machine.
- Postiz research preserved as evidence.
- Working tree clean, committed and pushed.

### Phase checkpoint

STOP. Report the recommendation and the proposed revised outline for the later
phases. Do not execute them until the user approves.

---

## Phase 9 - Shared runtime provisioning and the Zernio CLI

> **Revised in Phase 8B.** This phase previously covered the Postiz self-hosted
> container runtime. Postiz was evaluated and not selected, so WSL2, Docker
> Desktop and the nine-container stack are removed from the default dependency
> plan. What remains is provisioning one shared Node.js runtime and the two CLIs
> that depend on it. See `docs/social-backend-decision.md`.

### Goals

Provision the single Node.js runtime that serves both `@hyperframes/cli` and
`@zernio/cli`, and install the Zernio CLI as a managed dependency. No elevation,
no container runtime, no background service.

### Tasks

- [ ] Detect existing Node.js. If a compatible version is present, use it and change nothing.
- [ ] Confirm no major-version upgrade of an existing Node is performed silently.
- [ ] Install Node.js LTS only if absent or too old, and handle the elevation prompt correctly.
- [ ] Record Node.js as a `shared` prerequisite in local, uncommitted state.
- [ ] Install `npm install -g @zernio/cli` at the version pinned in `manifest/dependencies.json`.
- [ ] Detect the version correctly. Remember the unscoped `zernio` package does not exist, so `npx zernio` fails.
- [ ] Never install the unscoped `late` package. It is an unrelated project.
- [ ] Materialise the `zernio` skill into `%USERPROFILE%\.agents\skills` from the pinned ref.
- [ ] Materialise the `zernio-api` reference skill from its pinned ref.
- [ ] Do not install the six atomic skills from the Agent Skills index, the Claude Code plugin, or the hosted MCP.
- [ ] Confirm `scripts/verify.ps1` still passes its vendor-isolation check after the new skills land.
- [ ] Extend `scripts/install.ps1` with a dependency-provisioning path driven by `manifest/dependencies.json`.
- [ ] Extend `scripts/verify.ps1` to report the Node.js version and the Zernio CLI version without leaking the key.
- [ ] Extend `scripts/uninstall.ps1` to remove `@zernio/cli` only if the kit installed it, and never remove Node.js.
- [ ] Leave `%USERPROFILE%\.zernio` in place on uninstall because it holds the credential. Document that explicitly.

### Validation

- `zernio --version` reports the pinned version.
- `node --version` satisfies `>=22` for HyperFrames.
- The two skills resolve from `%USERPROFILE%\.agents\skills`.
- No vendor directory exists.
- Rerunning the installer produces no drift.

### Exit criteria

- One Node.js runtime serves both CLIs.
- The Zernio CLI and both skills are installed from the canonical path.
- Uninstall removes only what the kit owns.

### Phase checkpoint

STOP and report.

---

## Phase 10 - Zernio global Agent Skills and read-only validation

> **Revised in Phase 8B.** Previously the Postiz Skill and CLI. The shape is the
> same and simpler: there is no local instance to stand up, so the validation
> target is the Zernio API itself, proven read-only and at zero cost on the free
> two-account tier.

### Goals

Prove the Zernio integration works end to end against the real service, and that
both tested agents discover the canonical skills.

### Tasks

- [ ] Confirm the user has created a Zernio account. First two connected accounts are free and need no credit card.
- [ ] Have the user run `zernio auth:login` themselves, so the key is never handled by the agent.
- [ ] Confirm the key is configured, without printing it. Prefer the environment variable so nothing touches disk.
- [ ] Document that `zernio auth:set --key` puts the secret in shell history, and is not the recommended path.
- [ ] Verify with `zernio auth:check` that the key is valid.
- [ ] Prove read-only operations work: `profiles:list`, `accounts:list`, `posts:list`, `usage:stats`.
- [ ] Prove `accounts:health` works, which is the pre-flight gate before any batch.
- [ ] Prove `validate:post-length` and `validate:post` work, so bad posts are caught before a slot passes.
- [ ] Confirm nothing writes to a vendor or agent directory.
- [ ] Verify OpenCode discovers `zernio` and `zernio-api` from the canonical root.
- [ ] Verify Cline discovers the same canonical skills.
- [ ] Verify install and verify are idempotent, with no drift on rerun.
- [ ] Create a draft post as the highest-risk write test, and only with explicit user approval. Do not publish.
- [ ] Leave platform OAuth and app approval explicitly pending rather than faking them.
- [ ] Recommend a read-only, profile-scoped API key for reporting, as upstream advises.
- [ ] Record actual cost with `usage:stats` and `usage:x-pricing` rather than estimating.
- [ ] Update `docs/zernio.md` and `docs/troubleshooting.md` with observed behaviour.

### Exit criteria

- The CLI authenticates and reads against the real service.
- Both skills are discoverable by both tested agents.
- Drafts, not published posts, were used for any write test.
- Cost is reported from the API, not estimated.

### Phase checkpoint

STOP and report.

---

## Phase 11 - HyperFrames runtime, dependencies, and global Core Skills setup

### Goals

Provision Node.js, FFmpeg and the HyperFrames CLI; install the core skills
through the project's own materialisation path; prove local deterministic
rendering works.

### Tasks

- [ ] Detect existing Node.js and use it if the version satisfies `>=22`. Do not reinstall or silently upgrade a major version.
- [ ] Install Node.js LTS only if absent or too old, with the elevation path handled correctly.
- [ ] Install FFmpeg only if absent, and classify it as shared.
- [ ] Install `@hyperframes/cli` as a managed dependency at a pinned, reviewed version.
- [ ] Resolve the `npx hyperframes` versus `@hyperframes/cli` package-name question against the npm registry and record the answer.
- [ ] Vendor the 10 core skills from the pinned reviewed ref into `vendor/skills/`, each with a `PROVENANCE.md`.
- [ ] Apply the same vendor-product-deframing review the existing 27 forks received.
- [ ] Confirm upstream content hashes from `skills-manifest.json` for drift detection.
- [ ] Do not pre-install the 11 workflow skills. Keep the lazy model.
- [ ] Add a lint/check or doctor step where the CLI provides one.
- [ ] Create a small disposable deterministic smoke-test composition: text, shapes, at least one deterministic animation, and a timeline change. No generative media, no cloud service.
- [ ] Render it locally and prove the MP4 is valid.
- [ ] Re-render and prove reproducibility of the same project.
- [ ] Verify `/hyperframes` router availability and Core Skills discovery.
- [ ] Verify OpenCode discovers the skills.
- [ ] Verify Cline discovers the same canonical skills.
- [ ] Add dependency and CLI health checks to `scripts/verify.ps1`.
- [ ] Confirm generated media is gitignored and not committed.
- [ ] Update `docs/hyperframes.md` with actual observed behaviour.

### Exit criteria

- Node, FFmpeg and the CLI are installed or correctly detected.
- The core skills resolve from the canonical root by both tested agents.
- A valid MP4 renders locally and reproducibly, with no cloud or generative dependency.

### Phase checkpoint

STOP and report.

---

## Phase 12 - Reproducible dependency/bootstrap integration

### Goals

Make the whole extension reproducible from a clean compatible Windows machine
through the repository's own tooling, with ownership and uninstall boundaries
that hold.

### Tasks

- [ ] Drive every required dependency from `manifest/dependencies.json` in `scripts/install.ps1`.
- [ ] Add a dry-run or preview path for dependency provisioning where the current scripts support one.
- [ ] Make detection-before-install the default, and avoid reinstalling a compatible existing installation.
- [ ] Record kit-installed versus pre-existing software in local uncommitted state.
- [ ] Extend `scripts/verify.ps1` to report the status of Zernio, HyperFrames and every dependency without leaking secrets.
- [ ] Extend `scripts/update.ps1` so upstream code changes are reviewed before they are applied, per the existing review model.
- [ ] Extend `scripts/uninstall.ps1` with ownership-aware behaviour for every dependency class.
- [ ] Prove idempotency: rerun install, verify and update with no unintended drift.
- [ ] Test the full flow against a sandboxed target root so the live installation is not disturbed.
- [ ] Document the fresh-machine bootstrap path, including which steps remain human-only and why.
- [ ] Document blocked prerequisites with exact instructions.
- [ ] Update `docs/maintaining.md` for adding, removing and retiring runtime dependencies.

### Exit criteria

- A fresh compatible machine can reach a functional state from the repository alone, apart from unavoidable account steps.
- Ownership boundaries are enforced in code, not only in prose.
- Reruns are safe.

### Phase checkpoint

STOP and report.

---

## Phase 13 - Final end-to-end validation, documentation, GitHub synchronization and handoff

### Goals

Prove the extension meets its definition of done and hand it over.

### Tasks

- [ ] Run the full verification suite and record the result.
- [ ] Prove the Zernio CLI authenticates and reads against the real service, and report actual cost from `usage:stats`.
- [ ] Prove no WSL, Docker or container runtime was provisioned.
- [ ] Prove the HyperFrames smoke test renders reproducibly.
- [ ] Prove OpenCode and Cline both consume every new canonical skill.
- [ ] Prove no vendor skill directory was created by any installer.
- [ ] Prove no secret, `.env`, token or runtime data is tracked by Git.
- [ ] Prove `git status` is clean and local is in sync with `origin`.
- [ ] Update `README.md` and `README.es.md` with the expanded capabilities, keeping the agent-agnostic identity and both languages consistent.
- [ ] Update `docs/architecture.md` compatibility matrix and `docs/portability-verification.md`.
- [ ] Confirm `AGENTS.md` stayed compact and detailed material stayed in `docs/`.
- [ ] Confirm install, update and uninstall documentation matches actual behaviour.
- [ ] List every remaining human-only step with why, exact action, where, and the non-secret result needed.
- [ ] State the ongoing cost plainly in the README, including the X URL-post pass-through, so the user is not surprised.
- [ ] Final commit and push.

### Definition of Done

- Every required machine-level dependency is provisioned or safely detected by the reproducible setup.
- One shared Node.js runtime serves both `@hyperframes/cli` and `@zernio/cli`. No second runtime exists.
- Zernio is the social execution backend, integrated globally through the canonical `.agents` root, with the hosted MCP and the Claude Code plugin out of the picture.
- Existing social skills are rationalised against Zernio, with no strategy or editorial skill removed or demoted, and `crisis-and-moderation` still refusing autonomous moderation.
- Node.js, FFmpeg and the HyperFrames CLI are installed and validated.
- The HyperFrames core skills are installed reproducibly from the canonical root, with `/hyperframes` as the router, visible to both tested agents.
- A deterministic smoke-test MP4 renders locally with no generative or cloud dependency.
- Install, verify, update and uninstall remain idempotent and ownership-aware, and no shared software is removed.
- No WSL2, Docker Desktop or container runtime is required or installed.
- No secrets or runtime data are committed.
- Phases 0-8B remain intact, and the Postiz research is preserved as the record of the evaluated alternative.
- Final Git state is clean and synchronised with `origin`.