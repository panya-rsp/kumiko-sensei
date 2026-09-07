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
repo_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
destination="$repo_dir/handoffs/inbox/$slug.md"

mkdir -p "$(dirname -- "$destination")"

if [ -e "$destination" ]; then
  echo "Handoff already exists: $destination" >&2
  exit 1
fi

sed \
  -e "s/^title: \"\"/title: \"$slug\"/" \
  -e "s/^slug: \"\"/slug: \"$slug\"/" \
  -e "s/^created_at: \"YYYY-MM-DD\"/created_at: \"$(date +%F)\"/" \
  "$repo_dir/handoffs/TEMPLATE.md" > "$destination"

echo "Created $destination"
