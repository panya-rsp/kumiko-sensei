# Configure Claude Code for Cheatbook

Add this block to the `CLAUDE.md` file in each project where you use Claude Code. Replace `/absolute/path/to/cheatbook` once.

```md
## Cheatbook visual handoffs

When I ask for a visual explanation, cheatsheet, infographic, presentation,
bento board, PR review pack, or say `handoff to Cheatbook`, write a Markdown handoff using:

```sh
/absolute/path/to/cheatbook/scripts/new-handoff.sh <short-kebab-case-slug>
```

Complete every section in that file. Capture the goal, causal story, evidence
(paths/symbols/commits), before/after behavior, decisions, caveats, and visual
request. Keep it below 900 words. Never include secrets, customer data, or a
full transcript.

After saving it, tell me the exact handoff path and say:
`Open Cheatbook in Codex and ask it to process this handoff and create the requested visual.`

For a PR review pack, set `visual_format: pr-review-pack` and complete its
Reviewer takeaway, Why this matters, Review focus, and PR placement prompts.
After Kumiko-sensei returns the session output, read `pr-review-pack.md`, make
the generated image available to the pull request using this authorized GitHub
session, and insert the generated Markdown at the top of the PR description.
Kumiko-sensei does not have organization GitHub access; do not ask it to edit
the live PR.
```

This is deliberately file-based rather than a direct agent integration:

- It works across separate Claude Code and Codex sessions.
- The handoff is reviewable, versionable, and survives context-window resets.
- Codex can inspect the linked source repository before turning it into a visual.

If your project already has a `CLAUDE.md`, merge the block rather than replacing existing instructions.
