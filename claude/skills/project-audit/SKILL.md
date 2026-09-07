---
name: project-audit
description: Audit projects under ~/dev for drift from the SDLC playbook, the documentation sources-of-truth convention, and the shared project template — then propose fixes. Use when the user asks to check, audit, triage, heal, tidy, or health-check their projects, asks whether things are still following the conventions, or wants to know if anything has drifted or fallen out of structure.
---

# Project conformance audit

Two passes. Run the mechanical one first — it is cheap and catches most drift.

## Pass 1 — mechanical (scripted)

```bash
~/dev/projects/_project-template/project-audit.sh          # all projects
~/dev/projects/_project-template/project-audit.sh <slug>   # one
```

Checks slug shape, vault↔repo pairing, template conformance, unfilled `CLAUDE.md` sections,
ADR numbering (unique + sequential), chain order per feature, app code that exists without a
`plan.md`, whether vault notes were frozen once the repo appeared, and orphaned vault folders.

Report its output as-is. Do not re-check by hand what the script already checked.

## Pass 2 — judgment (yours)

The script cannot judge content. For each project, read `docs/features/*/`, `docs/decisions/`,
`docs/architecture.md`, `CLAUDE.md`, and look for:

- **Decisions that will be lost.** A load-bearing decision recorded only in `intent.md` or `spec.md`
  disappears when the feature is archived. It needs an ADR. This is the single most common real finding.
- **Two homes for one question.** The same fact stated in both the repo and the vault, or in both
  `CLAUDE.md` and `docs/architecture.md`. One must become the pointer.
- **Status lines that contradict reality** — an intent marked "draft" when the spec is written; a
  `CLAUDE.md` "Status" section describing a stage the project has left.
- **`docs/architecture.md` describing what is *intended* rather than what is *built*.** It is a
  current-state document; if nothing is built, it should say so rather than duplicating the spec.
- **Assumptions never confirmed.** Items flagged "assumption to confirm" in an intent that the spec
  silently inherited as decided.
- **Edited ADRs.** ADRs are append-only. Check: `git -C ~/dev/projects/<slug> log --oneline -- docs/decisions/`
  — a modification commit to an existing ADR is a violation; the fix is a new superseding ADR, not a revert.
- **Stale next-steps** — checklist items already done, or that name a blocker since resolved.

## Heal policy

Be conservative. The audit's value is that its output can be trusted.

**Safe to apply without asking:**
- `new-project.sh sync <slug> --apply` — restores missing/modified template-owned files only.

**Propose, show the diff, and wait:**
- Freezing vault notes; writing a new ADR; editing `CLAUDE.md`, `architecture.md`, or any chain artifact;
  correcting a status line.

**Never:**
- Edit or delete an existing ADR. Superseding means writing a *new* one that references the old.
- Delete anything from the vault. Freezing means adding a banner, not removing content.
- "Fix" a stack inconsistency between projects — that is deliberate (see `~/dev/CLAUDE.md` §4).

## Cadence

Worth running when starting work on a project after a gap, after finishing a chain artifact, and
after changing the template — the last one is the case where every project drifts at once.

Full rules: `~/dev/CLAUDE.md`.
