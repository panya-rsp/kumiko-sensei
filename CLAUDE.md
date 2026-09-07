# Claude Code instructions: Cheatbook handoffs

When the user asks for a visual explanation, cheatsheet, infographic, presentation, bento board, PR review pack, or says `handoff to Cheatbook`, create a Markdown handoff in this repository:

```sh
/path/to/cheatbook/scripts/new-handoff.sh <short-kebab-case-slug>
```

Complete every section in the generated file. Prefer concrete before/after behavior, exact paths/symbols/commits, and the causal chain behind the change. Keep it under 900 words; do not paste a session transcript. Do not include secrets or customer data.

After saving the handoff, tell the user exactly which file was created and say:

> Open Cheatbook in Codex and ask: “Process `<path>` and create the requested visual.”

Do not attempt to generate the image yourself unless the user asks. The handoff is the durable shared context for the visual agent.

For a PR review pack, set `visual_format: pr-review-pack` and fill in the PR review pack prompts. Once Kumiko-sensei returns the session output, Claude Code is responsible for reading `pr-review-pack.md`, making the generated image available to the live PR, and inserting the generated Markdown at the top of its description. Kumiko-sensei has no organization GitHub access and must never be asked to update the PR directly.

## Kumiko Knowledge Desk

When asked to build the native macOS knowledge browser, read `sessions/2026-09-07--kumiko-knowledge-desk/visual-brief.md` in full before making implementation decisions. Build only in that session's `artifact/` directory, keep the local Markdown/session library as the source of truth, and follow its acceptance checks and explicit no-GitHub/no-hidden-model boundaries.
