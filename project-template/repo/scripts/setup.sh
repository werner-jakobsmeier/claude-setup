#!/bin/bash
# One-time setup for a fresh clone.
#
# Git hooks are not cloned, so the guards in .githooks/ are inert until this
# points git at them. Run it once per checkout.
set -eu
cd "$(dirname "$0")/.."
git config core.hooksPath .githooks
echo "✓ core.hooksPath -> .githooks"
echo "  pre-commit: refuses commits on main"
echo "  pre-push:   refuses pushes to main"
