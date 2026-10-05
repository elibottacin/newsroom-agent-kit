# Maintaining this kit

Guidance for changing the selection after installation, and an honest statement of what this
repository does and does not promise.

## Maintenance status

**Read this before assuming anything about ongoing support.**

This repository was built and published as a working snapshot for one person's use. It is **not
maintained as a shared project.**

Concretely:

- **The vendored forks are frozen.** 27 skills under `vendor/skills/` are modified copies. When their
  upstream moves, those skills will **not** be updated here. They will keep working, because they are
  self-contained markdown, but they will not gain upstream improvements or fixes.
- **Pinned skills do not self-update either.** 13 skills are fetched from a commit pinned in
  `manifest/skills.json`. The pin guarantees the reviewed artifact is what you get; it also means
  upstream fixes do not arrive on their own.
- **No support commitment.** Issues and pull requests are welcome. Nothing promises a response, a
  review, or a merged change.
- **Nothing is scheduled for review.** There is no cadence, no roadmap, and no watch on upstream
  repositories.

What this means in practice: treat the pin and the fork as *where you froze something*, and check
`update.ps1 -CheckRemote` yourself if you care how far behind you are.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update.ps1 -CheckRemote
```

### If you fork this

You inherit a snapshot, not a commitment. The expensive part is the 27 forks: upstream changes must
be hand-merged. Budget for that, or drop the forks you do not use. See
[Retiring a skill](#retiring-a-skill) below — removing a fork you do not need is cheaper and more
honest than leaving it installed and unmaintained.

---

## Retiring a skill

The honest move when you stop using a skill is to **remove it from the manifest and uninstall it**,
not to leave it installed and quietly rot. This is especially true for vendored forks, because an
unmaintained fork is the part of this repository most likely to become a liability.

There are two things to change: what the manifest declares, and what is on disk.

### 1. Remove it from the manifest

Open `manifest/skills.json` and delete the skill's entry from whichever section it is in — `core`,
`vendor`, or `optional`. Do not leave it with a `status` field saying "retired"; an entry that is not
installed is what `optional` is for.

For a **vendored** skill, also delete its directory:

```powershell
Remove-Item -Recurse -Force .\vendor\skills\<name>
```

Keep `vendor/skills/` and `manifest/skills.json` consistent. `update.ps1` reports each vendored skill
with `provenance note MISSING` if you leave a directory behind without an entry.

### 2. Regenerate the notices

`THIRD_PARTY_NOTICES.md` lists every redistributed skill. Remove the retired row so the notice still
describes what the repository actually contains.

### 3. Uninstall it

`uninstall.ps1` removes **only** skills recorded as kit-owned, so it will happily remove the retired
skill:

```powershell
# preview first
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 -DryRun -Confirm

# then apply
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 -Confirm
```

### 4. Reinstall and verify

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Force
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1
```

`verify.ps1` will fail with `unmanaged directories present` if a directory is left behind that the
manifest no longer declares. That is the intended alarm, and it is how you notice a partial removal.

### 5. Commit

Commit the manifest change, the notices change and the deleted vendor directory together, so history
shows the skill leaving and the reason.

### If other people already installed it

Retiring a skill from the manifest does not uninstall it from anyone else's machine. Their
`uninstall.ps1` keeps working, because the ownership record on their disk still lists it. If a retired
skill has a security problem, that is not sufficient — see [Removing a skill from existing
installs](#removing-a-skill-from-existing-installs).

---

## Adding a skill

1. **Evaluate it properly.** Read the actual source, not a registry listing. Record: upstream
   repository and path, exact commit, licence with a real LICENSE file, purpose and triggers, whether
   it ships scripts or binaries, network or API needs, authentication requirements, and overlap with
   what you already have. `docs/discovery.md` is the worked example of that process.

2. **Check the licence.** No LICENSE file means default copyright and no redistribution grant. Either
   skip it, or fetch it at install time rather than vendoring it, which is what `og-image` does.

3. **Check for executable content.** If a skill ships scripts, decide whether the core can ship
   instruction-only. `impeccable` and `frontend-design` are both vendored trimmed for exactly this
   reason.

4. **Check for trigger overlap.** Two skills competing for the same prompt is worse than one missing
   skill. `docs/discovery.md` records the redundancy rules that were applied here.

5. **Add it to `manifest/skills.json`** with `status: "core"` and either:
   - `vendorPath` plus `source`, if you must modify it, or
   - `source` only, if the upstream artifact is usable verbatim. **Prefer this.**

6. **Validate before committing:**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update.ps1 -Fetch
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -DryRun
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1
```

`install.ps1` refuses any skill whose `SKILL.md` fails frontmatter validation, whose `name` does not
match its directory, or which contains executable files. Those are the two failure modes you are most
likely to hit.

---

## Removing a skill from existing installs

`uninstall.ps1` is per-machine and per-skill; it has no notion of "every machine that ever cloned
this". If you must retire a skill that is already out there, the only lever is the installer.

- Make the installer treat the skill as a **removal**: when a manifest entry disappears, have
  `install.ps1` delete the corresponding directory if the ownership record lists it. That is a real
  behaviour change and is not implemented here.
- Until then, treat a retired skill as "not installed for anyone who installs fresh", and say so
  plainly in the README rather than implying people are protected.

---

## Adding another coding agent

The point of the architecture is that this should usually be nothing.

**If the agent reads `%USERPROFILE%\.agents\skills` natively, you are already done.** No config, no
copy, no link. Three agents were confirmed this way: OpenCode, Cline, and Freebuff. That is the
expected case.

To check a new agent:

1. Look up its global skills path in its own documentation. Do not assume it reads `~/.agents`.
2. If it does, add a row to the compatibility matrix in `docs/architecture.md` and stop.
3. If it does not, you need exactly one of:
   - **a vendor link**, if the agent supports one, or
   - **a hard link** from the agent's global skills directory to `%USERPROFILE%\.agents\skills`,
     mirroring what is done for OpenCode's instruction file.

**Never copy skills into a vendor directory.** Two copies drift, and the whole design exists to avoid
that. If an agent only reads its own directory and offers no link mechanism, that is a limitation to
document, not a reason to duplicate 40 directories.

### The one existing exception

OpenCode reads global instructions only from `%USERPROFILE%\.config\opencode\AGENTS.md`. A single NTFS
hard link bridges it to the canonical `%USERPROFILE%\.agents\AGENTS.md`. That link exists for one
file only.

If a future OpenCode release supports the canonical path, **delete the link and the special case**:

```powershell
Remove-Item "$env:USERPROFILE\.config\opencode\AGENTS.md" -Force
```

`install.ps1` recreates it only when that path is absent and not already a hard link, so removing it
once and letting the next install rebuild it is safe. Do not remove it while OpenCode still needs it.

Hard links are used rather than symbolic links because symbolic links fail on Windows without
Administrator rights or Developer Mode. Hard links require both names to be on the same volume.

---

## The skill-update review process

`update.ps1` **reports and never merges.** That is deliberate: the tool cannot tell a good upstream
change from a bad one, and it has no way to know whether a third-party edit reintroduced a product
claim. Merging is a judgement call.

### Pinned skills

1. `update.ps1 -CheckRemote` — which repositories moved, and how far.
2. Read the upstream diff. Focus on anything that adds a script, a network call, or an instruction to
   send data somewhere.
3. Change `source.ref` in `manifest/skills.json` to the new commit.
4. `update.ps1 -Fetch`, then `install.ps1 -DryRun`, then read what it proposes.
5. `install.ps1 -Force`, then `verify.ps1`.

### Vendored forks

Harder, because the local copy is not the upstream copy.

1. Read the upstream change.
2. **Hand-merge** it into `vendor/skills/<name>`. Diff conceptually, not mechanically.
3. While merging, watch specifically for anything that reintroduces a product or vendor claim about
   what a tool can or cannot do. That is the entire reason the fork exists.
4. Delete the skill's upstream `evals/` fixtures if you did not already.
5. Repoint any sibling-skill reference at the name this kit actually installs.
6. Update `vendor/skills/<name>/PROVENANCE.md`: new commit, and what changed.
7. `install.ps1 -Force`, then `verify.ps1`. **If `verify.ps1` reports product references, the merge
   reintroduced the problem.** Fix it before committing.

**Never copy an upstream directory over a fork.** That is the single fastest way to undo the fork, and
`verify.ps1` will catch it — but only after you have committed it.

### Deciding not to update

Perfectly valid, and often correct. If upstream has not fixed anything you use, freezing is the
cheaper option. The only cost is that `update.ps1 -CheckRemote` will keep reporting movement, which is
informational by design.

---

## Optional integrations

## Known gap: no single bootstrap command

The advertised fresh-machine flow is five separate invocations, documented in
`README.md`:

```powershell
.\scripts\install.ps1 -InstallPrerequisites   # provision Node, npm, FFmpeg, both CLIs
.\scripts\update.ps1 -Fetch                   # fetch the pinned upstream commits
.\scripts\install.ps1 -DryRun                 # preview
.\scripts\install.ps1                         # install
.\scripts\verify.ps1                          # confirm
```

This was executed end to end on the reference machine across phases 9 to 11, and
reruns are idempotent, but it is not one command. **Tracked for phase 12.**

Two ordering constraints that a future single entry point must preserve, both
learned the hard way:

- **`-Fetch` must run before `-DryRun`.** Most skills are not stored in this
  repository, so a dry run before the fetch reports all of them as missing
  conflicts and under-reports the real change.
- **Dependency provisioning needs its own pass.** It is the only step that touches
  anything outside `%USERPROFILE%\.agents`, so it must stay opt-in rather than
  being folded silently into a plain `install.ps1`.

Also unproven, and therefore claimed nowhere: the HyperFrames render smoke test,
deferred on 2026-10-05 because the reference machine has 3.4 GB of RAM and the
CLI's own `doctor` warns that renders may fail.

`manifest/integrations.json` lists nine of them. **Every entry is `installAction: none`, and none is
required for the skill set to work.** The installed set is 40 markdown files and needs no account, no
API key and no network.

Two are worth understanding before you ever enable them:

- **Figma MCP** is gated behind a paid seat *and* behind Figma's client allow-list. Figma states that
  only catalog-listed clients can connect, so it may simply refuse your agent.
- **Cline plugins** are executable TypeScript running inside Cline, and the browser-automation ones
  manage external credentials. They are agent-specific and cannot be part of a portable core.

Do not connect an account to make a capability work without saying so to the user first.