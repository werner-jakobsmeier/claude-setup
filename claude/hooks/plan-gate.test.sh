#!/usr/bin/env bash
# Regression suite for plan-gate.sh. Run after any change to the gate.
# Reads live projects under ~/dev/projects, so expectations assume:
#   group-event-newsletter has an accepted plan.md · workout-tracker does not.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
H="$HOME"; WT="$H/dev/projects/workout-tracker"; GE="$H/dev/projects/group-event-newsletter"
pass=0; fail=0

t(){ printf '%-42s %-6s' "$1" "$3"
     printf '%s' "$2" | ./plan-gate.sh >/dev/null 2>&1
     r=$([ $? -eq 0 ] && echo ALLOW || echo DENY)
     if [ "$r" = "$3" ]; then echo "→ $r  ok"; pass=$((pass+1))
     else echo "→ $r  ** MISMATCH **"; fail=$((fail+1)); fi; }
w(){ printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1"; }
bc(){ jq -nc --arg c "$1" --arg d "$2" '{tool_name:"Bash",cwd:$d,tool_input:{command:$c}}'; }

t "relative redirect, no plan"   "$(bc 'echo x > src/y.ts' "$WT")"                  DENY
t "heredoc, relative"            "$(bc 'cat > src/y.ts <<EOF' "$WT")"               DENY
t "absolute heredoc"             "$(bc "cat > $WT/src/y.ts <<EOF" "$H")"            DENY
t "quoted absolute target"       "$(bc "echo x > \"$WT/src/y.ts\"" "$H")"           DENY
t "sed -i on app code"           "$(bc "sed -i '' s/a/b/ $WT/src/y.ts" "$H")"       DENY
t "Write, app code"              "$(w "$WT/src/app.ts")"                            DENY
t "> in single quotes"           "$(bc "grep -r 'a > b' src/" "$WT")"               ALLOW
t "> in double quotes"           "$(bc 'grep -r "a > b" src/' "$WT")"               ALLOW
t "relative docs write"          "$(bc 'echo x > docs/features/mvp/spec.md' "$WT")" ALLOW
t "relative write, plan accepted" "$(bc 'echo x > src/y.ts' "$GE")"                 ALLOW
t "plain read"                   "$(bc 'cat src/y.ts' "$WT")"                       ALLOW
t "pipe, no redirect"            "$(bc 'ls src/ | head -5' "$WT")"                  ALLOW
t "cwd outside projects"         "$(bc 'echo x > src/y.ts' "$H/Claude")"            ALLOW
t "Write, docs"                  "$(w "$WT/docs/features/mvp/spec.md")"             ALLOW
t "Write, repo CLAUDE.md"        "$(w "$WT/CLAUDE.md")"                             ALLOW
t "Write, plan accepted"         "$(w "$GE/src/app.ts")"                            ALLOW
t "non-SDLC project"             "$(w "$H/dev/projects/MacUI/src/x.swift")"         ALLOW
t "template"                     "$(w "$H/dev/projects/_project-template/repo/x.ts")" ALLOW
t "outside ~/dev/projects"       "$(w "$H/Claude/scratch.ts")"                      ALLOW
t "unrelated tool"               '{"tool_name":"Read","tool_input":{"file_path":"/etc/hosts"}}' ALLOW

# --- false positives fixed 2026-09-10 ---------------------------------------------
# A quoted redirect target followed by 2>&1: stripping the quotes must not leave the
# '>' to re-pair with the "2" and read it as a file named "2" under the cwd.
t "2>&1 after quoted target"     "$(bc 'git show HEAD:f > "/tmp/out" 2>&1' "$WT")"   ALLOW
t "2>&1, unexpanded \$var target" "$(bc 'tail -c 9 "$V/x.md" > "$S/o.md" 2>&1' "$WT")" ALLOW
t "2>&1, redirect into repo"     "$(bc 'git show HEAD:f > "'"$WT"'/gen.ts" 2>&1' "$H")" DENY
# Heredoc bodies are data: a Markdown '>' line or a path in prose there is not a write.
t "heredoc markdown blockquote"  "$(bc "$(printf 'python3 - <<%sPY%s\n> The repo at ~/dev/projects/workout-tracker/src\nPY' "'" "'")" "$WT")" ALLOW
t "heredoc names a repo path"    "$(bc "$(printf 'cat <<EOF\nsee %s/dev/projects/workout-tracker/src/app.ts\nEOF' "$H")" "$WT")" ALLOW
# ...but a real redirect on the heredoc opener line is still caught.
t "real redirect + heredoc stdin" "$(bc "$(printf 'cat > %s/src/gen.ts <<%sEOF%s\ncode\nEOF' "$WT" "'" "'")" "$H")" DENY

echo; echo "$pass passed, $fail failed"; [ "$fail" -eq 0 ]
