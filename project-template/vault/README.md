# {{TITLE}} — start here

**What this folder is**: the *design-era* record. Read in this order.

## The SDLC chain

| # | Artifact | Status |
|---|---|---|
| 1 | [[intent]] — problem, outcome, constraints, open questions | not started |
| 2 | [[spec]] — requirements + design decisions | not started |
| 3 | [[plan]] — files, order of work, tests, risks | not started |

Files aren't numbered on purpose: `intent/spec/plan` is a template that repeats **per feature**, not one sequence for the project's lifetime. Once a repo exists each feature gets its own chain under `docs/features/<feature>/`. Decisions over time *do* get numbered, as ADRs.

## ⚠ Where the source of truth lives

These notes are authoritative **only until `~/dev/projects/{{SLUG}}` is scaffolded**. After that:

- **How it works today** → the repo (`CLAUDE.md`, `docs/architecture.md`, `docs/data-model.md`). It lives beside the code because that's the only place that changes in the same commit.
- **Why it's like this** → `docs/decisions/NNNN-*.md`, append-only, never edited.
- **What's next** → `docs/features/<feature>/{intent,spec,plan}.md`.
- **These notes** → frozen as the historical design record; not authoritative for current behaviour.

Enforced by a `REVIEW.md` rule: *does this change alter behaviour described in `docs/`? Then `docs/` changes in this PR.* Structure alone decays; the trigger keeps it honest.

Standing convention for every project — see the `documentation-sources-of-truth` memory.
