# Newsroom Agent Kit — Project Instructions

## Purpose

This repository bootstraps and maintains a portable, global AI-agent setup for a Windows user whose day-to-day work includes community management, newsroom/content production, social media, website content, editorial workflows, design, and web design.

The result must be agent-agnostic: useful from any coding agent that supports the shared `.agents` / Agent Skills conventions, without making any vendor the source of truth.

OpenCode and Cline are the initial validation targets because they are installed on the bootstrap machine. They are **tested implementations**, not the identity or scope of the project.

## Non-negotiable architecture

- The canonical global agent root is `%USERPROFILE%\.agents`.
- Canonical global skills live under `%USERPROFILE%\.agents\skills\`.
- The canonical global instruction file is `%USERPROFILE%\.agents\AGENTS.md`.
- Do not create tool-specific copies or adapters when an agent natively supports the canonical `.agents` location.
- In particular, OpenCode and current Cline both support global `~/.agents/skills`, so their skills must be consumed directly from the canonical store.
- A tool-specific compatibility link/config is allowed only for an artifact that the tool does **not** natively discover from `.agents`. Keep such exceptions minimal, documented, reversible, and derived from the canonical file.
- Never make `.cline`, `.opencode`, `.claude`, `.codex`, or another vendor directory the source of truth.
- Never silently overwrite an existing global skill, `AGENTS.md`, rule file, MCP config, plugin config, or agent-specific configuration.
- Preserve unrelated existing user configuration. Back up before merge or replacement.

## Extension invariants — social backend and HyperFrames

Added in Phase 8, revised in Phase 8B. These are durable and always apply.

- **Local software is part of the reproducible setup.** If a capability needs a
  runtime, package, container, service or CLI, the installer provisions it or
  detects it, verification reports it, and fresh-machine bootstrap reproduces
  it. Do not leave required software as an undocumented manual prerequisite.
- **Ownership is explicit.** Every dependency declares an ownership value
  (`kit-installed`, `shared`, `user-owned`, `os-feature`, `ephemeral-cache`) in
  `manifest/dependencies.json`. A normal uninstall removes only what is safely
  attributable to the kit. Never uninstall shared software.
- **Zernio is the social execution backend.** Skills do the thinking; the
  backend executes. Publishing, scheduling, queueing, drafts, media upload,
  comment and DM handling, broadcasts, sequences and supported native metrics
  route through Zernio. Rationale and the full comparison in
  `docs/social-backend-decision.md`.
- **Zernio was chosen for hardware reasons, not capability.** The machine this
  was installed on cannot run the Postiz self-hosted stack. Where self-hosting
  is feasible, Postiz is the better backend and should be selected instead. This
  is a documented note only: nothing in the setup depends on Postiz, and no
  Postiz component is provisioned. See `docs/postiz.md`.
- **Which social accounts to connect is the installer's decision.** Never
  hardcode a default account list, never require particular accounts, and never
  have the installer touch connected accounts. Start from the free tier and let
  the installer choose.
- **Postiz self-hosted is evaluated and not selected here.** Its Phase 8 research
  is preserved as evidence. Do not provision WSL2, Docker Desktop or the Postiz
  stack. See `docs/postiz.md`.
- **Skill and CLI, never MCP, never a vendor wrapper.** Zernio's hosted MCP at
  `mcp.zernio.com` and the `zernio-claude-plugin` are both out. Add neither
  without user approval and a documented missing capability.
- **Never publish, send or moderate autonomously.** Stage the action, show it,
  and let the human act. This holds even though the API can do it. In
  particular, `crisis-and-moderation` must not use hide, pin, like or delete
  automatically.
- **Shared Node.js.** One Node.js LTS install serves both `@hyperframes/cli`
  and `@zernio/cli`. Do not create a second runtime.
- **HyperFrames is the deterministic motion layer.** Render locally. Image and
  video generation models, hosted renderers and cloud rendering are not the
  default and stay unconfigured.
- **Secrets and runtime data never enter Git.** No `.env`, tokens, API keys,
  credentials, database contents, or generated private configuration. Prefer an
  environment variable over a config file so the secret never touches disk.
- **Vendor directories stay forbidden.** Upstream installers that write to
  `~/.claude/skills`, `~/.config/opencode/skills`, or similar are not used. See
  `docs/hyperframes.md`.

Detail lives in `docs/zernio.md`, `docs/postiz.md`, `docs/social-backend-decision.md`,
`docs/hyperframes.md`, `docs/dependencies.md` and `manifest/dependencies.json`.
Do not restate it in this file.

## Execution contract

`PLAN.md` is the execution source of truth.

1. Read this file and all relevant sections of `PLAN.md` before acting.
2. Execute exactly one plan phase at a time.
3. Within the active phase, work continuously and autonomously through routine implementation choices.
4. Do not stop for minor choices that can be resolved safely from evidence.
5. Complete the phase's implementation and validation, update documentation and checkboxes, commit the result, then STOP.
6. At the end of every phase, report:
   - what changed;
   - validation performed and its result;
   - commits created;
   - unresolved risks/decisions;
   - what the next phase will do.
7. Wait for the user before starting the next phase.

A phase may stop early only for a real blocker: missing credentials/authentication, an irreversible/destructive action, an external account action requiring approval, an unresolved conflict with existing user configuration, or a decision that materially changes scope/cost/privacy.

## Git tracking — mandatory

This project must never lose implementation history.

- At the start, determine whether the workspace is already a Git repository.
- If not, initialize one locally.
- The repository MUST remain local-only with no remote until the explicit GitHub publication phase in `PLAN.md`.
- Commit all meaningful work.
- Do not accumulate a large uncommitted batch across multiple milestones.
- Every change from `- [ ]` to `- [x]` in `PLAN.md` must be committed with the work and validation that justifies that checkbox whenever practical.
- Every material update to `PLAN.md`, project architecture, discovery findings, manifests, installation scripts, or compatibility logic must be committed.
- At each phase boundary, `git status` should be clean unless a documented blocker makes that impossible.
- Use clear commit messages describing the completed unit of work.
- Never rewrite or discard history merely to make the repository look cleaner.

When the GitHub publication phase is reached, the repository may gain a remote as part of that phase.

## Discovery and evidence rules

This project is intentionally evidence-driven because agent ecosystems change quickly.

- Prefer current official documentation and upstream repositories.
- Treat Skills.sh or other registries as discovery indexes, not as the final trust authority.
- For every candidate skill/plugin/integration, inspect the actual upstream source before installation.
- Record source repository, exact skill name, license, relevant version/commit/tag when practical, external dependencies, scripts/hooks/tool execution, network behavior, authentication needs, and maintenance signals.
- Reject or quarantine candidates with unclear provenance, hidden execution, unsafe hooks, unexplained network calls, credential harvesting risk, or unnecessary platform lock-in.
- Avoid redundant skills that compete for the same trigger unless there is a documented reason.
- Prefer composable specialist skills over one giant prompt that injects excessive context.
- Re-check current compatibility instead of relying only on the seed research in `docs/seed-discovery.md`.

## Installation and security

- Windows is the target OS.
- Keep the installation idempotent and safe to rerun.
- Do not require Administrator privileges unless no reasonable user-level alternative exists.
- Never store API keys, OAuth tokens, passwords, cookies, or personal secrets in the repository.
- Do not commit machine-specific absolute paths when environment variables or discovery can be used.
- Do not install paid services or create paid resources without explicit user approval.
- Do not connect external accounts merely because an integration exists.
- MCP servers and plugins are optional capability layers, not required for the core skill setup.
- Agent-specific executable plugins/hooks require stricter review than plain instruction-only skills.
- Create backups before changing existing user configuration and provide a documented restore/uninstall path.

## Compatibility principles

The project is **agent-agnostic**. Its public identity must be based on the shared `.agents` / Agent Skills convention, not on OpenCode or Cline.

OpenCode and Cline are the initial tested agents. Current seed evidence indicates:

- OpenCode discovers global skills directly from `~/.agents/skills`.
- Cline's current runtime also scans global `~/.agents/skills`; no skill adapter is required for either agent.
- Cline reads the cross-tool global instruction file `~/.agents/AGENTS.md`.
- OpenCode V2 currently documents its global instruction file at `~/.config/opencode/AGENTS.md`, so a minimal link or other compatibility mechanism to canonical `~/.agents/AGENTS.md` may still be required for **global instructions only**.

These facts MUST be revalidated against the installed versions during discovery.

Do not add compatibility machinery speculatively. If another agent natively supports `.agents`, use it directly. Add a tool-specific exception only for a missing capability, and document exactly why it exists.

## Public repository positioning — mandatory

The eventual GitHub repository, README title/intro, description, installation language, and other public metadata MUST:

- describe the project as an **agent-agnostic global Agent Skills / `.agents` setup**;
- state that it is intended for **any compatible coding agent that supports the shared convention**;
- NOT describe itself as an "OpenCode setup", "Cline setup", "OpenCode/Cline kit", or imply those tools own the format;
- MAY state clearly that the setup is **tested with OpenCode and Cline**;
- keep vendor-specific compatibility notes in a test/support matrix or implementation section rather than in the project's identity.

## Repository deliverables

The finished repository should contain, at minimum:

- `README.md` with a copy/paste installation prompt containing the final GitHub repository URL.
- `AGENTS.md`, `PLAN.md`, and `CLAUDE.md`.
- A machine-readable manifest of selected skills and integrations.
- An idempotent Windows installer.
- Verification/diagnostic tooling.
- A compatibility/support matrix that distinguishes shared `.agents` support from tool-specific exceptions.
- Update tooling.
- Safe uninstall/restore guidance or tooling.
- Documentation of architecture, sources, trust decisions, and compatibility.
- No credentials and no generated user-specific backups committed to Git.

Prefer a small number of well-named files over unnecessary scaffolding.

## Documentation discipline

Keep this `AGENTS.md` compact and durable. Do not turn it into a transcript or research notebook.

- Procedural work belongs in `PLAN.md`.
- Detailed findings belong in `docs/`.
- Source lists and selection rationale belong in discovery/security documentation or manifests.
- If durable instructions become too large, move detail to `docs/` and leave only a pointer here.

## Validation standard

Do not call the setup complete merely because files exist.

At minimum validate:

- selected skills are present in the canonical root;
- `SKILL.md` metadata is structurally valid;
- OpenCode can see/use representative global skills;
- Cline can see/use representative global skills;
- the canonical global `AGENTS.md` is effectively applied by both agents through native discovery or adapters;
- rerunning the installer is safe and produces no unintended drift;
- existing user configuration remains intact;
- install/update/uninstall documentation matches actual behavior;
- a fresh-machine bootstrap path is plausible and tested as far as the available environment allows.

When automated verification is possible, prefer it over visual assumptions.
