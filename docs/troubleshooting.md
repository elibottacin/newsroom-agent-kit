# Troubleshooting

Every command below assumes Windows PowerShell 5.1. **The machine's execution
policy is `Restricted`, so `-ExecutionPolicy Bypass` is always required.**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\<script>.ps1
```

Always run `-DryRun` first and read the output before making changes.

---

## `install.ps1`

### "script execution is disabled on this system"

The execution policy is `Restricted`, so a directly invoked `.ps1` is blocked. This is expected.
Always use `powershell -NoProfile -ExecutionPolicy Bypass -File ...`.

Changing the machine policy permanently is **not** necessary and not recommended. If you prefer to
set it for your user only:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### "Missing skills: <names>" from verify, or "upstream not present in cache"

Pinned-fetch skills are not vendored in this repository. They are copied from a local cache that is
populated on demand. Populate it first:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update.ps1 -Fetch
```

This clones pinned commits into `~/.agents/cache/upstream`. It installs nothing and executes no
upstream code.

### "already current" / "would install" and nothing changes

The installer is idempotent by design. A second run with no upstream change writes nothing and
reports every skill as already current. That is the desired outcome, not a failure.

### "exists and is not kit-owned"

A file or directory under `~/.agents` is not recorded in `~/.agents/state/install-state.json`, so
the installer refuses to replace it. This is the non-destructive guard working.

Decide which of these applies:

1. **It is your own earlier work.** Merge it manually, or move it aside, then re-run.
2. **It is an old install of this kit** whose state file was lost. Compare it with the curated copy
   and, if the curated copy is what you want, move the old directory aside and re-run:
   ```powershell
   Move-Item "$env:USERPROFILE\.agents\skills\<name>" "$env:USERPROFILE\.agents\backups\manual-<timestamp>"
   ```
3. **You edited an installed skill on purpose.** The installer will refuse again. Either keep your
   version (it stays until you uninstall) or accept the curated version with `-Force`.

### "contains executable files and is not approved"

The curated set is instruction-only. A skill acquired executable content after review — or the
manifest points at a directory that includes scripts — and the installer refuses.

Do not work around this by editing the check. Either exclude the scripts at the source (as was done
for `impeccable` and `frontend-design`, both of which are vendored trimmed) or move the skill to the
`optional` section of the manifest.

### "invalid SKILL.md (...)"

The `SKILL.md` failed static validation against the Agent Skills specification. The message names
the problem: frontmatter missing, `name` not lowercase kebab-case, `name` not matching the directory
name, or `description` empty or over 1024 characters.

This usually means the wrong directory was staged. Check `source.subdir` in
`manifest/skills.json`.

### The OpenCode bridge was not created

Phase 1 proved symbolic links fail on this machine without elevation or Developer Mode, so the
bridge is an **NTFS hard link**, which works unelevated.

The bridge is skipped, with a message, when:

- `~/.config/opencode` does not exist, meaning OpenCode is not configured here. Nothing to bridge.
- `~/.config/opencode/AGENTS.md` already exists as a regular file. The installer will not overwrite
  it. Merge it into `~/.agents/AGENTS.md` yourself, or move it aside, then re-run.

Verify by hand:

```powershell
Get-Item "$env:USERPROFILE\.config\opencode\AGENTS.md" -Force | Select-Object LinkType, Length
```

`LinkType` must be `HardLink`.

### The bridge content is stale

Both names share one inode, so editing the canonical file is visible through both paths. The bridge
goes stale only if something **replaced** the file rather than editing it, for example a
write-temp-then-move. Re-run `install.ps1` and it will repair the link.

**Installer rule:** never replace the canonical `AGENTS.md` via write-temp-then-move. Replace by
delete-then-recreate so the link cannot be orphaned.

---

## Execution dependencies

The selected setup needs local software, not just markdown. `install.ps1
-InstallPrerequisites` provisions it from `manifest/dependencies.json`.

### `zernio` throws a PSSecurityException about scripts being disabled

**Expected on this machine, and not a broken install.** npm writes three shims for
every global command:

```
zernio        (POSIX shell)
zernio.cmd    (Windows command)
zernio.ps1    (PowerShell)
```

The effective execution policy here is `Restricted`, which blocks `.ps1`. When
you type bare `zernio`, PowerShell resolves to `zernio.ps1` and refuses to run it.
The error names `zernio.ps1`, which is the giveaway.

**Use the `.cmd` form.** It is not blocked, because a batch file is not a script:

```
zernio.cmd auth:login
zernio.cmd auth:check
zernio.cmd accounts:list
```

This is also why the kit's own instructions and scripts always use the `.cmd`
extension. `hyperframes.cmd` behaves the same way once HyperFrames is installed.

Do **not** fix this by loosening the execution policy. If you want bare `zernio`
to work, the least invasive option is a PowerShell profile function rather than a
security change:

```powershell
function zernio { & "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\OpenJS.NodeJS.LTS_Microsoft.Winget.Source_8wekyb3d8bbwe\node-v24.19.0-win-x64\zernio.cmd" @args }
```

That is per-user, reversible, and PowerShell-only. `Set-ExecutionPolicy
-Scope CurrentUser RemoteSigned` would also work, but it changes the machine's
security posture for every script, not just npm shims, so it is not this kit's
call to make.

### `zernio` is not recognised after installing

**This is expected until you open a new terminal.** winget and npm both add the
new directory to the persisted user `PATH`, but the terminal you already have open
keeps its old copy. Close it and open a new one.

Verify without a new terminal:

```
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -InstallPrerequisites
```

The `Execution dependencies` section reports what was found and where, even when
the current session cannot see it.

### "not recognised" and `npm` is also missing

Node.js is the prerequisite for both CLIs. Install it first:

```
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -InstallPrerequisites -Dependencies nodejs
```

### `winget` exits 1602

The installer was cancelled, usually a declined UAC prompt. The kit installs with
`--scope user` precisely so this does not happen: the Node.js package is a zip
that winget extracts and hash-verifies, with no machine-wide MSI and no
elevation. If you still see 1602 you are running an older copy of the script.

### `npx zernio` fails

Expected. The unscoped npm package `zernio` **does not exist**. The package is
`@zernio/cli`, so use `npx @zernio/cli` or install it globally.

The CLI also ships a legacy binary named `late`. Never install the unscoped
`late` package: on npm that name belongs to an unrelated project.

### "present but older than required ... Left alone"

The kit found the tool but will not upgrade it across a version you may depend on.
It prints the upgrade command; run it yourself if you want the newer version.

### A dependency shows MISSING in verify but is installed

Almost always a `PATH` problem. A freshly installed package is on disk but not in
the running session's `PATH`. Open a new terminal. If it persists, check the
`Execution dependencies` section of verify for the path it reports.

### Phase 9 versus Phase 11 warnings

`verify.ps1` reports three expected warnings on a Phase 9 install:

| Warning | Meaning | Fixed in |
|---|---|---|
| `hyperframes-cli MISSING` | not provisioned yet | Phase 11 |
| `ffmpeg MISSING` | not provisioned yet | Phase 11 |
| `zernio-auth not authenticated` | you have not run `zernio auth:login` | Phase 10 |

Each line shows the phase that provisions it. Nothing is broken.

## `verify.ps1`

### Exit codes

| Code | Meaning |
|---|---|
| 0 | all checks passed |
| 1 | one or more checks failed; the setup is not correct |
| 2 | passed, with warnings |

### "unmanaged directories present (not created by this kit, left alone)"

There are directories under `~/.agents/skills` that this kit did not install. That is a warning, not
a failure. The kit never deletes skills it does not own.

### "vendor skill directories contain skills"

Something created skills under `~/.config/opencode/skills`, `~/.claude/skills`, `~/.codex/skills`,
`~/.gemini/skills`, `~/.cursor/skills` or `~/.cline/skills`.

This kit never does that, and it never should: both tested agents read `~/.agents/skills` natively.
The likely cause is a third-party tool such as the `npx skills` CLI, which installs OpenCode's
skills to `~/.config/opencode/skills` and would create exactly this drift.

Fix by removing the vendor copies after confirming the canonical copy is complete:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1   # canonical first
```

Then delete the vendor directory by hand, one at a time, only after you have looked at it.

### "product references found in: <skill>"

A third-party product name reappeared in an installed skill. For vendored forks this means
something replaced a fork with an upstream copy. Restore it:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Force
```

### "curated skills reference N sibling skills that are not installed"

Expected, not a failure. The vendored set came from a library of 106 skills and this kit installs 27
of them, so some handoffs point at skills that are absent. The global `AGENTS.md` instructs the
agent to treat those as unavailable and to do the work itself rather than inventing content.

The most-referenced missing skills are listed in `manifest/skills.json` under `optional`.

### "not recorded as kit-owned"

The ownership record does not list every installed skill. `uninstall.ps1` relies on that record and
will not guess, so this is worth resolving before you ever need to uninstall. Re-run `install.ps1`
to rewrite the record.

---

## `uninstall.ps1`

### Nothing was deleted

By design. Run it with `-Confirm` to actually delete:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 -DryRun      # see the plan
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 -Confirm     # do it
```

### "No usable ownership record found"

`~/.agents/state/install-state.json` is missing or unreadable. The script refuses to delete skills it
cannot prove it created.

Review `~/.agents/skills` manually and delete what you recognise. Nothing else should be touched;
in particular `~/.config/opencode/` keeps its other files either way.

### Backups are not restored automatically

Backup filenames are flattened, so restoring is deliberately manual. Locate them:

```powershell
Get-ChildItem "$env:USERPROFILE\.agents\backups" -Directory | Sort-Object Name -Descending
```

Copy back what you need by hand. `-RestoreBackups` prints the candidates.

### "canonical AGENTS.md was edited outside the kit. Left in place."

Correct behaviour. The kit only removes a file it can prove is its own.

---

## `update.ps1`

### "FAILED to fetch ref <sha>"

The pinned commit no longer exists upstream, most likely because a branch was force-pushed or a
release was retracted. Do **not** silently repoint to a branch head. Investigate the repository, then
update `source.ref` in `manifest/skills.json` deliberately and record why.

### Upstream moved on

`update.ps1 -CheckRemote` reports that the pinned commit is no longer the branch head. This is
informational. Nothing is updated until you change the pin.

### How to adopt a change

- **Pinned-fetch skill:** change `source.ref`, run `update.ps1 -Fetch -CheckRemote`, read the diff,
  then `install.ps1 -Force`.
- **Vendored fork:** review upstream, hand-merge into `vendor/skills/<name>`, update
  `PROVENANCE.md`, then `install.ps1 -Force`. **Never copy an upstream directory over a fork** —
  that is what reintroduces the third-party product references this kit removed on purpose.

---

### Prerequisites: Python installed, Node.js not

`install.ps1 -InstallPrerequisites` installs `Python.Python.3.13` and `OpenJS.NodeJS.LTS` through
winget. On this machine:

- **Python 3.13.15 installed successfully**, along with the Python Launcher.
- **Node.js was not installed.** winget returned exit code `1602`
  (`ERROR_INSTALL_USEREXIT`), meaning the installer was cancelled — normally a declined or timed-out
  UAC prompt.

Neither runtime is needed. All 40 installed skills are markdown and `verify.ps1` confirms zero
executable files. To finish the Node.js install, accept the UAC prompt when it appears, or run:

```powershell
winget install --id OpenJS.NodeJS.LTS -e
```

### `python` opens the Microsoft Store instead of running

Windows ships a `python.exe` alias stub in `WindowsApps` that takes priority in an already-open
shell. The real interpreter, once installed, is:

```text
%USERPROFILE%\AppData\Local\Programs\Python\Python313\python.exe
```

Its installer prepends that directory to the user `PATH` ahead of the stub, so **open a new session**
and `python --version` resolves correctly. To check immediately without restarting:

```powershell
& "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe" --version
```
## Environment reference

From `docs/environment.md`, these are the machine facts that shape the tooling:

| Fact | Consequence |
|---|---|
| Windows PowerShell 5.1, no PowerShell 7 | No PS7-only syntax or modules |
| Execution policy `Restricted` | Always pass `-ExecutionPolicy Bypass` |
| Not elevated | Symbolic links fail; hard links work |
| Spanish-localized messages | Never parse error text; key off exit codes and object properties |
| `core.autocrlf=true` | Repo files are LF, checked out CRLF; both are tolerated |
| C: is NTFS | Hard links are available within the volume |

## Recovering from a bad state

The kit only ever writes inside `%USERPROFILE%\.agents`, plus one hard link at
`%USERPROFILE%\.config\opencode\AGENTS.md`. If something goes wrong:

1. **Do not** delete `~/.agents` wholesale. It may contain skills you installed yourself.
2. Remove kit-managed skills: `uninstall.ps1 -Confirm`.
3. Delete the bridge by hand if uninstall did not: it is a single file,
   `~/.config/opencode/AGENTS.md`, and only if `LinkType` is `HardLink`.
4. `~/.config/opencode/service.json` belongs to OpenCode, not to this kit. Leave it alone.

## Getting help

If a check fails in a way this document does not cover, capture:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1
```

and the full installer dry run. Both redact absolute user paths and print no file contents and no
credentials, so the output is safe to share.