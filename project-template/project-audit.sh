#!/usr/bin/env bash
# Mechanical conformance checks across every project under ~/dev/projects.
# Reports only — never modifies. Judgment-level checks live in the `project-audit` skill.
# Usage: project-audit.sh [slug]        (all projects if no slug given)
set -uo pipefail

TEMPLATE="$HOME/dev/projects/_project-template"
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/The Brain/01 Projects"
CODE="$HOME/dev/projects"

fail=0
say(){ printf '%s\n' "$*"; }
ok(){   printf '  \033[32mok\033[0m       %s\n' "$*"; }
warn(){ printf '  \033[33mWARN\033[0m     %s\n' "$*"; fail=1; }
bad(){  printf '  \033[31mFAIL\033[0m     %s\n' "$*"; fail=1; }
skip(){ printf '  \033[90m--\033[0m       %s\n' "$*"; }   # informational, does not fail the run

audit_project(){
  local slug="$1"
  local dir="$CODE/$slug"
  local vdir="$VAULT/$slug"
  say ""; say "── $slug ───────────────────────────────────"

  [[ "$slug" =~ ^[a-z0-9-]+$ ]] && ok "slug is lowercase-kebab" || bad "slug is not lowercase-kebab"

  # vault ↔ repo pairing
  if [ -d "$vdir" ]; then ok "vault folder exists"; else warn "no vault folder at 01 Projects/$slug"; fi

  # template conformance
  local sync_out; sync_out=$("$TEMPLATE/new-project.sh" sync "$slug" 2>&1 | grep -E '^  (ADD|RESTAMP)' || true)
  if [ -z "$sync_out" ]; then ok "template files up to date"
  else bad "template drift — run: new-project.sh sync $slug --apply"; printf '%s\n' "$sync_out" | sed 's/^/      /'; fi

  # CLAUDE.md actually filled in
  if [ -f "$dir/CLAUDE.md" ]; then
    # only the template's own placeholder text counts as unfilled; a custom comment is deliberate
    local stubs=0 line
    while IFS= read -r line; do
      grep -qxF "$line" "$dir/CLAUDE.md" && stubs=$((stubs+1))
    done < <(grep '^<!-- ' "$TEMPLATE/repo/CLAUDE.md")
    [ "$stubs" -eq 0 ] && ok "CLAUDE.md filled in" || warn "CLAUDE.md has $stubs section(s) still at template default"
  else bad "no CLAUDE.md"; fi

  # ADR hygiene: sequential, no duplicate numbers
  local adrs; adrs=$(ls "$dir/docs/decisions/" 2>/dev/null | grep -E '^[0-9]{4}-' | sort || true)
  if [ -z "$adrs" ]; then warn "no ADRs — are decisions recorded only in intent/spec? those get archived"
  else
    local nums dupes n i=1 gap=0
    nums=$(printf '%s\n' "$adrs" | cut -c1-4)
    dupes=$(printf '%s\n' "$nums" | uniq -d)
    [ -z "$dupes" ] && ok "ADR numbers unique ($(printf '%s\n' "$nums" | wc -l | tr -d ' ') total)" \
                    || bad "duplicate ADR numbers: $(echo $dupes)"
    for n in $nums; do [ "$((10#$n))" -eq "$i" ] || gap=1; i=$((i+1)); done
    [ "$gap" -eq 0 ] && ok "ADR numbering sequential" || warn "ADR numbering has gaps: $(echo $nums)"
  fi

  # chain order per feature
  local f
  for f in "$dir"/docs/features/*/; do
    [ -d "$f" ] || continue
    local name; name=$(basename "$f")
    local hi=0 hs=0 hp=0
    [ -f "$f/intent.md" ] && hi=1; [ -f "$f/spec.md" ] && hs=1; [ -f "$f/plan.md" ] && hp=1
    if   [ $hp -eq 1 ] && [ $hs -eq 0 ]; then bad "feature '$name': plan.md without spec.md"
    elif [ $hs -eq 1 ] && [ $hi -eq 0 ]; then bad "feature '$name': spec.md without intent.md"
    else ok "feature '$name': chain order valid (intent:$hi spec:$hs plan:$hp)"; fi
  done

  # app code without an accepted plan
  if [ -d "$dir/src" ] || [ -f "$dir/package.json" ]; then
    local anyplan; anyplan=$(ls "$dir"/docs/features/*/plan.md 2>/dev/null | head -1)
    [ -n "$anyplan" ] && ok "app code present, and a plan.md exists" \
                      || bad "app code exists but NO plan.md — code was written before its gate"
  fi

  # branching guards — code reaches main only through a pull request
  local hp; hp=$(git -C "$dir" config core.hooksPath 2>/dev/null || true)
  [ "$hp" = ".githooks" ] && ok "core.hooksPath -> .githooks" \
    || bad "core.hooksPath is '${hp:-unset}' — local main guards are INERT. Fix: (cd $dir && ./scripts/setup.sh)"
  local missing=""
  for f in .githooks/pre-commit .githooks/pre-push scripts/setup.sh CONTRIBUTING.md .github/workflows/guard-main.yml; do
    [ -f "$dir/$f" ] || missing="$missing $f"
  done
  [ -z "$missing" ] && ok "branching guard files present" || bad "missing guard files:$missing"
  for f in .githooks/pre-commit .githooks/pre-push scripts/setup.sh; do
    [ -f "$dir/$f" ] && [ ! -x "$dir/$f" ] && bad "$f is not executable — it will never run"
  done
  # the only unbypassable layer: a GitHub ruleset requiring a pull request
  local rem; rem=$(git -C "$dir" remote get-url origin 2>/dev/null || true)
  if [ -n "$rem" ]; then
    local nwo; nwo=$(printf '%s' "$rem" | sed -E 's|^git@github.com:||; s|^https://github.com/||; s|\.git$||')
    # gh writes the 403 body to stdout, so a bare capture looks like success. Demand an integer.
    local rs
    if rs=$(gh api "repos/$nwo/rulesets" --jq 'length' 2>/dev/null) && [ -n "$rs" ] && case "$rs" in ''"''"''|*[!0-9]*) false ;; *) true ;; esac; then
      if [ "$rs" -eq 0 ]; then
        bad "ruleset AVAILABLE but none enabled — run: new-project.sh protect <slug>"
      else
        ok "GitHub ruleset active ($rs) — direct pushes to main rejected server-side"
      fi
    else
      skip "ruleset unavailable on this plan (private repo needs GitHub Pro) — local guards are all there is"
    fi
  else
    skip "no git remote yet — nothing to protect server-side"
  fi

  # vault must be frozen once the repo exists
  if [ -d "$vdir" ] && [ -f "$vdir/intent.md" ]; then
    if grep -qi 'frozen' "$vdir/intent.md"; then ok "vault notes frozen"
    else
      local dup; dup=$(cd "$vdir" && ls intent.md spec.md plan.md 2>/dev/null | tr '\n' ' ')
      bad "repo exists but vault is NOT frozen — live duplicates in the vault: ${dup:-intent.md}"
    fi
  fi
}

say "Project conformance audit — $(date '+%Y-%m-%d %H:%M')"
if [ $# -ge 1 ]; then audit_project "$1"
else
  for d in "$CODE"/*/; do
    s=$(basename "$d"); [ "$s" = "_project-template" ] && continue
    if [ ! -d "$d/docs" ]; then
      say ""; say "── $s ───────────────────────────────────"
      if [ -d "$VAULT/$s" ]; then bad "has a vault folder but no docs/ — scaffold it: new-project.sh repo $s"
      else skip "not an SDLC project (no docs/, no vault folder) — skipped"; fi
      continue
    fi
    audit_project "$s"
  done
  # orphan vault folders
  say ""; say "── vault orphans ───────────────────────────────────"
  found=0
  for d in "$VAULT"/*/; do
    s=$(basename "$d")
    [[ "$s" =~ ^[a-z0-9-]+$ ]] || continue          # only slug-shaped (playbook-era) folders
    if [ ! -d "$CODE/$s" ]; then
      found=1
      if grep -qiE '^\*\*Status\*\*:.*\baccepted\b' "$d/intent.md" 2>/dev/null; then
        bad "vault '$s': intent is accepted but no repo — promote it: new-project.sh repo $s"
      else
        skip "vault '$s': design phase, no repo yet (correct until the intent is accepted)"
      fi
    fi
  done
  [ "$found" -eq 0 ] && ok "no orphaned vault folders"
fi
say ""
[ "$fail" -eq 0 ] && say "All mechanical checks passed." || say "Issues found — see above."
exit 0
