<#
    common.ps1 - shared helpers for the newsroom-agent-kit scripts.

    Dot-source this file; do not run it directly.

    Design constraints that come from Phase 1 discovery:
      - Windows PowerShell 5.1 only (no PowerShell 7 syntax).
      - Effective execution policy is Restricted, so scripts must be invoked with
        -ExecutionPolicy Bypass.
      - Not elevated. Symbolic links fail; NTFS hard links work.
      - The OS is localized, so never parse the text of an error message.
      - UTF-8 files on this machine are BOM-less. Get-Content/Set-Content corrupt
        em-dashes and curly quotes, so all file I/O goes through .NET with an
        explicit UTF8Encoding($false).
#>

Set-StrictMode -Version Latest

$script:KitUtf8 = New-Object System.Text.UTF8Encoding($false)

function Get-KitRoot {
    return (Split-Path -Parent $PSScriptRoot)
}

function Get-KitManifest {
    $path = Join-Path (Get-KitRoot) 'manifest\skills.json'
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Manifest not found: $path"
    }
    $raw = [System.IO.File]::ReadAllText($path, (New-Object System.Text.UTF8Encoding($false, $true)))
    return ($raw | ConvertFrom-Json)
}

function Get-KitTargetPaths {
    <#
        Resolve every path the kit touches.

        -TargetRoot and -OpenCodeConfigDir exist so the whole toolchain can be
        exercised end to end against a throwaway directory. Phase 3 requires the
        tooling to be reviewable and testable BEFORE any real user state is
        touched, and that is only possible if the target is redirectable.
    #>
    param(
        [string]$TargetRoot,
        [string]$OpenCodeConfigDir
    )

    $home_ = $env:USERPROFILE
    $root = if ($TargetRoot) { $TargetRoot } else { Join-Path $home_ '.agents' }
    $oc = if ($OpenCodeConfigDir) { $OpenCodeConfigDir } else { Join-Path $home_ '.config\opencode' }

    return [pscustomobject]@{
        Home         = $home_
        Root         = $root
        IsSandbox    = [bool]$TargetRoot
        SkillsDir    = Join-Path $root 'skills'
        AgentsFile   = Join-Path $root 'AGENTS.md'
        StateDir     = Join-Path $root 'state'
        StateFile    = Join-Path $root 'state\install-state.json'
        BackupsDir   = Join-Path $root 'backups'
        GlobalSource = Join-Path (Get-KitRoot) 'global\AGENTS.md'
        VendorDir    = Join-Path (Get-KitRoot) 'vendor\skills'
        FetchCache   = Join-Path $root 'cache\upstream'
        OpenCodeCfg  = $oc
    }
}

<#
    Vendor directories that must never be created by this kit. If any of these
    exist with skills in them, verification fails. Phase 1 proved that both
    tested agents read the canonical .agents location natively, so their presence
    means something else went wrong.
#>
function Get-KitForbiddenSkillDirs {
    $h = $env:USERPROFILE
    return @(
        (Join-Path $h '.config\opencode\skills'),
        (Join-Path $h '.claude\skills'),
        (Join-Path $h '.codex\skills'),
        (Join-Path $h '.gemini\skills'),
        (Join-Path $h '.cursor\skills'),
        (Join-Path $h '.cline\skills')
    )
}

function Write-KitLog {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DRYRUN', 'OK')][string]$Level = 'INFO'
    )
    $tag = switch ($Level) {
        'ERROR' { 'error' }
        'WARN' { 'warn ' }
        'OK' { 'ok   ' }
        'DRYRUN' { 'dry  ' }
        default { 'info ' }
    }
    Write-Host "[$tag] $Message"
}

<#
    Redact anything that looks like a user path down to a relative form, so logs
    never leak the machine layout. Never log file contents.
#>
function Format-KitPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $Path }
    $h = $env:USERPROFILE
    if ($Path.StartsWith($h, [System.StringComparison]::OrdinalIgnoreCase)) {
        return '~' + $Path.Substring($h.Length)
    }
    return Split-Path -Leaf $Path
}

function Get-KitFileHash {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-KitText {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, (New-Object System.Text.UTF8Encoding($false, $true)))
}

function Set-KitText {
    param([string]$Path, [string]$Text)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Text, $script:KitUtf8)
}

function Test-KitSkillFrontmatter {
    <#
        Static validation of a SKILL.md against the Agent Skills specification.
        Returns an object with Ok and a Problems array. Parses only the
        frontmatter block; never interprets the body.
    #>
    param([string]$SkillFile)

    $problems = New-Object System.Collections.ArrayList
    if (-not (Test-Path -LiteralPath $SkillFile)) {
        [void]$problems.Add('SKILL.md is missing')
        return [pscustomobject]@{ Ok = $false; Problems = $problems; Name = '' }
    }

    $text = Get-KitText $SkillFile
    $dirName = Split-Path -Leaf (Split-Path -Parent $SkillFile)

    if ($text -notmatch '(?s)^---\s*\r?\n(.*?)\r?\n---') {
        [void]$problems.Add('no YAML frontmatter block')
        return [pscustomobject]@{ Ok = $false; Problems = $problems; Name = '' }
    }
    $fm = $Matches[1]

    $name = ''
    if ($fm -match '(?m)^name:\s*(.+?)\s*$') { $name = $Matches[1].Trim().Trim('"', "'") }
    else { [void]$problems.Add('frontmatter has no name') }

    $descLen = 0
    if ($fm -match '(?m)^description:\s*(.*)$') {
        $raw = $Matches[1]
        if ($raw.Trim() -eq '>' -or $raw.Trim() -eq '|-' -or $raw.Trim() -eq '>-') {
            # block scalar: take everything indented under it
            $after = $fm.Substring($fm.IndexOf($raw) + $raw.Length)
            $sb = New-Object System.Text.StringBuilder
            foreach ($l in ($after -split "`r?`n")) {
                if ($l.Trim() -eq '') { continue }
                if ($l -match '^\s{2,}\S') { [void]$sb.Append($l.Trim()); [void]$sb.Append(' ') }
                else { break }
            }
            $descLen = $sb.ToString().Trim().Length
        } else {
            $descLen = $raw.Trim().Trim('"', "'").Length
        }
    } else { [void]$problems.Add('frontmatter has no description') }

    if ($name) {
        if ($name -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
            [void]$problems.Add("name '$name' is not lowercase kebab-case")
        }
        if ($name.Length -gt 64) { [void]$problems.Add("name is $($name.Length) chars, max 64") }
        if ($name -ne $dirName) {
            [void]$problems.Add("name '$name' does not match directory '$dirName'")
        }
    }
    if ($descLen -eq 0) { [void]$problems.Add('description is empty') }
    if ($descLen -gt 1024) { [void]$problems.Add("description is $descLen chars, max 1024") }

    return [pscustomobject]@{
        Ok = ($problems.Count -eq 0)
        Problems = $problems
        Name = $name
        DescriptionLength = $descLen
    }
}

function Get-KitCodeFiles {
    <#
        Executable content inside a skill directory. The curated core must have
        zero of these. Anything else means the skill set grew an executable
        surface without a manifest decision.
    #>
    param([string]$Dir)
    $exts = @('.js', '.mjs', '.cjs', '.ts', '.mts', '.py', '.sh', '.bash', '.ps1', '.psm1', '.rb', '.go', '.exe', '.bat', '.cmd')
    $found = New-Object System.Collections.ArrayList
    foreach ($f in Get-ChildItem -LiteralPath $Dir -Recurse -File -Force) {
        if ($exts -contains $f.Extension.ToLowerInvariant()) {
            [void]$found.Add($f.FullName.Substring($Dir.Length + 1))
        }
    }
    return $found
}

function Copy-KitTree {
    <# Byte-safe recursive copy that also removes files absent from the source. #>
    param([string]$Source, [string]$Destination)

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Source not found: $(Format-KitPath $Source)"
    }
    if (Test-Path -LiteralPath $Destination) {
        Get-ChildItem -LiteralPath $Destination -Recurse -File -Force |
            ForEach-Object { [System.IO.File]::Delete($_.FullName) }
        Get-ChildItem -LiteralPath $Destination -Recurse -Directory -Force |
            Sort-Object { $_.FullName.Length } -Descending |
            ForEach-Object { if (@(Get-ChildItem -LiteralPath $_.FullName -Force).Count -eq 0) { [System.IO.Directory]::Delete($_.FullName) } }
    } else {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    Get-ChildItem -LiteralPath $Source -Recurse -File -Force | ForEach-Object {
        $rel = $_.FullName.Substring($Source.Length + 1)
        $target = Join-Path $Destination $rel
        $parent = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        [System.IO.File]::Copy($_.FullName, $target, $true)
    }
}

function New-KitBackup {
    <#
        Copy a file the installer is about to replace into a timestamped folder
        under %USERPROFILE%\.agents\backups. Backups never live inside the git
        repository and are never tracked.
    #>
    param([string]$Path, [string]$BackupRoot, [string]$Stamp)
    $dir = Join-Path $BackupRoot $Stamp
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $flat = ($Path -replace '[:\\]', '_')
    $target = Join-Path $dir $flat
    [System.IO.File]::Copy($Path, $target, $true)
    return $target
}

function Get-KitStamp {
    return (Get-Date).ToString('yyyyMMdd-HHmmss')
}

function Test-KitSameContent {
    param([string]$A, [string]$B)
    if (-not (Test-Path -LiteralPath $A)) { return $false }
    if (-not (Test-Path -LiteralPath $B)) { return $false }
    return ((Get-KitFileHash $A) -eq (Get-KitFileHash $B))
}
function Get-KitSkillSource {
    <#
        Resolve where a manifest entry's files come from.

        Vendored skills come from vendor/skills/<name> in this repository.
        Pinned-fetch skills come from the local cache at
        ~/.agents/cache/upstream/<repo>@<short-ref>/<subdir>.
    #>
    param([Parameter(Mandatory)]$Entry, [Parameter(Mandatory)]$Targets)

    if ($Entry.PSObject.Properties.Name -contains 'vendorPath') {
        $vendored = Join-Path (Get-KitRoot) $Entry.vendorPath
        if (Test-Path -LiteralPath $vendored) {
            return [pscustomobject]@{ Path = $vendored; Mode = 'vendor'; Found = $true }
        }
        return [pscustomobject]@{ Path = $vendored; Mode = 'vendor'; Found = $false }
    }
    $ref7 = $Entry.source.ref.Substring(0, 7)
    $cached = Join-Path (Join-Path $Targets.FetchCache ($Entry.source.repo + '@' + $ref7)) $Entry.source.subdir
    return [pscustomobject]@{ Path = $cached; Mode = 'fetch'; Found = (Test-Path -LiteralPath $cached) }
}