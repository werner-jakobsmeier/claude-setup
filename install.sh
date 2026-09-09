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
for a in "$R"/claude/agents/*.md; do
  link "$a" "$HOME/.claude/agents/$(basename "$a")"
done

# Hooks live in settings.json, which is not a symlink (Claude Code writes to it).
# Merge our fragment in instead, substituting the repo's real path. Idempotent.
settings="$HOME/.claude/settings.json"
[ -f "$settings" ] || echo '{}' > "$settings"
frag=$(mktemp); merged=$(mktemp)
sed "s|__REPO__|$R|" "$R/claude/settings-hooks.json" > "$frag"
# `jq '.[0] * .[1]'` deep-merges objects but REPLACES arrays, and hooks live in
# arrays — so any hook entry in settings.json that this fragment does not also
# declare is silently dropped. That has actually happened: a hook added by hand
# vanished on the next install with no warning. Name the casualties first.
dropped=$(jq -r --slurpfile f "$frag" '
  [ .hooks // {} | to_entries[] | .key as $ev | .value[]?.hooks[]?.command ] as $have
  | [ $f[0].hooks // {} | to_entries[] | .value[]?.hooks[]?.command ] as $keep
  | $have - $keep | .[]' "$settings" 2>/dev/null | sed "s|^|    |")
if [ -n "$dropped" ]; then
  echo "  WARN    these hooks are in settings.json but not in settings-hooks.json;" >&2
  echo "          the merge below will remove them. Add them to the fragment to keep them:" >&2
  echo "$dropped" >&2
fi
if jq -s '.[0] * .[1]' "$settings" "$frag" > "$merged" 2>/dev/null; then
  if [ "$(jq -S . "$settings")" = "$(jq -S . "$merged")" ]; then echo "  ok      $settings (hooks already merged)"
  else cp "$settings" "$settings.bak-$(date +%Y%m%d-%H%M%S)"
       mv "$merged" "$settings"; echo "  MERGE   $settings (hooks; previous backed up)"; fi
else
  echo "  SKIP    $settings — could not parse, merge the hooks block by hand" >&2
fi
rm -f "$frag" "$merged"
echo "done."
