#!/usr/bin/env bash
# Symlink this repo's config into place. Idempotent; refuses to clobber real files.
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link(){ # link <source> <target>
  local src="$1" tgt="$2"
  if [ -L "$tgt" ]; then
    [ "$(readlink "$tgt")" = "$src" ] && { echo "  ok      $tgt"; return; }
    echo "  RELINK  $tgt"; rm "$tgt"
  elif [ -e "$tgt" ]; then
    echo "  SKIP    $tgt already exists and is not a symlink — move it aside first" >&2; return
  else
    echo "  LINK    $tgt"
  fi
  mkdir -p "$(dirname "$tgt")"; ln -s "$src" "$tgt"
}

link "$R/dev/CLAUDE.md"      "$HOME/dev/CLAUDE.md"
link "$R/project-template"   "$HOME/dev/projects/_project-template"
for s in "$R"/claude/skills/*/; do
  link "${s%/}" "$HOME/.claude/skills/$(basename "$s")"
done
echo "done."
