# Portability verification — Phase 5

What was checked to decide this repository is safe to publish and install on another machine.

- Date: 2026-10-04
- Method: replicate a fresh clone into a throwaway directory, then run the documented install flow
  against a throwaway home directory. The real `%USERPROFILE%\.agents` was not involved.

## 1. Tracked-file hygiene

| Check | Result |
|---|---|
| Tracked files | 232 |
| Absolute user paths of the form `<drive>\Users\<name>\...` | **0** |
| Machine hostname | **0** |
| Passwords, tokens, API keys, PATs | **0** |
| Machine-specific backups or diagnostic dumps | **0** tracked; `diagnostics/` is git-ignored |

34 absolute user-path occurrences were normalised to `%USERPROFILE%` tokens across
`docs/environment.md`, `docs/install-verification.md`, `docs/troubleshooting.md` and
`docs/bootstrap-state.md`. The three machine-evidence documents now open with a note saying they
record one bootstrap machine and are not prescriptive for anyone else's.

No file contains an absolute path outside its own code examples.

## 2. Licence handling

`LICENSE` is **MIT**, chosen because it is the most permissive and maximally compatible licence for
tooling people are expected to fork, and because it imposes no restriction on combining this tooling
with the permissively licensed third-party skills it installs.

The `LICENSE` file states explicitly what it does and does not cover:

- **Covers:** `scripts/`, `global/AGENTS.md`, `docs/`, the READMEs, `AGENTS.md`, `PLAN.md`,
  `CLAUDE.md`, `manifest/`, and **this project's modifications** to the forks in `vendor/skills/`.
- **Does not cover:** the vendored skills themselves, which remain under their upstream licences.
  Every one carries a `PROVENANCE.md` with the upstream repository, commit, licence and licence
  notice. `THIRD_PARTY_NOTICES.md` lists them all with full licence texts.

### The distribution decision

27 skills are **vendored forks**, 13 are **fetched at install time** from a pinned commit. The split
was decided per skill on licence, security and maintainability grounds:

| Mode | Chosen when | Skills |
|---|---|---|
| **Vendored fork** | The upstream text had to be rewritten, so the content is no longer byte-identical and must be versioned and reviewed here | the 27 from `social-media-skills/skills`, plus `impeccable` and `frontend-design`, which are vendored trimmed to keep executable files out of the installed set |
| **Pinned fetch** | The upstream artifact can be used verbatim, so a commit pin is a stronger guarantee than a local copy | the rest: `jamditis`, `blacktwist`, `Nutlope/hallmark`, `affaan-m/ecc`, `PracticalSwan`, `stevysmith` |

This matters for licensing in one specific way: **fetched skills are not redistributed by this
repository.** They are downloaded from their own upstream at install time, under their own licences.

### The one licence risk, and why it is not redistribution

`og-image` comes from `stevysmith/og-image-skill`, which has **no LICENSE file**. It is recorded in
`manifest/skills.json` with `licenseRisk: ACCEPTED-BY-USER-2026-10-04`, and it is **not** vendored:

```text
vendor/skills/og-image   does not exist
```

So this repository does not redistribute it. It is fetched at install time, where the licensing
ambiguity is the user's to accept on their own machine. This is stated in both READMEs, in `LICENSE`,
and in `docs/security.md`. Removing it is a one-line manifest change.

## 3. Identity is agent-agnostic

The README title, intro and description describe an **agent-agnostic global Agent Skills setup** built
on the shared `.agents` convention. Checked mechanically for forbidden framing:

| Phrase | Present |
|---|---|
| "OpenCode setup", "Cline setup", "kit for OpenCode", "for OpenCode and Cline" | **no** |
| "Tested with OpenCode and Cline" | **yes**, once, in the position where a support statement belongs |

Vendor-specific discussion lives in the compatibility section and in `docs/architecture.md`, not in
the project's identity.

## 4. Bilingual README

The English `README.md` is primary. Both files open with a language selector in the pattern used by
multilingual repositories, with each language named in its own language:

```markdown
README.md      **Languages:** [English](README.md) · [Español](README.es.md)
README.es.md   **Idiomas:** [English](README.md) · [Español](README.es.md)
```

`README.es.md` is a complete translation, not a summary: same sections, same tables, same commands,
same warnings. Cross-links verified in both directions.

The copy/paste installation prompt is deliberately **kept in English in both files**, because it is
text the reader hands to an agent rather than text they read. The Spanish README says so explicitly.

## 5. Bootstrap test from a clean directory

The repository content was replicated into a throwaway directory and the documented flow was run
against a throwaway home.

| Step | Result |
|---|---|
| `update.ps1 -Fetch` | 7 repositories fetched, `SKILL.md` counts 248, 1, 63, 1, 14, 106, 1027 |
| `install.ps1 -DryRun` | 41 planned, **0 conflicts**, nothing written |
| `install.ps1` | 41 applied, **0 conflicts** |
| `verify.ps1` | **13 passed, 0 warnings, 0 failures**, exit 0 |
| `uninstall.ps1 -Confirm` | removed 40 kit skills, **kept `my-own-skill`**, removed the canonical `AGENTS.md` |
| `install.ps1` again | 41 applied, round trip clean |
| `verify.ps1` | 12 passed, **1 warning**, 0 failures |

The counts are 41 rather than 42, and 13 rather than 14, for a correct reason: the throwaway home has
no `~/.config/opencode`, because that machine has no OpenCode. The bridge is skipped and reported as
not required. The reinstall warning is the `my-own-skill` directory the test added deliberately to
check that the kit never deletes skills it does not own.

### Defect this test caught

**`update.ps1 -Fetch` was silently broken, and the clean-directory test was the only thing that
found it.**

During Phase 4 a patch introduced a reference to `$r.repoEntry` in the fetch loop, but the `Replace`
that was supposed to add that property never matched, so the property did not exist. On a machine
where the cache was already populated the loop took the "already cached" branch and the broken line
was never reached. On a fresh machine it ran, and:

- `$dest` was never assigned, so `git init` was never called;
- the loop still printed `fetched, 0 SKILL.md files on disk`, because `$LASTEXITCODE` retained the
  value from the previous repository's successful checkout;
- `install.ps1` then reported 13 skills as conflicts.

Two things were wrong, not one: the missing property, and a success message that ignored whether
anything was actually fetched. Both are fixed. `update.ps1` now verifies the checkout produced a
worktree before reporting success, and the fetch loop takes its destination from the same
`Get-KitCacheDir` helper the rest of the toolchain uses.

**This is the argument for testing the fresh-machine path rather than only the path you already
have in place.** Phase 4 passed every check on a machine that had already been populated.

### Documentation defect the same test caught

The READMEs originally listed the commands as *dry run, then fetch, then install*. On a fresh
machine the dry run runs before anything is fetched, so it reports the 13 fetched skills as missing
conflicts. The documented order is now **fetch first, then dry run, then install**, with a comment
saying why.

## 6. Prerequisites are genuinely optional

The README states Node.js and Python are not needed. That claim is testable, and the bootstrap run
demonstrates it: it used only Windows PowerShell 5.1 and Git, and produced a complete verified
installation of 40 skills. `verify.ps1` reports **zero executable files** across all of them.

Python 3.13.15 happens to be present on this machine because the user asked for it, and Node.js is
not installed. Neither affected any result above.

## 7. Published location

- Repository: https://github.com/elibottacin/newsroom-agent-kit
- Visibility: **public**, confirmed by the user before creation
- Default branch: `main`
- Clone URL used in both READMEs: `git clone https://github.com/elibottacin/newsroom-agent-kit`

The `{{REPO_URL}}` placeholder that stood in through Phases 3 to 5 was replaced with the real URL in
both `README.md` and `README.es.md`, three occurrences each: the copy/paste installation prompt, the
manual clone command, and the compatibility reference.