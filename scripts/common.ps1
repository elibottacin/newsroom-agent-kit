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
    param([string]$SkillFile, [string]$ExpectedName)

    $problems = New-Object System.Collections.ArrayList
    if (-not (Test-Path -LiteralPath $SkillFile)) {
        [void]$problems.Add('SKILL.md is missing')
        return [pscustomobject]@{ Ok = $false; Problems = $problems; Name = '' }
    }

    $text = Get-KitText $SkillFile
    # The manifest entry name is the authority. Only fall back to the containing directory when
    # the caller has no name to check against, so validating a selective entry whose source sits in
    # a cache directory named "<repo>@<ref>" does not report a false mismatch.
    $dirName = if ($ExpectedName) { $ExpectedName } else { Split-Path -Leaf (Split-Path -Parent $SkillFile) }

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
function Get-KitDependencyManifest {
    <#
        The default-plan dependency list, read from manifest/dependencies.json.

        Only sections that describe what the selected setup actually needs are returned. The postiz
        section is deliberately excluded: Postiz was evaluated and not selected, so its WSL, Docker
        and container entries must never be provisioned by the installer.
    #>
    $path = Join-Path (Get-KitRoot) 'manifest\dependencies.json'
    if (-not (Test-Path -LiteralPath $path)) {
        Write-KitLog 'manifest/dependencies.json is missing. Dependency provisioning is unavailable.' 'ERROR'
        return @()
    }
    $doc = Get-KitText $path | ConvertFrom-Json

    $plan = @()
    foreach ($dep in @($doc.hyperframes.dependencies)) { $plan += $dep }
    if ($doc.PSObject.Properties.Name -contains 'zernio') {
        foreach ($dep in @($doc.zernio.dependencies)) { $plan += $dep }
    }
    return $plan
}

function Get-KitDependencyState {
    <#
        Detect one dependency. Returns Installed, Version, Path and, when the executable is a
        winget package that has not been added to this process's PATH yet, a RefreshPath hint.

        Detection never trusts a bare PATH lookup alone. On Windows a freshly installed package is
        often missing from the current session's PATH even though it is present on disk, which
        previously made "gh" look absent when it was installed. So the user and machine PATH are
        also searched directly, and winget's own package directory is checked as a last resort.
    #>
    param([Parameter(Mandatory)]$Dep)

    $command = switch ($Dep.id) {
        'nodejs' { 'node' }
        'npm-npx' { 'npm' }
        'hyperframes-cli' { 'hyperframes' }
        'zernio-cli' { 'zernio' }
        'ffmpeg' { 'ffmpeg' }
        default { $null }
    }
    if (-not $command) {
        return [pscustomobject]@{ Id = $Dep.id; Command = ''; Installed = $false; Version = ''; Path = ''; RefreshPath = $false }
    }

    $candidates = @()
    $onPath = Get-Command $command -ErrorAction SilentlyContinue
    if ($onPath) { $candidates += $onPath.Source }

    # This session's PATH, then the persisted user and machine PATH, then winget's package store.
    $roots = @($env:Path)
    foreach ($scope in @('User', 'Machine')) {
        $p = [Environment]::GetEnvironmentVariable('Path', $scope)
        if ($p) { $roots += ($p -split ';') }
    }
    $wingetRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    foreach ($r in $roots) {
        if (-not $r) { continue }
        if (Test-Path -LiteralPath $r) {
            # Prefer the real Windows launchers. npm and the Zernio CLI also ship an extension-less
            # POSIX shim in the same directory, and picking that one yields an empty --version.
            foreach ($ext in @('.cmd', '.exe', '.bat', '')) {
                $c = Join-Path $r ($command + $ext)
                if (Test-Path -LiteralPath $c) { $candidates += $c }
            }
        }
        if (Test-Path -LiteralPath $wingetRoot) {
            # Scan the winget package store generically and recursively, to a bounded depth.
            # Two earlier attempts were wrong: a name-based filter missed Gyan.FFmpeg entirely, and a
            # fixed two-level walk missed it again because the binary sits three levels down at
            # <package>/<version-dir>/bin/ffmpeg.exe. Depth is capped so this cannot become a slow
            # full-disk walk.
            foreach ($ext in @('.exe', '.cmd', '.bat')) {
                $candidates += @(Get-ChildItem -LiteralPath $wingetRoot -Recurse -Depth 3 -Force `
                    -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -eq ($command + $ext) } |
                    ForEach-Object { $_.FullName })
            }
        }
    }

    foreach ($c in ($candidates | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $c)) { continue }
        $version = ''
        $probeOk = $false
        # Try the GNU-style flag first, then the BSD-style one. ffmpeg prints its version for
        # --version but exits -1414549496, while -version exits 0, so probing only --version reported
        # a working ffmpeg 9.0.2 as missing and then tried to reinstall it.
        foreach ($flag in @('--version', '-version', '-v')) {
            try {
                $lines = @(& $c $flag 2>&1 | ForEach-Object { ([string]$_).Trim() } | Where-Object { $_ })
                if ($LASTEXITCODE -eq 0 -and $lines.Count -gt 0) {
                    $version = $lines[0]
                    $probeOk = $true
                    break
                }
                if (-not $version -and $lines.Count -gt 0) { $version = $lines[0] }
            } catch { }
        }
        # The executable existing is not proof it works. npm writes its .cmd shim before the package
        # finishes installing, so a failed install leaves a shim that exists but crashes on every
        # call. hyperframes --version reported "Cannot find module .../bin/hyperframes.mjs" and this
        # check is what caught it. Require the probe itself to succeed.
        if (-not $probeOk) { continue }
        $refresh = -not ($onPath -and $onPath.Source -eq $c)
        return [pscustomobject]@{ Id = $Dep.id; Command = $command; Installed = $true; Version = $version; Path = $c; RefreshPath = $refresh }
    }

    return [pscustomobject]@{ Id = $Dep.id; Command = $command; Installed = $false; Version = ''; Path = ''; RefreshPath = $false }
}

function Test-KitVersionSatisfies {
    <#
        Loose version gate used only to decide "absent, or too old to use". It is deliberately not a
        full semver implementation: the point is to avoid reinstalling something that already works
        and to avoid silently upgrading a major version the user may depend on.
    #>
    param([string]$Found, [string]$Required)

    # An unreadable version is not evidence of an old one. Reporting "too old" here produced a false
    # warning for npm, whose version line was being swallowed by its own stderr notice.
    if (-not $Found) { return $true }
    if (-not $Required) { return $true }
    $min = ($Required -replace '[^0-9\.].*$', '').Trim('.')
    # A requirement with no version in it ("bundled with Node", "recent") is a floor-less statement.
    if (-not $min) { return $true }
    $got = ($Found -replace '[^0-9\.].*$', '').Trim('.')
    if (-not $got) { return $true }
    $f = @($got -split '\.' | ForEach-Object { [int]$_ })
    $m = @($min -split '\.' | ForEach-Object { [int]$_ })
    for ($i = 0; $i -lt [Math]::Max($f.Count, $m.Count); $i++) {
        $fv = if ($i -lt $f.Count) { $f[$i] } else { 0 }
        $mv = if ($i -lt $m.Count) { $m[$i] } else { 0 }
        if ($fv -gt $mv) { return $true }
        if ($fv -lt $mv) { return $false }
    }
    return $true
}

function Initialize-KitNodePath {
    <#
        Put a detected Node.js directory on THIS process's PATH.

        Node is installed at user scope, which writes to the persisted user PATH. A terminal opened
        before the install keeps its old copy, and the kit's own shell sessions are no different.

        That is harmless for running a command directly, but npm runs package lifecycle scripts in a
        child cmd.exe that inherits the current PATH. esbuild's postinstall calls "node install.js",
        so with node missing from the session PATH the install died with:

            npm error command C:\WINDOWS\system32\cmd.exe /d /s /c node install.js
            npm error "node" no se reconoce como un comando interno o externo

        Returns the directory added, or an empty string when there was nothing to do.
    #>
    $sep = [System.IO.Path]::PathSeparator
    $current = $env:Path
    if ($current -match '(?i)node\.exe') { return '' }

    $roots = @($current)
    foreach ($scope in @('User', 'Machine')) {
        $p = [Environment]::GetEnvironmentVariable('Path', $scope)
        if ($p) { $roots += ($p -split ';') }
    }
    $wingetRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    foreach ($r in $roots) {
        if (-not $r) { continue }
        if (Test-Path -LiteralPath (Join-Path $r 'node.exe')) {
            $env:Path = "$r$sep$current"
            return $r
        }
        if (Test-Path -LiteralPath $wingetRoot) {
            $hit = Get-ChildItem -LiteralPath $wingetRoot -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like '*NodeJS*' } |
                ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Directory -ErrorAction SilentlyContinue } |
                Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'node.exe') } |
                Select-Object -First 1
            if ($hit) {
                $env:Path = "$($hit.FullName)$sep$current"
                return $hit.FullName
            }
        }
    }
    return ''
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
    $cached = Join-Path (Get-KitCacheDir -Entry $Entry -Targets $Targets) $Entry.source.subdir
    # An empty subdir means "the repository root", which Join-Path renders with a trailing
    # separator. Callers compute paths relative to the source with Substring($Source.Length + 1),
    # so a trailing separator would shift every one of them by a character. Normalise it away here,
    # once, rather than defensively in each consumer.
    $cached = $cached.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    return [pscustomobject]@{ Path = $cached; Mode = 'fetch'; Found = (Test-Path -LiteralPath $cached) }
}
function Get-KitEntryFiles {
    <#
        The exact set of files a manifest entry installs, as paths relative to the source root.

        Most entries install their whole subdirectory and this returns every file, which is the
        original behaviour. An entry may instead declare an "include" allowlist, which is how a
        skill is taken from a repository whose root also holds unrelated source. Without this,
        installing the `zernio` skill would drag zernio-cli's src/ and package.json into
        ~/.agents/skills and break the "no executable files in a skill" invariant.

        An include pattern matches when the relative path equals it, when it is a glob matching
        it, or when the path sits under it as a directory.
    #>
    param([Parameter(Mandatory)]$Entry, [Parameter(Mandatory)][string]$Source)

    $all = @(Get-ChildItem -LiteralPath $Source -Recurse -File -Force)
    if (-not ($Entry.PSObject.Properties.Name -contains 'include')) { return $all }

    $patterns = @($Entry.include)
    if ($patterns.Count -eq 0) { return @() }

    $picked = @()
    foreach ($f in $all) {
        $rel = $f.FullName.Substring($Source.Length + 1).Replace('\', '/')
        foreach ($p in $patterns) {
            $p = ([string]$p).Replace('\', '/')
            if ($rel -eq $p -or $rel -like "$p/*" -or $rel -like $p) { $picked += $f; break }
        }
    }
    return $picked
}

function Copy-KitEntry {
    <#
        Install an entry's selected files into the destination, removing anything already there
        that the entry no longer selects. Same prune-then-copy contract as Copy-KitTree, but driven
        by an explicit file list so a selective entry stays selective across reruns.
    #>
    param([Parameter(Mandatory)]$Entry, [Parameter(Mandatory)][string]$Source, [Parameter(Mandatory)][string]$Destination)

    $files = @(Get-KitEntryFiles -Entry $Entry -Source $Source)
    if ($files.Count -eq 0) { throw "Entry selected no files from $(Format-KitPath $Source)" }

    if (Test-Path -LiteralPath $Destination) {
        Get-ChildItem -LiteralPath $Destination -Recurse -File -Force |
            ForEach-Object { [System.IO.File]::Delete($_.FullName) }
        Get-ChildItem -LiteralPath $Destination -Recurse -Directory -Force |
            Sort-Object { $_.FullName.Length } -Descending |
            ForEach-Object { if (@(Get-ChildItem -LiteralPath $_.FullName -Force).Count -eq 0) { [System.IO.Directory]::Delete($_.FullName) } }
    } else {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    foreach ($f in $files) {
        $rel = $f.FullName.Substring($Source.Length + 1)
        $target = Join-Path $Destination $rel
        $parent = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        [System.IO.File]::Copy($f.FullName, $target, $true)
    }
}

function Get-KitExecutableApproval {
    <#
        Decide whether a skill's executable files are permitted, and whether the count matches.

        Until Phase 11 the rule was absolute: a skill contains zero executable files. That was
        deliberate (SEC-15) and it held for all 40 original skills. HyperFrames breaks it: five of its
        core skills ship scripts that their own instructions tell the agent to run, so excluding them
        would leave 40 broken script references.

        The user chose on 2026-10-05 to install the scripts and relax the rule to an explicit
        allowlist. An entry opts in with an "executableFiles" block declaring approved and a reviewed
        count. Anything NOT opted in is still rejected, and an opted-in skill whose count has changed
        is flagged, so a new unvetted script cannot slip in unnoticed.

        Returns Approved, Count, Declared, Ok and Reason.
    #>
    param([Parameter(Mandatory)]$Entry, [string]$Dir, $Files)

    # Use an explicit file list when the caller has one. A selective entry such as `zernio` takes a
    # single SKILL.md from a repository root that also holds 26 TypeScript files, so scanning the whole
    # directory reported it as containing 26 unapproved executables. verify.ps1 passes -Dir because
    # the installed tree is already exactly what was selected.
    $exts = @('.js', '.mjs', '.cjs', '.ts', '.mts', '.py', '.sh', '.bash', '.ps1', '.psm1', '.rb', '.go', '.exe', '.bat', '.cmd')
    if ($PSBoundParameters.ContainsKey('Files') -and $null -ne $Files) {
        $code = @(@($Files) | Where-Object { $exts -contains ([string]$_.Extension).ToLowerInvariant() })
    } elseif ($Dir) {
        $code = @(Get-KitCodeFiles $Dir)
    } else {
        $code = @()
    }
    $hasBlock = ($Entry.PSObject.Properties.Name -contains 'executableFiles') -and $Entry.executableFiles
    $approved = $false
    $declared = -1
    if ($hasBlock) {
        $approved = [bool]$Entry.executableFiles.approved
        if ($Entry.executableFiles.PSObject.Properties.Name -contains 'count') {
            $declared = [int]$Entry.executableFiles.count
        }
    }

    if ($code.Count -eq 0) {
        return [pscustomobject]@{ Approved = $true; Count = 0; Declared = $declared; Ok = $true; Reason = '' }
    }
    if (-not $approved) {
        return [pscustomobject]@{ Approved = $false; Count = $code.Count; Declared = $declared; Ok = $false
            Reason = "contains $($code.Count) executable file(s) and is not on the allowlist" }
    }
    if ($declared -ge 0 -and $declared -ne $code.Count) {
        return [pscustomobject]@{ Approved = $true; Count = $code.Count; Declared = $declared; Ok = $false
            Reason = "allowlisted for $declared executable file(s) but found $($code.Count). Review the difference before trusting it." }
    }
    return [pscustomobject]@{ Approved = $true; Count = $code.Count; Declared = $declared; Ok = $true; Reason = '' }
}

function Get-KitCacheDir {
    <#
        The single place that decides where a pinned upstream commit lives on disk.

        Layout: <FetchCache>/<owner>/<repo>@<short-ref>

        The repository field is "owner/repo", and Windows treats "/" as a separator, so this
        is deliberately two levels deep. install.ps1, update.ps1 and verify.ps1 must all
        agree on this, which is why they call this function rather than building the path
        themselves.
    #>
    param([Parameter(Mandatory)]$Entry, [Parameter(Mandatory)]$Targets)

    if (-not $Entry.source) { return $null }
    $ref = $Entry.source.ref
    if ($ref.Length -gt 7) { $ref = $ref.Substring(0, 7) }
    $leaf = ($Entry.source.repo + '@' + $ref)
    # normalise "/" to "\" so the result is unambiguous on Windows
    $leaf = $leaf.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    return (Join-Path $Targets.FetchCache $leaf)
}