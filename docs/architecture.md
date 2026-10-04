# Target architecture

## Principle

Use the shared `.agents` convention directly wherever an agent supports it.

```text
%USERPROFILE%\
└── .agents\
    ├── AGENTS.md              # canonical global instructions
    ├── skills\                # canonical global Agent Skills
    │   ├── <skill-a>\SKILL.md
    │   └── <skill-b>\SKILL.md
    └── state\                 # optional local installer metadata, not necessarily tracked
```

The repository and installer must not manufacture vendor-specific skill trees when the agent already scans `%USERPROFILE%\.agents\skills`.

Additional constraints confirmed in Phase 1:

- `%USERPROFILE%\.agents\plugins` is reserved by Cline and must not be populated by this kit.
- The installer runs under **Windows PowerShell 5.1** at user level, invoked with
  `-ExecutionPolicy Bypass` because the machine's effective execution policy is `Restricted`.
- Diagnostics must not depend on parsing localized Windows error messages.

## Initial tested agents

OpenCode and Cline are validation targets, not architectural owners of the project.

**Confirmed against the versions installed on the bootstrap machine in Phase 1**
(see `docs/environment.md` for the full evidence):

| Capability | OpenCode Desktop 2.0.22 | Cline Desktop 0.0.43 |
|---|---|---|
| Global `~/.agents/skills` | **Native** (documented + present in the installed binary) | **Native** (resolved by the shipped sidecar; public docs lag) |
| Global `~/.agents/AGENTS.md` | **Not supported** — global instructions are read only from `~/.config/opencode/AGENTS.md` | **Native** |
| Agent Skills `SKILL.md` concept | Native | Native |

Therefore:

- **No OpenCode skill adapter.**
- **No Cline skill adapter or compatibility artifact of any kind.**
- **No duplicated `.agents` skills under vendor folders.**

### The single proven compatibility exception

One artifact needs a tool-specific bridge, because the installed OpenCode build demonstrably does
not read it from the canonical location:

```text
NTFS hard link: %USERPROFILE%\.config\opencode\AGENTS.md  ->  %USERPROFILE%\.agents\AGENTS.md
```

Rules for this exception:

- It exists for the **global instruction file only**. Skills stay purely native.
- A hard link is used because it is the only single-file link that works on Windows without
  elevation or Developer Mode, and it preserves a single source of truth.
- It is reversible: delete the link, and the canonical file is untouched.
- It must never be turned into an independently maintained copy.
- Because both names share one inode, the installer must not replace the canonical file via
  write-temp-then-move. Replace by delete-then-recreate and re-verify the link.
- Remove this exception as soon as the installed OpenCode version supports
  `~/.agents/AGENTS.md`.

`~/.agents/plugins` is reserved for Cline's agent-plugin feature and must stay unused by this kit.

## Agent-agnostic public identity

The GitHub repository must be described as an agent-agnostic `.agents` / Agent Skills setup.

Do not brand the project as:

- an OpenCode setup;
- a Cline setup;
- an OpenCode + Cline kit.

It is acceptable and desirable to say:

> Agent-agnostic global Agent Skills setup. Tested with OpenCode and Cline.

Additional agents should be documented in a compatibility matrix as they are verified. Native `.agents` support should require no installation branch beyond the canonical setup.

### Compatibility matrix

Two different properties must be recorded separately. An agent can support the Agent Skills
**format** while reading global skills from a **vendor directory**. Only the second property
determines whether this kit needs a compatibility step.

| Agent | Agent Skills format | Global skills path | Compatibility step needed |
|---|---|---|---|
| Cline | yes | `~/.agents/skills/` | none |
| OpenCode | yes | `~/.agents/skills/` (also reads `~/.config/opencode/skills/` and `~/.claude/skills/`) | none for skills |
| OpenCode (global instructions) | n/a | `~/.config/opencode/AGENTS.md` only | **one hard link** (see above) |
| Zed, Warp, Dexto, Kimi Code CLI, Loaf, Sarvam Code | yes | `~/.agents/skills/` | none |
| Gemini CLI | yes | `~/.gemini/skills/` | documented vendor link |
| GitHub Copilot | yes | `~/.copilot/skills/` | documented vendor link |
| Claude Code | yes | `~/.claude/skills/` | documented vendor link |
| Codex, Cursor, Kiro, Roo Code, Factory, Amp, OpenHands, Goose, Mistral Vibe, Junie, TRAE | yes | vendor-specific | documented vendor link |
| Freebuff Desktop 0.0.158 (installed here) | yes | `~/.agents/skills/` and `~/.agents/AGENTS.md` | none |

Freebuff was verified by the user on 2026-10-04, after the Phase 4 install: both the 40 skills and the
global instructions were picked up from the canonical location, with no configuration. That was
observed on the first attempt and needed nothing beyond the canonical install.

That makes **three** agents confirmed reading this setup natively from `%USERPROFILE%\.agents`, which
is the useful signal: the architecture does not depend on any one vendor.

Global-path data for agents other than the two tested implementations is taken from the `skills`
CLI's supported-agent table, not from each agent's own documentation. Treat it as indicative and
re-verify before publishing a compatibility claim.

When adding another agent, prefer its native support for `%USERPROFILE%\.agents`. If it only reads a
vendor directory, document the single minimal link needed — do not duplicate the skill files.

## Repository role

The GitHub repository is the reproducible definition of the setup, not the live canonical runtime directory.

It should contain:

- curated global instruction template;
- manifests describing selected upstream skills/integrations;
- PowerShell installation/update/verification/uninstall tooling;
- documentation and trust decisions;
- compatibility tests/notes.

The installer materializes/synchronizes the selected version into `%USERPROFILE%\.agents`.

## Two distribution modes

The default install is 40 skills delivered in two different ways, recorded per skill in
`manifest/skills.json`.

**Pinned fetch.** The skill is copied verbatim from the commit pinned in `source.ref`. The pin is
the reviewed artifact, so behaviour cannot change silently. Files are cached locally under
`~/.agents/cache/upstream/<repo>@<short-ref>` and staged by the installer. No upstream script is
ever executed.

**Vendored fork.** The skill lives in `vendor/skills/<name>` in this repository as a modified copy,
each with a `PROVENANCE.md` recording the upstream repository, the exact commit, the licence, and
precisely what changed.

Forks exist because some upstream skills are written around one vendor's product, and leaving those
claims in place makes an agent conclude that capabilities the newsroom actually has do not exist.
Twenty-seven skills are forked; see `docs/security.md` SEC-07. A fork must never be replaced by a
fresh upstream copy, because that is exactly what reintroduces the problem. Upstream changes are
merged by hand.

Two skills are vendored purely to keep the installed set free of executable files:
`impeccable` ships only its instruction layer, and `frontend-design` ships without its Python
contrast checker.

## Testing without touching user state

Every script accepts `-TargetRoot` and `-OpenCodeConfigDir`. That redirects the entire toolchain
into a throwaway directory, so the full install, verify, idempotency and uninstall cycle can be
exercised before anything is written to `%USERPROFILE%\.agents`. Phase 3 used this to validate all
of it. `update.ps1` accepts `-TargetRoot` for the same reason.

## Compatibility-exception rules

- Prefer native `.agents` support.
- Never add a compatibility layer preemptively.
- If one artifact is unsupported at the canonical location, adapt that artifact only.
- Prefer a reversible link/reference to an independent copy.
- Preserve user-owned files.
- Track ownership so uninstall removes only kit-managed artifacts.
- Revalidate exceptions over time and delete them once the agent gains native support.

## Upstream skill strategy

Phase 2 must choose between vendoring and fetching/pinning.

Default preference:

1. keep source metadata in a manifest;
2. pin a reviewed ref/commit where practical;
3. install only the selected skill subtree;
4. retain license/attribution;
5. do not execute arbitrary upstream install scripts merely to copy a `SKILL.md` package;
6. review upstream changes before update.

## Optional integrations

MCP servers and executable plugins belong in a separate optional layer. The base kit should remain useful with plain Agent Skills and global instructions alone.
