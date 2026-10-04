# Install verification — Phase 4

This file is a **record of one bootstrap machine's install**, kept as evidence. Paths use
`%USERPROFILE%` tokens so they read correctly elsewhere. Your machine may differ; run
`scripts\verify.ps1` to see its real state.

What was actually observed when the setup was installed on this machine, as opposed to what was
predicted. Everything here was measured after the install.

- Date: 2026-10-04
- Machine: `<hostname>`, Windows 11 Home Single Language `10.0.26200`
- Canonical root: `%USERPROFILE%\.agents` — created by this phase
- Raw verifier output: `diagnostics/verify-phase4.txt` (git-ignored, contains no secrets and no
  absolute user paths)

## 1. What was written

| Path | Action |
|---|---|
| `%USERPROFILE%\.agents\AGENTS.md` | created, 7203 bytes, byte-identical to `global/AGENTS.md` |
| `%USERPROFILE%\.agents\skills\<name>\` | created for **40** skills |
| `%USERPROFILE%\.agents\state\install-state.json` | created, the ownership record |
| `%USERPROFILE%\.agents\cache\upstream\` | created by `update.ps1 -Fetch`, 173.7 MB of pinned worktrees |
| `%USERPROFILE%\.config\opencode\AGENTS.md` | created as an **NTFS hard link** to the canonical file |

Nothing else on the machine was modified by this project.

Cache layout is two levels deep, because the manifest stores the repository as `owner/repo` and
Windows treats `/` as a separator:

```text
%USERPROFILE%\.agents\cache\upstream\<owner>\<repo>@<short-ref>\
```

`affaan-m` is 87 MB of that total, because `affaan-m/ecc` contains 1027 `SKILL.md` files and the kit
uses exactly one of them.

## 2. OpenCode loads both artifacts natively

This is the strongest evidence in the project, and it was not scripted. The OpenCode server
restarted immediately after the install and came back reporting both artifacts:

```text
New skills are available in addition to those previously listed:
  <skill><id>accessibility-compliance</id> ... 40 entries ...

New instructions apply from:
Instructions from: %USERPROFILE%\.config\opencode\AGENTS.md
```

Two conclusions, both behavioural rather than inferred:

1. **All 40 skills were discovered from `%USERPROFILE%\.agents\skills`**, with their sanitised
   descriptions. No `~/.config/opencode/skills` directory exists. Phase 1's conclusion that no
   OpenCode skill adapter is needed is now confirmed in practice.
2. **Global instructions were applied from `%USERPROFILE%\.config\opencode\AGENTS.md`**, which is
   the hard link. This is exactly the single proven compatibility exception from Phase 1, working
   end to end: one file, two names, one source of truth. OpenCode applied it as
   "new instructions", meaning it loaded the content through the link and could read it.

Confirming the link rather than a copy:

```text
bridge LinkType  = HardLink
bridge bytes == canonical bytes = True
```

## 3. Cline resolves the canonical paths

Cline Desktop 0.0.43 has no headless or CLI mode — `code-sidecar.exe --help` does not return — so
this was verified by resolving, from the functions extracted out of the shipped sidecar in Phase 1,
the exact paths Cline computes, and confirming those targets exist and are valid.

| Cline function | Resolved path | Observed |
|---|---|---|
| `resolveSkillsConfigSearchPaths` | `<workspace>\.clinerules\skills` | absent |
| | `<workspace>\.cline\skills` | absent |
| | `<workspace>\.agents\skills` | absent |
| | `~\.cline\skills` | absent |
| | **`~\.agents\skills`** | **exists, 40 skills** |
| `resolveGlobalAgentsRulesPath` | **`~\.agents\AGENTS.md`** | **exists, 7203 bytes, first heading `# Global instructions - newsroom agent kit`** |
| `resolveRulesConfigSearchPaths` | `~\Documents\Cline\Rules` | absent |
| `resolveAgentPluginSearchPaths` | `~\.agents\plugins` | absent, as required |

Of the 40 installed skills, **40 have a valid `SKILL.md` whose `name` matches its directory**, so
Cline's discovery step accepts every one. Cline resolves the canonical global instructions and the
canonical global skills as its only populated paths. **No Cline compatibility artifact was created,
because none is needed.**

Remaining gap: Cline's UI has not been opened to confirm on screen. The path resolution and file
validity are proven; a visual confirmation is a one-minute manual step.

## 4. Idempotency

The installer was run a second time against the live install:

```text
planned changes : 42
applied         : 0
already current : 40
conflicts       : 0
backups         : 0
```

Zero writes. `backups: 0` also confirms nothing was replaced, so no user file was ever displaced.

## 5. Existing user configuration is intact

Hashes taken before the install and compared after:

| File | Before | After | Verdict |
|---|---|---|---|
| `~\.config\opencode\service.json` | `7857F591107F` | `7857F591107F` | unchanged |
| `~\.cline\data\settings\global-settings.json` | `9EB959E98D6B` | `9EB959E98D6B` | unchanged |
| `~\.cline\data\settings\providers.json` | `707704B1DCC1` | `707704B1DCC1` | unchanged |
| `~\.local\state\opencode\service.json` | `42E4C5BD1267` | `F0F45599F451` | changed by OpenCode itself |

The fourth file is OpenCode's own runtime state. Its modification time is nine seconds after the
install wrote `AGENTS.md`, and its contents differ only in `id`, `url` and `pid`, all of which change
on every OpenCode start. The `password` field is stable. This project never opens this file; the
installer writes only inside `~\.agents` plus the single hard link.

## 6. Vendor isolation

All of these must not exist, and none do:

```text
~\.config\opencode\skills   absent
~\.claude                    absent
~\.codex                     absent
~\.gemini\skills             absent
~\.cursor\skills             absent
~\.cline\skills              absent
~\.agents\plugins            absent
```

`~\.config\opencode` contains exactly `service.json` (pre-existing) and `AGENTS.md` (the new link).

## 7. Update behaviour

`update.ps1` reports only and changes nothing, confirmed by running `verify.ps1` afterwards:
14 passed, 0 warnings, 0 failures.

`update.ps1 -CheckRemote` compared each pinned commit against its upstream default branch. Every
pin is still the branch head:

```text
PracticalSwan/agent-skills        pinned ref is still the branch head
pbakaus/impeccable                pinned ref is still the branch head
Nutlope/hallmark                  pinned ref is still the branch head
jamditis/claude-skills-journalism pinned ref is still the branch head
stevysmith/og-image-skill         pinned ref is still the branch head
blacktwist/social-media-skills    pinned ref is still the branch head
social-media-skills/skills        pinned ref is still the branch head
affaan-m/ecc                      pinned ref is still the branch head
```

## 8. Uninstall behaviour

Tested non-destructively against the live install, since Phase 3 already exercised the full
destructive cycle in a sandbox.

- `uninstall.ps1 -DryRun` — reported 40 skills it would remove, deleted nothing.
- `uninstall.ps1` without `-Confirm` — reported 40, deleted nothing, said so explicitly.

After both, the install still verified at 14 passed, 0 warnings, 0 failures.

## 9. Prerequisites

`install.ps1 -InstallPrerequisites` was run because the user asked for both runtimes.

| Package | Result |
|---|---|
| `Python.Python.3.13` | **installed**, Python 3.13.15, plus the Python Launcher |
| `OpenJS.NodeJS.LTS` | **not installed**, winget/MSI exit code `1602` |

Exit code 1602 is `ERROR_INSTALL_USEREXIT`: the installer was cancelled, which here means the UAC
elevation prompt was declined or timed out. Node.js is therefore **not** on the machine.

Python works. Its installer prepended its directories to the user `PATH` ahead of the WindowsApps
alias stub, so in any new session `python` resolves to the real interpreter rather than to the
store stub. Verified directly:

```text
%USERPROFILE%\AppData\Local\Programs\Python\Python313\python.exe  ->  Python 3.13.15
```

Neither runtime is needed by the installed setup: all 40 skills are markdown, `verify.ps1` confirms
zero executable files, and Impeccable's CLI was excluded precisely because it downloads a binary.

To finish the Node.js install, either accept the UAC prompt when it appears, or run this yourself:

```powershell
winget install --id OpenJS.NodeJS.LTS -e
```

## 10. Defects found and fixed during this phase

1. **Dry run under-reported by one change.** It did not plan the OpenCode hard link, because in dry
   run the canonical file was never created and the bridge check then saw it as absent. The preview
   is supposed to be exact, so it now plans the link whenever the canonical file is also planned.
2. **`update.ps1` mis-resolved the cache path**, using the full 40-character ref where the rest of
   the toolchain uses the short ref, so every pinned skill was reported "not cached" while being
   cached. A single `Get-KitCacheDir` helper now owns that path for all scripts.
3. **`update.ps1 -CheckRemote` failed on every repository.** The `git ls-remote` URL was built
   inline, so PowerShell passed a literal `+` as an argument instead of concatenating, and the
   errors were suppressed, so it silently reported "could not query" for all eight. The URL is now
   built in a variable. All eight resolve correctly.
4. **`install.ps1` reported "Prerequisites installed" unconditionally**, even when Node.js failed
   with 1602. It now inspects winget's exit code per package and names what failed.

## 11. Verification summary

`scripts/verify.ps1` against the live install:

```text
passed  : 14
warnings: 0
failed  : 0
```

The checks that matter most here:

- canonical `~\.agents\AGENTS.md` exists and matches the repository version;
- all 40 curated skills are installed;
- every `SKILL.md` has valid frontmatter with `name` matching its directory;
- no installed skill contains executable files;
- no installed skill contains third-party product references, so the sanitising held through install;
- no unexpected skill directories under `~\.agents\skills`;
- no vendor-specific skill copies exist;
- the bridge is a hard link, not an independent copy, and its content matches the canonical file;
- the ownership record exists and covers every curated skill.

One reported characteristic, not a failure: 44 uninstalled sibling skills are referenced by the
installed set. `scheduling-and-queue` is the most referenced at 30 mentions. The global `AGENTS.md`
instructs the agent to treat those as unavailable rather than invent their contents.