<#
    gen-provenance.ps1 - write a PROVENANCE.md into each vendored skill.

    Run from the repository root after editing vendor/skills. Idempotent.
    The generated file is the audit record for that fork: where it came from,
    under which licence, and exactly what this repository changed.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$manifest = Get-KitManifest
$t = Get-KitTargetPaths

$template = @'
# Provenance of this fork

This directory is a **modified copy** maintained by the `newsroom-agent-kit`
project. It is not a verbatim upstream export.

## Upstream

- Repository: {URL}
- Commit: `{REF}`
- Commit date: {REFDATE}
- Upstream path: `{SUBDIR}`
- Licence: {LICENSE}

## Licence notice

{UPLICENSE}

Upstream content in this directory remains the copyright of its authors and is
used under {LICENSE}. This project retains the original licence text and the
attribution above. See `THIRD_PARTY_NOTICES.md` in the repository root.

## What this project changed

{CHANGES}

## Why

The upstream skill was written around a specific commercial product. Left
unmodified, an AI agent reading it would conclude that capabilities which do
exist in this newsroom's toolchain do not exist, or would invent a product the
user has never heard of. See `docs/security.md` finding SEC-07.

The rewrite preserves all substantive craft guidance and every safety rule. It
removes only claims about a proprietary product's capabilities, and replaces them
with statements about the human's own tools and the agent's role.

## Rules for future edits

1. Never copy an upstream directory over this one. Merge by hand.
2. Never reintroduce a product or vendor name. `scripts/verify.ps1` fails the
   installation if one appears.
3. Keep every human-in-the-loop rule. These skills draft; a human publishes.
4. Keep "never fabricate a metric or a source" intact.
5. Update the commit reference and the change list when you touch this file.
'@

$changesByKind = @{
    'product-references-removed' = @(
        'Removed every reference to a specific commercial product and its capability claims.',
        'Recast product limits as statements about the human''s own toolchain and the agent''s role.',
        'Deleted the upstream `evals/` fixtures, which were written against that product and are not used at runtime.',
        'Repointed references to sibling skills that are installed under a different name in this kit.'
    )
    'verbatim' = @(
        'No content change required: the upstream copy contained no third-party product references.',
        'The upstream `evals/` fixtures were still removed, since they are unused at runtime.',
        'Repointed references to sibling skills that are installed under a different name in this kit.'
    )
    'instruction-layer-only' = @(
        'Vendored the instruction layer only: `SKILL.md` plus the reference files.',
        'Excluded `scripts/`, because the launcher downloads a binary on first run (SEC-05).',
        'Excluded the four `.toml` sub-agent definitions and the hook and live-browser surface.'
    )
    'scripts-removed' = @(
        'Excluded `scripts/contrast-checker.py` so the installed set contains zero executable files.',
        'The checker is Python stdlib only and can be reinstated later if a Python interpreter is present.'
    )
}

$written = 0
foreach ($entry in $manifest.vendor) {
    $dir = Join-Path (Get-KitRoot) $entry.vendorPath
    if (-not (Test-Path -LiteralPath $dir)) {
        Write-KitLog "missing: $(Format-KitPath $dir)" 'WARN'
        continue
    }
    $src = $entry.source
    $uplicense = switch ($src.license) {
        'MIT' { 'Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, subject to the conditions of the MIT licence.' }
        'Apache-2.0' { 'Licensed under the Apache Licence, Version 2.0. You may obtain a copy at http://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable law or agreed to in writing, the software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND.' }
        default { "Licensed under $($src.license). See the upstream repository for the full text." }
    }
    $changes = ($changesByKind[$entry.fork] -join "`n") -replace '^', '- '
    $body = $template.Replace('{URL}', $src.url).Replace('{REF}', $src.ref).Replace('{REFDATE}', $src.refDate).
        Replace('{SUBDIR}', $src.subdir).Replace('{LICENSE}', $src.license).Replace('{UPLICENSE}', $uplicense).
        Replace('{CHANGES}', $changes)
    Set-KitText (Join-Path $dir 'PROVENANCE.md') $body
    $written++
    Write-KitLog "provenance written: $($entry.name)" 'OK'
}
Write-KitLog "wrote $written provenance files" 'OK'
exit 0