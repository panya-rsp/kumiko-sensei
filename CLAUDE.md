# Claude Code instructions: Cheatbook handoffs

When the user asks for a visual explanation, cheatsheet, infographic, presentation, bento board, PR review pack, or says `handoff to Cheatbook`, create a Markdown handoff in this repository:

```sh
/path/to/cheatbook/scripts/new-handoff.sh <short-kebab-case-slug>
```

Complete every section in the generated file. Prefer concrete before/after behavior, exact paths/symbols/commits, and the causal chain behind the change. Keep it under 900 words; do not paste a session transcript. Do not include secrets or customer data.

After saving the handoff, immediately run the relay and wait for it to finish:

```sh
/path/to/cheatbook/scripts/ask-kumiko.sh <short-kebab-case-slug>
```

Report the returned session and media paths. If the relay cannot run because the Codex CLI is unavailable or a permission is required, report that exact blocker and provide the handoff path as a manual fallback. Do not claim that processing happened if the relay failed.

Do not generate the image yourself unless the user asks. The handoff is the durable shared context for the visual agent.

For a PR review pack, set `visual_format: pr-review-pack` and fill in the PR review pack prompts. Once Kumiko-sensei returns the session output, Claude Code is responsible for reading `pr-review-pack.md`, making the generated image available to the live PR, and inserting the generated Markdown at the top of its description. Kumiko-sensei has no organization GitHub access and must never be asked to update the PR directly.

## Kumiko Sensei (mac app)

The native macOS knowledge browser lives in `app/` at the repo root (Xcode project, sources, tests, `Tools/`). When asked to build or change it, read `sessions/2026-09-07--kumiko-knowledge-desk/visual-brief.md` in full before making implementation decisions. Keep the local Markdown/session library as the source of truth, and follow the brief's acceptance checks and explicit no-GitHub/no-hidden-model boundaries.
