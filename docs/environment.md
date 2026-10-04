# Environment discovery — Phase 1

This file is a **record of one bootstrap machine**, kept as evidence for the compatibility
decisions in `docs/architecture.md`. Paths use `%USERPROFILE%` and similar tokens rather than
one person's absolute paths, so it reads correctly elsewhere. Expect it to differ from your
own machine; `scripts\verify.ps1` reports the actual state on yours.

Read-only discovery of the bootstrap machine. No global agent configuration was created,
modified, moved, or deleted while producing this document.

- Discovery date: 2026-10-04
- Machine: `<hostname>`
- Project workspace: `%REPO_ROOT%`

Everything below is either **observed on this machine** or **quoted from a cited source**.
Anything inferred is labelled as inference.

---

## 1. Operating system and shell

| Property | Value |
|---|---|
| Edition | Windows 11 Home Single Language |
| Version / build | `10.0.26200` (build 26200), 64-bit |
| Hardware | Acer Aspire A314-22, ~3.4 GB RAM |
| C: filesystem | **NTFS**, ~280 GB free |
| Shell | **Windows PowerShell 5.1.26100.9444** (Desktop edition) |
| PowerShell 7 (`pwsh`) | **not installed** |
| .NET CLR | 4.0.30319.42000 |
| UI/OS language | Spanish — system messages are localized |
| Elevated / Administrator | **No** |

### Consequences for Phase 3 tooling

1. **Scripts must target Windows PowerShell 5.1.** No PowerShell 7-only syntax or modules.
2. **Execution policy is `Restricted`** (verified: `Get-ExecutionPolicy -List` shows `Undefined`
   in every scope, and the effective value is `Restricted`). A directly invoked `.ps1` fails with
   *"script execution is disabled on this system"*. Verified working invocation:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1
   ```

   `powershell -NoProfile -ExecutionPolicy Bypass -File` must be the documented entry point in
   `README.md`, in the one-paste install prompt, and in any self-check the installer performs.
3. **Do not parse localized system error text.** Diagnostics must key off exit codes, `$?`,
   `LinkType`, `Test-Path`, and `Get-ItemProperty` values, never off message strings.
4. **No Administrator rights.** Installation must work at user level.

### Link capability (probed, then cleaned up)

The probe was run in `%LOCALAPPDATA%\Temp\opencode\linkprobe` and deleted afterwards. It did not
touch `%USERPROFILE%\.agents` or any agent configuration.

| Mechanism | Result |
|---|---|
| NTFS **hard link** (file) | **Works, no elevation required** (`New-Item -ItemType HardLink` → `LinkType = HardLink`) |
| **Symbolic link** (file) | **Fails** — requires Administrator privileges |
| **Directory junction** | Works, but only links directories, not a single file |
| Windows Developer Mode | Not enabled (`HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock\AllowDevelopmentWithoutDevLicense` absent) |

This is decisive for the one proven compatibility exception (section 4).

---

## 2. Canonical root

```text
%USERPROFILE%          = %USERPROFILE%
canonical root         = %USERPROFILE%\.agents
canonical root exists? = NO
```

`%USERPROFILE%\.agents` does **not** exist yet. There is therefore **no pre-existing global
skill library and no pre-existing global `AGENTS.md`** to merge with or back up.

### Other agent-owned locations checked (all absent)

```text
%USERPROFILE%\.agents                              absent
%USERPROFILE%\.claude                              absent
%USERPROFILE%\.codex                               absent
%USERPROFILE%\.gemini                              absent
%USERPROFILE%\.cursor                              absent
%USERPROFILE%\AGENTS.md                           absent
%USERPROFILE%\.config\opencode\AGENTS.md          absent
%USERPROFILE%\.config\opencode\opencode.json      absent
%USERPROFILE%\.config\opencode\skills             absent
%USERPROFILE%\.config\opencode\plugin             absent
%USERPROFILE%\.config\opencode\agent              absent
%USERPROFILE%\.cline\skills                       absent
%USERPROFILE%\.cline\rules                        absent
%USERPROFILE%\Cline                               absent
%USERPROFILE%\Documents\Cline                     absent
```

**Conflict risk for the canonical install is currently zero.** The installer must still refuse
unsafe overwrite, because a later run or another tool could create these paths.

Note: OpenCode walks *up* from the workspace collecting `AGENTS.md`. `%USERPROFILE%\AGENTS.md` is
absent, so no stray home-level instruction file will shadow anything.

---

## 3. Installed tooling

| Tool | Status | Version | Location |
|---|---|---|---|
| Git | installed | `2.56.0.windows.1` | `C:\Program Files\Git\cmd\git.exe` |
| OpenCode Desktop | installed | `2.0.22` (winget `SST.OpenCodeDesktop`) | `%LOCALAPPDATA%\Programs\@opencodedesktop\OpenCode.exe` |
| opencode-cli | installed (bundled, **not on PATH**) | `v2.0.22` | `%APPDATA%\ai.opencode.desktop\cli\2.0.22\opencode-cli.exe` |
| Cline Desktop | installed | `0.0.43` (winget `Cline`) | `%LOCALAPPDATA%\Cline\cline-app.exe` + `code-sidecar.exe` |
| Freebuff Desktop | installed | `0.0.158` | `%LOCALAPPDATA%\Programs\@codebufffreebuff-desktop\Freebuff.exe` |
| winget | present | — | `%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe` |
| **Node.js** | **MISSING** | — | not on PATH, not installed |
| **npm / npx** | **MISSING** | — | not installed |
| **GitHub CLI (`gh`)** | **MISSING** | — | not installed |
| VS Code / Code Insiders / Cursor / VSCodium | not installed | — | no `code` on PATH, no `~/.vscode` |
| Codex CLI / Gemini CLI / aider | not installed | — | — |
| `python` | WindowsApps alias stub only | — | not a confirmed interpreter |

Machine `PATH` contains only the WindowsApps user entry; Git is on the machine `PATH`. Neither
`opencode` nor `cline` is on `PATH`, so the kit must not depend on invoking them by name.

### Gaps that later phases must handle

- **No Node.js.** This blocks the `npx skills` CLI, any Node-based skill scripts, and the optional
  CLI/hook layer of candidates such as Impeccable. Phase 2 must evaluate this per candidate;
  Phase 3 must either bootstrap Node non-interactively via `winget` or keep the core
  Node-free. Both OpenCode's CLI and Cline's sidecar are Bun-compiled and need no system Node.
- **No `gh`.** Phase 6 will install GitHub CLI with `winget` and stop for interactive
  authentication.
- **Cline is the Desktop build, not the VS Code extension.** The VS Code extension source path
  cited in `docs/seed-discovery.md` is *not* what runs on this machine. Evidence was taken from
  the installed sidecar instead (section 4).
- **Freebuff Desktop** is a third agent host on this machine. Whether it consumes
  `%USERPROFILE%\.agents` natively is unverified. Tracked for Phase 2 compatibility-matrix work;
  it must not influence the canonical architecture.

---

## 4. Confirmed agent behavior

### 4.1 OpenCode 2.0.22 — skills are native, global instructions are not

Reported paths (`opencode debug paths`):

```text
home    %USERPROFILE%
data    %USERPROFILE%\.local\share\opencode
cache   %USERPROFILE%\.cache\opencode
config  %USERPROFILE%\.config\opencode
state   %USERPROFILE%\.local\state\opencode
tmp     %USERPROFILE%\AppData\Local\Temp\opencode
```

Reported configuration source (`opencode debug config`): exactly one —
`%USERPROFILE%\.config\opencode` (no `opencode.json` present).

**Global skills — native.** Official documentation, *Agent Skills*, last updated 2026-10-03,
lists among the searched locations:

```text
Global agent-compatible: ~/.agents/skills/<name>/SKILL.md
```

Corroborated inside the installed binary `opencode-cli.exe` v2.0.22, which contains the
adjacent literals `.agents`, `.claude` and `home` used to build its global skill directory list.
No OpenCode skill adapter is needed.

**Global instructions — NOT native. Proven exception.** Two independent sources agree:

1. *Rules* documentation: global rules live at `~/.config/opencode/AGENTS.md`; precedence is
   local → `~/.config/opencode/AGENTS.md` → `~/.claude/CLAUDE.md`. `~/.agents/AGENTS.md` is not
   listed.
2. *V2 Instructions* documentation: "OpenCode loads the global file" (`~/.config/opencode/AGENTS.md`),
   "OpenCode V2 recognizes `AGENTS.md` only. It does not use `CLAUDE.md` as a fallback", and
   "V2 does not currently resolve its files, glob patterns, or URLs" for the `instructions`
   array in `opencode.json`.
3. The compiled `ConfigInstructionPlugin` in the installed `opencode-cli.exe` v2.0.22:

   ```js
   j = await resolve(join(configDir, "AGENTS.md"))          // configDir = ~/.config/opencode
   R = [...global ? [j] : [], ...projectInside ? walkUp(dir).map(p => join(p, "AGENTS.md")) : []]
   globalSource = async () => (await isFile(j)) ? [await read(j)] : []
   ```

   The only global instruction path is `<config dir>/AGENTS.md`.

**Decision.** Canonical `~/.agents/AGENTS.md` stays canonical. Add exactly one OpenCode
compatibility artifact, and only for the global instruction file:

```text
NTFS hard link: %USERPROFILE%\.config\opencode\AGENTS.md  ->  %USERPROFILE%\.agents\AGENTS.md
```

- A hard link is chosen because it is the only single-file link mechanism that works on this
  machine without elevation (section 1), it keeps a single source of truth, it is reversible by
  deleting the link, and OpenCode's file watcher sees the same inode.
- A symbolic link is **not** viable here: it fails without Administrator rights or Developer Mode.
- An independent copy is **not** acceptable: it would create a second file to maintain and would
  silently drift.
- `opencode.json` `instructions` is **not** usable: V2 does not resolve it, and the project also
  forbids committing machine-specific absolute paths.
- **Installer constraint:** the canonical file and the link share one inode, so in-place edits are
  visible through both paths. The installer must never replace the canonical file via
  write-temp-then-move, which would break the link and silently orphan it. Replace by
  delete-then-recreate, and re-verify the link afterwards.
- `~/.config/opencode/` already exists and contains `service.json`. The installer must add only
  `AGENTS.md` and must never touch any other file in that directory.

**No other OpenCode exception is justified.** In particular, do not create
`~/.config/opencode/skills`, do not create `~/.claude/skills`, and do not duplicate skills.

### 4.2 Cline Desktop 0.0.43 — fully native, no adapter at all

Cline's shipped runtime resolves paths in `code-sidecar.exe`. Decompiled source strings:

```js
LEGACY_AGENT_SKILLS_CONFIG_DIR = ".agents"
AGENTS_RULES_FILE_NAME = "AGENTS.md"

function resolveSkillsConfigSearchPaths(workspacePath) {
  return dedupePaths([
    ...getWorkspaceSkillDirectories(workspacePath),                                  // <ws>/.clinerules|skills, <ws>/.cline/skills, <ws>/.agents/skills
    join(resolveClineDir(), "skills"),                                               // ~/.cline/skills
    join(HOME_DIR, LEGACY_AGENT_SKILLS_CONFIG_DIR, "skills")                         // ~/.agents/skills
  ]);
}

function resolveGlobalAgentsRulesPath() {
  return join(HOME_DIR, LEGACY_AGENT_SKILLS_CONFIG_DIR, AGENTS_RULES_FILE_NAME);     // ~/.agents/AGENTS.md
}

function resolveRulesConfigSearchPaths(workspacePath) {
  return dedupePaths([
    workspacePath ? join(workspacePath, "AGENTS.md") : [],
    ...resolveWorkspaceRulesConfigPaths(workspacePath),   // <ws>/.clinerules, <ws>/.cline/rules
    resolveGlobalAgentsRulesPath(),                       // ~/.agents/AGENTS.md
    ...resolveGlobalRulesConfigPaths()                    // ~/Documents/Cline/Rules
  ]);
}

function getGlobalSkillPaths(skillName) {                 // used by Cline's own global installer
  return [
    join(resolveClineDir(), "skills", skillName, "SKILL.md"),
    join(HOME_DIR, ".agents", "skills", skillName, "SKILL.md")
  ];
}
```

Cline's own "install skill globally" code path writes into `~/.agents/skills`
(`ensureGlobalSkillsDirWritable`), which independently confirms that `~/.agents` is the shared
canonical global skill root in current Cline.

`~/.agents/AGENTS.md` is also documented: Cline's *Rules* documentation lists
`AGENTS.md` / `~/.agents/AGENTS.md` as the cross-tool standard rule location.

**Documentation caveat worth recording:** Cline's public *Skills* page still lists only
`~/.cline/skills` as the global skills location. The shipped 0.0.43 runtime scans
`~/.agents/skills` as well. The runtime wins; the docs lag. Phase 3/4 verification must therefore
test behavior, not documentation.

**Decision.** Cline consumes canonical `~/.agents/AGENTS.md` and `~/.agents/skills` natively.
**Zero Cline compatibility artifacts.**

### 4.3 Reserved path — do not use

Cline also resolves a global *agent plugin* search path at:

```text
%USERPROFILE%\.agents\plugins
```

The kit must not create or populate that directory. It stays reserved for Cline's agent-plugin
feature.

---

## 5. Existing user state that must be preserved

None of the following was read for content beyond what is strictly needed, and none of it may be
modified, relocated, normalized, or committed.

| Path | Contents | Note |
|---|---|---|
| `%USERPROFILE%\.config\opencode\service.json` | service password | **secret** — never read into the repo, never logged |
| `%USERPROFILE%\.local\state\opencode\service.json` | service id, version, URL, pid, password | **secret** |
| `%USERPROFILE%\.local\share\opencode\` | `opencode.db` (+ WAL/SHM), `log\`, `repos\`, `shell\` | agent state |
| `%USERPROFILE%\.cache\opencode\bin` | OpenCode-managed binaries | agent state |
| `%USERPROFILE%\.cline\data\db\*.db` | sessions, tasks, cron, connectors, hub runs | agent state |
| `%USERPROFILE%\.cline\data\settings\providers.json` | provider credentials | **secret** — key names were listed, values were not read |
| `%USERPROFILE%\.cline\data\settings\global-settings.json` | `autoUpdateEnabled: true`, `telemetryOptOut: false`, web search enabled | user preference — do not change |
| `%USERPROFILE%\.cline\data\cache\*.json` | cached feature flags | agent state |
| `%LOCALAPPDATA%\Cline\` | `cline-app.exe`, `code-sidecar.exe`, `bin\remote-helpers\` | application install |
| `%LOCALAPPDATA%\Programs\@opencodedesktop\` | OpenCode Desktop install | application install |
| `%LOCALAPPDATA%\Programs\@codebufffreebuff-desktop\` | Freebuff Desktop install | application install |
| `%USERPROFILE%\.config\freebuff-desktop\` | orchestrator state, device key | **secret** |

Cline is signed in to a user account and its logs contain the account identifier and an OTLP
telemetry endpoint. **Cline logs must never be copied into this repository.** Diagnostics tooling
in Phase 3 must redact paths and must not dump log files.

Cline telemetry is currently **not** opted out (`telemetryOptOut: false`). Informational only; this
project does not change it.

---

## 6. Phase 1 conclusions

1. `%USERPROFILE%\.agents` is the correct canonical root, is currently empty, and has no
   conflicting neighbours.
2. **Skills need no compatibility layer in either tested agent.** Both read
   `%USERPROFILE%\.agents\skills` natively.
3. **Exactly one compatibility exception is proven**: OpenCode 2.0.22 reads global instructions
   only from `%USERPROFILE%\.config\opencode\AGENTS.md`. Implement it as a single NTFS hard link to
   canonical `%USERPROFILE%\.agents\AGENTS.md`. Do not generalize it.
4. Cline Desktop 0.0.43 needs **no** compatibility artifact of any kind.
5. The installer must run under Windows PowerShell 5.1 with `-ExecutionPolicy Bypass`, at user
   level, without localized-message parsing.
6. Two missing prerequisites are recorded for later phases: **Node.js** (Phase 2/3 decision) and
   **`gh`** (Phase 6).

## 7. Evidence index

| Claim | Source |
|---|---|
| OpenCode global skills include `~/.agents/skills` | <https://opencode.ai/docs/skills/> (page updated 2026-10-03) |
| OpenCode global rules at `~/.config/opencode/AGENTS.md` | <https://opencode.ai/docs/rules/> |
| OpenCode V2: only `AGENTS.md`, no `CLAUDE.md` fallback, `instructions` unresolved | <https://opencode.ai/v2/docs/instructions> |
| OpenCode instruction path resolution in the installed build | compiled `ConfigInstructionPlugin` in `%APPDATA%\ai.opencode.desktop\cli\2.0.22\opencode-cli.exe` |
| Cline global rules include `~/.agents/AGENTS.md` | <https://docs.cline.bot/features/cline-rules> |
| Cline global skills include `~/.agents/skills` | compiled `resolveSkillsConfigSearchPaths` / `getGlobalSkillPaths` in `%LOCALAPPDATA%\Cline\code-sidecar.exe` (0.0.43) |
| Cline docs lag on global skills location | <https://docs.cline.bot/features/skills> |
| Agent Skills format and `SKILL.md` frontmatter | <https://opencode.ai/docs/skills/> |
