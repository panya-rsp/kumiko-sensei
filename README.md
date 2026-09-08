# Kumiko Sensei

<p align="center">
  <img src="./kumiko-sensei-mascot.png" alt="Kumiko Sensei mascot" width="280" />
</p>

Kumiko Sensei is the visual storytelling guide behind this repo, helping engineering teams turn dense technical work into clear, memorable communication.  
She acts like a product-savvy design partner: taking structured handoffs from coding sessions and shaping them into infographics, cheatsheets, bento boards, presentation visuals, and PR review packs.  
Her role is to preserve technical accuracy while making the story easier for reviewers, teammates, and stakeholders to scan quickly.  
With Kumiko Sensei in the loop, teams spend less time rewriting context and more time shipping with shared understanding.  
This repository is the operating space where that handoff-to-visual workflow happens.

## The workflow

```text
Claude Code session
  -> writes handoffs/inbox/<slug>.md
  -> you say: “Process the latest Cheatbook handoff”
  -> Codex reads the handoff and relevant repository evidence
  -> writes handoffs/visual-briefs/<slug>.md
  -> generates the requested visual in assets/generated/
```

The handoff file is the source of truth. It lets either agent resume with the same context without copying a long chat transcript between products.

Completed work is preserved as a session capsule; see [`docs/media-library.md`](docs/media-library.md) for the layout and naming convention.

For presentation work, add a `Section plan` to the handoff. Kumiko-sensei generates each named section as its own consistent image page rather than squeezing the full story into one image.

For an interactive or browser-openable version of a visual, explicitly ask Claude Code to build the session's live artifact. Claude reads the visual brief from the session and writes the implementation to `artifact/`; it never creates code merely because a handoff exists.

For an important pull request, request a **PR review pack**. Kumiko-sensei returns a PR-ready TL;DR, a scannable visual mental model, and a concrete review guide in the session capsule. Claude Code—using its authorized organization session—then uploads the asset and updates the live PR; Kumiko-sensei never needs GitHub access.

The request to Claude Code can be as direct as: “Create a Cheatbook PR review pack for this PR, then use the returned package to update the PR description.” The relay is explicit: no PR is changed merely because a handoff was created.

## Start a handoff

From the repository that contains the work being explained:

```sh
/path/to/cheatbook/scripts/new-handoff.sh edge-swipe-fix
```

Fill in the created file in `handoffs/inbox/`. The required sections are intentionally short: goal, story, evidence, before/after, decisions, caveats, and visual request.

Then ask Codex:

> Process `handoffs/inbox/edge-swipe-fix.md` and create the requested visual.

Or, if Cheatbook is the current workspace:

> Process the latest Cheatbook handoff.

When the handoff comes from the global Claude Code skill, it can launch Codex and wait for the result automatically. Say “Ask Kumiko-sensei to explain this visually” or run `/kumiko-sensei <slug>`; no separate manual Codex prompt is needed.

The visual agent's maintainable contract lives in [`agents/kumiko-sensei.md`](agents/kumiko-sensei.md). Update that file to evolve Kumiko-sensei; the launcher only points Codex to it.

Not sure what to request? Browse [`docs/kumiko-capabilities.md`](docs/kumiko-capabilities.md) or ask Kumiko-sensei to recommend a format for the handoff.

## Claude Code setup

Copy the contents of [`docs/claude-code-setup.md`](docs/claude-code-setup.md) into the target project's `CLAUDE.md` (or merge it with your existing instructions). It tells Claude Code exactly when and how to create a handoff. No API key, MCP server, or direct cross-agent connection is required.

## Handoff lifecycle

- `handoffs/inbox/`: ready for Codex to digest.
- `handoffs/in-progress/`: actively being turned into a visual.
- `handoffs/archive/`: completed handoffs retained as project memory.
- `handoffs/visual-briefs/`: the factual, image-generation-ready brief produced by Codex.
- `assets/generated/`: final image outputs.

Keep handoffs free of credentials, production data, or private customer information. Use links, file paths, commit IDs, and concise summaries instead of transcripts.
