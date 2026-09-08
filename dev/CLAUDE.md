# Working rules — all projects under ~/dev

These apply to every project here. They are conventions Werner has already decided; follow them
without re-deriving or asking, and say so if a request conflicts with one.

## 1. The SDLC chain (AI-native SDLC playbook)

Every feature moves through **intent → spec → plan → code**, in that order, each accepted before the next.

| Artifact | Holds | Gate |
|---|---|---|
| `intent.md` | problem · outcome · affected users/systems · constraints · open questions | Werner accepts before spec |
| `spec.md` | requirements + design decisions | Werner accepts before plan |
| `plan.md` | files that change, order of work, tests that prove done, risks | Werner accepts before code |

**Hard rules:**
- **Never write code before an accepted `plan.md`.** Scaffolding a repo's *docs* is not code; scaffolding an app (deps, `src/`) is.
- **Never write the next artifact before the previous is accepted.** Draft it, show it, wait.
- **Elicit intent by asking questions**, not by assuming. Then draft, then get explicit approval.
- Keep solution design *out* of `intent.md` — it belongs in `spec.md` where it gets scrutinised.
- **Label your own inferences as assumptions to confirm.** If Werner didn't say it, don't write it as decided.

## 2. Where each kind of documentation lives

One home per question. Never two places answering the same one.

| Question | Home | Lifecycle |
|---|---|---|
| How does it work today? | repo — `CLAUDE.md`, `docs/architecture.md`, `docs/data-model.md` | durable; same PR as the change |
| Why is it like this? | `docs/decisions/NNNN-*.md` (ADRs) | append-only; **never edited** |
| What are we building next? | `docs/features/<feature>/{intent,spec,plan}.md` | disposable; archived once shipped |
| Half-formed thinking | Obsidian vault `01 Projects/<slug>/` | ephemeral; **not** authoritative |

- A decision that must outlive the feature goes in an **ADR**, not only in `intent.md` — `intent.md` gets archived.
- Once a repo exists it owns the chain. **Freeze the vault notes** as the design-era record.
- `REVIEW.md` carries the trigger: *does this change alter behaviour described in `docs/`? Then `docs/` changes in this PR.*

## 3. Scaffolding — never hand-write it

```
~/dev/projects/_project-template/new-project.sh init <slug> "<Title>"   # vault design folder
~/dev/projects/_project-template/new-project.sh repo <slug> "<Title>"   # repo docs skeleton + git init
~/dev/projects/_project-template/new-project.sh sync <slug> [--apply]   # re-stamp after template changes
```

Hand-writing these produces variants — it has happened. If a convention needs to change,
**change the template and re-stamp**; don't edit projects one at a time.

Slugs are lowercase-kebab and match the vault folder, the repo folder, and `~/dev/projects/<slug>`.

## 4. Branching — code reaches `main` only through a pull request

**Never commit or push directly to `main`.** This applies to every repo under `~/dev/projects`,
including tooling repos, and it applies to Claude as much as to a person.

```bash
git switch -c <type>/<short-kebab-summary>   # spike | feat | fix | docs | chore
# … work …
git fetch origin && git rebase origin/main
git push -u origin HEAD
gh pr create                                  # then squash-merge
```

Rebase rather than merging main into a branch; squash on merge so main reads as one commit per change.
One PR per reviewable idea, not per phase.

**Why, for a one-person project:** the pull request is the only moment `REVIEW.md`'s documentation
trigger actually fires — *does this change alter behaviour described in `docs/`? then `docs/` changes
in this PR*. No PR means no checkpoint, and the structure decays no matter how good it is.

Enforcement is layered, and each layer is bypassable except the first:
`.githooks/pre-commit` and `pre-push` (need `core.hooksPath .githooks` — `new-project.sh repo` sets it),
`.github/workflows/guard-main.yml` as a post-hoc CI backstop, and `~/.claude/hooks/block-main-commits.sh`
for Claude. **A GitHub ruleset requiring a PR is the only real enforcement** — free on public repos,
GitHub Pro on private ones. Enable it wherever it is available; it makes the rest redundant.

Each repo's `CONTRIBUTING.md` carries the detail.

## 5. What is and isn't standardised

**Standardised:** process, documentation structure, scaffolding.
**Deliberately NOT standardised: the stack.** group-event-newsletter is TanStack Start (SSR);
workout-tracker is a Vite SPA by explicit decision (ADR 0001). **Never force stack consistency
between projects** — each has reasons recorded in its ADRs. Read them before proposing a change.

## 6. Writing style

Concise. State the decision and the constraint; cut restated rationale. Prefer a table over prose
when comparing options. Don't pad documents to look thorough.
