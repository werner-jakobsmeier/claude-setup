#!/usr/bin/env bash
# PreToolUse gate: refuse app-code writes into an ~/dev/projects/<slug> repo that has no
# accepted plan.md. Enforces the hard rule in ~/dev/CLAUDE.md that a model cannot talk itself out of.
#
# Exit 0 silently = allowed. Exit 2 + deny JSON = blocked.
set -uo pipefail

ROOT="$HOME/dev/projects"
IN=$(cat)

deny() {
  jq -nc --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 2
}

tool=$(printf '%s' "$IN" | jq -r '.tool_name // empty')

# --- collect candidate write targets -------------------------------------------------
paths=()
case "$tool" in
  Write|Edit|MultiEdit|NotebookEdit)
    p=$(printf '%s' "$IN" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
    [ -n "$p" ] && paths+=("$p")
    ;;
  Bash)
    cmd=$(printf '%s' "$IN" | jq -r '.tool_input.command // empty')
    # Heredoc bodies are stdin data, not shell syntax — a Markdown '>' or a path named in
    # prose there is not a redirect. Strip each body (keeping the opening line, which may
    # carry a real redirect) before anything scans the command.
    cmd=$(printf '%s' "$cmd" | perl -0777 -pe "s/(<<-?\\s*([\"']?)(\\w+)\\2[^\\n]*\\n).*?^\\s*\\3\\s*\$\\n?/\$1/gms" 2>/dev/null || printf '%s' "$cmd")
    # a '>' inside a quoted string is not a redirect — drop quoted spans before looking for one,
    # so `grep 'a > b' src/` is not mistaken for a write
    bare=$(printf '%s' "$cmd" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")
    # only inspect commands that actually write; reading is always fine
    printf '%s' "$bare" | grep -qE '(>>?[[:space:]]*[^|&>]|[[:space:]]tee[[:space:]]|sed[[:space:]]+-i|cp[[:space:]]|mv[[:space:]]|install[[:space:]]|touch[[:space:]])' || exit 0
    # absolute paths anywhere in the command (covers quoted redirect targets too)
    while IFS= read -r m; do [ -n "$m" ] && paths+=("$m"); done < <(
      printf '%s' "$cmd" | grep -oE "(${HOME//\//\\/}|~)/dev/projects/[A-Za-z0-9._/-]+" | sed "s|^~|$HOME|"
    )
    # relative redirect targets, resolved against the session cwd (`cd project && echo x > src/y`).
    # Read from the RAW command with a quote-aware capture: stripping a quoted target first
    # would leave the '>' to re-pair with a later token — that is how `2>&1` was misread as a
    # file named "2", and a Markdown '> The ...' line as a file named "The".
    cwd=$(printf '%s' "$IN" | jq -r '.cwd // empty')
    if [ -n "$cwd" ]; then
      while IFS= read -r m; do
        m=${m#\"}; m=${m%\"}; m=${m#\'}; m=${m%\'}
        [ -n "$m" ] || continue
        case "$m" in /*|~*|\$*) ;; *) paths+=("$cwd/$m") ;; esac
      done < <(
        printf '%s' "$cmd" \
          | grep -oE ">>?[[:space:]]*(\"[^\"]*\"|'[^']*'|[A-Za-z0-9._~/-]+)" \
          | sed -E "s/^>>?[[:space:]]*//"
      )
    fi
    ;;
  *) exit 0 ;;
esac

[ ${#paths[@]} -eq 0 ] && exit 0

# --- classify each target -------------------------------------------------------------
for raw in "${paths[@]}"; do
  case "$raw" in
    /*) path="$raw" ;;
     ~*) path="$HOME${raw#\~}" ;;
      *) path="$(pwd)/$raw" ;;
  esac

  case "$path" in "$ROOT"/*) ;; *) continue ;; esac   # outside ~/dev/projects — not ours

  rest=${path#"$ROOT"/}
  slug=${rest%%/*}
  # A match on the project root itself (e.g. a bare `cd` into the repo) is a directory reference,
  # not a file write. Without this, sub falls back to the slug and never matches the exemptions below,
  # so any command that merely mentions the repo root reads as an app-code write.
  case "$rest" in */*) sub=${rest#*/} ;; *) continue ;; esac
  [ "$slug" = "_project-template" ] && continue
  [ -d "$ROOT/$slug/docs" ] || continue              # not an SDLC project

  # documentation, config and VCS are never gated — only app code is
  case "$sub" in
    docs/*|.claude/*|.git/*|.githooks/*|.github/*|scripts/setup.sh) continue ;;
    CLAUDE.md|REVIEW.md|README.md|CONTRIBUTING.md|.gitignore|LICENSE) continue ;;
  esac

  # is there an accepted plan? \baccepted\b, so "awaiting acceptance" does not count
  found_plan=0; accepted=0
  for plan in "$ROOT/$slug"/docs/features/*/plan.md; do
    [ -f "$plan" ] || continue
    found_plan=1
    if grep -qiE '^\*\*Status\*\*:.*\baccepted\b' "$plan"; then accepted=1; break; fi
  done
  [ "$accepted" -eq 1 ] && continue

  if [ "$found_plan" -eq 0 ]; then
    deny "Blocked by the SDLC plan gate: '$slug' has no plan.md, and this writes app code ($sub).
~/dev/CLAUDE.md: never write code before an accepted plan.md. Run the /sdlc skill to find which gate is open.
Docs under docs/ are not gated — scaffolding a repo's docs is not code."
  else
    deny "Blocked by the SDLC plan gate: '$slug' has a plan.md, but no '**Status**: ... accepted' line.
Written is not accepted. Show Werner the plan and get explicit approval, then stamp the status line.
This writes app code ($sub); docs under docs/ are not gated."
  fi
done
exit 0
