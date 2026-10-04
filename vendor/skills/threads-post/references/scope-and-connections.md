# Scope, distinctions + connections

threads-post is a **format-execution skill** — it writes a Threads-native conversation post (built to earn
replies) **and** carries the Threads publish facts. The agent writes the **post + topic tag +
media direction + reply angles**; a human **publishes and schedules the single post** with whichever tool
the newsroom uses; the **replying that drives reach is human**.

## Honest scope (never violate)
- **ONE Threads post per publish** (≤500 chars of text + optional image/video). **No separate link
  field** (links go inline), **no polls / voice notes / GIFs** (native-app only), and **no multi-post
  chain** (that's `thread-writer-sms`).
- **No reply/engagement surface** → the **replying that actually drives Threads reach is a human job**
  (`community-management`). The agent can draft reply angles; a person sends them.
- **Edits are delete + recreate, never edit-in-place** — a queued post can only be changed while it is
  still pending; once it has published, changes mean deleting it and posting again.
- **No engagement bait** (algorithm-penalized + dishonest); **no press-release/promo tone** (suppressed).
  **Never promise a reach multiple** (organic is tightening as ads roll out) and **never fabricate metrics**
  — native analytics only. **Verify-quarterly** (`references/threads-2026-reality.md`).

## Distinct from its siblings
- **threads-post (this)** — the **Threads-native conversation post** + the Threads publish facts.
- **thread-writer** — the **multi-post chain**; a user who says "write a thread" means that, not this.
  This skill produces ONE Threads post.
- **x-growth** — the **sibling text platform with a different culture**: X is real-time/credit-metered with
  **links pushed to the reply**; Threads is conversation/reply-driven with **links rewarded inline.** Don't
  cross-post the same text.
- **caption-writer** / **hook-writer** — supply the **post line** this skill builds into a Threads post.
- **community-management** — the **replies** (the half of Threads that wins reach).
- per-platform **strategy/growth** skills — the broader channel strategy; this is the post-level execution.

## Where this connects
- **Reads first:** `brand-profile` (niche/voice), `goals-and-kpis` (replies / profile visits / follower growth).
- **Copy:** `hook-writer` (the take/question), `caption-writer-sms` (the line + reply prompt), `brand-profile` (voice).
- **Media:** `image-prompt`/`ideogram`/`nano-banana` (a supporting photo), the `video`
  cluster (short clip).
- **Publish:** `scheduling-and-queue` (queue the single Threads post for a human to publish to a
  velocity window), `platform-specs-and-validation` (validate + the field rules),
  `content-calendar` (cadence).
- **Engage/measure:** `community-management` (the reply work), `analytics-and-reporting` (replies/reach/
  profile-visits readout), `experimentation-and-ab-testing` (A/B hooks/post times). **Replies + polls/voice stay native.**
