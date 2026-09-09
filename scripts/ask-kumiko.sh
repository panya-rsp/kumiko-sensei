#!/bin/sh

set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <short-kebab-case-slug>" >&2
  exit 1
fi

slug=$1
case "$slug" in
  *[!a-z0-9-]* | -* | *- | *--* | "")
    echo "Slug must use lowercase letters, numbers, and single hyphens." >&2
    exit 1
    ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cheatbook_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
source_dir=$(pwd -P)
handoff="$cheatbook_dir/handoffs/inbox/$slug.md"
agent_file="$cheatbook_dir/skills/kumiko-sensei/SKILL.md"

if [ ! -f "$handoff" ]; then
  echo "Handoff not found: $handoff" >&2
  exit 1
fi

if [ ! -f "$agent_file" ]; then
  echo "Kumiko-sensei contract not found: $agent_file" >&2
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "Codex CLI is not available on PATH." >&2
  exit 1
fi

prompt="Read and follow the Kumiko-sensei agent contract at $agent_file. Process the handoff at $handoff. The source project is $source_dir and is available only for evidence verification; do not modify it. This relay is explicit user authorization to generate the requested visual output."

exec codex exec \
  -C "$cheatbook_dir" \
  --add-dir "$source_dir" \
  --sandbox workspace-write \
  "$prompt"
