<#
    update.ps1 - review upstream changes before adopting them.

      powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update.ps1
      powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update.ps1 -Fetch

    This script deliberately does NOT update anything. It reports what moved
    upstream so a human can review the diff first.

    Two kinds of upstream exist in this kit:
      fetch  - the skill is installed verbatim from a pinned commit. Safe to
               re-fetch, because the reviewed artifact is exactly what is pinned.
      vendor - the skill is a fork maintained in this repository because upstream
               text was rewritten. Upstream changes must be merged BY HAND into
               vendor/skills/<name> and the provenance note updated. Blindly
               replacing a vendored copy would reintroduce the third-party
               product references this kit removed on purpose.

    Upstream install scripts are never executed. Only git fetch/checkout into a
    cache directory is used.
#>
[CmdletBinding()]
param(
    # Clone or refresh the pinned commits into the local cache. Never installs.
    [switch]$Fetch,

    # Also query each repository's default branch to report how far it has moved.
    [switch]$CheckRemote,

    # Redirect the install into a throwaway directory instead of %USERPROFILE%\.agents.
    # Used to test this toolchain without touching real user state.
    [string]$TargetRoot,

    # Override the OpenCode config directory. Only meaningful with -TargetRoot.
    [string]$OpenCodeConfigDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot 'common.ps1')

$manifest = Get-KitManifest
$t = Get-KitTargetPaths -TargetRoot $TargetRoot

$entries = @($manifest.core) + @($manifest.optional) + @($manifest.vendor)

Write-KitLog 'Upstream review' 'INFO'
Write-KitLog "  cache: $(Format-KitPath $t.FetchCache)"
Write-KitLog '  This tool reports only. It installs nothing and rewrites nothing.'
Write-KitLog ''

$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    Write-KitLog 'git was not found on PATH. Upstream review is unavailable.' 'ERROR'
    exit 1
}

$installed = @()
if (Test-Path -LiteralPath $t.StateFile) {
    try {
        $state = Get-KitText $t.StateFile | ConvertFrom-Json
        $installed = @($state.skills.PSObject.Properties.Name)
    } catch { $installed = @() }
}

$byRepo = @{}
foreach ($e in $entries) {
    if (-not $e.source) { continue }
    $repo = $e.source.repo
    if (-not $byRepo.ContainsKey($repo)) {
        $byRepo[$repo] = [pscustomobject]@{
            repo = $repo; ref = $e.source.ref; license = $e.source.license
            fetch = New-Object System.Collections.ArrayList
            vendor = New-Object System.Collections.ArrayList
        }
    }
    $isVendor = ($e.PSObject.Properties.Name -contains 'vendorPath')
    if ($isVendor) { [void]$byRepo[$repo].vendor.Add($e.name) } else { [void]$byRepo[$repo].fetch.Add($e.name) }
}

# ---------------------------------------------------------------- fetch mode ---

if ($Fetch) {
    Write-KitLog 'Fetching pinned commits into the cache (no install)' 'INFO'
    if (-not (Test-Path -LiteralPath $t.FetchCache)) {
        New-Item -ItemType Directory -Path $t.FetchCache -Force | Out-Null
    }
    foreach ($r in $byRepo.Values) {
        if ($r.fetch.Count -eq 0) { continue }
        $url = 'https://github.com/' + $r.repo + '.git'
        $dest = Join-Path $t.FetchCache ($r.repo + '@' + $r.ref.Substring(0, 7))
        Write-KitLog "  $($r.repo) @ $($r.ref.Substring(0,7))"
        if (Test-Path -LiteralPath (Join-Path $dest '.git')) {
            Write-KitLog '    already cached'
            continue
        }
        if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
        # A normal worktree, not --bare: install.ps1 has to read files from subdir,
        # so the pinned commit must actually be checked out on disk.
        & git init --quiet $dest 2>&1 | Out-Null
        & git -C $dest remote add origin $url 2>&1 | Out-Null
        & git -C $dest fetch --quiet --depth 1 origin $r.ref 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-KitLog "    FAILED to fetch ref $($r.ref). Check the ref still exists upstream." 'ERROR'
            continue
        }
        & git -C $dest checkout --quiet FETCH_HEAD 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-KitLog "    FAILED to check out $($r.ref.Substring(0,7))." 'ERROR'
            continue
        }
        $n = @(Get-ChildItem -LiteralPath $dest -Recurse -Filter 'SKILL.md' -File).Count
        Write-KitLog "    fetched, $n SKILL.md files on disk" 'OK'
    }
    Write-KitLog ''
}

# ------------------------------------------------------------- remote check ---

if ($CheckRemote) {
    Write-KitLog 'Comparing pinned commits with upstream default branch' 'INFO'
    foreach ($r in $byRepo.Values) {
        $remote = (& git ls-remote 'https://github.com/' + $r.repo + '.git' HEAD 2>$null)
        if (-not $remote) {
            Write-KitLog "  $($r.repo): could not query" 'WARN'
            continue
        }
        $head = ($remote -split '\s+')[0]
        if ($head -eq $r.ref) {
            Write-KitLog "  $($r.repo): pinned ref is still the branch head" 'OK'
        } else {
            Write-KitLog "  $($r.repo): upstream has moved. pinned=$($r.ref.Substring(0,7)) head=$($head.Substring(0,7))" 'WARN'
        }
    }
    Write-KitLog ''
}

# ------------------------------------------------------------------- report ---

Write-KitLog 'Per-skill status' 'INFO'

foreach ($e in $entries) {
    if (-not $e.source) { continue }
    $name = $e.name
    $installedHere = $installed -contains $name
    $isVendor = ($e.PSObject.Properties.Name -contains 'vendorPath')

    $note = @()
    if ($installedHere) { $note += 'installed' } else { $note += 'not installed' }
    $note += $(if ($isVendor) { 'vendored fork' } else { 'pinned fetch' })

    if ($isVendor) {
        $local = Join-Path (Get-KitRoot) $e.vendorPath
        if (Test-Path -LiteralPath $local) {
            $vendored = Get-ChildItem -LiteralPath $local -Recurse -File | Where-Object { $_.Name -eq 'PROVENANCE.md' }
            $note += $(if ($vendored) { 'provenance note present' } else { 'provenance note MISSING' })
        } else {
            $note += 'vendored copy MISSING'
        }
    } else {
        $cache = Join-Path $t.FetchCache ($e.source.repo + '@' + $e.source.ref)
        $note += $(if (Test-Path -LiteralPath $cache) { 'cached' } else { 'not cached, run with -Fetch' })
    }

    Write-KitLog ("  {0,-30} {1}" -f $name, ($note -join ', '))
}

Write-KitLog ''
Write-KitLog 'How to adopt an upstream change' 'INFO'
Write-KitLog '  fetch-pinned skills : bump source.ref in manifest\skills.json, run this script with'
Write-KitLog '                        -Fetch -CheckRemote, review the diff, then run install.ps1 -Force.'
Write-KitLog '  vendored skills    : review upstream, hand-merge the change into vendor\skills\<name>,'
Write-KitLog '                        update PROVENANCE.md, confirm no third-party product names were'
Write-KitLog '                        reintroduced, then run install.ps1 -Force.'
Write-KitLog '                        Never copy an upstream copy over a vendored one.'
Write-KitLog ''
Write-KitLog 'Nothing was changed.' 'OK'
exit 0