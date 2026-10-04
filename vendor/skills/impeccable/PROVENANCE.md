# Provenance of this fork

This directory is a **modified copy** maintained by the `newsroom-agent-kit`
project. It is not a verbatim upstream export.

## Upstream

- Repository: https://github.com/pbakaus/impeccable
- Commit: `6e802bd0ed99f53180e2359fddab6da8d97970d9`
- Commit date: 2026-10-04
- Upstream path: `.agents/skills/impeccable`
- Licence: Apache-2.0

## Licence notice

Licensed under the Apache Licence, Version 2.0. You may obtain a copy at http://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable law or agreed to in writing, the software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND.

Upstream content in this directory remains the copyright of its authors and is
used under Apache-2.0. This project retains the original licence text and the
attribution above. See `THIRD_PARTY_NOTICES.md` in the repository root.

## What this project changed

- Vendored the instruction layer only: `SKILL.md` plus the reference files.
Excluded `scripts/`, because the launcher downloads a binary on first run (SEC-05).
Excluded the four `.toml` sub-agent definitions and the hook and live-browser surface.

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