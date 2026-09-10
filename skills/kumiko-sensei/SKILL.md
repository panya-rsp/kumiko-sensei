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

## Revisions

When the relay names a session instead of an inbox handoff, read `sessions/<id>/revisions.md`. Each `## media/...` heading names one existing image and its `- [ ]` items are the user's feedback on that image, written while reviewing it in Kumiko Sensei.

1. Regenerate only the images that have open items, into the next `media/v<N+1>/` folder with the same page file name. Leave earlier versions in place.
2. Tick each addressed item to `- [x]` and append ` → v<N+1>: <one line on what changed>`. Leave an item open, with a short note, if it conflicts with the evidence.
3. Update `generated_media` in `visual-brief.md` to list the new paths, keep `status: generated`, and report which images changed.

Keep briefs factual: do not include secrets, full transcripts, unverified implementation claims, or invented review risks. Report the session path, outputs, evidence verified, unresolved questions, and remaining caveats.
