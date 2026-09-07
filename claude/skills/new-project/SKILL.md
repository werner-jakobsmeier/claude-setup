---
name: new-project
description: Scaffold a new project under ~/dev following the AI-native SDLC playbook — creates the Obsidian vault design folder and later the repo docs skeleton, via the shared template. Use when the user wants to start, create, scaffold, or set up a new project, app, or idea; or asks to promote an idea from their Project Ideas backlog into a real project.
---

# Scaffolding a new project

Never hand-write these files. The template is the source of truth; hand-written variants have
caused drift before.

## Step 1 — pick the slug

Lowercase-kebab, used identically for the vault folder, the repo folder, and `~/dev/projects/<slug>`.
Confirm it with the user if it isn't obvious from their wording.

## Step 2 — create the vault design folder

```bash
~/dev/projects/_project-template/new-project.sh init <slug> "<Title>"
```

Creates `01 Projects/<slug>/` in the Obsidian vault with a `README.md` index and an `intent.md`
skeleton, already in the right shape.

## Step 3 — write `intent.md` by interviewing, not assuming

Do **not** fill the skeleton from your own guesses. Ask the user questions in rounds until you
can state: the problem, the proposed outcome, who and what is affected, the real constraints,
and what's still open. Useful ground to cover:

- What do they do today, and what specifically fails about it?
- Who uses it — just them? Others later?
- What's the single most important interaction? What is the app *primarily* for?
- What platform, and what actually forces that choice?
- What would make them abandon it? What's the cold-start cost?
- How would they know in two months that it was worth building? (Push for something checkable.)

Then draft the artifact, show it in full, and **wait for explicit approval** before writing it.

Mark anything you inferred rather than heard as an **assumption to confirm** — otherwise `spec.md`
inherits it unexamined.

## Step 4 — critique before moving on

Before the intent is accepted, review it yourself for: latent logic gaps, domain realities the user
may not have considered, architecture choices made by default rather than decision, adoption risk,
and unfalsifiable success criteria. Raise them; don't quietly fix them.

## Step 5 — scaffold the repo when the intent is accepted

```bash
~/dev/projects/_project-template/new-project.sh repo <slug> "<Title>"
```

Creates `CLAUDE.md`, `REVIEW.md`, `docs/{architecture,data-model}.md`, `docs/decisions/`,
migrates the chain into `docs/features/mvp/`, and runs `git init`.

Then:
- **Write ADRs** for decisions already accepted during the intent phase. They currently live only in
  `intent.md`, which is the disposable lane — they must move to the append-only lane to survive.
- **Freeze the vault notes**: banner on `intent.md` pointing at the repo copy, and flip the vault
  `README.md` to say the repo now owns the chain.
- **Fill in the repo `CLAUDE.md`** with what's actually true — leaving the stub empty wastes the
  always-loaded layer.

## Step 6 — stop

The repo docs skeleton is not permission to write app code. **`spec.md` and `plan.md` come first.**
See the `sdlc` skill.
