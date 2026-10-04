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

## Initial tested agents

OpenCode and Cline are validation targets, not architectural owners of the project.

Current seed evidence:

| Capability | OpenCode | Cline |
|---|---|---|
| Global `~/.agents/skills` | Native | Native in current runtime |
| Global `~/.agents/AGENTS.md` | Revalidate; current V2 docs point to `~/.config/opencode/AGENTS.md` | Native |
| Agent Skills `SKILL.md` concept | Native | Native |

Therefore:

- **No OpenCode skill adapter.**
- **No Cline skill adapter.**
- **No duplicated `.agents` skills under vendor folders.**
- A minimal OpenCode compatibility link/config for the global `AGENTS.md` is allowed only if Phase 1 confirms the installed version still needs its documented tool-specific global instructions path.

## Agent-agnostic public identity

The GitHub repository must be described as an agent-agnostic `.agents` / Agent Skills setup.

Do not brand the project as:

- an OpenCode setup;
- a Cline setup;
- an OpenCode + Cline kit.

It is acceptable and desirable to say:

> Agent-agnostic global Agent Skills setup. Tested with OpenCode and Cline.

Additional agents should be documented in a compatibility matrix as they are verified. Native `.agents` support should require no installation branch beyond the canonical setup.

## Repository role

The GitHub repository is the reproducible definition of the setup, not the live canonical runtime directory.

It should contain:

- curated global instruction template;
- manifests describing selected upstream skills/integrations;
- PowerShell installation/update/verification/uninstall tooling;
- documentation and trust decisions;
- compatibility tests/notes.

The installer materializes/synchronizes the selected version into `%USERPROFILE%\.agents`.

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
