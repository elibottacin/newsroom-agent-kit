# Provenance of this fork

This directory is a **modified copy** maintained by the `newsroom-agent-kit`
project. It is not a verbatim upstream export.

## Upstream

- Repository: https://github.com/social-media-skills/skills
- Commit: `6e30eeb2f6736bda8683b6bbaa674af3641d7945`
- Commit date: 2026-07-19
- Upstream path: `skills/community-management`
- Licence: MIT

## Licence notice

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, subject to the conditions of the MIT licence.

Upstream content in this directory remains the copyright of its authors and is
used under MIT. This project retains the original licence text and the
attribution above. See `THIRD_PARTY_NOTICES.md` in the repository root.

## What this project changed

- Removed every reference to a specific commercial product and its capability claims.
Recast product limits as statements about the human's own toolchain and the agent's role.
Deleted the upstream `evals/` fixtures, which were written against that product and are not used at runtime.
Repointed references to sibling skills that are installed under a different name in this kit.

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