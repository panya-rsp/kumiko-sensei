# Configure Claude Code for Cheatbook

Cheatbook owns the Claude Code relay and the Codex skill. Replace `/absolute/path/to/cheatbook` below with the checkout path.

## Install the Codex skill

Copy the repository-owned skill into your Codex skills directory:

```sh
skill_dir="${CODEX_HOME:-$HOME/.codex}/skills/kumiko-sensei"
mkdir -p "$skill_dir"
cp -R /absolute/path/to/cheatbook/skills/kumiko-sensei/. "$skill_dir/"
```

Re-run the copy command after pulling changes to the skill. The source of truth is [`../skills/kumiko-sensei/SKILL.md`](../skills/kumiko-sensei/SKILL.md).

## Configure Claude Code

Add this block to the `CLAUDE.md` file in each project where you use Claude Code:

~~~md
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

After saving it, run the relay and wait for it to finish:

```sh
/absolute/path/to/cheatbook/scripts/ask-kumiko.sh <short-kebab-case-slug>
```

Then report the returned session and media paths. If the relay cannot run because the Codex CLI is unavailable or a permission is required, report that exact blocker and give the user the handoff path as a manual fallback; do not silently claim that processing happened.

For a PR review pack, set `visual_format: pr-review-pack` and complete its
Reviewer takeaway, Why this matters, Review focus, and PR placement prompts.
After Kumiko-sensei returns the session output, read `pr-review-pack.md`, make
the generated image available to the pull request using this authorized GitHub
session, and insert the generated Markdown at the top of the PR description.
Kumiko-sensei does not have organization GitHub access; do not ask it to edit
the live PR.
~~~

This remains file-based while the relay starts processing automatically:

- It works across separate Claude Code and Codex sessions.
- The handoff is reviewable, versionable, and survives context-window resets.
- Codex can inspect the linked source repository before turning it into a visual.
- Claude Code does not leave the user to manually trigger a second request after creating the handoff.

If your project already has a `CLAUDE.md`, merge the block rather than replacing existing instructions.
