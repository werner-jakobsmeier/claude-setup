#!/usr/bin/env bash
# Regression suite for block-main-commits.sh. Run after any change to the hook.
# Builds throwaway repos in known branch states, so it never depends on what any
# real project happens to be checked out to.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
HOOK="$PWD/block-main-commits.sh"
pass=0; fail=0
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

mkrepo(){ # mkrepo <dir> <branch>
  local d="$tmp/$1"; mkdir -p "$d"; cd "$d"
  git init -q -b main; git config user.email t@t; git config user.name t
  echo a > a; git add -A; git commit -qm init
  [ "$2" = main ] || git switch -qc "$2"
  cd - >/dev/null; printf '%s' "$d"
}
ON_MAIN=$(mkrepo on-main main)
ON_FEAT=$(mkrepo on-feat feat/x)

t(){ # t <name> <expected ALLOW|DENY> <cwd> <command>
  printf '%-52s %-5s' "$1" "$2"
  out=$(jq -nc --arg c "$4" --arg d "$3" '{tool_name:"Bash",cwd:$d,tool_input:{command:$c}}' | "$HOOK" 2>/dev/null)
  r=DENY; case "$out" in *'"deny"'*) ;; *) r=ALLOW ;; esac
  if [ "$r" = "$2" ]; then echo "→ $r  ok"; pass=$((pass+1))
  else echo "→ $r  ** MISMATCH **"; fail=$((fail+1)); fi; }

# the ordering bug: a push from a feature branch that tidies back to main afterwards
t "push from branch, then switch back to main" ALLOW "$ON_FEAT" \
  "cd $ON_FEAT
git push -q origin HEAD
gh pr create --title x
git switch -q main"

t "commit on main"                        DENY  "$ON_MAIN" "cd $ON_MAIN && git commit -m y"
t "bare push while on main"               DENY  "$ON_MAIN" "cd $ON_MAIN && git push -u origin HEAD"
t "switch off main, then commit"          ALLOW "$ON_MAIN" "cd $ON_MAIN && git switch -qc feat/y && git commit -m z"
t "switch TO main, then commit"           DENY  "$ON_FEAT" "cd $ON_FEAT && git switch -q main && git commit -m y"
t "explicit push to main"                 DENY  "$ON_FEAT" "cd $ON_FEAT && git push origin main"
t "push refspec HEAD:main"                DENY  "$ON_FEAT" "cd $ON_FEAT && git push origin HEAD:main"
t "PR body prose mentioning main"         ALLOW "$ON_FEAT" "cd $ON_FEAT && git push -q origin HEAD && gh pr create --body 'reaches main only via PR'"
t "commit message mentioning main"        ALLOW "$ON_FEAT" "cd $ON_FEAT && git commit -m 'stop stray commits on main'"
t "deleting a remote branch"              ALLOW "$ON_FEAT" "cd $ON_FEAT && git push origin --delete old/x"
t "explicit override"                     ALLOW "$ON_MAIN" "cd $ON_MAIN && ALLOW_MAIN=1 git commit -m y"
t "non-git command"                       ALLOW "$ON_MAIN" "cd $ON_MAIN && ls -la"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
