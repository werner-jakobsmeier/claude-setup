# claude-setup

Version-controlled working conventions for AI-assisted development — the rules, skills, and
scaffolding that make every project under `~/dev` follow the same flow.

Built around the [AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook):
every feature moves **intent → spec → plan → code**, each artifact accepted before the next.

## What's here

| Path | Installs to | What it does |
|---|---|---|
| `dev/CLAUDE.md` | `~/dev/CLAUDE.md` | The standing rules. Read automatically in every session under `~/dev` — this is the layer that doesn't depend on recall. |
| `claude/skills/new-project/` | `~/.claude/skills/` | Scaffold a project: slug → vault folder → intent interview → critique → repo promotion. |
| `claude/skills/sdlc/` | `~/.claude/skills/` | Which artifact is next, and the gates between them. |
| `claude/skills/project-audit/` | `~/.claude/skills/` | Find and fix drift across all projects. |
| `claude/agents/` | `~/.claude/agents/` | Five review personas, each with its own context window and read-only tools. |
| `claude/hooks/plan-gate.sh` | run from here | Refuses app-code writes into a project with no accepted `plan.md`. |
| `claude/settings-hooks.json` | merged into `~/.claude/settings.json` | Registers the hook. Merged, not symlinked — see *Not tracked*. |
| `project-template/` | `~/dev/projects/_project-template` | The scaffolding itself, plus `new-project.sh` and `project-audit.sh`. |

## Install

```bash
git clone git@github.com:werner-jakobsmeier/claude-setup.git ~/dev/claude-setup
~/dev/claude-setup/install.sh
```

Everything is **symlinked**, not copied — edit the installed file and the change is already in the
repo. No syncing back, no forgetting which copy is real.

## Commands

```bash
new-project.sh init <slug> "<Title>"     # vault design folder
new-project.sh repo <slug> "<Title>"     # repo docs skeleton, migrates the chain, git init
new-project.sh sync <slug> [--apply]     # re-stamp after the template changes (dry run by default)
project-audit.sh [slug]                  # conformance checks across all projects
```

## Roles, and what each one actually is

The playbook names six roles. They do **not** map onto six agents — a subagent starts cold and
cannot ask a question, so the roles that are conversations with Werner stay in the main thread.

| Role | Mechanism | Why |
|---|---|---|
| Product manager | main thread + `sdlc` skill | must interview Werner; a subagent would invent requirements |
| Technical architect | main thread, plan mode | needs full repo and ADR context, and explicit approval |
| Engineer | main thread; parallel subagents once the plan is accepted | the plan names the files, so slices are safe |
| QA / verification | `spec-critic`, `plan-verifier`, `qa-reviewer`, `doc-drift`, `adr-gap-finder` | narrow input, checkable output — and a cold context cannot rationalise work it didn't do |
| Release | `plan-gate.sh` (PreToolUse hook) | a gate a model can be talked out of is not a gate |
| Operations | scheduled task → `project-audit.sh` | a recurring job, not a conversation |

Agents are invoked by name (*"have spec-critic look at this"*) or picked up automatically from their
`description`. All five are **read-only** — they produce findings, Werner decides.

## The plan gate

`plan-gate.sh` runs before every `Write`, `Edit`, `NotebookEdit` and write-shaped `Bash` call. It
blocks when **all** of these hold: the target is under `~/dev/projects/<slug>/`, that project has a
`docs/` directory, the path is app code (not `docs/`, `.claude/`, `CLAUDE.md`, `REVIEW.md`,
`README.md`), and no `docs/features/*/plan.md` carries an accepted status line.

Acceptance is matched as `\baccepted\b`, so the template's *"awaiting acceptance"* correctly does
not count. Written is not accepted.

To bypass it deliberately, stamp the plan's status line — which is the point.

## The idea

Conventions decay when they live only in someone's head, or in a tool's soft memory. These live in
files that load unconditionally, are enforced by scripts that check the same things every time, and
are versioned so a change to the convention is a change to the template — applied everywhere with
`sync`, not re-typed per project.

## Not tracked

`~/.claude/settings.json` is deliberately excluded — it holds machine-specific settings and may
gain environment values that shouldn't be published. The hook registration is therefore kept here as
`claude/settings-hooks.json` and **merged** into it by `install.sh` (with a timestamped backup, and
the repo path substituted). Everything else is symlinked as normal.
