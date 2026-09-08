# Working in {{TITLE}}

Solo project, so this is deliberately light. Every rule here earns its place by preventing something
that has actually gone wrong.

## One-time setup

```bash
./scripts/setup.sh
```

Git hooks aren't cloned, so this has to be run once per checkout. Until it is, **every local guard
below is inert** — that is the weakest link in the whole scheme. `new-project.sh repo` sets it for you
at creation; a fresh `git clone` still needs it.

## Branching

**Trunk-based with short-lived branches.** No `develop`, no release branches — there's one developer
and no release train, so they'd be pure overhead.

```
<type>/<short-kebab-summary>
```

| Type | For |
|---|---|
| `spike/` | Throwaway. Answers a question, then dies |
| `feat/` | A slice of behaviour |
| `fix/` | A defect |
| `docs/` | Documentation or ADRs only |
| `chore/` | Tooling, dependencies, CI |

**One PR per reviewable idea — not per phase.** If a branch is hard to describe in a sentence, it's
two branches.

## Getting a change to main

```bash
git switch -c feat/your-change
# … work …
git fetch origin && git rebase origin/main   # before opening, and again if it goes stale
git push -u origin HEAD
gh pr create
```

Then **squash and merge**.

- **Rebase, never merge main into your branch.** Keeps history linear and bisectable.
- **Squash on merge** so main reads as one commit per change. The PR body carries the detail.
- Delete the branch after merge.

## Why PRs at all, for one person

The pull request is where [`REVIEW.md`](REVIEW.md)'s documentation trigger fires:

> **Does this change alter behaviour described in `docs/`? Then `docs/` changes in this PR.**

Without a PR there is no moment when that question gets asked, and the structure decays regardless of
how good it is. The PR is not approval theatre — it's the checkpoint.

## Commit messages

Subject in the imperative, under ~72 chars. Body explains **why**, not what — the diff already says
what. Reference an ADR when the change implements a decision.

## What's enforced, and where

| Rule | Enforced by | Override |
|---|---|---|
| No **commit** on `main` | `.githooks/pre-commit` | `ALLOW_MAIN=1 git commit` |
| No **push** to `main` | `.githooks/pre-push` | `git push --no-verify` |
| A commit reaching `main` anyway | `.github/workflows/guard-main.yml` — fails if the commit has no PR | none (detection, not prevention) |
| Claude committing or pushing on `main` | `~/.claude/hooks/block-main-commits.sh` | prefix `ALLOW_MAIN=1` |
| Code written before an accepted `plan.md` | `~/.claude/hooks/plan-gate.sh` | none — write the plan |
| Docs change alongside behaviour | `REVIEW.md`, read at review time | judgement |

**Code reaches `main` only by merging a pull request.** `pre-commit` stops work being committed on
main; `pre-push` stops a branch being pushed there. Without the first, a commit could be made on main
and then be stranded — unpushable and easy to lose.

The Claude Code hooks live in `~/.claude/settings.json`, outside this repo, because they must fire from
sessions rooted anywhere, not only from a session opened in this directory. They are versioned in
[claude-setup](https://github.com/werner-jakobsmeier/claude-setup).

### The honest limit

**A GitHub ruleset requiring a pull request is the only unbypassable enforcement.** It is free on
**public** repositories and requires GitHub Pro (~$4/month) on **private** ones.

Check which applies here:

```bash
gh api repos/OWNER/REPO/rulesets --jq 'length'   # 403 => unavailable on this plan
```

**If it is available, enable it — it makes everything below redundant.** If it isn't:

- every local guard is bypassable with `--no-verify` or `ALLOW_MAIN=1`;
- none of them exist in a clone that hasn't run `scripts/setup.sh`;
- the CI job catches a direct push *after* it lands, not before.

That stack makes a direct push to main deliberate, and loud if it happens anyway — but not impossible.

## Documentation rules

See [`CLAUDE.md`](CLAUDE.md). The short version: the repo owns *how it works today*,
`docs/decisions/` owns *why* and is append-only, `docs/features/<feature>/` owns *what's next*, and the
Obsidian vault is frozen design history that is **not** authoritative.
