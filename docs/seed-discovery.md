# Seed discovery — 2026-10-04

This file records leads gathered before the bootstrap agent starts. It is **not** an allowlist and it is **not** a substitute for Phase 2 research.

Revalidate everything against current upstream documentation before installation.

> **Status update after Phase 1.** The agent/platform assumptions below were revalidated against the
> versions actually installed on this machine. Confirmed facts now live in `docs/environment.md`.
> Summary of what changed:
>
> - OpenCode is installed as **OpenCode Desktop 2.0.22**; its global skills path `~/.agents/skills` is confirmed native.
> - OpenCode's global instruction path gap is **confirmed and proven**, not merely suspected: v2 reads global instructions only from `~/.config/opencode/AGENTS.md`, has no `CLAUDE.md` fallback, and does not resolve the `instructions` array. A single reversible NTFS hard link is the chosen mechanism.
> - Cline is installed as **Cline Desktop 0.0.43**, not the VS Code extension, so the cited `apps/vscode/...` source is not what runs here. The shipped runtime was inspected directly and does resolve both `~/.agents/skills` and `~/.agents/AGENTS.md`.
> - Cline's public skills documentation lags behind its own runtime on the global `~/.agents/skills` location.
> - Symbolic links are **not** usable on this machine (no elevation, Developer Mode off); hard links are. This determined the compatibility mechanism choice.
>
> The skill-candidate research below is still unvalidated and remains Phase 2 work.

## Portable Agent Skills foundation

### Agent Skills format

The open Agent Skills ecosystem uses a directory containing `SKILL.md` with YAML metadata such as `name` and `description`, plus optional supporting resources.

Useful starting points:

- https://agentskills.io/
- https://github.com/agentskills/agentskills

### OpenCode

Current OpenCode documentation reports global skill discovery from:

- `~/.config/opencode/skills`
- `~/.claude/skills`
- `~/.agents/skills`

Current OpenCode V2 global `AGENTS.md` documentation points to:

- `~/.config/opencode/AGENTS.md`

Therefore, the intended architecture is to keep `.agents` canonical and provide an OpenCode instruction adapter rather than moving the canonical file.

Docs:

- https://opencode.ai/docs/skills
- https://opencode.ai/v2/docs/instructions

### Cline

Current Cline runtime source includes both `.cline/skills` and `.agents/skills` in its global skill scan list. A July 2026 documentation PR also records maintainers confirming that project and global `.agents/skills` paths are scanned.

Current Cline rules documentation states that it reads the cross-tool global instruction file:

- `~/.agents/AGENTS.md`

Therefore, no Cline adapter should be created for either global skills or the canonical global `AGENTS.md` if the installed version confirms the same behavior.

Evidence:

- https://github.com/cline/cline/blob/main/apps/vscode/src/core/storage/skill-directories.ts
- https://github.com/cline/cline/pull/12517
- https://github.com/cline/cline/blob/main/docs/customization/cline-rules.mdx

### Important nuance for OpenCode global instructions

OpenCode currently documents native global skills under `~/.agents/skills`, but OpenCode V2 documentation still places its global instruction file at `~/.config/opencode/AGENTS.md`.

That means:

- skills: shared canonical path, no adapter;
- global instructions: revalidate installed OpenCode; if necessary, use one minimal reversible link/reference from the OpenCode global instruction path to canonical `~/.agents/AGENTS.md`.

Do not generalize this single exception into a vendor adapter architecture.

## Seed skill candidates

### Newsroom/editorial

Repository: https://github.com/jamditis/claude-skills-journalism

Candidates:

- `newsroom-style`
- `source-verification`

Why they are interesting:

- newsroom-oriented writing/editing;
- source provenance and verification;
- relevant to a media outlet rather than generic SaaS marketing.

### Social/content

Repository: https://github.com/social-media-skills/skills

Candidates:

- `brand-profile`
- channel-specific skills only where relevant

Repository: https://github.com/coreyhaines31/marketingskills

Candidates:

- `social-content`
- `copywriting`

Repository: https://github.com/blacktwist/social-media-skills

Candidate:

- `content-calendar-sms`

Repository: https://github.com/notque/vexjoy-agent

Candidates:

- `content-calendar`
- `fact-check`
- `news-collection`

Avoid installing overlapping calendar/fact-check systems without a documented reason.

Repository: https://github.com/scrapecreators/social-media-research-skills

Candidate:

- `content-repurposing`

Useful for turning transcripts, videos, podcasts, webinars, and source material into platform-native derivatives. Review data/API dependencies and guard against copying competitors.

Additional candidates from `social-media-skills/skills`:

- `content-audit`
- `design-and-templates`

`content-audit` is relevant for learning from account performance. `design-and-templates` is relevant for maintaining reusable on-brand social creative systems.

### High-priority UI/design candidates

#### Impeccable

Repository:

- https://github.com/pbakaus/impeccable

Skill:

- `impeccable`

Why it is especially relevant:

- explicitly targets production-grade frontend design rather than generic code generation;
- covers design, redesign, critique, audit, polish, typography, layout, color, motion, accessibility, responsive behavior, UX copy, and design systems;
- includes a deterministic anti-pattern detector for common AI-generated-UI problems;
- can use persistent `PRODUCT.md` / `DESIGN.md` context;
- upstream documents compatibility with skill-aware agents including OpenCode and many others.

Important review point:

- the optional CLI/detector/hook layer has runtime requirements and executable components;
- separate the value of the portable Agent Skill from the optional executable tooling during security review;
- do not make agent-specific hook installation mandatory for the portable core.

Current upstream reference:
https://github.com/pbakaus/impeccable

#### Hallmark

Repository:

- https://github.com/Nutlope/hallmark

Skill:

- `hallmark`

Why it is especially relevant:

- specifically targets "anti-AI-slop" UI;
- emphasizes structural variety, not only palette/style changes;
- supports build, audit, redesign, and design-study/extraction workflows;
- can emit portable design-system artifacts such as `design.md` / tokens;
- editorial is explicitly within its design vocabulary, which is relevant to a media website.

Important review point:

- upstream describes Hallmark as powered by Together AI;
- Phase 2 must identify which capabilities are pure skill instructions and which require external API/service access;
- any external-service dependency belongs in `optional` unless the user explicitly approves it.

Current upstream reference:
https://github.com/Nutlope/hallmark

#### Comparison requirement

Do not select these by popularity alone.

Compare:

1. Impeccable
2. Hallmark
3. `frontend-design`
4. `web-design-guidelines`

Score them on:

- quality of generated/refined UI;
- resistance to generic AI visual patterns;
- editorial/media-site suitability;
- ability to preserve an existing brand/design system;
- auditing and critique;
- accessibility and responsive guidance;
- context footprint;
- standard Agent Skills portability;
- executable code/hooks;
- external account/API requirements;
- Windows compatibility;
- licensing;
- maintenance health.

Likely end state should be **one strong primary design skill plus, only if complementary, one review/standards skill**, not four overlapping design skills.

### Web/design

Repository: https://github.com/PracticalSwan/agent-skills

Candidate:

- `frontend-design`

Repository: https://github.com/vercel-labs/agent-skills

Candidates:

- `web-design-guidelines`
- `writing-guidelines`

Accessibility candidate:

- https://github.com/accesslint/skills — `accessibility-audit`

This is potentially valuable for WCAG 2.2 review of media websites, but it has executable/tool dependencies and must receive a stricter supply-chain review before selection.

Social/web preview candidate:

- https://github.com/stevysmith/og-image-skill — `og-image`

Potentially useful for producing consistent social preview/Open Graph assets from a site's existing design system.

### SEO

Compare at least:

- https://github.com/affaan-m/ecc — `seo`
- https://github.com/iannuttall/seo — `seo`

Choose one strong default that fits editorial/media websites and has acceptable dependencies.

## Optional integrations — not core

### Figma MCP

Official documentation:

- https://developers.figma.com/docs/figma-mcp-server/
- https://www.figma.com/mcp-catalog/

Potential use:

- structured design context;
- design system/component extraction;
- design-to-code;
- in supported clients, write-back to Figma.

Before recommending installation, verify support for the actual OpenCode/Cline versions and understand Figma plan/account requirements.

### Canva MCP

Official documentation:

- https://www.canva.dev/docs/apps/mcp/
- https://www.canva.dev/docs/apps/quickstart/

Potential use:

- design creation/editing;
- assets/brand management;
- export/comment workflows.

Keep optional because it uses an external account/service and may require authentication.

### Cline plugins

Official catalog:

- https://github.com/cline/plugins

Potentially relevant examples include browser automation or image generation, but these are Cline-specific and therefore should not be part of the agent-agnostic core unless a portable equivalent is unavailable and the user explicitly wants the capability.

## Installer/tooling note

The `npx skills` ecosystem supports global installs and multiple agent targets, but the project requirement is stricter: `%USERPROFILE%\.agents` must remain canonical.

During Phase 2/3, compare:

1. using the CLI only where it preserves the required canonical layout;
2. staging/fetching skills and managing canonical storage via this repository's own PowerShell scripts;
3. a dedicated canonical-store linker if it is mature, secure, and not needlessly heavyweight.

Do not blindly trust CLI path assumptions. Verify actual installed versions and resulting paths.


## Capability areas Phase 2 must search beyond the seed list

The agent should not stop at the named candidates. It must search current sources for high-quality, portable skills covering:

1. newsroom/editorial writing and style;
2. source verification, fact-checking, provenance, and research hygiene;
3. social strategy and content calendars;
4. captions, headlines, hooks, threads, carousels, scripts, and platform-native formatting;
5. community management: replies, moderation, escalation, sentiment/issue triage;
6. content repurposing across article/video/audio/social formats;
7. brand voice/profile and editorial guardrails;
8. social analytics, reporting, and retrospective content audits;
9. visual design systems and repeatable social templates;
10. image/creative and social-preview/OG asset workflows;
11. frontend/web design and UX review;
12. accessibility/WCAG;
13. editorial SEO/GEO, metadata, structured data, internal linking, and discoverability;
14. CMS/publishing workflows when they are portable enough to justify a global skill;
15. browser/web QA for responsive layouts and published output;
16. localization/translation adaptation if a strong portable candidate exists;
17. optional integrations such as Figma/Canva/browser tooling, clearly separated from the no-account-required core.

Selection should optimize for a **small, composable, trustworthy core**, not maximum skill count.
