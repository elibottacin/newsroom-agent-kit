<#
    uninstall.ps1 - remove only what this kit installed.

      powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 -DryRun
      powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1

    Safety rules enforced here:
      - Dry run is the default behaviour of -WhatIf; use -DryRun for the same effect.
      - A skill directory is removed only if the ownership record lists it.
      - AGENTS.md is removed only if it still matches this repository's copy.
      - The OpenCode bridge is removed only if it really is a link.
      - Nothing outside %USERPROFILE%\.agents is ever deleted.
      - -RestoreBackups puts back anything the installer replaced.
#>
[CmdletBinding()]
param(
    [switch]$DryRun,

    # Also delete the ownership record and state directory.
    [switch]$PurgeState,

    # Restore files from the most recent backup folder.
    [switch]$RestoreBackups,

    # Confirm you want kit-managed skills actually deleted.
    [switch]$Confirm,

    # Redirect the install into a throwaway directory instead of %USERPROFILE%\.agents.
    # Used to test this toolchain without touching real user state.
    [string]$TargetRoot,

    # Override the OpenCode config directory. Only meaningful with -TargetRoot.
    [string]$OpenCodeConfigDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$t = Get-KitTargetPaths -TargetRoot $TargetRoot -OpenCodeConfigDir $OpenCodeConfigDir
$script:Removed = New-Object System.Collections.ArrayList
$script:Kept = New-Object System.Collections.ArrayList

Write-KitLog 'Uninstall plan' 'INFO'
Write-KitLog "  canonical root: $(Format-KitPath $t.Root)"
if ($DryRun) { Write-KitLog '  DRY RUN: nothing will be deleted.' 'DRYRUN' }

if (-not (Test-Path -LiteralPath $t.Root)) {
    Write-KitLog 'Canonical root does not exist. Nothing to do.' 'OK'
    exit 0
}

$state = $null
if (Test-Path -LiteralPath $t.StateFile) {
    try { $state = Get-KitText $t.StateFile | ConvertFrom-Json } catch { $state = $null }
}
if (-not $state) {
    Write-KitLog 'No usable ownership record found. Refusing to guess what is safe to remove.' 'ERROR'
    Write-KitLog 'Review docs\troubleshooting.md for the manual procedure.' 'ERROR'
    exit 1
}

$owned = @($state.skills.PSObject.Properties.Name)
Write-KitLog "  kit-owned skills recorded: $($owned.Count)"
Write-KitLog ''

# ------------------------------------------------------------------- skills ---

Write-KitLog 'Skills' 'INFO'
foreach ($name in $owned) {
    $dir = Join-Path $t.SkillsDir $name
    if (-not (Test-Path -LiteralPath $dir)) {
        [void]$script:Kept.Add("$name (already absent)")
        continue
    }
    if ($DryRun) {
        Write-KitLog "would remove ~/.agents/skills/$name" 'DRYRUN'
        [void]$script:Removed.Add($name)
        continue
    }
    if (-not $Confirm) {
        Write-KitLog "$name : would be removed. Re-run with -Confirm to actually delete." 'WARN'
        [void]$script:Removed.Add($name)
        continue
    }
    $bk = Join-Path $t.BackupsDir (Get-KitStamp)
    New-Item -ItemType Directory -Path $bk -Force | Out-Null
    Copy-KitTree $dir (Join-Path $bk $name)
    Remove-Item -LiteralPath $dir -Recurse -Force
    Write-KitLog "removed ~/.agents/skills/$name (previous copy saved to $(Format-KitPath $bk))" 'OK'
    [void]$script:Removed.Add($name)
}

# Unmanaged directories are reported and never touched.
if (Test-Path -LiteralPath $t.SkillsDir) {
    $foreign = @(Get-ChildItem -LiteralPath $t.SkillsDir -Directory | Where-Object { $owned -notcontains $_.Name })
    foreach ($f in $foreign) {
        [void]$script:Kept.Add($f.Name)
        Write-KitLog "left alone (not kit-owned): ~/.agents/skills/$($f.Name)" 'INFO'
    }
}

# --------------------------------------------------------- global AGENTS.md ---

Write-KitLog ''
Write-KitLog 'Global instructions' 'INFO'
if (-not (Test-Path -LiteralPath $t.AgentsFile)) {
    Write-KitLog 'canonical AGENTS.md already absent'
} elseif (Test-KitSameContent $t.GlobalSource $t.AgentsFile) {
    if ($DryRun) {
        Write-KitLog 'would remove ~/.agents/AGENTS.md' 'DRYRUN'
    } elseif (-not $Confirm) {
        Write-KitLog 'canonical AGENTS.md matches this repository and would be removed. Re-run with -Confirm.' 'WARN'
    } else {
        Remove-Item -LiteralPath $t.AgentsFile -Force
        Write-KitLog 'removed ~/.agents/AGENTS.md' 'OK'
    }
} else {
    [void]$script:Kept.Add('AGENTS.md (edited outside the kit)')
    Write-KitLog 'canonical AGENTS.md was edited outside the kit. Left in place.' 'WARN'
}

# -------------------------------------------------------------- OpenCode link ---

Write-KitLog ''
Write-KitLog 'OpenCode compatibility bridge' 'INFO'
$linkPath = Join-Path $t.OpenCodeCfg 'AGENTS.md'
if (Test-Path -LiteralPath $linkPath) {
    $item = Get-Item -LiteralPath $linkPath -Force
    if ($item.LinkType -eq 'HardLink') {
        if ($DryRun) {
            Write-KitLog 'would remove the hard link ~/.config/opencode/AGENTS.md' 'DRYRUN'
        } elseif (-not $Confirm) {
            Write-KitLog 'hard link would be removed. Re-run with -Confirm.' 'WARN'
        } else {
            Remove-Item -LiteralPath $linkPath -Force
            Write-KitLog 'removed the hard link. Nothing else in ~/.config/opencode was touched.' 'OK'
        }
    } elseif (Test-KitSameContent $linkPath $t.GlobalSource) {
        # Orphaned bridge: a plain file whose bytes are our own template.
        if ($DryRun) {
            Write-KitLog 'would remove an orphaned bridge (~/.config/opencode/AGENTS.md)' 'DRYRUN'
        } elseif (-not $Confirm) {
            Write-KitLog 'orphaned bridge would be removed. Re-run with -Confirm.' 'WARN'
        } else {
            Remove-Item -LiteralPath $linkPath -Force
            Write-KitLog 'removed an orphaned bridge. Nothing else in ~/.config/opencode was touched.' 'OK'
        }
    } else {
        [void]$script:Kept.Add('~/.config/opencode/AGENTS.md')
        Write-KitLog 'bridge is a regular file with different content, so it is not ours. Left in place.' 'WARN'
    }
} else {
    Write-KitLog 'no bridge present'
}

# --------------------------------------------------------------- dependencies ---

# Ownership drives removal. The ownership record says which dependencies this kit installed; the
# manifest says whether each one may be removed at all. A dependency that was already on the machine,
# or that other software may share, is reported and left alone even when -Confirm is passed.
#
# Credentials are never deleted here. %USERPROFILE%\.zernio holds the API key, and removing it would
# silently break an authenticated session the user still owns. It is reported with the exact command
# to run if they do want it gone.
Write-KitLog ''
Write-KitLog 'Execution dependencies' 'INFO'

$stateHasDeps = $false
try {
    $st = Get-KitText $t.StateFile | ConvertFrom-Json
    $stateHasDeps = ($st.PSObject.Properties.Name -contains 'dependencies')
} catch { }

if (-not $stateHasDeps) {
    Write-KitLog '  no dependency record found. Nothing to remove. This record only exists on installs made with dependency provisioning.'
} else {
    foreach ($prop in $st.dependencies.PSObject.Properties) {
        $id = $prop.Name
        $rec = $prop.Value
        $dep = @(Get-KitDependencyManifest | Where-Object { $_.id -eq $id })
        $ownership = if ($dep.Count -gt 0) { $dep[0].ownership } else { $rec.ownership }

        if (-not $rec.installed) {
            Write-KitLog "  $id : not installed" 'INFO'
            continue
        }
        if (-not $rec.removable) {
            Write-KitLog "  $id : LEFT IN PLACE. Ownership is '$ownership', so it may be shared with other software." 'INFO'
            continue
        }
        if (-not $rec.kitInstalled) {
            Write-KitLog "  $id : LEFT IN PLACE. Present before this kit installed it, so it is not ours to remove." 'INFO'
            continue
        }

        # Removable and recorded as kit-installed. Only a Node-backed CLI is handled here; anything
        # else needs its own removal path and is reported rather than guessed at.
        $ds = Get-KitDependencyState -Dep ([pscustomobject]@{ id = $id })
        if (-not $ds.Installed) {
            Write-KitLog "  $id : already absent" 'INFO'
            continue
        }
        $npmPkg = switch ($id) {
            'zernio-cli' { '@zernio/cli' }
            'hyperframes-cli' { '@hyperframes/cli' }
            default { $null }
        }
        if (-not $npmPkg) {
            Write-KitLog "  $id : installed by this kit, but it has no automated removal path. Remove it with: $($dep[0].installMechanism -replace 'install.*','')" 'WARN'
            continue
        }
        if ($DryRun) {
            Write-KitLog "  $id : would remove via npm uninstall -g $npmPkg" 'DRYRUN'
            continue
        }
        if (-not $Confirm) {
            Write-KitLog "  $id : would remove via npm uninstall -g $npmPkg. Re-run with -Confirm." 'WARN'
            continue
        }
        $npm = Get-KitDependencyState -Dep ([pscustomobject]@{ id = 'npm-npx' })
        if (-not $npm.Installed) {
            Write-KitLog "  $id : npm is not available, so it was not removed" 'WARN'
            continue
        }
        & $npm.Path uninstall -g $npmPkg 2>&1 | ForEach-Object { if ($_ -notmatch 'npm notice') { Write-KitLog "  $_" } }
        if ($LASTEXITCODE -eq 0) {
            Write-KitLog "  $id : removed" 'OK'
        } else {
            Write-KitLog "  $id : NOT removed, npm exit $LASTEXITCODE" 'WARN'
        }
    }

    # Node.js itself: shared, so it is never removed. Say so explicitly rather than staying silent.
    Write-KitLog '  nodejs : LEFT IN PLACE. It is shared, and other npm packages depend on it.' 'INFO'

    $zdir = Join-Path $env:USERPROFILE '.zernio'
    if (Test-Path -LiteralPath $zdir) {
        Write-KitLog "  credentials: $(Format-KitPath $zdir) LEFT IN PLACE. It holds your API key." 'INFO'
        Write-KitLog '    To remove it yourself, after revoking the key in the Zernio dashboard: Remove-Item -Recurse -Force (Join-Path $env:USERPROFILE ''.zernio'')' 'INFO'
    }
}

# -------------------------------------------------------------- backup restore ---

if ($RestoreBackups -and -not $DryRun) {
    Write-KitLog ''
    Write-KitLog 'Restore backups' 'INFO'
    if (Test-Path -LiteralPath $t.BackupsDir) {
        $latest = Get-ChildItem -LiteralPath $t.BackupsDir -Directory |
            Sort-Object Name -Descending | Select-Object -First 1
        if ($latest) {
            Write-KitLog "restoring from $(Format-KitPath $latest.FullName)"
            Get-ChildItem -LiteralPath $latest.FullName -File | ForEach-Object {
                Write-KitLog "  candidate: $($_.Name)"
            }
            Write-KitLog 'Backup filenames are flattened, so restore is manual and deliberate. See docs\troubleshooting.md.' 'WARN'
        } else {
            Write-KitLog 'no backup folders found'
        }
    } else {
        Write-KitLog 'no backup folder exists'
    }
}

# ------------------------------------------------------------------- summary ---

Write-KitLog ''
Write-KitLog 'Summary' 'INFO'
Write-KitLog "  would remove / removed : $($script:Removed.Count)"
Write-KitLog "  deliberately kept       : $($script:Kept.Count)"
foreach ($k in $script:Kept) { Write-KitLog "    keep: $k" 'INFO' }

if ($PurgeState -and -not $DryRun -and $Confirm) {
    foreach ($p in @($t.StateFile, $t.StateDir, $t.FetchCache)) {
        if (Test-Path -LiteralPath $p) {
            if ((Get-Item -LiteralPath $p).PSIsContainer) {
                Remove-Item -LiteralPath $p -Recurse -Force
            } else {
                Remove-Item -LiteralPath $p -Force
            }
            Write-KitLog "removed $(Format-KitPath $p)" 'OK'
        }
    }
}

Write-KitLog ''
if ($DryRun) { Write-KitLog 'Dry run complete. Nothing was deleted.' 'DRYRUN'; exit 0 }
if (-not $Confirm) {
    Write-KitLog 'Nothing was deleted. Re-run with -Confirm to apply.' 'WARN'
    exit 0
}
Write-KitLog 'Uninstall complete.' 'OK'
exit 0