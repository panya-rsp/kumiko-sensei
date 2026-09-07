# Media library

Use a session capsule for every completed visual story. It keeps the source knowledge, the factual brief, and all generated variants together.

```text
sessions/
  2026-09-07--edge-swipe-fix/
    handoff.md          # Claude Code's factual transfer
    visual-brief.md     # Codex's verified visual plan
    pr-review-pack.md   # Optional: PR-ready TL;DR and reviewer guide
    media/
      v1-cheatsheet.png
      v2-cheatsheet.png
    artifact/
      index.html        # Optional: Claude Code's live implementation
    revisions.md        # Optional: requested changes and decisions
```

## Naming

- **Session ID:** `YYYY-MM-DD--short-kebab-case-topic`
- **Media:** `v<revision>-<format>.<extension>`, such as `v1-infographic.png`
- **Multi-page media:** `v<revision>/<two-digit-page>-<section>.<extension>`, such as `v1/01-problem.png`
- **Formats:** `infographic`, `cheatsheet`, `bento`, `presentation`
- **PR review packs:** `pr-review-pack.md` plus a single supporting image, normally named `v<revision>-pr-review-pack.png`

## Initial lifecycle

1. Claude Code creates a handoff in `handoffs/inbox/`.
2. Codex creates `sessions/<session-id>/`, moves the handoff there, and writes `visual-brief.md`.
3. Codex saves generated media into that session's `media/` directory.
4. The inbox entry is archived after delivery; the session capsule remains the searchable record.

## Live artifacts

When explicitly requested, Claude Code may turn `visual-brief.md` and the generated media into a live artifact in `artifact/`. Default to a self-contained `index.html` with local CSS and JavaScript so it is easy to open, share, and revise. Use a framework only when the visual brief or user specifically requires it.

Codex owns the factual visual brief and generated image assets. Claude Code owns the requested implementation. The user must explicitly request the build; a handoff alone never creates executable artifacts.

## PR review packs

Use `visual_format: pr-review-pack` for a consequential pull request that needs a human-friendly top-of-description summary. Kumiko-sensei writes the PR-ready Markdown and stores the visual in the session; it has no GitHub access and never changes the pull request.

Claude Code, using its authorized organization session, is the final relay: it reads `pr-review-pack.md`, uploads or otherwise makes the generated media available to the pull request, and inserts the generated Markdown at the top of the description. Keep the detailed implementation narrative below the review pack, preferably in a collapsed section. The visual should explain the model; exact claims, caveats, links, and review targets remain selectable Markdown.

## Automated relay

`scripts/ask-kumiko.sh <slug>` is the bridge used by the global Claude Code skill. It launches `codex exec` against the handoff, supplies the current source project for read-only evidence verification, and waits for the final Codex report. Claude Code then returns the completed media paths in the same session.

The existing `handoffs/` directories remain the simple exchange mailbox. `sessions/` is the permanent library, so the workflow can later add a gallery, metadata index, or multiple visual variants without changing the contract between agents.

## Presentations and page sequences

Use `## Section plan` in the handoff whenever the output should be multiple images. Name the pages in their intended order and state what each must teach. Kumiko-sensei turns that list into a coordinated sequence: one section per image, consistent visual language across pages, and no pressure to fit the entire story into a single canvas.
