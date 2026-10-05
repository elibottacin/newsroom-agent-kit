<#
    install.ps1 - install the curated global Agent Skills setup into
    %USERPROFILE%\.agents.

    Usage (execution policy on this machine is Restricted, so Bypass is required):

      powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -DryRun
      powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1

    The installer is idempotent: a second run with no upstream change performs no
    writes. It never overwrites a file it does not own, never executes an upstream
    install script, and never writes to a vendor-specific skill directory.
#>
[CmdletBinding()]
param(
    # Show every proposed change and write nothing.
    [switch]$DryRun,

    # Install only these skills. Omit to install everything marked install:true.
    [string[]]$Skills,

    # Replace kit-owned files even if they were edited outside the kit.
    [switch]$Force,

    # Also install the optional Python and Node.js prerequisites via winget.
    # Off by default. Requires your explicit approval.
    [switch]$InstallPrerequisites,

    # With -InstallPrerequisites, provision only these dependency ids.
    # Omit to provision the whole declared plan. Lets one phase provision its own
    # dependencies without pulling in another phase's, for example Node and the Zernio CLI
    # without also installing the HyperFrames CLI.
    [string[]]$Dependencies,

    # Redirect the install into a throwaway directory instead of %USERPROFILE%\.agents.
    # Used to test this toolchain without touching real user state.
    [string]$TargetRoot,

    # Override the OpenCode config directory. Only meaningful with -TargetRoot.
    [string]$OpenCodeConfigDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$manifest = Get-KitManifest
$t = Get-KitTargetPaths -TargetRoot $TargetRoot -OpenCodeConfigDir $OpenCodeConfigDir

$script:Planned = New-Object System.Collections.ArrayList
$script:Applied = New-Object System.Collections.ArrayList
$script:Skipped = New-Object System.Collections.ArrayList
$script:Conflicts = New-Object System.Collections.ArrayList
$script:Backups = New-Object System.Collections.ArrayList
$script:PrereqFailed = New-Object System.Collections.ArrayList
$script:DepsPresent = New-Object System.Collections.ArrayList
$script:DepsInstalled = New-Object System.Collections.ArrayList
$script:DepsFailed = New-Object System.Collections.ArrayList
$script:Stamp = Get-KitStamp

function Add-Plan {
    param([string]$Action, [string]$Target, [string]$Detail = '')
    [void]$script:Planned.Add([pscustomobject]@{ Action = $Action; Target = $Target; Detail = $Detail })
}

function Invoke-Plan {
    param([scriptblock]$Body)
    if ($DryRun) {
        Write-KitLog "would run: $Body" 'DRYRUN'
        return
    }
    & $Body
}

# ---------------------------------------------------------------- preflight ---

Write-KitLog 'Preflight' 'INFO'
Write-KitLog "  kit root      : $(Format-KitPath (Get-KitRoot))"
Write-KitLog "  canonical root: $(Format-KitPath $t.Root)"
Write-KitLog "  PowerShell    : $($PSVersionTable.PSVersion)"

if ($PSVersionTable.PSVersion.Major -lt 5) {
    throw 'Windows PowerShell 5.1 or newer is required.'
}

$execPolicy = Get-ExecutionPolicy
Write-KitLog "  exec policy   : $execPolicy"
if ($execPolicy -eq 'Restricted' -and -not $DryRun) {
    Write-KitLog 'Execution policy is Restricted. Re-run with -ExecutionPolicy Bypass.' 'WARN'
}

if (-not (Test-Path -LiteralPath $t.GlobalSource)) {
    throw "Global instructions template missing: $(Format-KitPath $t.GlobalSource)"
}

$isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
Write-KitLog "  elevated      : $isAdmin"
if ($isAdmin) {
    Write-KitLog 'Running elevated. Nothing here needs Administrator rights.' 'WARN'
}

# ------------------------------------------------------------ prerequisites ---

# ------------------------------------------------------------- dependencies ---

# Local software is part of the reproducible setup. The list comes from manifest/dependencies.json,
# so the manifest is the single source of truth and adding a capability means adding an entry there
# rather than editing this script.
#
# Two rules govern this section:
#   * Detect before installing. A compatible existing installation is used and never replaced, and an
#     existing installation that is merely older is reported rather than silently upgraded.
#   * Ownership governs removal, not installation. A `shared` dependency is installed when absent
#     because the capability needs it, but uninstall.ps1 will still never remove it.

if ($InstallPrerequisites) {
    Write-KitLog 'Dependency provisioning requested.' 'INFO'

    if ($t.IsSandbox) {
        Write-KitLog 'Target is a sandbox. Skipping dependency provisioning so real software is never touched.' 'WARN'
    } else {
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        $plan = @(Get-KitDependencyManifest)
        if ($Dependencies -and $Dependencies.Count -gt 0) {
            # Invoking through `powershell -File script.ps1 -Dependencies a,b,c` hands the array over
            # as one comma-joined string rather than an array, so split on commas as well. Without
            # this the filter silently matches nothing and provisioning does nothing.
            $wanted = @($(foreach ($d in $Dependencies) { ([string]$d) -split ',' }) | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            $plan = @($plan | Where-Object { $wanted -contains $_.id })
            Write-KitLog "Provisioning a subset: $($wanted -join ', ')" 'INFO'
            if ($plan.Count -eq 0) {
                Write-KitLog "None of those ids are in the declared plan. Declared: $(@(Get-KitDependencyManifest | ForEach-Object { $_.id }) -join ', ')" 'WARN'
            }
        }
        if ($plan.Count -eq 0 -and -not ($Dependencies -and $Dependencies.Count -gt 0)) {
            Write-KitLog 'No dependencies declared. Nothing to do.' 'INFO'
        }

        foreach ($dep in $plan) {
            $state = Get-KitDependencyState -Dep $dep
            $satisfied = $state.Installed -and (Test-KitVersionSatisfies -Found $state.Version -Required $dep.requiredVersion)

            if ($satisfied) {
                Write-KitLog "$($dep.id) : present, $($state.Version)  [$($dep.ownership)]" 'OK'
                if ($state.RefreshPath) {
                    Write-KitLog "  found at $(Format-KitPath $state.Path); not on this session's PATH yet. Open a new terminal to use it." 'INFO'
                }
                [void]$script:DepsPresent.Add($dep.id)
                continue
            }

            # A dependency with no command to probe is a cache or a download that appears on first
            # use. Report it, but never treat it as a provisioning failure, or the summary would
            # claim the setup is incomplete on a machine where nothing is actually wrong.
            if (-not $state.Command) {
                Write-KitLog "$($dep.id) : not present yet. Appears on first use. [$($dep.ownership)]" 'INFO'
                [void]$script:DepsPresent.Add($dep.id)
                continue
            }

            if ($state.Installed) {
                # Present but below the declared floor. Report; do not upgrade across a version the
                # user may depend on without being asked.
                Write-KitLog "$($dep.id) : present but older than required ($($state.Version) vs '$($dep.requiredVersion)'). Left alone." 'WARN'
                Write-KitLog "  Upgrade it yourself if you want the newer version: $($dep.installMechanism)" 'INFO'
                [void]$script:DepsPresent.Add($dep.id)
                continue
            }

            $mechanism = [string]$dep.installMechanism
            if ($DryRun) {
                Write-KitLog "$($dep.id) : missing. Would install with: $mechanism" 'DRYRUN'
                continue
            }

            Write-KitLog "$($dep.id) : missing. Installing." 'INFO'

            # npm globals ride on the Node runtime, so Node has to exist first.
            if ($mechanism -match '^npm ' -and -not (Get-KitDependencyState -Dep ([pscustomobject]@{ id = 'nodejs' })).Installed) {
                Write-KitLog '  Node.js is required first and is not installed yet.' 'ERROR'
                [void]$script:DepsFailed.Add($dep.id)
                continue
            }

            if ($mechanism -match '^winget ') {
                if (-not $winget) {
                    Write-KitLog '  winget is not available on this machine.' 'ERROR'
                    [void]$script:DepsFailed.Add($dep.id)
                    continue
                }
                $pkg = ($mechanism -replace '^winget install --id\s+', '' -replace '\s+-e.*$', '')
                # Prefer --scope user so the install stays out of the machine-wide MSI path, which
                # needs a UAC prompt this kit must never require.
                #
                # This is NOT universally safe, and that was verified rather than assumed. The Node.js
                # LTS manifest declares a WiX MSI as its default installer, yet `--scope user` selected
                # a zip installer instead: it downloaded nodejs.org's zip, hash-verified it and
                # extracted it with no elevation. Gyan.FFmpeg is portable/zip, so user scope is safe
                # there by construction. A package offering only a machine-scope MSI would refuse
                # user scope entirely, so fall back to the default scope and say plainly that
                # elevation may now be required.
                $attempts = @(
                    @{ Args = @('--scope', 'user'); Label = 'user scope' },
                    @{ Args = @(); Label = 'default scope (may require elevation)' }
                )
                $installed = $false
                foreach ($attempt in $attempts) {
                    & winget install --id $pkg -e @($attempt.Args) --silent --disable-interactivity `
                        --accept-package-agreements --accept-source-agreements 2>&1 |
                        ForEach-Object { Write-KitLog "  $_" }
                    $code = $LASTEXITCODE
                    if ($code -eq 0) {
                        Write-KitLog "  $pkg installed ($($attempt.Label))" 'OK'
                        $installed = $true
                        break
                    }
                    if ($code -eq -1978335212) {
                        Write-KitLog "  $pkg already installed or newer ($($attempt.Label))" 'OK'
                        $installed = $true
                        break
                    }
                    if ($attempt.Label -eq 'user scope') {
                        Write-KitLog "  user scope unavailable for $pkg (winget exit $code). Retrying at default scope." 'WARN'
                        Write-KitLog '  A UAC prompt may appear. Decline it and this dependency is reported as not installed.' 'INFO'
                    } else {
                        Write-KitLog "  $pkg NOT installed: winget exit $code ($($attempt.Label))" 'ERROR'
                    }
                }
                if ($installed) { [void]$script:DepsInstalled.Add($dep.id) } else { [void]$script:DepsFailed.Add($dep.id) }
            } elseif ($mechanism -match '^npm ') {
                $npm = Get-KitDependencyState -Dep ([pscustomobject]@{ id = 'npm-npx' })
                if (-not $npm.Installed) {
                    Write-KitLog '  npm is not available.' 'ERROR'
                    [void]$script:DepsFailed.Add($dep.id)
                    continue
                }
                $pkgName = ($mechanism -replace '^npm install -g\s+', '' -replace '\s+at version.*$', '').Trim()
                $pinned = $dep.pinnedVersion
                $target = if ($pinned) { "$pkgName@$pinned" } else { $pkgName }
                & $npm.Path install -g $target --no-fund --no-audit 2>&1 |
                    ForEach-Object { if ($_ -match 'npm notice') { } else { Write-KitLog "  $_" } }
                if ($LASTEXITCODE -eq 0) {
                    Write-KitLog "  $target installed" 'OK'
                    [void]$script:DepsInstalled.Add($dep.id)
                } else {
                    Write-KitLog "  $target NOT installed: npm exit $LASTEXITCODE" 'ERROR'
                    [void]$script:DepsFailed.Add($dep.id)
                }
            } else {
                Write-KitLog "  no automated mechanism is declared for '$mechanism'. Install it manually." 'WARN'
                [void]$script:DepsFailed.Add($dep.id)
            }
        }

        if ($script:DepsFailed.Count -eq 0) {
            Write-KitLog 'All declared dependencies are present.' 'OK'
        } else {
            Write-KitLog "Dependencies incomplete: $($script:DepsFailed -join ', ')" 'WARN'
            Write-KitLog 'The skills still install; only the execution backends are affected.' 'WARN'
        }
        if ($script:DepsInstalled.Count -gt 0) {
            Write-KitLog "Installed by this kit: $($script:DepsInstalled -join ', ')" 'INFO'
            Write-KitLog 'Open a new terminal so a new PATH is picked up.' 'INFO'
        }
    }
}

# --------------------------------------------------------------- select set ---

$selected = @($manifest.core) + @($manifest.vendor)
if ($Skills -and $Skills.Count -gt 0) {
    $selected = @($selected | Where-Object { $Skills -contains $_.name })
    if ($selected.Count -eq 0) {
        throw "No manifest entries matched: $($Skills -join ', ')"
    }
}

Write-KitLog "Selected $($selected.Count) skills for installation" 'INFO'

# ------------------------------------------------------------- global AGENTS ---

Write-KitLog ''
Write-KitLog 'Global instructions' 'INFO'

if (Test-KitSameContent $t.GlobalSource $t.AgentsFile) {
    Write-KitLog "AGENTS.md already current  (~/.agents/AGENTS.md)" 'OK'
    Add-Plan 'skip' '~/.agents/AGENTS.md' 'identical'
} elseif (Test-Path -LiteralPath $t.AgentsFile) {
    # The curated copy differs from what is installed. Never clobber silently: without -Force this
    # is a conflict, exactly as verify.ps1 reports it. With -Force the curated copy is restored and
    # the previous file is backed up first, matching how kit-owned skills are replaced.
    if (-not $Force) {
        Write-KitLog '~/.agents/AGENTS.md exists and differs from the curated copy. It was not overwritten.' 'WARN'
        Write-KitLog 'Re-run with -Force to restore the curated copy, or resolve it manually. Nothing was changed.' 'ERROR'
        $script:Conflicts.Add('~/.agents/AGENTS.md')
        Add-Plan 'conflict' '~/.agents/AGENTS.md' 'differs from curated copy'
    } else {
        Add-Plan 'replace' '~/.agents/AGENTS.md' 'differs from curated copy'
        if ($DryRun) {
            Write-KitLog 'would replace ~/.agents/AGENTS.md with the curated copy (previous version backed up)' 'DRYRUN'
        } else {
            $bkAgents = New-KitBackup $t.AgentsFile $t.BackupsDir $script:Stamp
            [void]$script:Backups.Add($bkAgents)
            [System.IO.File]::Copy($t.GlobalSource, $t.AgentsFile, $true)
            Write-KitLog 'replaced ~/.agents/AGENTS.md with the curated copy (previous version backed up)' 'OK'
            [void]$script:Applied.Add('~/.agents/AGENTS.md')
        }
    }
} else {
    Add-Plan 'create' '~/.agents/AGENTS.md' ''
    Write-KitLog 'would install canonical AGENTS.md' 'DRYRUN'
    Invoke-Plan {
        New-Item -ItemType Directory -Path $t.Root -Force | Out-Null
        [System.IO.File]::Copy($t.GlobalSource, $t.AgentsFile, $false)
    }.GetNewClosure()
    if (-not $DryRun) {
        Write-KitLog 'installed ~/.agents/AGENTS.md' 'OK'
        [void]$script:Applied.Add('~/.agents/AGENTS.md')
    }
}

# ------------------------------------------------------------------- skills ---

Write-KitLog ''
Write-KitLog 'Skills' 'INFO'

foreach ($entry in $selected) {
    $name = $entry.name
    $dest = Join-Path $t.SkillsDir $name

    $resolved = Get-KitSkillSource -Entry $entry -Targets $t
    $source = $resolved.Path
    if (-not $resolved.Found) {
        if ($resolved.Mode -eq 'vendor') {
            Write-KitLog "$name : vendored source missing at $(Format-KitPath $source)" 'ERROR'
        } else {
            Write-KitLog "$name : upstream not in cache. Run scripts\update.ps1 -Fetch first." 'ERROR'
        }
        $script:Conflicts.Add($name)
        continue
    }

    $skillFile = Join-Path $source 'SKILL.md'
    $check = Test-KitSkillFrontmatter -SkillFile $skillFile -ExpectedName $name
    if (-not $check.Ok) {
        Write-KitLog "$name : invalid SKILL.md ($($check.Problems -join '; '))" 'ERROR'
        $script:Conflicts.Add($name)
        continue
    }

    $entryFiles = @(Get-KitEntryFiles -Entry $entry -Source $source)
    $code = @($entryFiles | ForEach-Object { $_ } | Where-Object {
        $ext = $_.Extension.ToLowerInvariant()
        $ext -in @('.ps1', '.psm1', '.psd1', '.js', '.mjs', '.cjs', '.ts', '.tsx', '.jsx', '.py', '.sh', '.bat', '.cmd', '.exe', '.dll', '.com')
    })
    if ($code.Count -gt 0) {
        $names = $code | ForEach-Object { $_.FullName.Substring($source.Length + 1) }
        Write-KitLog "$name : contains executable files and is not approved: $($names -join ', ')" 'ERROR'
        $script:Conflicts.Add($name)
        continue
    }

    if (Test-Path -LiteralPath $dest) {
        $owned = $false
        if (Test-Path -LiteralPath $t.StateFile) {
            $state = Get-KitText $t.StateFile | ConvertFrom-Json
            if ($state.skills.PSObject.Properties.Name -contains $name) { $owned = $true }
        }
        if (-not $owned) {
            Write-KitLog "$name : ~/.agents/skills/$name exists and is not kit-owned. Left untouched." 'WARN'
            $script:Conflicts.Add($name)
            continue
        }
        $same = $true
        foreach ($f in $entryFiles) {
            $rel = $f.FullName.Substring($source.Length + 1)
            $d = Join-Path $dest $rel
            if (-not (Test-Path -LiteralPath $d) -or (Get-KitFileHash $d) -ne (Get-KitFileHash $f.FullName)) { $same = $false; break }
        }
        if ($same) {
            Write-KitLog "$name : already current" 'OK'
            [void]$script:Skipped.Add($name)
            Add-Plan 'skip' "~/.agents/skills/$name" 'identical'
            continue
        }
        if (-not $Force) {
            Write-KitLog "$name : installed copy differs from the curated version. Re-run with -Force to replace it." 'WARN'
            $script:Conflicts.Add($name)
            continue
        }
        Add-Plan 'replace' "~/.agents/skills/$name" 'kit-owned, differs'
        if ($DryRun) { Write-KitLog "would replace $name" 'DRYRUN'; continue }
        Invoke-Plan {
            $bk = New-KitBackup (Join-Path $dest 'SKILL.md') $t.BackupsDir $script:Stamp
            [void]$script:Backups.Add($bk)
            Copy-KitEntry -Entry $entry -Source $source -Destination $dest
        }.GetNewClosure()
        Write-KitLog "replaced $name" 'OK'
        [void]$script:Applied.Add($name)
    } else {
        Add-Plan 'create' "~/.agents/skills/$name" ''
        if ($DryRun) { Write-KitLog "would install $name" 'DRYRUN'; continue }
        Invoke-Plan { Copy-KitEntry -Entry $entry -Source $source -Destination $dest }.GetNewClosure()
        Write-KitLog "installed $name" 'OK'
        [void]$script:Applied.Add($name)
    }
}

# ------------------------------------------------- OpenCode compatibility link ---

Write-KitLog ''
Write-KitLog 'OpenCode global-instruction compatibility' 'INFO'

$linkPath = Join-Path $t.OpenCodeCfg 'AGENTS.md'
if (-not (Test-Path -LiteralPath $t.OpenCodeCfg)) {
    Write-KitLog '~/.config/opencode does not exist. OpenCode is not configured on this machine; nothing to bridge.' 'INFO'
} elseif (-not (Test-Path -LiteralPath $t.AgentsFile) -and $script:Planned.Count -eq 0) {
    Write-KitLog 'Canonical ~/.agents/AGENTS.md is absent and will not be created by this run, so no bridge is needed.' 'WARN'
} elseif (-not (Test-Path -LiteralPath $t.AgentsFile)) {
    # The canonical file is planned above and will exist by the time this runs. Report the
    # bridge in the dry run too, otherwise the preview under-reports by exactly one change.
    Add-Plan 'create-link' '~/.config/opencode/AGENTS.md' 'hard link to canonical file'
    if ($DryRun) {
        Write-KitLog 'would create a hard link ~/.config/opencode/AGENTS.md -> ~/.agents/AGENTS.md (after the canonical file is written)' 'DRYRUN'
    } else {
        Invoke-Plan {
            New-Item -ItemType HardLink -Path $linkPath -Target $t.AgentsFile | Out-Null
        }.GetNewClosure()
        Write-KitLog 'hard link created (single source of truth, reversible)' 'OK'
        [void]$script:Applied.Add('hardlink')
    }
} else {
    $item = $null
    if (Test-Path -LiteralPath $linkPath) { $item = Get-Item -LiteralPath $linkPath -Force }
    if ($item -and $item.LinkType -eq 'HardLink') {
        if (Test-KitSameContent $linkPath $t.AgentsFile) {
            Write-KitLog 'hard link present and correct' 'OK'
            Add-Plan 'skip' '~/.config/opencode/AGENTS.md' 'hard link already correct'
        } else {
            Add-Plan 'repair' '~/.config/opencode/AGENTS.md' 'hard link points at stale content'
            if ($DryRun) { Write-KitLog 'would repair the hard link' 'DRYRUN' }
            else {
                Invoke-Plan {
                    [System.IO.File]::Delete($linkPath)
                    New-Item -ItemType HardLink -Path $linkPath -Target $t.AgentsFile | Out-Null
                }.GetNewClosure()
                Write-KitLog 'hard link repaired' 'OK'
            }
        }
    } elseif ($item -and (Test-KitSameContent $linkPath $t.GlobalSource)) {
        # An orphaned bridge. Deleting the canonical file leaves this name behind as an
        # ordinary file with the same bytes, because NTFS keeps the data alive while any
        # hard link remains. Content that is byte-identical to our own template proves it
        # came from this kit, so replacing it is safe. Anything else is left alone.
        Add-Plan 'repair' '~/.config/opencode/AGENTS.md' 'orphaned bridge from this kit'
        if ($DryRun) {
            Write-KitLog 'would replace an orphaned bridge with a correct hard link' 'DRYRUN'
        } else {
            Invoke-Plan {
                [System.IO.File]::Delete($linkPath)
                New-Item -ItemType HardLink -Path $linkPath -Target $t.AgentsFile | Out-Null
            }.GetNewClosure()
            Write-KitLog 'orphaned bridge replaced with a hard link' 'OK'
            [void]$script:Applied.Add('hardlink')
        }
    } elseif ($item) {
        Write-KitLog '~/.config/opencode/AGENTS.md exists and is NOT a link. Refusing to touch it.' 'WARN'
        Write-KitLog 'It is not kit-owned. Merge it manually or move it aside, then re-run.' 'ERROR'
        $script:Conflicts.Add('~/.config/opencode/AGENTS.md')
        Add-Plan 'conflict' '~/.config/opencode/AGENTS.md' 'pre-existing regular file'
    } else {
        Add-Plan 'create-link' '~/.config/opencode/AGENTS.md' 'hard link to canonical file'
        if ($DryRun) {
            Write-KitLog 'would create a hard link ~/.config/opencode/AGENTS.md -> ~/.agents/AGENTS.md' 'DRYRUN'
        } else {
            Invoke-Plan {
                New-Item -ItemType HardLink -Path $linkPath -Target $t.AgentsFile | Out-Null
            }.GetNewClosure()
            Write-KitLog 'hard link created (single source of truth, reversible)' 'OK'
            [void]$script:Applied.Add('hardlink')
        }
    }
}

# -------------------------------------------------------------- state file ---

if (-not $DryRun) {
    Write-KitLog ''
    Write-KitLog 'Ownership record' 'INFO'
    $existing = [pscustomobject]@{ skills = [pscustomobject]@{} }
    if (Test-Path -LiteralPath $t.StateFile) {
        try { $existing = Get-KitText $t.StateFile | ConvertFrom-Json } catch { $existing = [pscustomobject]@{ skills = [pscustomobject]@{} } }
    }
    $ownedSkills = [ordered]@{}
    if ($existing.PSObject.Properties.Name -contains 'skills') {
        foreach ($p in $existing.skills.PSObject.Properties) { $ownedSkills[$p.Name] = $p.Value }
    }
    foreach ($e in $selected) {
        if (Test-Path -LiteralPath (Join-Path $t.SkillsDir $e.name)) {
            $ownedSkills[$e.name] = [pscustomobject]@{
                source    = if ($e.PSObject.Properties.Name -contains 'vendorPath') { 'vendor' } else { 'fetch' }
                repo      = $e.source.repo
                ref       = $e.source.ref
                subdir    = $e.source.subdir
                license   = $e.source.license
                installedAt = (Get-Date).ToString('s')
            }
        }
    }
    # Dependency ownership record. This is machine state, not repository content, and it is the only
    # thing that lets uninstall.ps1 tell "the kit installed this" from "the user already had this".
    # Ownership comes from the manifest; kitInstalled is only true for dependencies this run installed
    # or that a previous run recorded as kit-installed. Never record a `shared` dependency as
    # kit-removable, so a normal uninstall cannot take the user's Node.js or FFmpeg away.
    $ownedDeps = @{}
    foreach ($dep in @(Get-KitDependencyManifest)) {
        $st = Get-KitDependencyState -Dep $dep
        $wasKit = $script:DepsInstalled -contains $dep.id
        if (-not $wasKit -and (Test-Path -LiteralPath $t.StateFile)) {
            try {
                $prev = Get-KitText $t.StateFile | ConvertFrom-Json
                if ($prev.PSObject.Properties.Name -contains 'dependencies' -and
                    $prev.dependencies.PSObject.Properties.Name -contains $dep.id -and
                    $prev.dependencies.($dep.id).kitInstalled) { $wasKit = $true }
            } catch { }
        }
        $removable = ([string]$dep.ownership -eq 'kit-installed' -or [string]$dep.ownership -eq 'ephemeral-cache')
        $ownedDeps[$dep.id] = [pscustomobject]@{
            ownership    = $dep.ownership
            installed    = [bool]$st.Installed
            version      = $st.Version
            kitInstalled = [bool]($wasKit -and $removable)
            removable    = $removable
            checkedAt    = (Get-Date).ToString('s')
        }
    }
    $state = [pscustomobject]@{
        schemaVersion = 2
        updatedAt     = (Get-Date).ToString('s')
        canonicalRoot = '~/.agents'
        skills        = [pscustomobject]$ownedSkills
        dependencies  = [pscustomobject]$ownedDeps
    }
    Set-KitText $t.StateFile ($state | ConvertTo-Json -Depth 6)
    Write-KitLog 'wrote ~/.agents/state/install-state.json (kit-owned, used by verify and uninstall)' 'OK'
}

# ------------------------------------------------------------------ summary ---

Write-KitLog ''
Write-KitLog 'Summary' 'INFO'
Write-KitLog "  planned changes : $($script:Planned.Count)"
Write-KitLog "  applied         : $($script:Applied.Count)"
Write-KitLog "  already current : $($script:Skipped.Count)"
Write-KitLog "  conflicts       : $($script:Conflicts.Count)"
Write-KitLog "  backups         : $($script:Backups.Count)"

if ($script:Conflicts.Count -gt 0) {
    Write-KitLog ''
    Write-KitLog 'Unresolved, nothing was forced:' 'ERROR'
    foreach ($c in $script:Conflicts) { Write-KitLog "  - $c" 'ERROR' }
}

if ($DryRun) {
    Write-KitLog ''
    Write-KitLog 'Dry run complete. Nothing was written.' 'DRYRUN'
    exit 0
}

Write-KitLog ''
if ($script:Conflicts.Count -gt 0) {
    Write-KitLog 'Finished with conflicts. See docs\troubleshooting.md.' 'WARN'
    exit 2
}
Write-KitLog 'Install complete. Run scripts\verify.ps1 to confirm.' 'OK'
exit 0