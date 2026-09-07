# Cheatbook agent instructions

This repository is a shared, file-based handoff channel between coding agents and Codex.

When asking the locally installed Claude Code agent to review or enrich a handoff, use its default Opus model first. If it is unavailable, fall back to the latest Sonnet model, then Haiku.

When asked to process a handoff:

1. Read the named file from `handoffs/inbox/`, or choose the most recently modified Markdown file there.
2. Treat it as a claim that must be checked against its listed evidence when the source repository is accessible.
3. Create `sessions/<YYYY-MM-DD--slug>/`, preserve the source as `handoff.md`, and write a concise factual visual brief to `visual-brief.md` before generating an image.
4. Use the requested format unless it would obscure the story; state any format change in the brief.
5. Generate images only when explicitly asked, and save them in that session's `media/` directory using the versioned naming convention in `docs/media-library.md`.
6. Move the inbox handoff to `handoffs/archive/` only after the session's visual brief and requested output exist.

When the user wants Claude Code to implement a live artifact, include an `## Live artifact` section in `visual-brief.md` describing the intended interaction, content hierarchy, visual style, assets, and acceptance checks. Claude Code builds it only on the user's explicit request in `sessions/<session-id>/artifact/`.

For `visual_format: pr-review-pack`, also write `sessions/<session-id>/pr-review-pack.md`. It must provide a reviewer TL;DR, what changed, and a concrete review guide alongside the generated visual. Kumiko-sensei never accesses or updates a live organization PR: Claude Code uses its authorized session to publish the media and insert the generated Markdown into the PR description.

If a requested visual has no clear format or style, ask the user before finalizing the handoff or generating media. Confirm the format (infographic, cheatsheet, bento, presentation, or other), orientation, audience, and visual tone.

Do not put secrets, full chat transcripts, or unverified implementation claims in visual briefs.
