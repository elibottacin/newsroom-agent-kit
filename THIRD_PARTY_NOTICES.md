# Third-party notices

This repository redistributes or installs content from the projects below. The
`newsroom-agent-kit` project does not claim ownership of any of it.

Two distribution modes appear:

- **Vendored fork** — a modified copy lives in `vendor/skills/<name>`. Each one has its own
  `PROVENANCE.md` recording the upstream repository, the exact commit, the licence, and precisely
  what was changed.
- **Pinned fetch** — installed verbatim from the commit pinned in `manifest/skills.json`. The
  commit is the reviewed artifact; nothing is executed.

Attribution and licence texts are reproduced in each vendored skill's `PROVENANCE.md`.

## Summary

| Project | Licence | Skills | Mode |
|---|---|---|---|
| [jamditis/claude-skills-journalism](https://github.com/jamditis/claude-skills-journalism) | MIT | 6 | pinned fetch |
| [social-media-skills/skills](https://github.com/social-media-skills/skills) | MIT | 25 | **vendored fork** |
| [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | Apache-2.0 | 1 | **vendored fork**, instruction layer only |
| [PracticalSwan/agent-skills](https://github.com/PracticalSwan/agent-skills) | MIT AND Apache-2.0 | 2 | 1 pinned fetch, 1 **vendored fork** |
| [blacktwist/social-media-skills](https://github.com/blacktwist/social-media-skills) | MIT | 3 | pinned fetch |
| [Nutlope/hallmark](https://github.com/Nutlope/hallmark) | MIT | 1 | pinned fetch |
| [affaan-m/ecc](https://github.com/affaan-m/ecc) | MIT | 1 | pinned fetch, single directory only |
| [stevysmith/og-image-skill](https://github.com/stevysmith/og-image-skill) | **none found** | 1 | pinned fetch — see risk note below |

## Licence texts

### MIT

> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
> associated documentation files (the "Software"), to deal in the Software without restriction,
> including without limitation the rights to use, copy, modify, merge, publish, distribute,
> sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or
> substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
> NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
> NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
> DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
> OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### Apache License 2.0

> Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
> in compliance with the License. You may obtain a copy of the License at
> <http://www.apache.org/licenses/LICENSE-2.0>
>
> Unless required by applicable law or agreed to in writing, software distributed under the License
> is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
> or implied. See the License for the specific language governing permissions and limitations under
> the License.

### MIT AND Apache-2.0 (PracticalSwan/agent-skills)

That project ships `LICENSE.txt`, `LICENSE-APACHE-2.0.txt`, `LICENSE-GITHUB-MIT.txt` and
`THIRD_PARTY_NOTICES.md` inside each skill directory. Those files are redistributed verbatim with
the vendored copy of `frontend-design`.

## Modifications made by this project

Only the vendored forks were modified. The changes fall into three kinds, all recorded per skill in
`vendor/skills/<name>/PROVENANCE.md`:

1. **Product references removed.** Upstream `social-media-skills` skills were written around a
   commercial product. Claims about that product's capabilities were replaced with statements about
   the human's own toolchain and the agent's role. All craft guidance and safety rules were kept.
   See `docs/security.md` SEC-07.
2. **Executable content excluded.** `impeccable` was reduced to its instruction layer because its
   launcher downloads a binary on first run. `frontend-design` was reduced to `SKILL.md`,
   `references/` and its licence files, dropping a Python script, so that the installed set contains
   zero executable files.
3. **Fixtures and dangling pointers removed.** Upstream `evals/` directories were deleted because
   they are not used at runtime. Sibling-skill references were repointed to the names this kit
   actually installs. References to files that do not exist upstream were removed rather than left
   dangling.

The MIT licence permits modification provided the copyright notice and permission notice are
retained. Both are preserved: the licence text is reproduced above and in each `PROVENANCE.md`, and
every fork records its upstream repository, commit and author-facing attribution.

## Accepted licence risk

`og-image`, from `stevysmith/og-image-skill`, is installed from a repository that has **no LICENSE
file** at the pinned commit. Default copyright therefore applies and there is no grant of
redistribution rights.

This was brought to the user's attention and **explicitly accepted on 2026-10-04**. It is the only
such entry in the default install set. If upstream ever adds a licence, re-evaluate it. If this
repository is ever published and distribution of that one skill becomes a problem, removing it is a
one-line manifest change.

See `docs/security.md` SEC-01 and SEC-03.