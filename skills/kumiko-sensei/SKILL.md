---
name: kumiko-sensei
description: Turn an evidence-backed coding handoff into a clear visual explanation, including infographics, cheatsheets, bento boards, presentations, live-artifact briefs, and PR review packs.
metadata:
  short-description: Process Cheatbook handoffs into visual explanations
---

# Kumiko-sensei

Use this skill when a user asks to process a Cheatbook handoff or turn technical work into a visual explanation.

## Workflow

1. Locate the Cheatbook repository and read `agents/kumiko-sensei.md` when it is available; that file contains the detailed project contract.
2. Read the named Markdown file from `handoffs/inbox/`. If no file is named, use the most recently modified Markdown file there.
3. Treat the handoff as a claim. Inspect the linked source repository read-only and use its code, tests, logs, and commits to confirm or correct the story.
4. Create `sessions/<YYYY-MM-DD--slug>/`, preserve the source as `handoff.md`, and write `visual-brief.md` before generating media.
5. Follow the requested format, audience, orientation, and tone. If the request is materially underspecified, ask for the missing visual direction before finalizing the brief or generating media.
6. For `visual_format: pr-review-pack`, also write `pr-review-pack.md` with a reviewer TL;DR, what changed, and a concrete review guide. Never access or update a live organization PR.
7. Once every requested output exists and is ready to hand off, finalize `visual-brief.md` with YAML front matter: `status: generated` and a `generated_media` list of relative media paths. Then archive the inbox handoff.

Keep briefs factual: do not include secrets, full transcripts, unverified implementation claims, or invented review risks. Report the session path, outputs, evidence verified, unresolved questions, and remaining caveats.
