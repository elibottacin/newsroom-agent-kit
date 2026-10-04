# Newsroom Agent Kit

Bootstrap project for a portable, global, **agent-agnostic** AI-agent skill setup on Windows using the shared `.agents` / Agent Skills conventions.

## Status

Local-only bootstrap workspace. Follow `PLAN.md` one phase at a time.

- Phase 0 (bootstrap and Git tracking) is complete; see `docs/bootstrap-state.md` for the recorded starting state.
- The repository intentionally has **no remote** until the publication phase in `PLAN.md`.

The final system will use:

- `%USERPROFILE%\.agents\AGENTS.md` as the canonical global instruction file;
- `%USERPROFILE%\.agents\skills\` as the canonical global skill library;
- direct native consumption by any compatible coding agent that supports the shared `.agents` convention;
- only minimal compatibility handling for a specific artifact when a tool does not natively support its canonical `.agents` location.

## Compatibility

The project is **not an OpenCode or Cline-specific setup**.

It targets the shared `.agents` / Agent Skills ecosystem and should work with any compatible coding agent. The initial implementation is **tested with OpenCode and Cline** because those are available on the bootstrap machine.

Current seed evidence indicates both agents can consume global skills directly from `~/.agents/skills`. Cline also consumes `~/.agents/AGENTS.md`; OpenCode's global instruction behavior must be revalidated during the plan and may require a minimal compatibility link for that single file.

## Operating instructions

The coding agent must read `AGENTS.md` and `PLAN.md` before making changes.

The plan is phase-gated: complete one phase, validate it, update checkboxes and documentation, commit everything, then stop for user review.

## Future one-prompt installer

Phase 5 will finalize this prompt and Phase 6 will replace `{{REPO_URL}}` with the actual GitHub URL:

```text
Set up my global coding-agent skills from {{REPO_URL}} on this Windows PC.

Clone the repository, read its README and installation documentation, and follow the repository's supported install path. Use %USERPROFILE%\.agents as the canonical global source for AGENTS.md and skills. Preserve and back up any existing user configuration; do not silently overwrite unrelated settings. Detect the coding agents installed on this PC. Use native `.agents` discovery wherever supported and do not create vendor-specific skill copies. Add compatibility handling only for a capability that is proven not to support the canonical location. Install the curated core setup, leave optional external-account/MCP integrations unconnected unless I explicitly approve them, run the repository verification tooling, and report exactly what was installed, linked, skipped, or needs my action.
```

Do not use this placeholder prompt on another machine until the repository has been published and the URL has been replaced.
