#!/usr/bin/env bash
# Scaffold a project the same way every time.
# Usage:
#   new-project.sh init <slug> "<Title>"    create the vault design folder (README + intent skeleton)
#   new-project.sh repo <slug> "<Title>"    create the repo docs skeleton and move the chain into it
#   new-project.sh sync <slug> [--apply]    re-stamp template files into an existing repo (dry run unless --apply)
set -euo pipefail

TEMPLATE="$HOME/dev/projects/_project-template"
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/The Brain/01 Projects"
CODE="$HOME/dev/projects"

die(){ echo "error: $*" >&2; exit 1; }

# Files the project fills in with its own content. Sync will create them if missing, but never
# overwrites or reports them — differing from the template stub is their expected state.
SEEDED="CLAUDE.md CONTRIBUTING.md docs/architecture.md docs/data-model.md"
is_seeded(){ case " $SEEDED " in *" $1 "*) return 0;; *) return 1;; esac; }
stamp(){ sed -i '' -e "s|{{SLUG}}|$1|g" -e "s|{{TITLE}}|$2|g" "$3"; }

cmd="${1:-}"; slug="${2:-}"; title="${3:-}"
[ -n "$cmd" ] && [ -n "$slug" ] || die "usage: new-project.sh {init|repo} <slug> \"<Title>\""
[[ "$slug" =~ ^[a-z0-9-]+$ ]] || die "slug must be lowercase-kebab (playbook convention)"
[ -n "$title" ] || title="$slug"

case "$cmd" in
  init)
    dest="$VAULT/$slug"
    [ -e "$dest" ] && die "$dest already exists"
    mkdir -p "$dest"
    cp "$TEMPLATE/vault/README.md" "$TEMPLATE/vault/intent.md" "$dest/"
    for f in "$dest"/*.md; do stamp "$slug" "$title" "$f"; done
    echo "vault folder ready: 01 Projects/$slug"
    echo "next: write intent.md, get it accepted, then spec.md and plan.md"
    ;;
  repo)
    dest="$CODE/$slug"
    [ -e "$dest/docs" ] && die "$dest/docs already exists"
    mkdir -p "$dest"
    cp -R "$TEMPLATE/repo/." "$dest/"
    find "$dest/CLAUDE.md" "$dest/REVIEW.md" "$dest/docs" -name '*.md' -print0 |
      while IFS= read -r -d '' f; do stamp "$slug" "$title" "$f"; done
    # migrate the chain out of the vault: the repo owns it once the repo exists
    # Vault folders are slug-named by convention, but projects predating it are
    # title-cased. Resolve both rather than silently migrating nothing.
    vdir="$VAULT/$slug"
    if [ ! -d "$vdir" ]; then
      alt="$(find "$VAULT" -maxdepth 1 -type d -iname "$(echo "$slug" | tr '-' ' ')" | head -1)"
      [ -n "$alt" ] && vdir="$alt" && echo "  vault folder resolved by title: $(basename "$vdir")"
    fi
    [ -d "$vdir" ] || echo "  warning: no vault folder for '$slug' — nothing to migrate"

    mkdir -p "$dest/docs/features/mvp"
    for a in intent spec plan; do
      src="$vdir/$a.md"
      [ -f "$src" ] || continue
      cp "$src" "$dest/docs/features/mvp/$a.md"
      # Freeze the vault copy. Copying alone would leave two live copies of the
      # same document, which is the exact drift this structure exists to prevent.
      if ! grep -q "Frozen — design-era record" "$src"; then
        tmp="$(mktemp)"
        {
          echo "> [!warning] Frozen — design-era record"
          echo "> The repo owns this document now: \`~/dev/projects/$slug/docs/features/mvp/$a.md\`."
          echo "> This copy is the design-era history and is **not** maintained. Make changes in the repo."
          echo
          cat "$src"
        } > "$tmp"
        mv "$tmp" "$src"
      fi
      echo "  $a.md -> docs/features/mvp/ (vault copy frozen)"
    done
    [ -d "$dest/.git" ] || (cd "$dest" && git init -q && echo "  git initialised")
    # hooks are not cloned, and scripts/setup.sh is easy to forget — wire them now
    (cd "$dest" && git config core.hooksPath .githooks) && echo "  core.hooksPath -> .githooks (no commits or pushes on main)"
    echo "repo docs skeleton ready: ~/dev/projects/$slug"
    echo "next: freeze the vault notes as the design-era record; stack scaffolding is per-project"
    ;;
  sync)
    dest="$CODE/$slug"
    [ -d "$dest" ] || die "$dest does not exist — run 'repo' first"
    apply=0; [ "${3:-}" = "--apply" ] || [ "${4:-}" = "--apply" ] && apply=1
    # recover the title from the existing CLAUDE.md heading unless one was given
    if [ -z "$title" ] || [ "$title" = "$slug" ] || [ "$title" = "--apply" ]; then
      title=$(sed -n '1s/^# //p' "$dest/CLAUDE.md" 2>/dev/null)
      [ -n "$title" ] || title="$slug"
    fi
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
    add=0; upd=0; drift=0
    (cd "$TEMPLATE/repo" && find . -type f ! -name '.gitkeep' | sed 's|^\./||') | while read -r rel; do
      cp "$TEMPLATE/repo/$rel" "$tmp/f"; stamp "$slug" "$title" "$tmp/f"
      if [ ! -f "$dest/$rel" ]; then
        echo "  ADD      $rel"
        [ "$apply" = 1 ] && mkdir -p "$dest/$(dirname "$rel")" && cp "$tmp/f" "$dest/$rel"
      elif cmp -s "$tmp/f" "$dest/$rel"; then
        :
      elif is_seeded "$rel"; then
        : # project-owned and filled in — differing from the stub is the expected state, not drift
      else
        echo "  RESTAMP  $rel"
        [ "$apply" = 1 ] && cp "$tmp/f" "$dest/$rel"
      fi
    done
    if [ "$apply" = 1 ]; then echo "applied to ~/dev/projects/$slug"
    else echo; echo "dry run — nothing changed. re-run with --apply to write."; fi
    ;;
  *) die "unknown command '$cmd'" ;;
esac
