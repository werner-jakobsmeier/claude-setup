#!/bin/bash
# PostToolUse (Write|Edit): when a design mock changes, rebuild what is generated
# from it, so the generated copies can never quietly disagree with the source.
#
# Project-agnostic: it triggers on any edit under a `prototype/mocks/` directory
# that has a sibling `prototype/build.sh`, so a project opts in simply by having
# that layout. Written after design notes shipped stale twice in
# group-event-newsletter — the mock was edited and the generator was not re-run.
#
# Builds can be slow (~90s for a full screenshot pass), so this runs async, with
# a lock that coalesces rapid successive edits into one trailing build.
set -u
f=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null)
case "$f" in */prototype/mocks/*) ;; *) exit 0 ;; esac

proto="${f%%/prototype/mocks/*}/prototype"
[ -x "$proto/build.sh" ] || exit 0

key=$(printf '%s' "$proto" | shasum | cut -c1-12)
LOCK="/tmp/rebuild-generated-$key.lock"
DIRTY="/tmp/rebuild-generated-$key.dirty"
: > "$DIRTY"
if mkdir "$LOCK" 2>/dev/null; then
  trap 'rmdir "$LOCK" 2>/dev/null' EXIT
  while [ -f "$DIRTY" ]; do
    rm -f "$DIRTY"
    (cd "$proto" && ./build.sh) > "/tmp/rebuild-generated-$key.log" 2>&1
  done
fi
exit 0
