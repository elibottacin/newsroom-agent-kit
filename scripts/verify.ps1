<#
    verify.ps1 - prove the global setup is correct, without changing anything.

      powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1

    Read-only. Exit codes:
      0  all checks passed
      1  one or more checks failed
      2  warnings only
#>
[CmdletBinding()]
param(
    # Include per-skill detail instead of only failures.
    [switch]$Verbose2,

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

$script:Fail = New-Object System.Collections.ArrayList
$script:Warn = New-Object System.Collections.ArrayList
$script:Pass = New-Object System.Collections.ArrayList

function Assert-That {
    param([bool]$Condition, [string]$OkMessage, [string]$FailMessage, [switch]$Warning)
    if ($Condition) {
        [void]$script:Pass.Add($OkMessage)
        Write-KitLog $OkMessage 'OK'
    } elseif ($Warning) {
        [void]$script:Warn.Add($FailMessage)
        Write-KitLog $FailMessage 'WARN'
    } else {
        [void]$script:Fail.Add($FailMessage)
        Write-KitLog $FailMessage 'ERROR'
    }
}

Write-KitLog 'Verifying the global Agent Skills setup' 'INFO'
Write-KitLog "  canonical root: $(Format-KitPath $t.Root)"
Write-KitLog ''

# ---------------------------------------------------------------- structure ---

Assert-That (Test-Path -LiteralPath $t.Root) 'canonical root ~/.agents exists' 'canonical root ~/.agents is missing. Run scripts\install.ps1'
Assert-That (Test-Path -LiteralPath $t.SkillsDir) 'canonical skills dir ~/.agents/skills exists' 'canonical skills dir ~/.agents/skills is missing'

# ------------------------------------------------------- global instructions ---

Write-KitLog ''
Write-KitLog 'Global instructions' 'INFO'

if (Test-Path -LiteralPath $t.AgentsFile) {
    Assert-That $true 'canonical ~/.agents/AGENTS.md exists' ''
    Assert-That (Test-KitSameContent $t.GlobalSource $t.AgentsFile) `
        'canonical AGENTS.md matches this repository version' `
        'canonical AGENTS.md has been edited outside the kit. Re-run install.ps1 -Force to restore, or review the difference.' `
        -Warning
} else {
    Assert-That $false '' 'canonical ~/.agents/AGENTS.md is missing'
}

# -------------------------------------------------------------------- skills ---

Write-KitLog ''
Write-KitLog 'Skills' 'INFO'

$entries = @($manifest.core) + @($manifest.vendor)
$selected = $entries
$expected = @($selected | ForEach-Object { $_.name })
$missing = @()
$invalid = @()
$executable = @()
$allowlisted = @()
$contaminated = @()

foreach ($entry in $selected) {
    $name = $entry.name
    $dir = Join-Path $t.SkillsDir $name
    if (-not (Test-Path -LiteralPath $dir)) { $missing += $name; continue }

    $check = Test-KitSkillFrontmatter (Join-Path $dir 'SKILL.md')
    if (-not $check.Ok) { $invalid += "$name ($($check.Problems -join '; '))" }

    # Executable content is rejected unless the manifest entry explicitly allowlists it, and an
    # allowlisted skill whose reviewed count has changed is also a failure. See
    # Get-KitExecutableApproval for why the rule moved from absolute to allowlisted in Phase 11.
    $approval = Get-KitExecutableApproval -Entry $entry -Dir $dir
    if (-not $approval.Ok) {
        $executable += "$name ($($approval.Reason))"
    } elseif ($approval.Count -gt 0) {
        $allowlisted += "$name ($($approval.Count))"
    }

    $found = @(Get-ChildItem -LiteralPath $dir -Recurse -File -Force |
        Select-String -Pattern 'woop[\s\-_]?social' -CaseSensitive:$false -ErrorAction SilentlyContinue)
    if ($found.Count -gt 0) {
        # Report only the relative path and a line number. Never the absolute path and
        # never the matched text: logs get pasted into issues.
        $where = (($found | Select-Object -First 3 | ForEach-Object {
                '{0}:{1}' -f $_.Path.Substring($dir.Length + 1), $_.LineNumber
            }) -join ', ')
        $contaminated += ('{0} ({1} lines, first at {2})' -f $name, $found.Count, $where)
    }

    if ($Verbose2) { Write-KitLog "  $name ok" 'INFO' }
}

Assert-That ($missing.Count -eq 0) `
    "all $($expected.Count) curated skills are installed" `
    "missing skills: $($missing -join ', ')"
Assert-That ($invalid.Count -eq 0) `
    'every installed SKILL.md has valid frontmatter with name matching its directory' `
    "invalid SKILL.md: $($invalid -join '; ')"
Assert-That ($executable.Count -eq 0) `
    'no installed skill contains unapproved executable files' `
    "executable content found in: $($executable -join '; ')"
if ($allowlisted.Count -gt 0) {
    Write-KitLog "  approved executable content, count matches the reviewed manifest: $($allowlisted -join ', ')" 'INFO'
}
Assert-That ($contaminated.Count -eq 0) `
    'no installed skill contains third-party product references' `
    "product references found in: $($contaminated -join '; ')"

$extra = @()
if (Test-Path -LiteralPath $t.SkillsDir) {
    $extra = @(Get-ChildItem -LiteralPath $t.SkillsDir -Directory |
            Where-Object { $expected -notcontains $_.Name } |
            ForEach-Object { $_.Name })
}
Assert-That ($extra.Count -eq 0) `
    'no unexpected skill directories under ~/.agents/skills' `
    "unmanaged directories present (not created by this kit, left alone): $($extra -join ', ')" `
    -Warning

# ------------------------------------------------- no vendor-specific copies ---

Write-KitLog ''
Write-KitLog 'Vendor isolation' 'INFO'

$vendorCopies = @()
foreach ($d in Get-KitForbiddenSkillDirs) {
    if (Test-Path -LiteralPath $d) {
        $n = @(Get-ChildItem -LiteralPath $d -Directory -ErrorAction SilentlyContinue).Count
        if ($n -gt 0) { $vendorCopies += "$(Format-KitPath $d) ($n skills)" }
    }
}
Assert-That ($vendorCopies.Count -eq 0) `
    'no vendor-specific skill copies exist' `
    "vendor skill directories contain skills: $($vendorCopies -join '; '). Both tested agents read ~/.agents/skills natively, so these are drift."

# ---------------------------------------------------- OpenCode bridge check ---

Write-KitLog ''
Write-KitLog 'OpenCode compatibility bridge' 'INFO'

$linkPath = Join-Path $t.OpenCodeCfg 'AGENTS.md'
if (-not (Test-Path -LiteralPath $t.OpenCodeCfg)) {
    Assert-That $true 'OpenCode config dir absent, so no bridge is required' '' -Warning
} elseif (-not (Test-Path -LiteralPath $t.AgentsFile)) {
    Assert-That $false '' 'OpenCode is configured but canonical AGENTS.md is missing; the bridge cannot be created.'
} elseif (-not (Test-Path -LiteralPath $linkPath)) {
    Assert-That $false '' 'OpenCode bridge missing: ~/.config/opencode/AGENTS.md does not exist. Re-run install.ps1.'
} else {
    $item = Get-Item -LiteralPath $linkPath -Force
    if ($item.LinkType -ne 'HardLink' -and (Test-KitSameContent $linkPath $t.GlobalSource)) {
        Assert-That $false '' 'the bridge is an orphaned copy, not a hard link. This happens if ~/.agents/AGENTS.md was deleted. Re-run install.ps1 to rebuild the link.'
    } else {
        Assert-That ($item.LinkType -eq 'HardLink') `
            'bridge is a hard link, not an independent copy' `
            "bridge exists but LinkType is '$($item.LinkType)'. It must be a hard link so there is a single source of truth."
    }
    Assert-That (Test-KitSameContent $linkPath $t.AgentsFile) `
        'bridge content matches the canonical file' `
        'bridge content differs from the canonical file. Re-run install.ps1 to repair.'
}

# --------------------------------------------------------- ownership record ---

Write-KitLog ''
Write-KitLog 'Ownership record' 'INFO'

if (Test-Path -LiteralPath $t.StateFile) {
    Assert-That $true 'ownership record ~/.agents/state/install-state.json exists' ''
    $state = Get-KitText $t.StateFile | ConvertFrom-Json
    $owned = @($state.skills.PSObject.Properties.Name)
    $unowned = @($expected | Where-Object { $owned -notcontains $_ })
    Assert-That ($unowned.Count -eq 0) `
        'ownership record covers every curated skill' `
        "not recorded as kit-owned: $($unowned -join ', ')" `
        -Warning
} else {
    Assert-That $false '' 'ownership record missing. uninstall.ps1 cannot tell what is safe to remove.'
}

# ------------------------------------------------------------ known limits ---

Write-KitLog ''
Write-KitLog 'Known characteristics (not failures)' 'INFO'

$missingSiblings = @{}
foreach ($f in Get-ChildItem -LiteralPath $t.SkillsDir -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue) {
    $text = Get-KitText $f.FullName
    foreach ($m in [regex]::Matches($text, '`([a-z0-9]+(?:-[a-z0-9]+)+)`')) {
        $tok = $m.Groups[1].Value
        if ($expected -notcontains $tok) {
            if (-not $missingSiblings.ContainsKey($tok)) { $missingSiblings[$tok] = 0 }
            $missingSiblings[$tok] = $missingSiblings[$tok] + 1
        }
    }
}
# Only count tokens that are real upstream skills, so file names and API paths are not
# mistaken for uninstalled skills. The cached upstream worktree is the authority.
$knownUpstream = @{}
foreach ($e in $entries) {
    if ($e.source.repo -ne 'social-media-skills/skills') { continue }
    $repoRoot = Join-Path $t.FetchCache ($e.source.repo + '@' + $e.source.ref.Substring(0, 7))
    if (-not (Test-Path -LiteralPath $repoRoot)) { continue }
    Get-ChildItem -LiteralPath (Join-Path $repoRoot 'skills') -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { $knownUpstream[$_.Name] = $true }
}
$realSiblings = @($missingSiblings.Keys | Where-Object { $knownUpstream.ContainsKey($_) } |
    Sort-Object { -$missingSiblings[$_] })
$otherTokens = $missingSiblings.Count - $realSiblings.Count
Write-KitLog ('  {0} uninstalled sibling skills are referenced by the installed set.' -f $realSiblings.Count) 'INFO'
Write-KitLog '  The global AGENTS.md tells the agent to treat those as unavailable.' 'INFO'
$topRefs = @($realSiblings | Select-Object -First 6) -join ', '
Write-KitLog ('  Most referenced uninstalled siblings: {0}' -f $topRefs) 'INFO'
Write-KitLog ('  {0} other hyphenated tokens are file names or API paths, not skills.' -f $otherTokens) 'INFO'

# ------------------------------------------------------------- dependencies ---

# Reports whether the execution backends are usable. This never reads, prints or hashes a credential:
# it checks only whether a CLI is present and which version it reports, plus whether a configuration
# file exists. A key that exists is reported as present, never as content.
Write-KitLog ''
Write-KitLog 'Execution dependencies' 'INFO'

$plan = @(Get-KitDependencyManifest)
if ($plan.Count -eq 0) {
    Write-KitLog '  no dependencies declared' 'INFO'
} else {
    foreach ($dep in $plan) {
        $ds = Get-KitDependencyState -Dep $dep
        $phase = if ($dep.PSObject.Properties.Name -contains 'provisionedInPhase') { "phase $($dep.provisionedInPhase)" } else { '' }
        if (-not $ds.Command) {
            Write-KitLog ("  {0,-16} appears on first use   [{1}]  {2}" -f $dep.id, $dep.ownership, $phase) 'INFO'
            continue
        }
        if ($ds.Installed) {
            $ver = if ($ds.Version) { $ds.Version } else { 'version unknown' }
            Write-KitLog ("  {0,-16} {1,-12} [{2}]  {3}" -f $dep.id, $ver, $dep.ownership, $phase) 'OK'
            [void]$script:Pass.Add($dep.id)
        } else {
            Write-KitLog ("  {0,-16} MISSING                [{1}]  {2}  {3}" -f $dep.id, $dep.ownership, $phase, $dep.installMechanism) 'WARN'
            [void]$script:Warn.Add("$($dep.id) is not installed")
        }
    }

    # Zernio credential status. The value is tested for presence and never printed, logged or hashed.
    # A config file on its own does not mean authenticated: it counts only if it actually carries a
    # key. Reporting "config file present, but not authenticated" for a working key was wrong.
    $zcfg = Join-Path $env:USERPROFILE '.zernio\config.json'
    $zKey = ''
    if (Test-Path -LiteralPath $zcfg) {
        try { $zKey = [string]((Get-KitText $zcfg | ConvertFrom-Json).apiKey) } catch { $zKey = '' }
    }
    if ($env:ZERNIO_API_KEY) {
        Write-KitLog '  zernio-auth      authenticated, key from the environment' 'OK'
        [void]$script:Pass.Add('zernio-auth')
    } elseif ($zKey) {
        # Deliberately reports only the shape, so the log can never leak the secret.
        Write-KitLog ('  zernio-auth      authenticated, key in ~/.zernio/config.json ({0} chars, {1}...)' -f $zKey.Length, $zKey.Substring(0, [Math]::Min(3, $zKey.Length))) 'OK'
        [void]$script:Pass.Add('zernio-auth')
    } elseif (Test-Path -LiteralPath $zcfg) {
        Write-KitLog '  zernio-auth      config file exists but holds no key.' 'WARN'
        Write-KitLog '                    Run "zernio.cmd auth:login" in your own terminal.' 'INFO'
        [void]$script:Warn.Add('zernio is not authenticated yet')
    } else {
        Write-KitLog '  zernio-auth      not authenticated. Run "zernio.cmd auth:login" in your own terminal.' 'WARN'
        [void]$script:Warn.Add('zernio is not authenticated yet')
    }

    # Postiz was evaluated and not selected, so no container runtime is required. If one is present
    # that is harmless, but worth surfacing so nobody assumes the kit put it there.
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Write-KitLog '  docker           present, and not required. Postiz was evaluated and not selected.' 'INFO'
    }
}

Write-KitLog ''
Write-KitLog 'Summary' 'INFO'
Write-KitLog "  passed  : $($script:Pass.Count)"
Write-KitLog "  warnings: $($script:Warn.Count)"
Write-KitLog "  failed  : $($script:Fail.Count)"

if ($script:Fail.Count -gt 0) {
    Write-KitLog ''
    Write-KitLog 'Setup is NOT correct yet. See docs\troubleshooting.md.' 'ERROR'
    exit 1
}
if ($script:Warn.Count -gt 0) {
    Write-KitLog ''
    Write-KitLog 'Setup is correct, with warnings above.' 'WARN'
    exit 2
}
Write-KitLog ''
Write-KitLog 'All checks passed.' 'OK'
exit 0