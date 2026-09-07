---
name: sdlc
description: Determine and produce the next artifact in the intent → spec → plan → code chain for a project under ~/dev, and enforce the gates between them. Use when the user asks what the next step is, what to work on next, whether they can start coding, or asks to write or review a spec, plan, ADR, or intent document.
---

# The artifact chain and its gates

Order is **intent → spec → plan → code**. Each is accepted by Werner before the next begins.

## First: establish where the project actually is

Check, in this order:
1. `~/dev/projects/<slug>/docs/features/<feature>/` — which of `intent.md`, `spec.md`, `plan.md` exist?
2. Each file's status line — written is not the same as accepted.
3. `docs/decisions/` — what is already settled and must not be re-litigated.

State the answer plainly before doing anything: *"intent accepted, spec is next, and it's gated on X."*

## The gates

| Want to write | Requires | Never do this |
|---|---|---|
| `spec.md` | accepted `intent.md` | invent requirements the intent never raised |
| `plan.md` | accepted `spec.md` | plan around undecided design |
| code | accepted `plan.md` | scaffold an app "just to get started" |

**Scaffolding the repo's docs is not code. Scaffolding an app — dependencies, `src/`, a build — is.**

If asked to skip ahead, say which gate is open and what would close it. Do the parts that don't
depend on the gate, and name what you left.

## What each artifact contains

**`intent.md`** — problem statement · proposed outcome · affected users/systems · constraints ·
open questions. No solution design; that's the spec's job. Label inferences as assumptions to confirm.

**`spec.md`** — requirements and design decisions. Must resolve everything the intent flagged as
deferred. The intent/spec pair records *what was asked for* and *what was decided*.

**`plan.md`** — files that change, order of work, tests that prove completion, risks.

**ADRs** (`docs/decisions/NNNN-short-kebab-title.md`) — numbered, append-only, **never edited**.
Context · Decision · Alternatives considered · Consequences. Reversing one means a **new** ADR that
supersedes it. Write an ADR whenever a decision must outlive the feature — `intent.md` and `spec.md`
get archived when the feature ships, so a decision left only there is lost.

## Working method

1. **Ask before assuming.** Quiz in rounds; open questions are a valid outcome.
2. **Critique before accepting.** Look for latent logic gaps, domain realities, defaults masquerading
   as decisions, adoption risk, unfalsifiable success criteria. Raise them rather than silently fixing.
3. **Draft, show in full, wait for approval, then write.**
4. **Recommend plan mode + Opus** for `spec.md` and `plan.md`, where design trade-offs matter.
5. After writing, **update the repo `CLAUDE.md`** if conventions changed, and check whether any newly
   settled decision needs an ADR.

Full standing rules: `~/dev/CLAUDE.md`.
