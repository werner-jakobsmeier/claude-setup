#!/bin/bash
# PreToolUse (Bash): refuse a commit on main, or a push that targets main, in ANY
# git repo — every repo here is PR-only.
#
# The real enforcement is the GitHub ruleset (unbypassable). This fires earlier so
# a mistake costs a second at the keyboard rather than a rejected push, and it
# catches the one case a ruleset cannot see: a commit made ON main, which strands
# work on a branch that can never be pushed.
#
# Two lessons are baked in, both from real false positives:
#   * the repo is resolved from an explicit `cd <dir>`, never from a repo name
#     appearing in the command text — a commit message that mentions another repo
#     is not a command against it;
#   * only the git invocation itself is inspected, never the whole command — a
#     heredoc PR body saying "pushes to main" is prose, not a refspec.
#
# Deliberate override: prefix the command with ALLOW_MAIN=1.
set -u
cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)
case "$cmd" in *ALLOW_MAIN=1*) exit 0 ;; esac

# git invocations at a command position (line start, or after && ; | ), each cut
# at the next separator so a following command's words are not read as arguments.
invocations=$(printf '%s\n' "$cmd" \
  | grep -oE '(^|[;&|(]|&&)[[:space:]]*git[[:space:]]+(commit|push)([[:space:]][^&;|]*)?' \
  | sed -E 's/^[;&|(]*[[:space:]]*//')
[ -n "$invocations" ] || exit 0

dir=$(printf '%s\n' "$cmd" \
  | grep -oE '^[[:space:]]*cd[[:space:]]+("[^"]*"|'"'"'[^'"'"']*'"'"'|[^[:space:];&|]+)' \
  | head -1 | sed -E 's/^[[:space:]]*cd[[:space:]]+//; s/^"//; s/"$//; s/^'"'"'//; s/'"'"'$//')
dir=${dir/#\~/$HOME}
dir=${dir//\$HOME/$HOME}
[ -n "$dir" ] && [ -d "$dir" ] || dir="$PWD"

root=$(cd "$dir" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || exit 0
branch=$(cd "$root" && git symbolic-ref --short HEAD 2>/dev/null) || exit 0

# A command may move off main before committing — `git switch -c feat/x && git commit`
# is the correct workflow, not a violation. The hook runs before any of it executes,
# so honour the last branch the command itself switches to.
switched=$(printf '%s\n' "$cmd" \
  | grep -oE 'git[[:space:]]+(switch|checkout)[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*[^[:space:];&|]+' \
  | sed -E 's/.*[[:space:]]//' | grep -vE '^-' | tail -1)
[ -n "$switched" ] && branch="$switched"

blocked=""
while IFS= read -r inv; do
  [ -n "$inv" ] || continue
  case "$inv" in
    "git commit"*)
      [ "$branch" = "main" ] && { blocked="commit on main"; break; }
      ;;
    "git push"*)
      if printf '%s' "$inv" | grep -Eq -- '--delete|[[:space:]]:[A-Za-z]'; then
        :                                                   # deleting a remote branch
      elif printf '%s' "$inv" | grep -Eq -- ':main([[:space:]]|$)|[[:space:]]main([[:space:]]|$)'; then
        blocked="push targeting main"; break
      elif [ "$branch" = "main" ]; then
        blocked="push from main"; break
      fi
      ;;
  esac
done <<< "$invocations"
[ -n "$blocked" ] || exit 0

jq -cn --arg b "$blocked" --arg r "$(basename "$root")" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",
    permissionDecisionReason:("Refusing: " + $b + " in " + $r + ". Every repo is PR-only and main is sealed by a GitHub ruleset, so the server would reject this anyway. Use: git switch -c <type>/<summary>, push, and open a PR. Deliberate override: prefix the command with ALLOW_MAIN=1.")}}'
exit 0
