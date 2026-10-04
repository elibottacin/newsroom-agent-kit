# Provenance of this fork

This directory is a **modified copy** maintained by the `newsroom-agent-kit`
project. It is not a verbatim upstream export.

## Upstream

- Repository: https://github.com/PracticalSwan/agent-skills
- Commit: `ff6d12f61e8250dd1b988e101a482f6adc05c451`
- Commit date: 2026-09-14
- Upstream path: `frontend-design`
- Licence: MIT AND Apache-2.0

## Licence notice

Licensed under MIT AND Apache-2.0. See the upstream repository for the full text.

Upstream content in this directory remains the copyright of its authors and is
used under MIT AND Apache-2.0. This project retains the original licence text and the
attribution above. See `THIRD_PARTY_NOTICES.md` in the repository root.

## What this project changed

- Excluded `scripts/contrast-checker.py` so the installed set contains zero executable files.
The checker is Python stdlib only and can be reinstated later if a Python interpreter is present.

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